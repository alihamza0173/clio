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

class ProjectSessionsScreen extends ConsumerStatefulWidget {
  const ProjectSessionsScreen({
    super.key,
    required this.project,
    this.visible = true,
  });

  final Project project;
  final bool visible;

  @override
  ConsumerState<ProjectSessionsScreen> createState() =>
      _ProjectSessionsScreenState();
}

class _ProjectSessionsScreenState extends ConsumerState<ProjectSessionsScreen> {
  final _mounted = <String>[];

  @override
  Widget build(BuildContext context) {
    final project = widget.project;
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
            error: (e, _) =>
                Center(child: Text('$e', style: AppTypography.label)),
            data: (sessions) {
              if (sessions.isEmpty) {
                return Center(
                  child: Text(l10n.noSessions, style: AppTypography.label),
                );
              }
              return _buildTerminals(project.id, sessions, activeId);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTerminals(
    String projectId,
    List<Session> sessions,
    String? activeId,
  ) {
    final ids = sessions.map((s) => s.id).toSet();
    _mounted.removeWhere((id) => !ids.contains(id));

    final effectiveId = _effectiveId(sessions, activeId);
    if (!_mounted.contains(effectiveId)) _mounted.add(effectiveId);

    return IndexedStack(
      index: _mounted.indexOf(effectiveId),
      sizing: StackFit.expand,
      children: [
        for (final id in _mounted)
          SessionTerminalView(
            key: ValueKey('$projectId:$id'),
            projectId: projectId,
            sessionId: id,
            active: widget.visible && id == effectiveId,
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
