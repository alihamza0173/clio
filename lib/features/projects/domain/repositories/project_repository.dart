import '../entities/project.dart';

abstract interface class ProjectRepository {
  Future<List<Project>> getProjects();
  Future<void> addProject(Project project);
  Future<void> removeProject(String id);
}
