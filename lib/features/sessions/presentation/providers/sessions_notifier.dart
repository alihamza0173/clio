import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
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
import '../../domain/usecases/update_resume_id.dart';
import '../../../projects/presentation/providers/projects_notifier.dart';

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
  Future<List<Session>> build(String projectId) async {
    final repo = ref.watch(sessionRepositoryProvider);
    final sessions = await GetSessions(repo)(projectId);
    return _syncTitlesFromDisk(projectId, sessions, repo);
  }

  Future<List<Session>> _syncTitlesFromDisk(
    String projectId,
    List<Session> sessions,
    SessionRepository repo,
  ) async {
    if (sessions.isEmpty) return sessions;

    String? projectPath;
    for (final p in await ref.read(projectsProvider.future)) {
      if (p.id == projectId) {
        projectPath = p.path;
        break;
      }
    }
    if (projectPath == null) return sessions;

    final service = ref.read(claudeSessionServiceProvider);
    final path = projectPath;
    final titles = await Future.wait([
      for (final s in sessions)
        s.claudeStarted
            ? service.readTitle(projectPath: path, sessionId: s.resumeId)
            : Future<String?>.value(),
    ]);

    var changed = false;
    final updated = <Session>[];
    for (var i = 0; i < sessions.length; i++) {
      final s = sessions[i];
      final title = titles[i];
      if (title != null && title.isNotEmpty && title != s.title) {
        updated.add(s.copyWith(title: title));
        changed = true;
      } else {
        updated.add(s);
      }
    }

    if (changed) {
      for (var i = 0; i < sessions.length; i++) {
        if (!identical(updated[i], sessions[i])) {
          await repo.renameSession(
            projectId: projectId,
            sessionId: sessions[i].id,
            title: updated[i].title,
          );
        }
      }
    }
    return updated;
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
    _patch(sessionId, (s) => s.copyWith(claudeStarted: true));
  }

  Future<void> rename(String sessionId, String title) async {
    final repo = ref.read(sessionRepositoryProvider);
    await RenameSession(repo)(
      projectId: projectId,
      sessionId: sessionId,
      title: title,
    );
    _patch(sessionId, (s) => s.copyWith(title: title));
  }

  Future<void> updateResumeId(String sessionId, String resumeId) async {
    final repo = ref.read(sessionRepositoryProvider);
    await UpdateResumeId(repo)(
      projectId: projectId,
      sessionId: sessionId,
      resumeId: resumeId,
    );
    _patch(sessionId, (s) => s.copyWith(resumeId: resumeId));
  }

  void _patch(String sessionId, Session Function(Session) update) {
    final current = state.value;
    if (current == null) return;
    var changed = false;
    final next = <Session>[];
    for (final s in current) {
      if (s.id == sessionId) {
        next.add(update(s));
        changed = true;
      } else {
        next.add(s);
      }
    }
    if (changed) state = AsyncData(next);
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
  String? build(String projectId) => ref
      .read(storageServiceProvider)
      .getString(AppConstants.activeSessionStorageKey(projectId));

  void select(String? id) {
    state = id;
    final store = ref.read(storageServiceProvider);
    final key = AppConstants.activeSessionStorageKey(projectId);
    if (id == null) {
      store.remove(key);
    } else {
      store.setString(key, id);
    }
  }
}
