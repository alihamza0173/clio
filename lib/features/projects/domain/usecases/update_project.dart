import '../entities/project.dart';
import '../repositories/project_repository.dart';

class UpdateProject {
  const UpdateProject(this._repository);

  final ProjectRepository _repository;

  Future<void> call(Project project) => _repository.updateProject(project);
}
