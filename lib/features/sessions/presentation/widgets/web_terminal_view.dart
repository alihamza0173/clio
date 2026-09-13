import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../../../core/services/native_focus_service.dart';
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
    required this.revision,
    required this.onLink,
  });

  final TerminalBridge bridge;
  final bool active;

  /// Called with a URL the user clicked in the terminal; opens it externally.
  final ValueChanged<String> onLink;

  /// Changes whenever a sibling terminal is mounted or unmounted.
  final int revision;

  @override
  State<WebTerminalView> createState() => _WebTerminalViewState();
}

class _WebTerminalViewState extends State<WebTerminalView> {
  InAppWebViewController? _web;
  final _focus = FocusNode(debugLabel: 'terminal');

  void _grabKeyboard() {
    if (!mounted || !widget.active) return;
    _focus.requestFocus();
    NativeFocusService.reclaimKeyboard();
  }

  void _grabKeyboardSettling() {
    _grabKeyboard();
    for (final ms in const [120, 350, 700]) {
      Future.delayed(Duration(milliseconds: ms), _grabKeyboard);
    }
  }

  void _nudge() => _web?.evaluateJavascript(
    source: 'window.clioNudge && window.clioNudge()',
  );

  void _bindOutput() {
    final controller = _web;
    if (controller == null) return;
    widget.bridge.onOutput = (bytes) {
      controller.evaluateJavascript(
        source: "window.clioWrite('${base64Encode(bytes)}')",
      );
    };
  }

  @override
  void didUpdateWidget(WebTerminalView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.bridge, oldWidget.bridge)) {
      oldWidget.bridge.onOutput = null;
      _bindOutput();
    }
    if (widget.active && !oldWidget.active) {
      _grabKeyboard();
      _nudge();
    } else if (widget.active && widget.revision != oldWidget.revision) {
      // Disposing a sibling webview can leave this one's WKWebView layer
      // presenting a black surface, and an idle session emits no output to
      // trigger the usual repaint — so force one once the frame has landed.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nudge();
      });
    }
  }

  @override
  void dispose() {
    widget.bridge.onOutput = null;
    _web = null;
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
        _grabKeyboardSettling();
      case 'resize':
        widget.bridge.handleResize(
          (msg['cols'] as num).toInt(),
          (msg['rows'] as num).toInt(),
        );
      case 'data':
        widget.bridge.handleReply(utf8.encode(msg['data'] as String));
      case 'link':
        widget.onLink(msg['url'] as String);
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
      onPointerDown: (_) => _grabKeyboard(),
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
            useShouldOverrideUrlLoading: true,
            javaScriptCanOpenWindowsAutomatically: false,
            supportMultipleWindows: false,
            verticalScrollBarEnabled: false,
            horizontalScrollBarEnabled: false,
          ),
          onWebViewCreated: (controller) {
            _web = controller;
            controller.addJavaScriptHandler(
              handlerName: 'clio',
              callback: (args) => _onJsMessage(args),
            );
            _bindOutput();
          },
          shouldOverrideUrlLoading: (controller, action) async {
            final url = action.request.url;
            if (url == null || url.scheme == 'file') {
              return NavigationActionPolicy.ALLOW;
            }
            widget.onLink(url.toString());
            return NavigationActionPolicy.CANCEL;
          },
          onLoadStop: (controller, url) {
            controller.evaluateJavascript(
              source: 'window.clioFocus && window.clioFocus()',
            );
            _grabKeyboardSettling();
          },
        ),
      ),
    );
  }
}
