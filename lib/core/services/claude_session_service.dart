import 'dart:convert';
import 'dart:io';

typedef ClaudeSessionInfo = ({String? sessionId, String? name});

typedef _Transcript = ({File file, DateTime modified});

/// A folder claude has been run in, recovered from `~/.claude/projects`.
class ClaudeProjectSummary {
  const ClaudeProjectSummary({
    required this.path,
    required this.name,
    required this.chatCount,
    required this.lastActiveAt,
  });

  final String path;
  final String name;
  final int chatCount;
  final DateTime lastActiveAt;
}

/// A past conversation that can be reopened with `claude --resume <id>`.
class ClaudeChatSummary {
  const ClaudeChatSummary({
    required this.id,
    required this.promptCount,
    required this.lastActiveAt,
    this.title,
    this.preview,
    this.gitBranch,
  });

  final String id;
  final int promptCount;
  final DateTime lastActiveAt;
  final String? title;
  final String? preview;
  final String? gitBranch;

  String get label {
    final value = title ?? preview;
    return value == null || value.isEmpty ? id : value;
  }
}

class ClaudeSessionService {
  const ClaudeSessionService();

  static final RegExp _cwdPattern = RegExp(r'"cwd":"([^"]+)"');
  static const int _headBytes = 65536;
  static const int _pathProbeLimit = 3;
  static const int _concurrency = 8;
  static const int _previewLength = 120;

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

  /// Every folder claude has a transcript for, newest first. The directory
  /// names under `~/.claude/projects` are lossy (`_encode` maps both `/` and
  /// `.` to `-`), so the real path is recovered from the `cwd` recorded inside
  /// a transcript instead of decoded from the name.
  Future<List<ClaudeProjectSummary>> discoverProjects() async {
    final root = _projectsRoot();
    if (root == null || !await root.exists()) return const [];

    final dirs = <Directory>[];
    try {
      await for (final entity in root.list(followLinks: false)) {
        if (entity is Directory) dirs.add(entity);
      }
    } catch (_) {
      return const [];
    }

    final summaries = <ClaudeProjectSummary>[];
    for (final summary in await _mapLimited(dirs, _summarizeProjectDir)) {
      if (summary != null) summaries.add(summary);
    }
    summaries.sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
    return summaries;
  }

  /// Resumable conversations recorded for [projectPath], newest first.
  /// Transcripts without a real exchange are skipped — `--resume` fails on them.
  Future<List<ClaudeChatSummary>> discoverChats(String projectPath) async {
    final dir = await _locateProjectDir(projectPath);
    if (dir == null) return const [];

    final transcripts = await _transcripts(dir);
    final chats = <ClaudeChatSummary>[];
    for (final chat in await _mapLimited(transcripts, _summarizeTranscript)) {
      if (chat != null) chats.add(chat);
    }
    chats.sort((a, b) => b.lastActiveAt.compareTo(a.lastActiveAt));
    return chats;
  }

  Future<ClaudeProjectSummary?> _summarizeProjectDir(Directory dir) async {
    final transcripts = await _transcripts(dir);
    if (transcripts.isEmpty) return null;

    final path = await _recoverProjectPath(transcripts);
    if (path == null) return null;
    if (!await Directory(path).exists()) return null;

    return ClaudeProjectSummary(
      path: path,
      name: _basename(path),
      chatCount: transcripts.length,
      lastActiveAt: transcripts.first.modified,
    );
  }

  Future<String?> _recoverProjectPath(List<_Transcript> transcripts) async {
    final probes = transcripts.length < _pathProbeLimit
        ? transcripts.length
        : _pathProbeLimit;
    for (var i = 0; i < probes; i++) {
      final path = await _readCwd(transcripts[i].file);
      if (path != null && path.isNotEmpty) return path;
    }
    return null;
  }

  Future<String?> _readCwd(File file) async {
    try {
      final bytes = <int>[];
      await for (final chunk in file.openRead(0, _headBytes)) {
        bytes.addAll(chunk);
      }
      final head = utf8.decode(bytes, allowMalformed: true);
      return _cwdPattern.firstMatch(head)?.group(1);
    } catch (_) {
      return null;
    }
  }

  Future<ClaudeChatSummary?> _summarizeTranscript(
    _Transcript transcript,
  ) async {
    String? title;
    String? preview;
    String? gitBranch;
    var prompts = 0;
    var hasContent = false;

    try {
      final lines = transcript.file
          .openRead()
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter());
      await for (final line in lines) {
        if (line.isEmpty) continue;
        if (!hasContent &&
            (line.contains('"type":"user"') ||
                line.contains('"type":"assistant"'))) {
          hasContent = true;
        }
        if (line.contains('"kind":"human"')) {
          prompts++;
          if (preview == null) {
            final decoded = _decodeLine(line);
            if (decoded != null) {
              preview = _extractPrompt(decoded);
              final branch = decoded['gitBranch'];
              if (branch is String && branch.isNotEmpty) gitBranch = branch;
            }
          }
        }
        if (line.contains('"ai-title"')) {
          final decoded = _decodeLine(line);
          if (decoded != null && decoded['type'] == 'ai-title') {
            final value = decoded['aiTitle'];
            if (value is String && value.isNotEmpty) title = value;
          }
        }
      }
    } catch (_) {
      return null;
    }

    if (!hasContent) return null;

    return ClaudeChatSummary(
      id: _sessionIdOf(transcript.file),
      promptCount: prompts,
      lastActiveAt: transcript.modified,
      title: title,
      preview: preview,
      gitBranch: gitBranch,
    );
  }

  String? _extractPrompt(Map<String, dynamic> decoded) {
    final message = decoded['message'];
    if (message is! Map<String, dynamic>) return null;
    final content = message['content'];
    if (content is String) return _condense(content);
    if (content is List) {
      for (final part in content) {
        if (part is Map<String, dynamic> && part['type'] == 'text') {
          final text = part['text'];
          if (text is String && text.trim().isNotEmpty) return _condense(text);
        }
      }
    }
    return null;
  }

  String? _condense(String raw) {
    final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (text.isEmpty) return null;
    return text.length <= _previewLength
        ? text
        : '${text.substring(0, _previewLength)}…';
  }

  Map<String, dynamic>? _decodeLine(String line) {
    try {
      final decoded = jsonDecode(line);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  Future<List<_Transcript>> _transcripts(Directory dir) async {
    final transcripts = <_Transcript>[];
    try {
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File || !entity.path.endsWith('.jsonl')) continue;
        final stat = await entity.stat();
        transcripts.add((file: entity, modified: stat.modified));
      }
    } catch (_) {
      return transcripts;
    }
    transcripts.sort((a, b) => b.modified.compareTo(a.modified));
    return transcripts;
  }

  Future<Directory?> _locateProjectDir(String projectPath) async {
    final root = _projectsRoot();
    if (root == null) return null;

    final candidate = Directory('${root.path}/${_encode(projectPath)}');
    if (await candidate.exists()) return candidate;

    try {
      await for (final entity in root.list(followLinks: false)) {
        if (entity is! Directory) continue;
        final transcripts = await _transcripts(entity);
        if (transcripts.isEmpty) continue;
        if (await _recoverProjectPath(transcripts) == projectPath) {
          return entity;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Runs [task] over [items] a few at a time so a project with dozens of
  /// transcripts doesn't open every file handle at once.
  Future<List<R>> _mapLimited<T, R>(
    List<T> items,
    Future<R> Function(T) task,
  ) async {
    final results = <R>[];
    for (var i = 0; i < items.length; i += _concurrency) {
      final end = i + _concurrency;
      final batch = items.sublist(i, end > items.length ? items.length : end);
      results.addAll(await Future.wait(batch.map(task)));
    }
    return results;
  }

  String _sessionIdOf(File file) {
    final name = _basename(file.path);
    return name.endsWith('.jsonl')
        ? name.substring(0, name.length - '.jsonl'.length)
        : name;
  }

  String _basename(String path) {
    final parts = path
        .split(RegExp(r'[/\\]'))
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? path : parts.last;
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
