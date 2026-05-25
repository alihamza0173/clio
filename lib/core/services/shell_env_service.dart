import 'dart:io';

class ShellEnvService {
  String? _cachedPath;

  Future<String> loginPath() async {
    if (_cachedPath != null) return _cachedPath!;
    final current = Platform.environment['PATH'] ?? '';
    if (Platform.isWindows) {
      return _cachedPath = current;
    }
    try {
      final shell = Platform.environment['SHELL'] ??
          (Platform.isMacOS ? '/bin/zsh' : '/bin/bash');
      final result = await Process.run(shell, ['-l', '-c', r'echo $PATH']);
      if (result.exitCode == 0) {
        final shellPath = (result.stdout as String).trim();
        if (shellPath.isNotEmpty) {
          return _cachedPath =
              current.isEmpty ? shellPath : '$shellPath:$current';
        }
      }
    } catch (_) {}
    return _cachedPath = current;
  }

  Future<Map<String, String>> buildEnvironment() async {
    return {
      ...Platform.environment,
      'PATH': await loginPath(),
      'TERM': 'xterm-256color',
    };
  }
}
