import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/session.dart';
import '../providers/session_status.dart';
import '../providers/sessions_notifier.dart';
import '../providers/terminal_controller.dart';
import 'new_session_button.dart';

class SessionTabBar extends ConsumerWidget {
  const SessionTabBar({super.key, required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions =
        ref.watch(sessionsProvider(projectId)).value ?? const <Session>[];
    final activeId = ref.watch(activeSessionIdProvider(projectId));
    final effectiveId = _effectiveId(sessions, activeId);

    return Container(
      height: 36,
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final session in sessions)
                  _SessionTab(
                    session: session,
                    active: session.id == effectiveId,
                    onSelect: () => ref
                        .read(activeSessionIdProvider(projectId).notifier)
                        .select(session.id),
                    onClose: () => _close(ref, session.id),
                  ),
              ],
            ),
          ),
          NewSessionButton(projectId: projectId),
        ],
      ),
    );
  }

  String? _effectiveId(List<Session> sessions, String? activeId) {
    if (activeId != null && sessions.any((s) => s.id == activeId)) {
      return activeId;
    }
    return sessions.isNotEmpty ? sessions.first.id : null;
  }

  Future<void> _close(WidgetRef ref, String sessionId) async {
    ref.invalidate(terminalControllerProvider(projectId, sessionId));
    ref.invalidate(sessionStatusProvider(projectId, sessionId));
    if (ref.read(activeSessionIdProvider(projectId)) == sessionId) {
      ref.read(activeSessionIdProvider(projectId).notifier).select(null);
    }
    await ref.read(sessionsProvider(projectId).notifier).remove(sessionId);
  }
}

class _SessionTab extends ConsumerWidget {
  const _SessionTab({
    required this.session,
    required this.active,
    required this.onSelect,
    required this.onClose,
  });

  final Session session;
  final bool active;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      sessionStatusProvider(session.projectId, session.id),
    );
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        decoration: BoxDecoration(
          color: active ? AppColors.background : Colors.transparent,
          border: const Border(
            right: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Stack(
          alignment: .center,
          children: [
            Padding(
              padding: const .symmetric(horizontal: 14),
              child: Row(
                children: [
                  SizedBox.square(dimension: 12, child: _indicator(status)),
                  const SizedBox(width: 6),
                  Text(
                    session.title,
                    style: AppTypography.tab.copyWith(
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: onClose,
                    child: const Icon(
                      Icons.close,
                      size: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              height: 2,
              child: _underline(status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _underline(SessionStatus status) => switch (status) {
    SessionStatus.busy => LinearProgressIndicator(
      minHeight: 2,
      color: AppColors.primary,
      backgroundColor: active
          ? AppColors.primary.withValues(alpha: 0.35)
          : Colors.transparent,
    ),
    SessionStatus.needsAttention => const ColoredBox(color: AppColors.warning),
    SessionStatus.idle =>
      active
          ? const ColoredBox(color: AppColors.primary)
          : const SizedBox.shrink(),
  };

  Widget? _indicator(SessionStatus status) => switch (status) {
    SessionStatus.needsAttention => Center(
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppColors.warning,
          shape: .circle,
        ),
      ),
    ),
    SessionStatus.busy || SessionStatus.idle => null,
  };
}
