import '../../domain/entities/session.dart';

class SessionModel extends Session {
  SessionModel({
    required super.id,
    required super.projectId,
    required super.title,
    required super.claudeStarted,
    required super.createdAt,
    super.resumeId,
  });

  factory SessionModel.fromEntity(Session session) => SessionModel(
    id: session.id,
    projectId: session.projectId,
    title: session.title,
    claudeStarted: session.claudeStarted,
    createdAt: session.createdAt,
    resumeId: session.resumeId,
  );

  factory SessionModel.fromJson(Map<String, dynamic> json) => SessionModel(
    id: json['id'] as String,
    projectId: json['projectId'] as String,
    title: json['title'] as String,
    claudeStarted: json['claudeStarted'] as bool? ?? false,
    createdAt: DateTime.parse(json['createdAt'] as String),
    resumeId: json['resumeId'] as String? ?? json['id'] as String,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'projectId': projectId,
    'title': title,
    'claudeStarted': claudeStarted,
    'createdAt': createdAt.toIso8601String(),
    'resumeId': resumeId,
  };
}
