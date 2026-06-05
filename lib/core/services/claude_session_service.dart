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

  Future<String?> findActiveSessionId({
    required String projectPath,
    required DateTime since,
    required Set<String> excludeIds,
  }) async {
    final dir = _projectDir(projectPath);
    if (dir == null || !await dir.exists()) return null;
    final threshold = since.subtract(const Duration(seconds: 2));
    final candidates = <({File file, String id, DateTime mtime})>[];
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.jsonl')) continue;
        final name = entity.uri.pathSegments.last;
        final id = name.substring(0, name.length - '.jsonl'.length);
        if (excludeIds.contains(id)) continue;
        final stat = await entity.stat();
        if (stat.modified.isBefore(threshold)) continue;
        candidates.add((file: entity, id: id, mtime: stat.modified));
      }
    } catch (_) {
      return null;
    }
    candidates.sort((a, b) => b.mtime.compareTo(a.mtime));
    for (final c in candidates) {
      if (await _hasRealContent(c.file)) return c.id;
    }
    return null;
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

  Directory? _projectDir(String projectPath) {
    final root = _projectsRoot();
    if (root == null) return null;
    return Directory('${root.path}/${_encode(projectPath)}');
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
