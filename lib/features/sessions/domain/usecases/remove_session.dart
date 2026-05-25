import '../repositories/session_repository.dart';

class RemoveSession {
  const RemoveSession(this._repository);

  final SessionRepository _repository;

  Future<void> call({required String projectId, required String sessionId}) =>
      _repository.removeSession(projectId: projectId, sessionId: sessionId);
}
