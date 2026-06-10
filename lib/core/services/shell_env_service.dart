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
      final shell =
          Platform.environment['SHELL'] ??
          (Platform.isMacOS ? '/bin/zsh' : '/bin/bash');
      final result = await Process.run(shell, ['-l', '-c', r'echo $PATH']);
      if (result.exitCode == 0) {
        final shellPath = (result.stdout as String).trim();
        if (shellPath.isNotEmpty) {
          return _cachedPath = current.isEmpty
              ? shellPath
              : '$shellPath:$current';
        }
      }
    } catch (_) {}
    return _cachedPath = current;
  }

  Future<String> resolveExecutable(String name) async {
    if (name.contains('/') || name.contains(r'\')) return name;
    final sep = Platform.isWindows ? ';' : ':';
    final exts = Platform.isWindows
        ? (Platform.environment['PATHEXT'] ?? '.COM;.EXE;.BAT;.CMD').split(';')
        : const [''];
    final dirs = (await loginPath()).split(sep);
    for (final dir in dirs) {
      if (dir.isEmpty) continue;
      for (final ext in exts) {
        final candidate = '$dir${Platform.pathSeparator}$name$ext';
        if (await File(candidate).exists()) return candidate;
      }
    }
    return name;
  }

  Future<Map<String, String>> buildEnvironment() async {
    return {
      ...Platform.environment,
      'PATH': await loginPath(),
      'TERM': 'xterm-256color',
      'CLAUDE_CODE_NO_FLICKER': '1',
    };
  }
}
