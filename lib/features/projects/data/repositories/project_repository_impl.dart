import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../datasources/project_local_datasource.dart';
import '../models/project_model.dart';

class ProjectRepositoryImpl implements ProjectRepository {
  const ProjectRepositoryImpl(this._local);

  final ProjectLocalDataSource _local;

  @override
  Future<List<Project>> getProjects() => _local.readProjects();

  @override
  Future<void> addProject(Project project) async {
    final projects = await _local.readProjects();
    projects.add(ProjectModel.fromEntity(project));
    await _local.writeProjects(projects);
  }

  @override
  Future<void> removeProject(String id) async {
    final projects = await _local.readProjects();
    projects.removeWhere((p) => p.id == id);
    await _local.writeProjects(projects);
  }
}
