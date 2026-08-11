import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/claude_session_service.dart';
import '../../../projects/presentation/providers/projects_notifier.dart';
import 'sessions_notifier.dart';

part 'claude_chat_suggestions.g.dart';

/// Past claude conversations for a project that aren't already open as tabs.
/// Two ptys resuming one transcript would fight over the same file, so anything
/// clio already holds is excluded rather than shown disabled.
@riverpod
Future<List<ClaudeChatSummary>> claudeChatSuggestions(
  Ref ref,
  String projectId,
) async {
  String? projectPath;
  for (final project in await ref.watch(projectsProvider.future)) {
    if (project.id == projectId) {
      projectPath = project.path;
      break;
    }
  }
  if (projectPath == null || projectPath.isEmpty) return const [];

  final sessions = await ref.watch(sessionsProvider(projectId).future);
  final taken = {for (final session in sessions) session.resumeId};

  final chats = await ref
      .read(claudeSessionServiceProvider)
      .discoverChats(projectPath);

  return [
    for (final chat in chats)
      if (!taken.contains(chat.id)) chat,
  ];
}
