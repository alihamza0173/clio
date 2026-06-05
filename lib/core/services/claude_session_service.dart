import 'dart:convert';
import 'dart:io';

class ClaudeSessionService {
  const ClaudeSessionService();

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
