import 'dart:convert';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/services/storage_service.dart';
import '../models/session_model.dart';

abstract interface class SessionLocalDataSource {
  Future<List<SessionModel>> readSessions(String projectId);
  Future<void> writeSessions(String projectId, List<SessionModel> sessions);
}

class SessionLocalDataSourceImpl implements SessionLocalDataSource {
  const SessionLocalDataSourceImpl(this._store);

  final KeyValueStore _store;

  @override
  Future<List<SessionModel>> readSessions(String projectId) async {
    final raw = _store.getString(AppConstants.sessionsStorageKey(projectId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => SessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw StorageException('Failed to read sessions: $e');
    }
  }

  @override
  Future<void> writeSessions(
    String projectId,
    List<SessionModel> sessions,
  ) async {
    final raw = jsonEncode([for (final s in sessions) s.toJson()]);
    await _store.setString(AppConstants.sessionsStorageKey(projectId), raw);
  }
}
