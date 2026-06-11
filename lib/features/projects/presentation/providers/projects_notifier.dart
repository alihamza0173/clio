import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/project_local_datasource.dart';
import '../../data/repositories/project_repository_impl.dart';
import '../../domain/entities/project.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/usecases/add_project.dart';
import '../../domain/usecases/get_projects.dart';
import '../../domain/usecases/remove_project.dart';
import '../../domain/usecases/update_project.dart';

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

  Future<void> setProjectHidden(String id, bool hidden) async {
    final projects = await future;
    Project? project;
    for (final p in projects) {
      if (p.id == id) {
        project = p;
        break;
      }
    }
    if (project == null || project.hidden == hidden) return;
    final repo = ref.read(projectRepositoryProvider);
    await UpdateProject(repo)(project.copyWith(hidden: hidden));
    ref.invalidateSelf();
    await future;
  }

  String _basename(String path) {
    final parts = path
        .split(RegExp(r'[/\\]'))
        .where((s) => s.isNotEmpty)
        .toList();
    return parts.isEmpty ? path : parts.last;
  }
}

@riverpod
class HiddenSectionExpanded extends _$HiddenSectionExpanded {
  @override
  bool build() => false;

  void set(bool value) => state = value;

  void toggle() => state = !state;
}

@riverpod
class SelectedProjectId extends _$SelectedProjectId {
  @override
  String? build() => ref
      .read(storageServiceProvider)
      .getString(AppConstants.selectedProjectStorageKey);

  void select(String? id) {
    state = id;
    final store = ref.read(storageServiceProvider);
    if (id == null) {
      store.remove(AppConstants.selectedProjectStorageKey);
    } else {
      store.setString(AppConstants.selectedProjectStorageKey, id);
    }
  }
}
