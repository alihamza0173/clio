import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/storage_service.dart';
import '../models/project_model.dart';

abstract interface class ProjectLocalDataSource {
  Future<List<ProjectModel>> readProjects();
  Future<void> writeProjects(List<ProjectModel> projects);
}

class ProjectLocalDataSourceImpl implements ProjectLocalDataSource {
  const ProjectLocalDataSourceImpl(this._store);

  final KeyValueStore _store;

  @override
  Future<List<ProjectModel>> readProjects() async {
    final raw = _store.getString(AppConstants.projectsStorageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => ProjectModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageException('Failed to read projects: $e');
    }
  }

  @override
  Future<void> writeProjects(List<ProjectModel> projects) async {
    final raw = jsonEncode([for (final p in projects) p.toJson()]);
    await _store.setString(AppConstants.projectsStorageKey, raw);
  }
}
