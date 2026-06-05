class Session {
  Session({
    required this.id,
    required this.projectId,
    required this.title,
    required this.claudeStarted,
    required this.createdAt,
    String? resumeId,
  }) : resumeId = resumeId ?? id;

  /// Stable internal key; passed to `claude --session-id` on first launch.
  final String id;
  final String projectId;
  final String title;

  /// Real Claude transcript id used for `claude --resume`. Defaults to [id];
  /// auto-updated when the user resumes a different chat inside the running TUI.
  final String resumeId;

  /// Whether `claude` has already been launched once for this session.
  /// Drives `--session-id` (first run) vs `--resume` (restore).
  final bool claudeStarted;
  final DateTime createdAt;

  Session copyWith({String? title, bool? claudeStarted, String? resumeId}) =>
      Session(
        id: id,
        projectId: projectId,
        title: title ?? this.title,
        claudeStarted: claudeStarted ?? this.claudeStarted,
        createdAt: createdAt,
        resumeId: resumeId ?? this.resumeId,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          other.id == id &&
          other.projectId == projectId &&
          other.title == title &&
          other.resumeId == resumeId &&
          other.claudeStarted == claudeStarted &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, projectId, title, resumeId, claudeStarted, createdAt);
}
