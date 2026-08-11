import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clio/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/claude_chat_suggestions.dart';
import 'resume_chat_dialog.dart';

/// Only rendered once claude history for this project is known to hold chats
/// clio isn't already showing, so the tab bar never carries a dead control.
class ResumeChatButton extends ConsumerWidget {
  const ResumeChatButton({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final chats = ref.watch(claudeChatSuggestionsProvider(projectId)).value;
    if (chats == null || chats.isEmpty) return const SizedBox.shrink();

    return IconButton(
      icon: const Icon(Icons.history, size: 16),
      color: AppColors.textSecondary,
      splashRadius: 14,
      tooltip: l10n.restorePreviousChatCount(chats.length),
      onPressed: () => ResumeChatDialog.show(context, projectId),
    );
  }
}
