import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
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
/// The `claude` process is spawned lazily on the first layout-driven resize so
/// the pty starts at the terminal's real column/row count — spawning at a
/// default size first causes the TUI to reflow and duplicate its output.
///
/// `reflowEnabled: false` and a synchronous (non-debounced) pty resize are both
/// load-bearing: `claude` is an Ink TUI that redraws on SIGWINCH by clearing the
/// previous frame's line count and repainting. xterm's reflow rewraps the
/// on-screen frame without moving the cursor with it, so claude's clear misses
/// the old frame (duplicate banner); debouncing the pty resize lets xterm's
/// buffer width drift from the pty width, so claude paints against a stale width
/// (stranded text / double cursor). Keeping reflow off and the resize in lockstep
/// with the pty mirrors how `claude` behaves in a real terminal.
///
/// Kept alive so switching between session tabs does not kill the running
/// `claude` process; disposed (and the pty killed) only when the session is
/// removed via [ref.invalidate] or the app shuts down.
@Riverpod(keepAlive: true)
class TerminalController extends _$TerminalController {
  PtyHandle? _pty;
  bool _starting = false;
  bool _disposed = false;
  Timer? _reconcileTimer;
  DateTime? _launchTime;
  String? _projectPath;
  String? _resumeId;
  String? _currentTitle;

  @override
  Terminal build(String projectId, String sessionId) {
    final terminal = Terminal(
      maxLines: 10000,
      reflowEnabled: false,
      platform: _terminalPlatform(),
    );
    terminal.onOutput = (data) =>
        _pty?.write(Uint8List.fromList(utf8.encode(data)));
    terminal.onResize = (width, height, pixelWidth, pixelHeight) {
      final pty = _pty;
      if (pty == null) {
        _launch(terminal, rows: height, columns: width);
      } else {
        pty.resize(height, width);
      }
    };
    ref.onDispose(() {
      _disposed = true;
      _reconcileTimer?.cancel();
      _pty?.kill();
    });
    return terminal;
  }

  TerminalTargetPlatform _terminalPlatform() {
    if (Platform.isMacOS) return TerminalTargetPlatform.macos;
    if (Platform.isLinux) return TerminalTargetPlatform.linux;
    if (Platform.isWindows) return TerminalTargetPlatform.windows;
    return TerminalTargetPlatform.unknown;
  }

  Future<void> _launch(
    Terminal terminal, {
    required int rows,
    required int columns,
  }) async {
    if (_starting || _pty != null || rows <= 0 || columns <= 0) return;
    _starting = true;
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
          ? ['--resume', session.resumeId]
          : ['--session-id', session.id];

      final environment = await ref
          .read(shellEnvServiceProvider)
          .buildEnvironment();

      _projectPath = project.path;
      _resumeId = session.resumeId;
      _currentTitle = session.title;
      _launchTime = DateTime.now();

      final pty = ref
          .read(ptyServiceProvider)
          .start(
            executable: AppConstants.claudeExecutable,
            arguments: args,
            workingDirectory: project.path,
            environment: environment,
            rows: rows,
            columns: columns,
          );
      _pty = pty;
      if (terminal.viewWidth > 0 &&
          terminal.viewHeight > 0 &&
          (terminal.viewWidth != columns || terminal.viewHeight != rows)) {
        pty.resize(terminal.viewHeight, terminal.viewWidth);
      }
      pty.output.listen((data) {
        terminal.write(utf8.decode(data, allowMalformed: true));
        _scheduleReconcile();
      });

      if (!session.claudeStarted) {
        await ref
            .read(sessionsProvider(projectId).notifier)
            .markStarted(session.id);
      }
    } catch (e) {
      _starting = false;
      terminal.write(
        'clio: failed to launch ${AppConstants.claudeExecutable}: $e\r\n',
      );
    }
  }

  void _scheduleReconcile() {
    if (_disposed) return;
    _reconcileTimer?.cancel();
    _reconcileTimer = Timer(const Duration(milliseconds: 1500), _reconcile);
  }

  Future<void> _reconcile() async {
    if (_disposed) return;
    final projectPath = _projectPath;
    final launchTime = _launchTime;
    if (projectPath == null || launchTime == null) return;

    final service = ref.read(claudeSessionServiceProvider);
    try {
      final sessions = await ref.read(sessionsProvider(projectId).future);
      if (_disposed) return;
      final excludeIds = <String>{
        for (final s in sessions)
          if (s.id != sessionId) ...[s.id, s.resumeId],
      };

      final found = await service.findActiveSessionId(
        projectPath: projectPath,
        since: launchTime,
        excludeIds: excludeIds,
      );
      if (_disposed || found == null) return;

      if (found != _resumeId) {
        _resumeId = found;
        await ref
            .read(sessionsProvider(projectId).notifier)
            .updateResumeId(sessionId, found);
        if (_disposed) return;
      }

      final title = await service.readTitle(
        projectPath: projectPath,
        sessionId: found,
      );
      if (_disposed) return;
      if (title != null && title.isNotEmpty && title != _currentTitle) {
        _currentTitle = title;
        await ref
            .read(sessionsProvider(projectId).notifier)
            .rename(sessionId, title);
      }
    } catch (_) {}
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
