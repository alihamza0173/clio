import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:clio/l10n/app_localizations.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../projects/domain/entities/project.dart';
import '../../domain/entities/session.dart';
import '../providers/sessions_notifier.dart';
import '../widgets/session_tab_bar.dart';
import '../widgets/terminal_view.dart';

class ProjectSessionsScreen extends ConsumerWidget {
  const ProjectSessionsScreen({super.key, required this.project});

  final Project project;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final sessionsAsync = ref.watch(sessionsProvider(project.id));
    final activeId = ref.watch(activeSessionIdProvider(project.id));

    return Column(
      children: [
        SessionTabBar(projectId: project.id),
        const Divider(height: 0.5, color: AppColors.border),
        Expanded(
          child: sessionsAsync.when(
            loading: () => const Center(
              child: SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Center(
              child: Text('$e', style: AppTypography.label),
            ),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Text(l10n.noSessions, style: AppTypography.label),
                );
              }
              final effectiveId = _effectiveId(sessions, activeId);
              return SessionTerminalView(
                key: ValueKey('${project.id}:$effectiveId'),
                projectId: project.id,
                sessionId: effectiveId,
              );
            },
          ),
        ),
      ],
    );
  }

  String _effectiveId(List<Session> sessions, String? activeId) {
    if (activeId != null && sessions.any((s) => s.id == activeId)) {
      return activeId;
    }
    return sessions.first.id;
  }
}
