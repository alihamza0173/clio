import 'dart:convert';
import 'dart:io';

typedef ClaudeSessionInfo = ({String? sessionId, String? name});

class ClaudeSessionService {
  const ClaudeSessionService();

  /// Reads `~/.claude/sessions/<pid>.json`, which claude maintains per running
  /// process. Its `sessionId`/`name` reflect the *current* conversation — they
  /// update when the user `/resume`s a different chat inside the running TUI —
  /// so this is the authoritative, pid-attributable source of truth.
  Future<ClaudeSessionInfo?> readSessionByPid(int pid) async {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null || home.isEmpty) return null;
    final file = File('$home/.claude/sessions/$pid.json');
    try {
      if (!await file.exists()) return null;
      final decoded =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final sessionId = decoded['sessionId'];
      final name = decoded['name'];
      return (
        sessionId: sessionId is String ? sessionId : null,
        name: name is String ? name : null,
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> readTitle({
    required String projectPath,
    required String sessionId,
  }) async {
    final file = await _locateTranscript(projectPath, sessionId);
    if (file == null) return null;
    try {
      String? title;
      final lines = await file.readAsLines();
      for (final line in lines) {
        if (!line.contains('"ai-title"')) continue;
        try {
          final decoded = jsonDecode(line) as Map<String, dynamic>;
          if (decoded['type'] == 'ai-title') {
            final value = decoded['aiTitle'];
            if (value is String && value.isNotEmpty) title = value;
          }
        } catch (_) {}
      }
      return title;
    } catch (_) {
      return null;
    }
  }

  Future<bool> hasResumableTranscript({
    required String projectPath,
    required String sessionId,
  }) async {
    final file = await _locateTranscript(projectPath, sessionId);
    if (file == null) return false;
    return _hasRealContent(file);
  }

  Future<bool> _hasRealContent(File file) async {
    try {
      final lines = await file.readAsLines();
      for (final line in lines) {
        if (line.contains('"type":"user"') ||
            line.contains('"type":"assistant"')) {
          return true;
        }
      }
    } catch (_) {}
    return false;
  }

  Future<File?> _locateTranscript(String projectPath, String sessionId) async {
    final root = _projectsRoot();
    if (root == null) return null;

    final candidate = File(
      '${root.path}/${_encode(projectPath)}/$sessionId.jsonl',
    );
    if (await candidate.exists()) return candidate;

    try {
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory) continue;
        final match = File('${entity.path}/$sessionId.jsonl');
        if (await match.exists()) return match;
      }
    } catch (_) {}
    return null;
  }

  Directory? _projectsRoot() {
    final home =
        Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null || home.isEmpty) return null;
    return Directory('$home/.claude/projects');
  }

  String _encode(String projectPath) =>
      projectPath.replaceAll(RegExp(r'[/.]'), '-');
}
