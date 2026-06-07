import 'dart:convert';

import 'package:flutter/services.dart';

/// Translates a Flutter [KeyEvent] into the byte sequence a PTY expects.
///
/// The terminal renderer (xterm.js) runs inside a WKWebView that never receives
/// the physical keyboard on macOS, so Flutter captures keys itself and writes
/// the encoded bytes straight to the pty. `Cmd` (meta) is left untouched so the
/// app keeps copy/paste/quit shortcuts; `Option` (alt) is treated as Meta.
List<int>? encodeTerminalKey(KeyEvent event) {
  if (event is KeyUpEvent) return null;

  final kb = HardwareKeyboard.instance;
  if (kb.isMetaPressed) return null;

  final key = event.logicalKey;
  final ctrl = kb.isControlPressed;
  final alt = kb.isAltPressed;
  final shift = kb.isShiftPressed;

  switch (key) {
    case LogicalKeyboardKey.enter:
    case LogicalKeyboardKey.numpadEnter:
      return const [0x0d];
    case LogicalKeyboardKey.backspace:
      return const [0x7f];
    case LogicalKeyboardKey.tab:
      return shift ? const [0x1b, 0x5b, 0x5a] : const [0x09];
    case LogicalKeyboardKey.escape:
      return const [0x1b];
    case LogicalKeyboardKey.arrowUp:
      return const [0x1b, 0x5b, 0x41];
    case LogicalKeyboardKey.arrowDown:
      return const [0x1b, 0x5b, 0x42];
    case LogicalKeyboardKey.arrowRight:
      return const [0x1b, 0x5b, 0x43];
    case LogicalKeyboardKey.arrowLeft:
      return const [0x1b, 0x5b, 0x44];
    case LogicalKeyboardKey.home:
      return const [0x1b, 0x5b, 0x48];
    case LogicalKeyboardKey.end:
      return const [0x1b, 0x5b, 0x46];
    case LogicalKeyboardKey.insert:
      return const [0x1b, 0x5b, 0x32, 0x7e];
    case LogicalKeyboardKey.delete:
      return const [0x1b, 0x5b, 0x33, 0x7e];
    case LogicalKeyboardKey.pageUp:
      return const [0x1b, 0x5b, 0x35, 0x7e];
    case LogicalKeyboardKey.pageDown:
      return const [0x1b, 0x5b, 0x36, 0x7e];
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
