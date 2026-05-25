import 'dart:convert';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:xterm/xterm.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/pty_service.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/providers/projects_notifier.dart';
import '../../domain/entities/session.dart';
import 'sessions_notifier.dart';

part 'terminal_controller.g.dart';

/// Owns the [Pty] + xterm [Terminal] lifecycle for a single session.
///
/// Kept alive so switching between session tabs does not kill the running
/// `claude` process; disposed (and the pty killed) only when the session is
/// removed via [ref.invalidate] or the app shuts down.
@Riverpod(keepAlive: true)
class TerminalController extends _$TerminalController {
  PtyHandle? _pty;

  @override
  Terminal build(String projectId, String sessionId) {
    final terminal = Terminal(maxLines: 10000);
    terminal.onOutput =
        (data) => _pty?.write(Uint8List.fromList(utf8.encode(data)));
    terminal.onResize = (width, height, pw, ph) => _pty?.resize(height, width);
    ref.onDispose(() => _pty?.kill());
    _launch(terminal);
    return terminal;
  }

  Future<void> _launch(Terminal terminal) async {
    try {
      final project = _findProject(await ref.read(projectsProvider.future));
      if (project == null) {
        terminal.write('clio: project not found.\r\n');
        return;
      }
      final session = _findSession(
        await ref.read(sessionsProvider(projectId).future),
      );
      if (session == null) {
        terminal.write('clio: session not found.\r\n');
        return;
      }

      final args = session.claudeStarted
          ? ['--resume', session.id]
          : ['--session-id', session.id];

      final environment =
          await ref.read(shellEnvServiceProvider).buildEnvironment();

      final pty = ref.read(ptyServiceProvider).start(
            executable: AppConstants.claudeExecutable,
            arguments: args,
            workingDirectory: project.path,
            environment: environment,
            rows: terminal.viewHeight > 0 ? terminal.viewHeight : 24,
            columns: terminal.viewWidth > 0 ? terminal.viewWidth : 80,
          );
      _pty = pty;
      pty.output.listen(
        (data) => terminal.write(utf8.decode(data, allowMalformed: true)),
      );

      if (!session.claudeStarted) {
        await ref
            .read(sessionsProvider(projectId).notifier)
            .markStarted(session.id);
      }
    } catch (e) {
      terminal.write(
        'clio: failed to launch ${AppConstants.claudeExecutable}: $e\r\n',
      );
    }
  }

  Project? _findProject(List<Project> projects) {
    for (final p in projects) {
      if (p.id == projectId) return p;
    }
    return null;
  }

  Session? _findSession(List<Session> sessions) {
    for (final s in sessions) {
      if (s.id == sessionId) return s;
    }
    return null;
  }
}
