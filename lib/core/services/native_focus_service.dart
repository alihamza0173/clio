import 'dart:io';

import 'package:flutter/services.dart';

class NativeFocusService {
  static const _channel = MethodChannel('clio/native_focus');

  static Future<void> reclaimKeyboard() async {
    if (!Platform.isMacOS) return;
    try {
      await _channel.invokeMethod('reclaimKeyboard');
    } catch (_) {}
  }
}
