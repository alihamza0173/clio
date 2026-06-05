import '../entities/session.dart';

abstract interface class SessionRepository {
  Future<List<Session>> getSessions(String projectId);
  Future<Session> createSession({required String projectId, String? title});
  Future<void> markStarted({
    required String projectId,
    required String sessionId,
  });
  Future<void> renameSession({
    required String projectId,
    required String sessionId,
    required String title,
  });
  Future<void> removeSession({
    required String projectId,
    required String sessionId,
  });
}
