import '../repositories/session_repository.dart';

class MarkSessionStarted {
  const MarkSessionStarted(this._repository);

  final SessionRepository _repository;

  Future<void> call({required String projectId, required String sessionId}) =>
      _repository.markStarted(projectId: projectId, sessionId: sessionId);
}
