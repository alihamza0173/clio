# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Web terminal renderer** (`WebTerminalView`): xterm.js hosted in `flutter_inappwebview`, replacing the `xterm` package widget. Hardware keyboard is captured by Flutter and forwarded to the PTY (WKWebView receives no keyboard on macOS), with Cmd+C/Cmd+V clipboard support. Assets bundled under `assets/web_terminal/` (xterm core + `fit`/`unicode11`/`web-links`/`webgl` addons, `bridge.js`, CSS).
- **Terminal key encoder** (`terminal_key_encoder.dart`): maps Flutter `KeyEvent`s to PTY byte sequences — arrow keys, function keys, Ctrl/Alt modifiers, and UTF-8 characters.
- **`ClaudeSessionService`**: reads live Claude TUI state by PID and transcript metadata; exposes `hasResumableTranscript()` and reads AI-assigned session titles.
- **Session renaming**: rename a session; persisted locally and reconciled with Claude transcript titles on startup.
- **Resume ID tracking**: sessions track a `resumeId` (the real Claude transcript id) distinct from the internal session UUID, auto-updated when the user resumes a different chat inside the running TUI.
- **File drag-and-drop into the terminal** via `desktop_drop`; dropped paths are quoted and pasted.
- **Persisted UI state**: remembers the last selected project and the active session per project (new keys `clio.selected_project`, `clio.active_session.<projectId>`).
- **JetBrains Mono Medium** font for terminal weight 700.

### Changed
- `Session` entity gains a `resumeId` field (defaults to `id`), included in `copyWith`/equality.
- `TerminalController` refactored around a `TerminalBridge`; spawns `claude` lazily at the renderer's exact columns/rows on first ready, and polls `ClaudeSessionService` by PID to reconcile `resumeId`.
- `ProjectSessionsScreen` now keeps all session terminals mounted (`IndexedStack`) so state survives tab switches, and syncs titles from Claude transcripts on load.
- `ShellEnvService` passes `CLAUDE_CODE_NO_FLICKER=1` to the `claude` process.

### Fixed
- Session titles stay in sync with user-assigned titles from the Claude TUI.
- PTY starts at the renderer's exact size, avoiding double-render artifacts in Claude's Ink TUI.

### Dependencies
- Added `flutter_inappwebview ^6.1.5` and `desktop_drop ^0.6.0`.

## [0.1.0] - 2026-05-25

### Added
- Initial Flutter desktop scaffold (macOS/Linux/Windows) under the name **clio**.
- **Feature-first clean architecture**: `core/` shared layer plus `features/projects` and `features/sessions`, each split into `data / domain / presentation`.
- **Riverpod 3.x** state management with code generation (`@riverpod`); DI seam in `core/providers`.
- **Localization** via official `gen-l10n` — English and Arabic (RTL), `l10n.yaml` + ARB files.
- **Projects feature**: add a folder as a project (via `file_selector`), list and remove projects; persisted to `shared_preferences` (`clio.projects`).
- **Sessions feature**: per-project Claude sessions backed by a real PTY (`flutter_pty`) rendered with `xterm`. Each session owns a UUID used for `claude --session-id` (first launch) and `claude --resume` (restore); persisted per project (`clio.sessions.<projectId>`).
- `terminalController` (keepAlive) owning the PTY ↔ terminal lifecycle so switching tabs does not kill running `claude` processes.
- Core services: `pty_service`, `process_service`, `shell_env_service` (login-shell `PATH` loader), `storage_service`, `uuid_service`.
- GitHub-dark theme and bundled JetBrains Mono font.

### Notes
- `riverpod_generator` / `riverpod_lint` resolve to dev prereleases — the only versions compatible with the `riverpod 3.2.1` runtime; they are build-time only.
- `riverpod_lint` 3.x registers through `analysis_server_plugin` (no `custom_lint`).

[Unreleased]: https://github.com/alihamza0173/clio/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/alihamza0173/clio/releases/tag/v0.1.0
