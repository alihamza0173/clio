# Terminal Migration — How clio's Terminal Works

This document explains, in plain language, how we replaced clio's terminal and
built our own around **xterm.js**. It covers *why* we did it, *what* we built,
*how each piece works*, and *every bug we hit and fixed*.

---

## 1. The problem we started with

clio's whole job is to run the **Claude Code CLI** (`claude`) inside the app, one
session per tab. To show that CLI we need a **terminal emulator** — the thing
that takes the raw bytes a program prints and turns them into the text, colors,
and cursor you see.

The old terminal used a package called **`xterm` (xterm.dart)** — a terminal
emulator written in pure Dart. It mostly worked, but it had a lot of visible
bugs when running Claude:

- Text **duplicated** and kept duplicating (especially when answering a
  multi-question prompt and moving next/back).
- Text sometimes showed **with no spaces**, impossible to read.
- **Resizing** the window (full screen → small) caused glitches and garbled output.

The root cause: Claude Code is an **"Ink" TUI** (a rich, full-screen text UI). It
redraws the screen by moving the cursor around and clearing lines. xterm.dart's
emulation wasn't complete enough to keep up with that style of drawing, so frames
got mangled. The previous author had already tried to patch around it, but the
limitations were fundamental.

**Decision:** stop fighting a limited emulator and switch to **xterm.js** — the
same battle-tested terminal engine that **VS Code** uses. It renders Claude's UI
correctly because it's a complete, industry-standard terminal.

---

## 2. The core idea: a terminal made of two halves

xterm.js is a **JavaScript** library — it runs in a browser, not directly in
Flutter. So we run it inside an **embedded webview** (a mini-browser inside the
app) and connect it to Flutter.

Think of our terminal as two halves talking to each other:

```
   ┌─────────────────────────── Flutter (Dart) ───────────────────────────┐
   │                                                                       │
   │   claude CLI  ⇄  PTY  ⇄  TerminalController/Bridge  ⇄  WebTerminalView │
   │   (the program)  (pipe)     (the brains)              (the glue)       │
   │                                                            │          │
   └────────────────────────────────────────────────────────── │ ─────────┘
                                                                 │  bridge
                                                                 ▼ (messages)
   ┌─────────────────────────── Webview (JavaScript) ───────────────────────┐
   │   bridge.js  ⇄  xterm.js  →  what you actually see on screen            │
   └────────────────────────────────────────────────────────────────────────┘
```

- **The PTY** ("pseudo-terminal") is the pipe between clio and the `claude`
  program. clio writes your keystrokes into it; `claude` writes its output back
  out of it. This part was already good and we kept it unchanged.
- **xterm.js** (in the webview) only does one job: **draw** the output and report
  its size. It's "render-only."
- **Flutter** owns everything else: launching `claude`, your keyboard, copy/paste,
  drag-and-drop, and shuttling bytes back and forth.

### Why is xterm.js "render-only"? (the big discovery)

Normally a webview terminal would also handle the keyboard itself. But during a
proof-of-concept we discovered a hard macOS limitation:

> **An embedded webview on macOS does NOT receive physical keyboard input.**

You could click the terminal and type, and *nothing* happened — the keys never
reached the webview. This is a known, unsolved issue with embedding a WKWebView
inside a Flutter desktop app.

So we flipped the design: **Flutter captures the keyboard** (which works
perfectly on macOS), translates each key into the bytes a terminal expects, and
sends them straight to the PTY. The webview never needs the keyboard — it just
draws. This sidesteps the whole problem.

---

## 3. The pieces we built (file by file)

### The web side — `assets/web_terminal/`

This folder is a tiny, fully **offline** web page (no internet needed). It's
bundled into the app as assets.

- **`xterm.js`, `xterm.css`, and the addon files** — the vendored xterm.js 6.0.0
  library plus four official add-ons:
  - **fit** — measures the available space and computes how many columns/rows fit.
  - **unicode11** — gets the width of emoji/wide characters right (wrong widths
    were a cause of the "no spaces" bug).
  - **web-links** — makes URLs clickable.
  - (webgl was tried and removed — see fixes below.)
  - The **JetBrains Mono** font files, so the terminal uses the same font as the
    rest of the app, offline.
- **`index.html`** — the page that loads everything and holds the terminal `<div>`.
- **`bridge.js`** — our own glue code. It:
  - Creates the xterm.js terminal with our theme, font, and colors.
  - Receives output from Flutter and draws it (`window.clioWrite`).
  - Receives paste text (`window.clioPaste`) and copy requests (`window.clioCopy`).
  - Reports its size back to Flutter when it's ready or resized.
  - Handles all the rendering fixes (cursor, resize repaint — see below).

### The Flutter side

- **`lib/features/sessions/presentation/widgets/web_terminal_view.dart`**
  The widget that hosts the webview. It:
  - Loads `index.html` into an `InAppWebView`.
  - **Captures the keyboard** via a Flutter `Focus` widget and feeds keys to the
    terminal.
  - Handles **Cmd-V paste** (reads the clipboard, sends it to xterm.js) and
    **Cmd-C copy** (asks xterm.js for the selection, puts it on the clipboard).
  - Keeps Flutter focused when you click (so keys keep flowing).
  - Pumps `claude`'s output into the webview to be drawn.

- **`lib/features/sessions/presentation/widgets/terminal_key_encoder.dart`**
  A small, focused translator: it turns a Flutter `KeyEvent` into the exact bytes
  a terminal expects. Examples:
  - Enter → `0x0D`, Backspace → `0x7F`, Tab → `0x09`, Shift-Tab → `ESC [ Z`
  - Arrow keys → `ESC [ A/B/C/D`, Home/End/Delete/PageUp/PageDown → their codes
  - Ctrl+C → `0x03`, Ctrl+D → `0x04`, etc. (Ctrl + letter → 1–26)
  - Normal letters/symbols → their UTF-8 bytes; Option/Alt acts as "Meta" (`ESC` prefix)
  - `Cmd` is deliberately ignored so app shortcuts (copy/paste/quit) still work.

- **`lib/features/sessions/presentation/providers/terminal_controller.dart`**
  The "brains" for one session. Instead of returning a terminal object like
  before, its `build()` now returns a **`TerminalBridge`** — a small handle the
  widget talks to. The controller:
  - **Launches `claude` lazily**: it waits until the webview reports its real
    size, then starts `claude` at exactly that size. (Starting at a wrong size
    first is what used to cause duplicated output.)
  - Forwards your input to the PTY, forwards the PTY's output to the webview.
  - Handles resize, kills the process when the session closes, and keeps the
    1.5-second background timer that syncs the session title/id (unchanged).
  - Is **kept alive** so switching tabs doesn't kill your running `claude`.

- **`lib/features/sessions/presentation/widgets/terminal_view.dart`**
  A thin wrapper that connects a session to a `WebTerminalView` and keeps the
  drag-and-drop-a-file-to-paste-its-path feature.

- **`lib/features/sessions/presentation/screens/project_sessions_screen.dart`**
  Changed to keep **all open sessions mounted** at once using an `IndexedStack`
  (only the active one is visible). This is required because a webview is a real
  native view — if we unmounted it on tab switch, its whole screen and history
  would be destroyed. Now switching tabs just hides/shows; your `claude` keeps
  running with full history.

- **`lib/core/services/shell_env_service.dart`**
  Sets the environment for `claude`. We added one important variable here
  (`CLAUDE_CODE_NO_FLICKER=1`, explained below).

- **`pubspec.yaml`** — added the `flutter_inappwebview` dependency and the
  `assets/web_terminal/` folder; removed the old `xterm` package.

---

## 4. How the two halves talk (the "bridge")

Messages are simple JSON, sent both ways.

**Webview → Flutter** (via a registered handler called `clio`):
- `ready {cols, rows}` — "I've loaded and measured myself" → Flutter launches `claude`.
- `resize {cols, rows}` — "my size changed" → Flutter resizes the PTY.
- `data {text}` — used only for paste (so paste respects "bracketed paste" rules).

**Flutter → Webview** (by calling JS functions):
- `window.clioWrite(base64)` — here's new output to draw.
- `window.clioPaste(text)` — paste this text.
- `window.clioFocus()` / `window.clioCopy()` — focus / get the selected text.

**A note on correctness:** output bytes are sent as-is (base64-encoded) and
decoded **once** by xterm.js. The old code decoded bytes too early in Dart, which
could corrupt characters that span multiple bytes. The new path is byte-accurate.

---

## 5. The bugs we hit after migrating — and how we fixed each

We didn't get everything perfect on the first try. Here's each issue and the fix.

### 5.1 Keyboard didn't reach the webview (macOS)
**Symptom:** clicking + typing did nothing.
**Fix:** Flutter captures the keyboard and encodes keys to bytes itself
(`terminal_key_encoder.dart`). The webview is render-only. ✅

### 5.2 Bold/header text looked "broken" and "danced"
**Symptom:** headings rendered in a wrong font with letters jumping around.
**Cause:** the **WebGL** renderer in xterm.js had glyph/atlas glitches.
**Fix:** switched to xterm.js's **DOM renderer** (removed the WebGL add-on) and
**pre-loaded both font weights** before the first draw. ✅

### 5.3 Resizing duplicated the whole UI
**Symptom:** the welcome banner and content appeared several times after a resize.
**Cause:** this is a known, deep incompatibility between Claude's "normal screen"
drawing and how a terminal re-wraps text on resize. It even happens in some real
terminals.
**Fix:** run Claude on the **alternate screen** ("fullscreen" mode) by launching
it with `CLAUDE_CODE_NO_FLICKER=1`. On the alternate screen there's no scrollback
to re-wrap, so Claude fully repaints cleanly on every resize. (We verified this
environment variable is real by inspecting the `claude` binary.) ✅

> Trade-off we accepted: in fullscreen mode the input box sits at the **bottom**
> (like `claude` in iTerm/VS Code), so a brand-new session shows an empty gap
> until you start chatting. We considered the "classic" layout (input follows the
> text) but it cannot resize cleanly — so fullscreen was chosen as the default.

### 5.4 Cursor was a hollow outline and didn't fill
**Symptom:** the cursor showed as an empty box.
**Cause:** because Flutter holds the keyboard focus, the webview's text box is
always "blurred" from the system's view, so xterm.js drew its *unfocused* cursor.
**Fix:** tell xterm.js to always use a solid **block** cursor, and re-send it a
synthetic "focus" event so it renders the active cursor even though Flutter owns
the real focus. (It doesn't blink — that matches other terminals in this mode.) ✅

### 5.5 Resizing to a smaller window sometimes went fully black
**Symptom:** shrinking the window occasionally showed a black screen; worse on
long/heavy sessions.
**Cause:** the content was actually fine (the size was correct and Claude kept
drawing) — but the **native webview surface didn't repaint** after the resize.
**Fix:** force a "repaint nudge" — a momentary, invisible opacity toggle that
makes the webview recomposite — right after each resize, and keep nudging on every
output frame for ~1.5 seconds afterward (throttled to once per frame). That last
part matters for long sessions, whose repaint takes longer to finish. ✅

### 5.6 Keeping sessions alive across tabs
**Symptom risk:** a webview is destroyed if its widget unmounts.
**Fix:** the screen keeps every opened session mounted via `IndexedStack`, so
switching tabs only hides/shows; `claude` and its on-screen history survive. ✅

---

## 6. What it looks like end-to-end now

1. You open a session. The webview loads xterm.js and measures itself.
2. It reports its size; clio launches `claude` at that exact size.
3. `claude` prints output → PTY → Flutter → `clioWrite` → drawn by xterm.js.
4. You type → Flutter captures the key → encodes it → writes to the PTY → `claude`
   reacts. Paste/copy and drag-drop also work.
5. Resizing keeps the PTY and the terminal in sync, with a repaint nudge so the
   surface never stays black.
6. Switching tabs keeps every session running.

All of this was verified by actually running the app on macOS.

---

## 7. Known limitations

- **Platform:** verified on **macOS**. `flutter_inappwebview` also supports
  Windows, but **not Linux** — a Linux build would need a different webview engine.
- **IME / non-Latin typing:** because Flutter captures raw keys, composed input
  (e.g. Chinese/Japanese IME, accents via dead keys) isn't handled yet. Plain
  English typing, paste, and shortcuts all work. Full IME would need a hidden
  Flutter text field.
- **Layout:** fullscreen mode pins the input at the bottom (the empty-gap on a
  fresh session is cosmetic). A future enhancement could add a setting to toggle
  between fullscreen and classic layouts.

---

## 8. Key files reference

| File | Role |
|---|---|
| `assets/web_terminal/index.html` | The page that loads xterm.js |
| `assets/web_terminal/bridge.js` | Our JS glue: draw, paste, resize, cursor, repaint nudge |
| `assets/web_terminal/xterm.js` + addons + fonts | Vendored xterm.js 6.0.0, offline |
| `lib/.../widgets/web_terminal_view.dart` | Hosts the webview, captures keyboard, paste/copy |
| `lib/.../widgets/terminal_key_encoder.dart` | Turns key presses into terminal bytes |
| `lib/.../providers/terminal_controller.dart` | Launches/owns `claude`, the `TerminalBridge` |
| `lib/.../widgets/terminal_view.dart` | Connects a session + drag-drop paste |
| `lib/.../screens/project_sessions_screen.dart` | Keeps sessions alive via `IndexedStack` |
| `lib/core/services/shell_env_service.dart` | Sets env, incl. `CLAUDE_CODE_NO_FLICKER=1` |
| `pubspec.yaml` | Added `flutter_inappwebview`, removed `xterm` |

---

## 9. Where the code came from (provenance)

To be clear about what is third-party vs. written for clio:

**The terminal engine — vendored, unmodified, open source.**
The actual terminal emulator is **xterm.js** (the same engine VS Code uses,
MIT-licensed). We installed the official npm packages and copied their pre-built
files into `assets/web_terminal/`:

```bash
npm install @xterm/xterm @xterm/addon-fit @xterm/addon-unicode11 @xterm/addon-web-links
# then copied each package's lib/*.js and css/xterm.css into assets/web_terminal/
```

Versions: `@xterm/xterm` 6.0.0, `addon-fit` 0.11.0, `addon-unicode11` 0.9.0,
`addon-web-links` 0.12.0. The `JetBrainsMono-*.ttf` files were copied from the
app's existing `assets/fonts/`.

**The glue/integration code — written from scratch for clio.**
None of this was copied from another project:
- `bridge.js` (drives xterm.js: draw, paste, cursor, resize, repaint nudge)
- `terminal_key_encoder.dart` (Flutter key → terminal bytes)
- `web_terminal_view.dart`, `terminal_controller.dart`, `terminal_view.dart`,
  and the `IndexedStack` change

It was written using the **public APIs** of xterm.js and `flutter_inappwebview`,
**standard terminal escape codes** (e.g. `ESC[A` = up arrow, `0x03` = Ctrl-C —
well-known VT100/xterm codes), and **research into GitHub issues** for the macOS
keyboard limitation and the resize/reflow behavior.

The `CLAUDE_CODE_NO_FLICKER=1` fix was found by inspecting the installed `claude`
binary's strings to confirm the variable is real.

---

## 10. Running just the web terminal locally (offline)

Everything in `assets/web_terminal/` is **fully self-contained** — no CDN, no
internet. So you can run the terminal UI outside the Flutter app, in a normal
browser. There are two levels.

### 10a. Just see it render (no shell behind it)

This serves the exact files we ship and shows the terminal drawing — useful to
check the font, colors, and layout offline.

```bash
cd assets/web_terminal
python3 -m http.server 8000      # or: npx serve .
# open http://localhost:8000 in a browser
```

You'll see a themed, empty terminal with a cursor. It is **not interactive**,
because `bridge.js` is written to talk to the Flutter side (a real `claude`
process behind a PTY). With no Flutter and no process, there's nothing to type
into — it just renders. (The bridge harmlessly queues its "ready" message.)

> Note: in a real browser tab the keyboard works fine with xterm.js directly —
> the "webview gets no keyboard" problem is specific to embedding a webview
> *inside a Flutter macOS app*, not to browsers. So the standalone version below
> does NOT need the Flutter key-capture trick.

### 10b. A real, interactive web terminal (optional, ~5 minutes)

To get a working shell in the browser using the **same vendored xterm.js files**,
add a tiny local backend that connects xterm.js to a real PTY. This is the
classic "terminal in a browser" setup (how ttyd/Wetty work).

**1) Install a small backend in a scratch folder:**

```bash
mkdir /tmp/webterm && cd /tmp/webterm
npm init -y
npm install node-pty ws
```

**2) Create `server.js`** (point `ROOT` at clio's `assets/web_terminal`):

```js
const http = require('http');
const fs = require('fs');
const path = require('path');
const pty = require('node-pty');
const { WebSocketServer } = require('ws');

const ROOT = '/Users/alihamza/Development/StudioProjects/clio/assets/web_terminal';

const server = http.createServer((req, res) => {
  const url = (req.url === '/' ? '/standalone.html' : req.url).split('?')[0];
  fs.readFile(path.join(ROOT, url), (err, data) => {
    if (err) { res.writeHead(404); res.end('not found'); return; }
    res.end(data);
  });
});

const wss = new WebSocketServer({ server });
wss.on('connection', (ws) => {
  const shell = process.env.SHELL || 'bash';
  const term = pty.spawn(shell, ['-il'], {
    name: 'xterm-256color', cols: 80, rows: 24,
    cwd: process.env.HOME, env: process.env,
  });
  term.onData((d) => ws.readyState === 1 && ws.send(d));
  ws.on('message', (m) => {
    const msg = JSON.parse(m);
    if (msg.type === 'data') term.write(msg.data);
    if (msg.type === 'resize') term.resize(msg.cols, msg.rows);
  });
  ws.on('close', () => term.kill());
});

server.listen(8080, () => console.log('open http://localhost:8080'));
```

**3) Create `standalone.html` inside `assets/web_terminal/`** (it reuses the same
`xterm.js`/`xterm.css`/`addon-fit.js` we already ship, with a tiny browser
bootstrap instead of the Flutter-specific `bridge.js`):

```html
<!doctype html>
<html>
<head>
  <meta charset="utf-8" />
  <link rel="stylesheet" href="xterm.css" />
  <style>
    html, body { margin: 0; height: 100%; background: #0D1117; }
    #t { width: 100%; height: 100%; padding: 8px; box-sizing: border-box; }
  </style>
  <script src="xterm.js"></script>
  <script src="addon-fit.js"></script>
</head>
<body>
  <div id="t"></div>
  <script>
    const term = new Terminal({
      fontFamily: 'JetBrains Mono, monospace', fontSize: 13,
      cursorBlink: true,
      theme: { background: '#0D1117', foreground: '#E6EDF3' },
    });
    const fit = new FitAddon.FitAddon();
    term.loadAddon(fit);
    term.open(document.getElementById('t'));
    fit.fit();
    term.focus();

    const ws = new WebSocket('ws://' + location.host);
    ws.onopen = () => ws.send(JSON.stringify({ type: 'resize', cols: term.cols, rows: term.rows }));
    ws.onmessage = (e) => term.write(e.data);
    term.onData((d) => ws.send(JSON.stringify({ type: 'data', data: d })));
    term.onResize((s) => ws.send(JSON.stringify({ type: 'resize', cols: s.cols, rows: s.rows })));
    new ResizeObserver(() => fit.fit()).observe(document.getElementById('t'));
  </script>
</body>
</html>
```

**4) Run it:**

```bash
node /tmp/webterm/server.js
# open http://localhost:8080 — a real, typeable shell in the browser
```

You can even run `claude` inside it. This proves the terminal layer is fully
portable: the same offline xterm.js assets power both clio's embedded terminal
and a standalone browser terminal — the only difference is what's feeding the
PTY (Flutter in the app, a Node server here).
