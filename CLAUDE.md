# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this app is

`clio` is a Flutter **desktop** app (macOS/Linux/Windows) that manages multiple **Claude Code (`claude` CLI) sessions**, organized by project. A user adds a project (a folder), then creates sessions inside it. Each session spawns the interactive `claude` TUI in the project directory via a real pseudo-terminal — there is **no manual shell**; the user lands directly in a Claude chat.

## Commands

```bash
flutter pub get                       # install deps
dart run build_runner build           # regenerate Riverpod *.g.dart (run after editing any @riverpod)
dart run build_runner watch           # codegen in watch mode during development
flutter gen-l10n                      # regenerate AppLocalizations from lib/l10n/*.arb
dart format <file>                    # run after editing any Dart file (see below)
flutter analyze                       # must be clean before committing
flutter run -d macos                  # or -d linux / -d windows
flutter build macos --debug           # full native compile check (verifies flutter_pty links)
flutter test                          # run tests (none yet)
flutter test path/to/foo_test.dart -p name   # single test by name
```

`flutter run` / `flutter pub get` auto-trigger l10n generation (`generate: true`), but **not** Riverpod codegen — run `build_runner` yourself after provider changes.

## Architecture

Feature-first **clean architecture**. Shared code in `core/`; each feature in `features/<name>/` split into three layers:

- **domain** — pure Dart: `entities/` (plain immutable classes, manual `==`/`hashCode`, no codegen/freezed), `repositories/` (abstract interfaces), `usecases/` (one thin callable class each).
- **data** — `models/` (extend the entity, hand-written `toJson`/`fromJson`), `datasources/` (talk to `KeyValueStore`), `repositories/` (implement the domain interface).
- **presentation** — Riverpod notifiers (`@riverpod`), screens, widgets.

**Dependency rule:** presentation → domain → data. Presentation reaches implementations only through providers (`core/providers/core_providers.dart` for services; the feature notifier files wire datasource → repository). Don't import a `data/` impl directly into a widget.

**Two features:** `projects` (CRUD of folders) and `sessions` (Claude sessions per project). `ProjectsScreen` is a master/detail: a projects rail on the left, the selected project's `ProjectSessionsScreen` on the right.

### Session lifecycle (the core of the app)

- Each `Session` owns a v4 UUID (`Session.id`). First launch runs `claude --session-id <id>`; once started (`claudeStarted = true`, persisted), restore runs `claude --resume <id>`. Never use `--continue` or `--fork-session`. Claude owns the chat history; clio only stores the id and re-invokes.
- `terminal_controller.dart` (`@Riverpod(keepAlive: true)`) owns the PTY ↔ xterm `Terminal` for one session: pipes `pty.output → terminal.write`, `terminal.onOutput → pty.write`, `terminal.onResize → pty.resize(rows=height, cols=width)`, and kills the pty in `ref.onDispose`. It is **keepAlive** so switching tabs doesn't kill `claude`; closing a session must `ref.invalidate(terminalControllerProvider(projectId, sessionId))` to dispose it.
- The PTY environment comes from `ShellEnvService.buildEnvironment()`, which merges the login-shell `PATH` (`$SHELL -l -c 'echo $PATH'`) so `claude` resolves.

### Persistence

`shared_preferences` only, as JSON strings (`core/constants/app_constants.dart`):
- `clio.projects` → list of `{id,name,path,createdAt}`
- `clio.sessions.<projectId>` → list of `{id,title,claudeStarted,createdAt}`

`sharedPreferencesProvider` is resolved in `main()` and injected via `ProviderScope(overrides: [...])`.

## Conventions & gotchas

- **Always run `dart format` on a Dart file after you finish editing it** (e.g. `dart format lib/path/to/file.dart`) before moving on.
- **No comments** in source unless they capture non-obvious intent. Match surrounding style.
- **Use dot shorthands** (SDK is Dart 3.12) wherever the target type is inferred: `.stretch` for `crossAxisAlignment`, `const .all(12)` / `const .symmetric(...)` for `EdgeInsets`, `.zero`, `.ellipsis`, `.centerLeft`, etc. `dart format` and `flutter analyze` accept them.
- **Prefer adaptive widgets so macOS gets native Cupertino chrome**: `showAdaptiveDialog` + `AlertDialog.adaptive`, branching to `CupertinoDialogAction` (use `isDestructiveAction` for destructive choices) under `Platform.isMacOS` with a `TextButton` fallback; `CircularProgressIndicator.adaptive()`. Note: adaptive spinners render `CupertinoActivityIndicator` on macOS and ignore the Material `progressIndicatorTheme`.
- **Centralize shared widget styling in `AppTheme`** (`DividerThemeData`, `ProgressIndicatorThemeData`, …) rather than passing the same props per-widget. `Divider`/`VerticalDivider` default `height` to 16 — set it explicitly when you need a hairline.
- **Import order:** `package:` imports before relative (`../`) imports.
- **Riverpod 4.x generator strips the `Notifier` suffix**: `class ProjectsNotifier` → `projectsProvider` (NOT `projectsNotifierProvider`). `Controller`/`Id` suffixes are kept (`terminalControllerProvider`, `activeSessionIdProvider`).
- `riverpod_annotation`/`riverpod_generator` are on the **4.x** line while the runtime (`flutter_riverpod`/`riverpod`) is **3.x** — this is the correct decoupled pairing; do not "align" them to the same major. `riverpod_generator`/`riverpod_lint` resolve to dev prereleases (only versions matching `riverpod 3.2.1`); leave them.
- Provider files use `import 'package:riverpod_annotation/riverpod_annotation.dart';` and the non-generic `Ref`. Widgets import `flutter_riverpod`.
- On `AsyncValue`, use `.value` (nullable), not `.valueOrNull` (not defined in 3.x).
- Avoid `firstOrNull` on `Iterable` — it's not in `dart:core` here; use an explicit loop/helper.
- Localized strings live in `lib/l10n/app_en.arb` (template) + `app_ar.arb`; access via `AppLocalizations.of(context)` (non-null — `nullable-getter: false`). Add new keys to both ARBs, then `flutter gen-l10n`. Use directional widgets (start/end) so Arabic RTL works.
- The native `flutter_pty` plugin emits a Swift Package Manager warning on macOS builds — informational, not an error.

## Note on the package name

The pubspec `name:` is `clio`; imports use `package:clio/...`. (The repo was renamed from an earlier `dart_terminal`.)
