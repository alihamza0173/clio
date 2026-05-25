import '../entities/session.dart';
import '../repositories/session_repository.dart';

class GetSessions {
  const GetSessions(this._repository);

  final SessionRepository _repository;

  Future<List<Session>> call(String projectId) =>
      _repository.getSessions(projectId);
}
