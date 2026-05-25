import '../entities/session.dart';
import '../repositories/session_repository.dart';

class CreateSession {
  const CreateSession(this._repository);

  final SessionRepository _repository;

  Future<Session> call({required String projectId, String? title}) =>
      _repository.createSession(projectId: projectId, title: title);
}
