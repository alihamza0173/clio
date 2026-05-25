import '../repositories/project_repository.dart';

class RemoveProject {
  const RemoveProject(this._repository);

  final ProjectRepository _repository;

  Future<void> call(String id) => _repository.removeProject(id);
}
