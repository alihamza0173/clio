class Session {
  const Session({
    required this.id,
    required this.projectId,
    required this.title,
    required this.claudeStarted,
    required this.createdAt,
  });

  /// UUID passed to `claude --session-id` and later `claude --resume`.
  final String id;
  final String projectId;
  final String title;

  /// Whether `claude` has already been launched once for this session.
  /// Drives `--session-id` (first run) vs `--resume` (restore).
  final bool claudeStarted;
  final DateTime createdAt;

  Session copyWith({String? title, bool? claudeStarted}) => Session(
        id: id,
        projectId: projectId,
        title: title ?? this.title,
        claudeStarted: claudeStarted ?? this.claudeStarted,
        createdAt: createdAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Session &&
          other.id == id &&
          other.projectId == projectId &&
          other.title == title &&
          other.claudeStarted == claudeStarted &&
          other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, projectId, title, claudeStarted, createdAt);
}
