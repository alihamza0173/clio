import '../repositories/session_repository.dart';

class UpdateResumeId {
  const UpdateResumeId(this._repository);

  final SessionRepository _repository;

  Future<void> call({
    required String projectId,
    required String sessionId,
    required String resumeId,
  }) => _repository.updateResumeId(
    projectId: projectId,
    sessionId: sessionId,
    resumeId: resumeId,
  );
}
