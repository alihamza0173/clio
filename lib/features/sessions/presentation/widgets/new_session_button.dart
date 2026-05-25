import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clio/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../providers/sessions_notifier.dart';

class NewSessionButton extends ConsumerWidget {
  const NewSessionButton({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return IconButton(
      icon: const Icon(Icons.add, size: 16),
      color: AppColors.textSecondary,
      splashRadius: 14,
      tooltip: l10n.newSession,
      onPressed: () => _create(ref),
    );
  }

  Future<void> _create(WidgetRef ref) async {
    final session =
        await ref.read(sessionsProvider(projectId).notifier).create();
    ref.read(activeSessionIdProvider(projectId).notifier).select(session.id);
  }
}
