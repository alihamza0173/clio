import '../entities/project.dart';
import '../repositories/project_repository.dart';

class AddProject {
  const AddProject(this._repository);

  final ProjectRepository _repository;

  Future<void> call(Project project) => _repository.addProject(project);
}
