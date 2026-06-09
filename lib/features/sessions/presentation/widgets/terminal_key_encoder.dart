import 'dart:convert';

import 'package:flutter/services.dart';

/// Translates a Flutter [KeyEvent] into the byte sequence a PTY expects.
///
/// The terminal renderer (xterm.js) runs inside a WKWebView that never receives
/// the physical keyboard on macOS, so Flutter captures keys itself and writes
/// the encoded bytes straight to the pty. `Cmd+C`/`Cmd+V` are handled upstream
/// for copy/paste; `Cmd` with arrows/backspace emulates macOS line editing
/// (Ghostty-style: start/end of line, kill-to-start); `Option` (alt) is Meta.
/// `Shift+Enter` sends Esc+CR so claude inserts a newline instead of submitting.
List<int>? encodeTerminalKey(KeyEvent event) {
  if (event is KeyUpEvent) return null;

  final kb = HardwareKeyboard.instance;
  final key = event.logicalKey;

  if (kb.isMetaPressed) {
    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
        return const [0x01];
      case LogicalKeyboardKey.arrowRight:
        return const [0x05];
      case LogicalKeyboardKey.backspace:
        return const [0x15];
    }
    return null;
  }

  final ctrl = kb.isControlPressed;
  final alt = kb.isAltPressed;
  final shift = kb.isShiftPressed;

  final mod = 1 + (shift ? 1 : 0) + (alt ? 2 : 0) + (ctrl ? 4 : 0);
  List<int> csiLetter(int letter) => mod == 1
      ? [0x1b, 0x5b, letter]
      : [0x1b, 0x5b, 0x31, 0x3b, 0x30 + mod, letter];
  List<int> csiTilde(int num) => mod == 1
      ? [0x1b, 0x5b, num, 0x7e]
      : [0x1b, 0x5b, num, 0x3b, 0x30 + mod, 0x7e];

  switch (key) {
    case LogicalKeyboardKey.enter:
    case LogicalKeyboardKey.numpadEnter:
      return shift ? const [0x1b, 0x0d] : const [0x0d];
    case LogicalKeyboardKey.backspace:
      if (ctrl) return const [0x17];
      if (alt) return const [0x1b, 0x7f];
      return const [0x7f];
    case LogicalKeyboardKey.tab:
      return shift ? const [0x1b, 0x5b, 0x5a] : const [0x09];
    case LogicalKeyboardKey.escape:
      return const [0x1b];
    case LogicalKeyboardKey.arrowUp:
      return csiLetter(0x41);
    case LogicalKeyboardKey.arrowDown:
      return csiLetter(0x42);
    case LogicalKeyboardKey.arrowRight:
      return csiLetter(0x43);
    case LogicalKeyboardKey.arrowLeft:
      return csiLetter(0x44);
    case LogicalKeyboardKey.home:
      return csiLetter(0x48);
    case LogicalKeyboardKey.end:
      return csiLetter(0x46);
    case LogicalKeyboardKey.insert:
      return csiTilde(0x32);
    case LogicalKeyboardKey.delete:
      return csiTilde(0x33);
    case LogicalKeyboardKey.pageUp:
      return csiTilde(0x35);
    case LogicalKeyboardKey.pageDown:
      return csiTilde(0x36);
  }

  if (ctrl) {
    final label = key.keyLabel.toLowerCase();
    if (label.length == 1) {
      final c = label.codeUnitAt(0);
      if (c >= 0x61 && c <= 0x7a) return [c - 0x60];
      if (c == 0x20) return const [0x00];
      if (c == 0x5b) return const [0x1b];
      if (c == 0x5c) return const [0x1c];
      if (c == 0x5d) return const [0x1d];
    }
    return null;
  }

  final ch = event.character;
  if (ch != null && ch.isNotEmpty) {
    final bytes = utf8.encode(ch);
    return alt ? [0x1b, ...bytes] : bytes;
  }
  return null;
}
