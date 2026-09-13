import 'dart:io';

import 'process_service.dart';

/// Opens a URL in the OS browser. Terminal output is untrusted, so only web
/// and mail schemes are ever handed to the platform opener.
class UrlLauncherService {
  const UrlLauncherService(this._process);

  final ProcessService _process;

  static const _allowedSchemes = {'http', 'https', 'mailto'};

  Future<void> open(String url) async {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        !uri.hasScheme ||
        !_allowedSchemes.contains(uri.scheme.toLowerCase())) {
      return;
    }
    final target = uri.toString();
    try {
      if (Platform.isMacOS) {
        await _process.run('open', [target]);
      } else if (Platform.isLinux) {
        await _process.run('xdg-open', [target]);
      } else if (Platform.isWindows) {
        await _process.run('rundll32', ['url.dll,FileProtocolHandler', target]);
      }
    } catch (_) {}
  }
}
