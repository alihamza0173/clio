import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../providers/terminal_controller.dart';
import 'terminal_key_encoder.dart';

/// Render-only xterm.js host. The WKWebView never receives the physical keyboard
/// on macOS, so Flutter captures keys, encodes them, and feeds the [bridge];
/// the webview only paints pty output and reports its fitted size.
class WebTerminalView extends StatefulWidget {
  const WebTerminalView({
    super.key,
    required this.bridge,
    required this.active,
  });

  final TerminalBridge bridge;
  final bool active;

  @override
  State<WebTerminalView> createState() => _WebTerminalViewState();
}

class _WebTerminalViewState extends State<WebTerminalView> {
  InAppWebViewController? _web;
  final _focus = FocusNode(debugLabel: 'terminal');

  @override
  void didUpdateWidget(WebTerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _focus.requestFocus();
  }

  @override
  void dispose() {
    widget.bridge.onOutput = null;
    _focus.dispose();
    super.dispose();
  }

  void _onJsMessage(List<dynamic> args) {
    if (args.isEmpty) return;
    final msg = jsonDecode(args.first as String) as Map<String, dynamic>;
    switch (msg['type']) {
      case 'ready':
        widget.bridge.handleReady(
          (msg['cols'] as num).toInt(),
          (msg['rows'] as num).toInt(),
        );
      case 'resize':
        widget.bridge.handleResize(
          (msg['cols'] as num).toInt(),
          (msg['rows'] as num).toInt(),
        );
      case 'data':
        widget.bridge.handleInput(utf8.encode(msg['data'] as String));
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final meta = HardwareKeyboard.instance.isMetaPressed;
    if (meta && event.logicalKey == LogicalKeyboardKey.keyV) {
      _pasteFromClipboard();
      return KeyEventResult.handled;
    }
    if (meta && event.logicalKey == LogicalKeyboardKey.keyC) {
      _copySelection();
      return KeyEventResult.handled;
    }
    final bytes = encodeTerminalKey(event);
    if (bytes == null) return KeyEventResult.ignored;
    widget.bridge.handleInput(bytes);
    return KeyEventResult.handled;
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.isEmpty) return;
    await _web?.evaluateJavascript(
      source: 'window.clioPaste(${jsonEncode(text)})',
    );
  }

  Future<void> _copySelection() async {
    final selection = await _web?.evaluateJavascript(
      source: 'window.clioCopy()',
    );
    if (selection is String && selection.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: selection));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _focus.requestFocus(),
      child: Focus(
        focusNode: _focus,
        autofocus: widget.active,
        onKeyEvent: _onKey,
        child: InAppWebView(
          initialFile: 'assets/web_terminal/index.html',
          initialSettings: InAppWebViewSettings(
            transparentBackground: true,
            allowFileAccessFromFileURLs: true,
            allowUniversalAccessFromFileURLs: true,
            supportZoom: false,
            verticalScrollBarEnabled: false,
            horizontalScrollBarEnabled: false,
          ),
          onWebViewCreated: (controller) {
            _web = controller;
            controller.addJavaScriptHandler(
              handlerName: 'clio',
              callback: (args) => _onJsMessage(args),
            );
            widget.bridge.onOutput = (bytes) {
              controller.evaluateJavascript(
                source: "window.clioWrite('${base64Encode(bytes)}')",
              );
            };
          },
          onLoadStop: (controller, url) {
            controller.evaluateJavascript(
              source: 'window.clioFocus && window.clioFocus()',
            );
            _focus.requestFocus();
          },
        ),
      ),
    );
  }
}
