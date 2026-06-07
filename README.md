# clio

A terminal-style desktop app (macOS/Linux/Windows) for managing multiple **Claude Code** sessions, organized by project.

Add a project by picking its folder, then spawn multiple **sessions** inside it. Each session launches `claude` directly in that directory — you land straight in a Claude chat. Sessions are persisted by id and resumed (`claude --resume`) on the next launch, so your conversations are restored.

> Early scaffold. The architecture, state management, and localization are in place; features are a work in progress — see [CHANGELOG.md](CHANGELOG.md).

## Project status & contributions

clio is in a **full development phase** — the architecture, APIs, and UI change
frequently and without notice. **Pull requests are not reviewed or accepted**
right now. You're welcome to **fork** it for your own use; it's MIT-licensed
(see [LICENSE](LICENSE)).

## Download

Prebuilt macOS and Windows builds are attached to each release on the
[**GitHub Releases**](https://github.com/alihamza0173/clio/releases) page. Download the
`clio-*-macos.zip` or `clio-*-windows-x64.zip` for the latest version, unzip, and run.

### Opening the app on macOS (unsigned build)

The macOS build is **unsigned and not notarized** (there's no Apple Developer account
yet), so on first launch Gatekeeper blocks it with:

> "Apple could not verify 'clio' is free of malware that may harm your Mac."

The fix is a **one-time** command after unzipping — clear the quarantine attribute, then
open the app normally:

```bash
xattr -cr ~/Downloads/clio.app
```

Adjust the path if you extracted it elsewhere. You only need to do this **once per
downloaded copy**; after the first launch the app opens by double-clicking like any
other app.

Prefer not to use the terminal? Click **Done** on the dialog, then go to **System
Settings → Privacy & Security**, scroll to the bottom, and click **Open Anyway**.

### Running on Windows

The Windows build is a **portable app** — no installer. Extract the entire zip and keep
all files together in one folder; `clio.exe` loads its DLLs and the `data/` folder from
beside itself, so don't move the `.exe` out on its own. Run `clio.exe` (optionally pin it
to Start or the taskbar).

The exe is **unsigned**, so on first launch SmartScreen may show *"Windows protected your
PC"*. Click **More info**, then **Run anyway** — this only happens once.

Requirements:
- The `claude` CLI must be on your `PATH` (same as macOS).
- The **Microsoft Edge WebView2 Runtime** must be installed. It's preinstalled on Windows
  11 and most Windows 10 machines; if the app window is blank, install it from
  <https://developer.microsoft.com/microsoft-edge/webview2/>.

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
