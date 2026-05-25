# clio

A terminal-style desktop app (macOS/Linux/Windows) for managing multiple **Claude Code** sessions, organized by project.

Add a project by picking its folder, then spawn multiple **sessions** inside it. Each session launches `claude` directly in that directory — you land straight in a Claude chat. Sessions are persisted by id and resumed (`claude --resume`) on the next launch, so your conversations are restored.

> Early scaffold. The architecture, state management, and localization are in place; features are a work in progress — see [CHANGELOG.md](CHANGELOG.md).

## Features

- **Projects** — add folders as projects; the list is persisted locally.
- **Sessions** — each project hosts multiple Claude sessions, each backed by a real pseudo-terminal (PTY) rendering the interactive `claude` TUI.
- **Resume** — every session owns a UUID used as `claude --session-id`; on restart it resumes via `claude --resume <id>`.
- **Localization** — English and Arabic (RTL) out of the box, via Flutter's official `gen-l10n`.

## Tech stack

| Concern | Choice |
| --- | --- |
| State management | [Riverpod](https://riverpod.dev) 3.x + code generation (`@riverpod`) |
| Localization | Official `flutter_localizations` + `intl` + `gen-l10n` (ARB files) |
| Persistence | `shared_preferences` (project paths + session ids, as JSON) |
| Terminal | `flutter_pty` (PTY) + `xterm` (terminal emulator widget) |
| Folder picker | `file_selector` |
| IDs | `uuid` (v4) |

## Architecture

Feature-first **clean architecture**. Each feature is split into `data / domain / presentation`; shared code lives in `core/`.

```
lib/
  main.dart                 # ProviderScope + SharedPreferences override
  app/clio_app.dart         # MaterialApp: theme, l10n, home
  core/
    constants/              # storage keys, claude executable
    theme/                  # colors, typography, ThemeData
    error/                  # Failure / Exception types
    services/               # pty, process, shell-env, storage, uuid
    providers/              # DI seam (service providers)
  l10n/                     # app_en.arb, app_ar.arb (+ generated)
  features/
    projects/
      data/                 # datasource, model, repository impl
      domain/               # entity, repository interface, usecases
      presentation/         # notifiers, screen, widgets
    sessions/
      data/ domain/ presentation/   # same layering; terminal_controller owns PTY+xterm
```

**Data flow:** `presentation (Riverpod notifier)` → `domain (usecase → repository interface)` → `data (repository impl → datasource)`. The presentation layer never imports `data` implementations directly except through providers in `core/providers` and the feature notifier files.

## Getting started

Prerequisites:
- Flutter (Dart SDK `^3.12.0`) with desktop support enabled.
- The [`claude`](https://code.claude.com/docs) CLI on your `PATH` (sessions launch it).

```bash
flutter pub get
dart run build_runner build          # generate Riverpod *.g.dart
flutter gen-l10n                     # generate localizations
flutter run -d macos                 # or -d linux / -d windows
```

During development, keep codegen running:

```bash
dart run build_runner watch
```

## Development notes

- **No hand-written comments** in source unless they explain non-obvious intent — match the existing style.
- After adding/editing a `@riverpod` provider or a notifier, re-run `build_runner`.
- The Riverpod 4.x generator **strips the `Notifier` suffix**: `class ProjectsNotifier` generates `projectsProvider` (not `projectsNotifierProvider`).
- `flutter analyze` must be clean before committing.

See [CLAUDE.md](CLAUDE.md) for full conventions.
