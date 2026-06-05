import '../repositories/session_repository.dart';

class RenameSession {
  const RenameSession(this._repository);

  final SessionRepository _repository;

  Future<void> call({
    required String projectId,
    required String sessionId,
    required String title,
  }) => _repository.renameSession(
    projectId: projectId,
    sessionId: sessionId,
    title: title,
  );
}
