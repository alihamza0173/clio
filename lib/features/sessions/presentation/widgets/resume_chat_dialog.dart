import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clio/l10n/app_localizations.dart';

import '../../../../core/services/claude_session_service.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/relative_time.dart';
import '../../../../core/widgets/app_dialog_shell.dart';
import '../../../../core/widgets/suggestion_tile.dart';
import '../providers/claude_chat_suggestions.dart';
import '../providers/sessions_notifier.dart';

/// Lists this project's past claude conversations. Picking one opens it as a
/// tab that resumes the transcript instead of starting a new chat.
class ResumeChatDialog extends ConsumerWidget {
  const ResumeChatDialog({super.key, required this.projectId});

  final String projectId;

  static Future<void> show(BuildContext context, String projectId) =>
      showDialog<void>(
        context: context,
        builder: (_) => ResumeChatDialog(projectId: projectId),
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chatsAsync = ref.watch(claudeChatSuggestionsProvider(projectId));

    return AppDialogShell(
      title: l10n.previousChatsTitle,
      subtitle: l10n.previousChatsSubtitle,
      child: chatsAsync.when(
        loading: () => const Padding(
          padding: .all(24),
          child: Center(child: CircularProgressIndicator.adaptive()),
        ),
        error: (e, _) => _message('$e'),
        data: (chats) {
          if (chats.isEmpty) return _message(l10n.noPreviousChats);
          return ListView.builder(
            padding: .zero,
            shrinkWrap: true,
            itemCount: chats.length,
            itemBuilder: (_, i) => _chatTile(context, ref, l10n, chats[i]),
          );
        },
      ),
    );
  }

  Widget _chatTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    ClaudeChatSummary chat,
  ) {
    final relative = formatRelativeTime(l10n, chat.lastActiveAt);
    return SuggestionTile(
      icon: Icons.forum_outlined,
      title: chat.label,
      subtitle: _subtitle(chat),
      meta: chat.promptCount > 0
          ? '${l10n.promptCount(chat.promptCount)} · $relative'
          : relative,
      onTap: () => _restore(context, ref, chat),
    );
  }

  String _subtitle(ClaudeChatSummary chat) {
    final branch = chat.gitBranch;
    final preview = chat.title == null ? null : chat.preview;
    if (branch != null && preview != null) return '$branch · $preview';
    return branch ?? preview ?? chat.id;
  }

  Future<void> _restore(
    BuildContext context,
    WidgetRef ref,
    ClaudeChatSummary chat,
  ) async {
    final sessions = ref.read(sessionsProvider(projectId).notifier);
    final active = ref.read(activeSessionIdProvider(projectId).notifier);
    Navigator.of(context).pop();
    active.select((await sessions.restoreChat(chat)).id);
  }

  Widget _message(String text) => Padding(
    padding: const .all(16),
    child: Text(text, style: AppTypography.label),
  );
}
