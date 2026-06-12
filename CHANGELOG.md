# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.1] - 2026-06-12

### Fixed
- **Windows: new session failed with `Error: Invalid JSON provided to --settings`.** The busy-indicator hooks were passed as an inline JSON string to `claude --settings`; on Windows `flutter_pty` builds the command line with no quoting, so `CreateProcessW`/Node argv parsing consumed the `"` characters in the JSON and claude received malformed settings. The hook config is now written to a temp file and passed as `--settings <path>` (`ClaudeHookServer.settingsFile()`), with the path wrapped in quotes on Windows to survive spaces. The temp dir is cleaned up when the session is disposed. macOS/Linux load the same settings, now from a file.

## [0.2.0] - 2026-06-12

### Added
- **Selected session tab auto-scrolls into view.** With an overflowed tab strip, the active tab could sit off-screen (app start at offset 0 with a far-right persisted session, or returning to a project after scrolling the strip away), forcing the user to hunt for the selection. Each tab now reveals itself (`Scrollable.ensureVisible`, centered, 200 ms) when it becomes active, when its project becomes visible again (the `visible` flag is threaded `ProjectsScreen` → `ProjectSessionsScreen` → `SessionTabBar`), and on first build. The strip switched from a lazy horizontal `ListView` to `SingleChildScrollView` + `Row` — lazily-built off-screen tabs never mounted, so they could never scroll themselves into view.
- **Live status indicator on session tabs.** While a session's `claude` is working, the tab's bottom underline animates as an indeterminate linear loader (green over a dimmed track on the active tab, over transparent on background tabs); when blocked on a permission prompt the underline turns solid amber and an amber dot appears next to the title, so background sessions are visible at a glance. Terminal-generated input (xterm.js focus reports, query responses, paste — `TerminalBridge.handleReply`) is excluded from "user is typing" detection so re-focusing a tab can't flip a pending permission prompt back to busy and let the silence watchdog wrongly clear it; keystrokes while a prompt is pending don't clear it either (answering one question of a multi-question prompt must keep the amber state) — the `PostToolUse` hook restores busy once the prompt is fully resolved and the tool actually runs. The attention state also bubbles up to the sidebar: a project tile's start border turns amber (instead of the green selection border) whenever any of its sessions is waiting on a permission prompt (`projectNeedsAttentionProvider`), including projects that aren't currently selected. Driven by per-invocation Claude Code hooks: `terminal_controller` injects `--settings` with `http`-type hooks (`UserPromptSubmit`, `PostToolUse`, `Stop`/`StopFailure`, `SessionEnd`, `Notification` with `permission_prompt`/`idle_prompt` matchers) that POST to a new in-app loopback `ClaudeHookServer` (ephemeral port, identity in the URL path so it survives claude-side session-id drift from `/clear`/`/resume`; `allowedHttpHookUrls` allow-listed; hooks merge across scopes so user hooks keep working). State lives in a new `sessionStatusProvider(projectId, sessionId)` (idle/busy/needsAttention), invalidated on tab close; the indicator occupies a fixed 12 px slot so tabs never reflow. Since `Stop` never fires on an Esc/Ctrl+C interrupt (and the idle TUI keeps repainting, so output silence can't be trusted), a bare Esc/Ctrl+C keypress in the input path demotes the status immediately, with a 6 s output-silence watchdog kept only as a dead-session backstop. If the hook server fails to start, the session launches without hooks (no indicator, otherwise unaffected).
- **Hide / unhide projects without losing sessions.** Each project tile now shows hover-revealed actions (hide, remove — the remove button is no longer always visible) and a right-click context menu. Hidden projects move to a collapsible "HIDDEN (n)" section at the bottom of the sidebar, rendered dimmed; they stay fully openable from there (terminals/sessions keep running, `IndexedStack` still mounts all projects) and can be unhidden anytime. Hiding the selected project keeps it selected and auto-expands the section. Persisted as a backward-compatible `hidden` flag on `Project` (`clio.projects` JSON, defaults to visible); backed by a new `updateProject` repository method and `UpdateProject` usecase.

## [0.1.5] - 2026-06-11

### Fixed
- **macOS: terminal stopped accepting keyboard input after idle, and new sessions ignored input until a tab switch.** The terminal is a real `WKWebView` NSView (flutter_inappwebview), but the app relies on the Flutter view owning the physical keyboard. When the window lost and regained key status (app switch, display sleep, Mission Control), or when a freshly-loaded webview grabbed first responder, macOS routed `keyDown` to the webview, which silently dropped it — so typing was dead even though clicking, copying, and tab-switching still worked. `_focus.requestFocus()` only set Flutter-internal focus and could not reclaim the native first responder.

### Changed
- `MainFlutterWindow` now reclaims first responder for the FlutterView on every window `becomeKey`, and exposes a `clio/native_focus` method channel (`NativeFocusService.reclaimKeyboard()`) so Dart can force keyboard ownership back to Flutter. `WebTerminalView` reclaims on pointer-down, on the inactive→active transition, and — with short settling retries (120/350/700 ms) — after the webview loads and reports `ready`, winning the race against the webview's late first-responder grab so new sessions accept input on first open.

## [0.1.4] - 2026-06-10

### Fixed
- **macOS: new session failed with `execvp: No such file or directory`** (and spammed CoreFoundation "you MUST exec()" warnings). `flutter_pty` exec'd the bare name `claude`, leaving `execvp` to do a `$PATH` search inside the forked child — fragile, and missing `/opt/homebrew/bin` when clio was launched without a full PATH (e.g. from Finder). `ShellEnvService.resolveExecutable()` now resolves `claude` to an absolute path from the login-shell PATH before spawning, so `execvp` execs directly with no PATH search; the immediate exec also stops the fork-without-exec CoreFoundation warnings.

### Changed
- `resolveExecutable()` also resolves on Windows, searching PATH with `PATHEXT` (preferring `claude.exe`) and returning an absolute path, removing any dependence on PATH being correct at process-launch time. Falls back to the bare name when nothing matches.

## [0.1.3] - 2026-06-09

### Added
- **Shift+Enter inserts a newline.** `terminal_key_encoder.dart` now sends Esc+CR (`\x1b\r`) for Shift+Enter, which claude treats as a line break instead of submitting — matching Ghostty.

### Fixed
- **Windows: new session auto-submitted a message to claude.** On Windows the `InAppWebView` (WebView2) holds real keyboard focus, unlike WKWebView on macOS, so keystrokes were processed twice (Flutter + xterm.js `onData`) and a stray Enter on session start auto-submitted a message. `bridge.js` now calls `term.attachCustomKeyEventHandler(() => false)` so xterm stays render-only for the physical keyboard on every platform; paste and terminal query responses are unaffected.

## [0.1.2] - 2026-06-09

### Added
- **Word- and line-wise terminal shortcuts.** `terminal_key_encoder.dart` now sends modifier-aware sequences so editing keys behave like a native terminal: Ctrl/Option/Shift with arrows, Home/End, Delete, and PageUp/Down emit standard CSI modifier sequences (e.g. Option+Left = word back), and Ctrl/Option+Backspace delete the previous word. macOS Cmd line-editing matches Ghostty: Cmd+Left = start of line (`^A`), Cmd+Right = end of line (`^E`), Cmd+Delete = delete to start of line (`^U`).

### Fixed
- **Blank/black terminal when returning to a project.** Switching projects previously disposed the previous project's `ProjectSessionsScreen`, tearing down its terminal webviews; returning rebuilt an empty webview while `claude` (kept alive) sat idle, leaving a black screen. `ProjectsScreen` now keeps each visited project's sessions mounted in an `IndexedStack` (keyed `project:<id>`) so webviews survive project switches.
- **Black screen when switching session tabs fast.** Bringing a webview from an offscreen `IndexedStack` branch to the front leaves WKWebView presenting a stale black surface until forced to recomposite. The foreground terminal now forces a recomposite when it becomes visible.
- **Black screen on claude's "jump to bottom" / redraw after idle.** A one-off redraw after an idle period painted to a surface WKWebView never presented; output now always forces a recomposite (rAF-throttled).

### Changed
- `ProjectSessionsScreen` takes a `visible` flag, folded into each terminal's `active` so the foreground session re-focuses and triggers a webview recomposite when its project becomes visible.
- `WebTerminalView` calls `window.clioNudge()` on the inactive→active transition; `bridge.js` exposes `clioNudge` and uses a stronger repaint nudge (body-opacity **plus** a `translateZ` compositing-transform toggle on the terminal element) to more reliably force WKWebView's native layer to re-present. Mitigates upstream flutter_inappwebview macOS issue [#1923](https://github.com/pichillilorenzo/flutter_inappwebview/issues/1923).

## [0.1.1] - 2026-06-08

### Fixed
- **Long-running UI freezes and unresponsive/blank terminals.** Two compounding causes addressed: (1) the per-session reconcile loop no longer re-runs `SessionsNotifier.build()` (and the all-session transcript parse) on every title/resume-id change — `rename`/`updateResumeId`/`markStarted` now patch session state in place; (2) PTY output is coalesced into a single per-frame (~16 ms) write to the webview instead of one base64-encoded `evaluateJavascript` call per chunk, ending the platform-channel flooding that blanked terminals and stalled input.

### Changed
- `TerminalBridge` buffers PTY output in a single `BytesBuilder`, capped at 1 MB (oldest dropped), flushed once per frame; the flush timer, PTY output subscription, and bridge are cancelled on dispose.
- `TerminalController` reconciles on a fixed 3 s interval (with a re-entrancy guard) instead of re-arming a 1.5 s timer on every output chunk.

## [0.1.0] - 2026-06-07

### Added
- **App logo and launcher icons** for macOS and Windows via `flutter_launcher_icons` (clio and clio-owl assets).
- **Web terminal renderer** (`WebTerminalView`): xterm.js hosted in `flutter_inappwebview`, replacing the `xterm` package widget. Hardware keyboard is captured by Flutter and forwarded to the PTY (WKWebView receives no keyboard on macOS), with Cmd+C/Cmd+V clipboard support. Assets bundled under `assets/web_terminal/` (xterm core + `fit`/`unicode11`/`web-links`/`webgl` addons, `bridge.js`, CSS).
- **Terminal key encoder** (`terminal_key_encoder.dart`): maps Flutter `KeyEvent`s to PTY byte sequences — arrow keys, function keys, Ctrl/Alt modifiers, and UTF-8 characters.
- **`ClaudeSessionService`**: reads live Claude TUI state by PID and transcript metadata; exposes `hasResumableTranscript()` and reads AI-assigned session titles.
- **Session renaming**: rename a session; persisted locally and reconciled with Claude transcript titles on startup.
- **Resume ID tracking**: sessions track a `resumeId` (the real Claude transcript id) distinct from the internal session UUID, auto-updated when the user resumes a different chat inside the running TUI.
- **File drag-and-drop into the terminal** via `desktop_drop`; dropped paths are quoted and pasted.
- **Persisted UI state**: remembers the last selected project and the active session per project (new keys `clio.selected_project`, `clio.active_session.<projectId>`).
- **JetBrains Mono Medium** font for terminal weight 700.
- Initial Flutter desktop scaffold (macOS/Linux/Windows) under the name **clio**.
- **Feature-first clean architecture**: `core/` shared layer plus `features/projects` and `features/sessions`, each split into `data / domain / presentation`.
- **Riverpod 3.x** state management with code generation (`@riverpod`); DI seam in `core/providers`.
- **Localization** via official `gen-l10n` — English and Arabic (RTL), `l10n.yaml` + ARB files.
- **Projects feature**: add a folder as a project (via `file_selector`), list and remove projects; persisted to `shared_preferences` (`clio.projects`).
- **Sessions feature**: per-project Claude sessions backed by a real PTY (`flutter_pty`) rendered with `xterm`. Each session owns a UUID used for `claude --session-id` (first launch) and `claude --resume` (restore); persisted per project (`clio.sessions.<projectId>`).
- `terminalController` (keepAlive) owning the PTY ↔ terminal lifecycle so switching tabs does not kill running `claude` processes.
- Core services: `pty_service`, `process_service`, `shell_env_service` (login-shell `PATH` loader), `storage_service`, `uuid_service`.
- GitHub-dark theme and bundled JetBrains Mono font.

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

### Notes
- `riverpod_generator` / `riverpod_lint` resolve to dev prereleases — the only versions compatible with the `riverpod 3.2.1` runtime; they are build-time only.
- `riverpod_lint` 3.x registers through `analysis_server_plugin` (no `custom_lint`).

[Unreleased]: https://github.com/alihamza0173/clio/compare/v0.1.1...HEAD
[0.1.1]: https://github.com/alihamza0173/clio/compare/v0.1.0...v0.1.1
[0.1.0]: https://github.com/alihamza0173/clio/releases/tag/v0.1.0
