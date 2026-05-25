import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/project_local_datasource.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/usecases/add_project.dart';
import '../../domain/usecases/get_projects.dart';
import '../../domain/usecases/remove_project.dart';

part 'projects_notifier.g.dart';

@riverpod
ProjectRepository projectRepository(Ref ref) {
  return ProjectRepositoryImpl(
    ProjectLocalDataSourceImpl(ref.watch(storageServiceProvider)),
  );
}

@riverpod
class ProjectsNotifier extends _$ProjectsNotifier {
  @override
  Future<List<Project>> build() {
    final repo = ref.watch(projectRepositoryProvider);
    return GetProjects(repo)();
  }

  Future<void> addProjectByPath(String path) async {
    final repo = ref.read(projectRepositoryProvider);
    final uuid = ref.read(uuidServiceProvider);
    final project = Project(
      id: uuid.v4(),
      name: _basename(path),
      path: path,
      createdAt: DateTime.now(),
    );
    await AddProject(repo)(project);
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeProject(String id) async {
    final repo = ref.read(projectRepositoryProvider);
    await RemoveProject(repo)(id);
    ref.invalidateSelf();
    await future;
  }

  String _basename(String path) {
    final parts =
        path.split(RegExp(r'[/\\]')).where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? path : parts.last;
  }
}

@riverpod
class SelectedProjectId extends _$SelectedProjectId {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}
