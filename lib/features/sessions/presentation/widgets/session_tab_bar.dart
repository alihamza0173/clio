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
  const SessionTabBar({
    super.key,
    required this.projectId,
    this.visible = true,
  });

  final String projectId;
  final bool visible;

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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: .stretch,
                children: [
                  for (final session in sessions)
                    _SessionTab(
                      session: session,
                      active: session.id == effectiveId,
                      visible: visible,
                      onSelect: () => ref
                          .read(activeSessionIdProvider(projectId).notifier)
                          .select(session.id),
                      onClose: () => _close(ref, session.id),
                    ),
                ],
              ),
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

class _SessionTab extends ConsumerStatefulWidget {
  const _SessionTab({
    required this.session,
    required this.active,
    required this.visible,
    required this.onSelect,
    required this.onClose,
  });

  final Session session;
  final bool active;
  final bool visible;
  final VoidCallback onSelect;
  final VoidCallback onClose;

  @override
  ConsumerState<_SessionTab> createState() => _SessionTabState();
}

class _SessionTabState extends ConsumerState<_SessionTab> {
  @override
  void initState() {
    super.initState();
    if (widget.active && widget.visible) _scheduleReveal();
  }

  @override
  void didUpdateWidget(_SessionTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active &&
        widget.visible &&
        (!oldWidget.active || !oldWidget.visible)) {
      _scheduleReveal();
    }
  }

  void _scheduleReveal() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.5,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  bool get active => widget.active;

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final status = ref.watch(
      sessionStatusProvider(session.projectId, session.id),
    );
    return GestureDetector(
      onTap: widget.onSelect,
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
                    onTap: widget.onClose,
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
