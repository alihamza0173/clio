import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/claude_hook_server.dart';
import 'sessions_notifier.dart';

part 'session_status.g.dart';

enum SessionStatus { idle, busy, needsAttention }

@riverpod
bool projectNeedsAttention(Ref ref, String projectId) {
  final sessions = ref.watch(sessionsProvider(projectId)).value ?? const [];
  return sessions.any(
    (s) =>
        ref.watch(sessionStatusProvider(projectId, s.id)) ==
        SessionStatus.needsAttention,
  );
}

/// Live activity state for one session's `claude` turn, driven by injected
/// Claude Code hooks (authoritative). `Stop` never fires when the user
/// interrupts, and the idle TUI keeps repainting (so output silence can't be
/// relied on) — a bare Esc/Ctrl+C keypress in the input path demotes instead,
/// with the silence watchdog kept only as a backstop for dead sessions.
@Riverpod(keepAlive: true)
class SessionStatusNotifier extends _$SessionStatusNotifier {
  static const _silence = Duration(seconds: 6);

  DateTime? _lastOutputAt;
  Timer? _watchdog;

  @override
  SessionStatus build(String projectId, String sessionId) {
    final sub = ref.read(claudeHookServerProvider).events.listen(_onHook);
    ref.onDispose(() {
      sub.cancel();
      _watchdog?.cancel();
    });
    return .idle;
  }

  void _onHook(ClaudeHookEvent e) {
    if (e.projectId != projectId || e.sessionId != sessionId) return;
    switch (e.event) {
      case 'UserPromptSubmit' || 'PostToolUse':
        _setBusy();
      case 'Stop' || 'StopFailure' || 'SessionEnd':
        _setIdle();
      case 'Notification':
        if (e.notificationKind == 'permission_prompt') {
          _set(.needsAttention);
        } else if (e.notificationKind == 'idle_prompt' &&
            state == SessionStatus.busy) {
          _setIdle();
        }
    }
  }

  void notePtyOutput() => _lastOutputAt = DateTime.now();

  /// Only a bare Esc/Ctrl+C demotes (interrupt). Other keystrokes are
  /// deliberately ignored: answering one question of a multi-question prompt
  /// must not clear needsAttention — `PostToolUse` fires once the prompt is
  /// fully resolved and the tool actually ran.
  void noteUserInput(List<int> bytes) {
    final interrupt =
        bytes.length == 1 && (bytes[0] == 0x1b || bytes[0] == 0x03);
    if (interrupt && state != SessionStatus.idle) _setIdle();
  }

  void reset() => _setIdle();

  void _setBusy() {
    _lastOutputAt = DateTime.now();
    _set(.busy);
    _watchdog ??= Timer.periodic(const Duration(seconds: 2), (_) {
      final last = _lastOutputAt;
      if (state == SessionStatus.busy &&
          last != null &&
          DateTime.now().difference(last) > _silence) {
        _setIdle();
      }
    });
  }

  void _setIdle() {
    _watchdog?.cancel();
    _watchdog = null;
    _set(.idle);
  }

  void _set(SessionStatus next) {
    if (state != next) state = next;
  }
}
