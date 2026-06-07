(function () {
  'use strict';

  var theme = {
    background: '#0D1117',
    foreground: '#E6EDF3',
    cursor: '#E6EDF3',
    cursorAccent: '#0D1117',
    selectionBackground: '#284566',
    black: '#484F58',
    red: '#FF7B72',
    green: '#7EE787',
    yellow: '#E3B341',
    blue: '#79C0FF',
    magenta: '#D2A8FF',
    cyan: '#56D4DD',
    white: '#C9D1D9',
    brightBlack: '#6E7681',
    brightRed: '#FFA198',
    brightGreen: '#56D364',
    brightYellow: '#E3B341',
    brightBlue: '#A5D6FF',
    brightMagenta: '#D2A8FF',
    brightCyan: '#56D4DD',
    brightWhite: '#F0F6FC'
  };

  var term = new Terminal({
    fontFamily: 'JetBrains Mono, monospace',
    fontSize: 13,
    lineHeight: 1.2,
    scrollback: 10000,
    allowProposedApi: true,
    cursorBlink: true,
    cursorStyle: 'block',
    cursorInactiveStyle: 'block',
    macOptionIsMeta: true,
    theme: theme
  });

  var fitAddon = new FitAddon.FitAddon();
  term.loadAddon(fitAddon);

  try {
    term.loadAddon(new Unicode11Addon.Unicode11Addon());
    term.unicode.activeVersion = '11';
  } catch (e) { }

  term.open(document.getElementById('terminal'));

  // Flutter owns the real keyboard focus, so the textarea is always OS-blurred
  // and xterm would render the inactive (hollow, non-blinking) cursor. Re-assert
  // a synthetic focus so xterm renders the active, blinking block cursor.
  var ta = term.textarea;
  if (ta) {
    ta.addEventListener('blur', function () {
      requestAnimationFrame(function () {
        ta.dispatchEvent(new FocusEvent('focus'));
      });
    });
    ta.dispatchEvent(new FocusEvent('focus'));
  }

  try {
    term.loadAddon(new WebLinksAddon.WebLinksAddon(function (event, uri) {
      postToDart({ type: 'link', url: uri });
    }));
  } catch (e) { }

  // ---- Dart bridge ----

  var queue = [];
  function rawPost(s) { window.flutter_inappwebview.callHandler('clio', s); }
  function postToDart(msg) {
    var s = JSON.stringify(msg);
    if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
      rawPost(s);
    } else {
      queue.push(s);
    }
  }
  function flushQueue() {
    if (!(window.flutter_inappwebview && window.flutter_inappwebview.callHandler)) return;
    for (var i = 0; i < queue.length; i++) rawPost(queue[i]);
    queue = [];
  }
  window.addEventListener('flutterInAppWebViewPlatformReady', flushQueue);

  function b64ToBytes(b64) {
    var bin = atob(b64);
    var len = bin.length;
    var bytes = new Uint8Array(len);
    for (var i = 0; i < len; i++) bytes[i] = bin.charCodeAt(i);
    return bytes;
  }

  // PTY output -> terminal
  window.clioWrite = function (b64) {
    term.write(b64ToBytes(b64));
    if (Date.now() < nudgeUntil) scheduleNudge();
  };
  // Clipboard / drag-drop paste -> respects bracketed-paste mode, fires onData
  window.clioPaste = function (text) { term.paste(text); };
  window.clioFocus = function () { term.focus(); };
  window.clioCopy = function () { return term.getSelection(); };
  window.clioSetTheme = function (json) {
    try {
      var t = JSON.parse(json);
      if (t.theme) term.options.theme = t.theme;
      if (t.fontFamily) term.options.fontFamily = t.fontFamily;
      if (t.fontSize) term.options.fontSize = t.fontSize;
      if (t.lineHeight) term.options.lineHeight = t.lineHeight;
      doFit();
    } catch (e) { }
  };

  // Only fires from clioPaste (the webview never holds keyboard focus).
  term.onData(function (data) { postToDart({ type: 'data', data: data }); });

  var lastCols = 0;
  var lastRows = 0;
  var sentReady = false;

  term.onResize(function (size) {
    if (size.cols === lastCols && size.rows === lastRows) return;
    lastCols = size.cols;
    lastRows = size.rows;
    if (sentReady) postToDart({ type: 'resize', cols: size.cols, rows: size.rows });
  });

  var nudgeUntil = 0;
  var nudgeQueued = false;

  function repaintNudge() {
    // Some WKWebView platform views present a black surface after a resize until
    // the compositor is forced to recomposite. A momentary body-opacity toggle
    // forces a full repaint of the presented bitmap.
    var b = document.body;
    b.style.opacity = '0.999';
    requestAnimationFrame(function () {
      b.style.opacity = '1';
      try { term.refresh(0, term.rows - 1); } catch (e) {}
    });
  }

  function scheduleNudge() {
    if (nudgeQueued) return;
    nudgeQueued = true;
    requestAnimationFrame(function () {
      nudgeQueued = false;
      repaintNudge();
    });
  }

  function doFit() {
    var el = document.getElementById('terminal');
    if (!el || el.clientWidth < 8 || el.clientHeight < 8) return;
    try {
      fitAddon.fit();
    } catch (e) {}
    // Keep forcing recomposites while Claude repaints (a long/heavy session can
    // take a while to fully redraw after the resize).
    nudgeUntil = Date.now() + 1500;
    scheduleNudge();
    setTimeout(scheduleNudge, 250);
    setTimeout(scheduleNudge, 700);
  }

  function tryReady() {
    if (sentReady) return;
    doFit();
    if (term.cols >= 10 && term.rows >= 4) {
      sentReady = true;
      postToDart({ type: 'ready', cols: term.cols, rows: term.rows });
      term.focus();
    } else {
      requestAnimationFrame(tryReady);
    }
  }

  var resizeTimer = null;
  function scheduleFit() {
    if (resizeTimer) clearTimeout(resizeTimer);
    resizeTimer = setTimeout(function () {
      resizeTimer = null;
      doFit();
    }, 90);
  }

  var ro = new ResizeObserver(function () {
    if (!sentReady) tryReady();
    else scheduleFit();
  });
  ro.observe(document.getElementById('terminal'));

  function start() {
    tryReady();
  }
  if (document.fonts && document.fonts.load) {
    Promise.all([
      document.fonts.load('400 13px "JetBrains Mono"'),
      document.fonts.load('700 13px "JetBrains Mono"')
    ]).then(start, start);
  } else {
    start();
  }
  requestAnimationFrame(tryReady);
})();
