import '../../../../core/services/uuid_service.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../datasources/session_local_datasource.dart';
import '../models/session_model.dart';

class SessionRepositoryImpl implements SessionRepository {
  const SessionRepositoryImpl(this._local, this._uuid);

  final SessionLocalDataSource _local;
  final UuidService _uuid;

  @override
  Future<List<Session>> getSessions(String projectId) =>
      _local.readSessions(projectId);

  @override
  Future<Session> createSession({
    required String projectId,
    String? title,
  }) async {
    final sessions = await _local.readSessions(projectId);
    final session = SessionModel(
      id: _uuid.v4(),
      projectId: projectId,
      title: title ?? 'Session ${sessions.length + 1}',
      claudeStarted: false,
      createdAt: DateTime.now(),
    );
    sessions.add(session);
    await _local.writeSessions(projectId, sessions);
    return session;
  }

  @override
  Future<void> markStarted({
    required String projectId,
    required String sessionId,
  }) async {
    final sessions = await _local.readSessions(projectId);
    final updated = [
      for (final s in sessions)
        if (s.id == sessionId)
          SessionModel.fromEntity(s.copyWith(claudeStarted: true))
        else
          s,
    ];
    await _local.writeSessions(projectId, updated);
  }

  @override
  Future<void> renameSession({
    required String projectId,
    required String sessionId,
    required String title,
  }) async {
    final sessions = await _local.readSessions(projectId);
    final updated = [
      for (final s in sessions)
        if (s.id == sessionId)
          SessionModel.fromEntity(s.copyWith(title: title))
        else
          s,
    ];
    await _local.writeSessions(projectId, updated);
  }

  @override
  Future<void> removeSession({
    required String projectId,
    required String sessionId,
  }) async {
    final sessions = await _local.readSessions(projectId);
    sessions.removeWhere((s) => s.id == sessionId);
    await _local.writeSessions(projectId, sessions);
  }
}
