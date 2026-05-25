# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
