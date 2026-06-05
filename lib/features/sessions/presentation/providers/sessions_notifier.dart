import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../data/datasources/session_local_datasource.dart';
import '../../data/repositories/session_repository_impl.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/session_repository.dart';
import '../../domain/usecases/create_session.dart';
import '../../domain/usecases/get_sessions.dart';
import '../../domain/usecases/mark_session_started.dart';
import '../../domain/usecases/remove_session.dart';
import '../../domain/usecases/rename_session.dart';

part 'sessions_notifier.g.dart';

@riverpod
SessionRepository sessionRepository(Ref ref) {
  return SessionRepositoryImpl(
    SessionLocalDataSourceImpl(ref.watch(storageServiceProvider)),
    ref.watch(uuidServiceProvider),
  );
}

@riverpod
class SessionsNotifier extends _$SessionsNotifier {
  @override
  Future<List<Session>> build(String projectId) {
    final repo = ref.watch(sessionRepositoryProvider);
    return GetSessions(repo)(projectId);
  }

  Future<Session> create({String? title}) async {
    final repo = ref.read(sessionRepositoryProvider);
    final session = await CreateSession(repo)(
      projectId: projectId,
      title: title,
    );
    ref.invalidateSelf();
    await future;
    return session;
  }

  Future<void> markStarted(String sessionId) async {
    final repo = ref.read(sessionRepositoryProvider);
    await MarkSessionStarted(repo)(projectId: projectId, sessionId: sessionId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> rename(String sessionId, String title) async {
    final repo = ref.read(sessionRepositoryProvider);
    await RenameSession(repo)(
      projectId: projectId,
      sessionId: sessionId,
      title: title,
    );
    ref.invalidateSelf();
    await future;
  }

  Future<void> remove(String sessionId) async {
    final repo = ref.read(sessionRepositoryProvider);
    await RemoveSession(repo)(projectId: projectId, sessionId: sessionId);
    ref.invalidateSelf();
    await future;
  }
}

@riverpod
class ActiveSessionId extends _$ActiveSessionId {
  @override
  String? build(String projectId) => null;

  void select(String? id) => state = id;
}
