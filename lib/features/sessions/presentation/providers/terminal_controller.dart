import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/providers/core_providers.dart';
import '../../../../core/services/pty_service.dart';
import '../../../projects/domain/entities/project.dart';
import '../../../projects/presentation/providers/projects_notifier.dart';
import '../../domain/entities/session.dart';
import 'sessions_notifier.dart';

part 'terminal_controller.g.dart';

/// Facade handed to the webview-backed terminal widget for one session.
///
/// The widget pushes pty output toward the renderer via [onOutput] and feeds
/// keyboard/paste/resize back through [handleInput]/[handleResize]; the first
/// [handleReady] (emitted once xterm.js has a real column/row count) lazily
/// launches `claude` at that exact size.
class TerminalBridge {
  TerminalBridge._(this._controller);

  final TerminalController _controller;
  void Function(Uint8List bytes)? _outputSink;
  final List<Uint8List> _pending = [];

  set onOutput(void Function(Uint8List bytes)? sink) {
    _outputSink = sink;
    if (sink != null && _pending.isNotEmpty) {
      for (final b in _pending) {
        sink(b);
      }
      _pending.clear();
    }
  }

  void _emit(Uint8List bytes) {
    final sink = _outputSink;
    if (sink != null) {
      sink(bytes);
    } else {
      _pending.add(bytes);
    }
  }

  void handleReady(int cols, int rows) => _controller._onReady(rows, cols);
  void handleResize(int cols, int rows) => _controller._onResize(rows, cols);
  void handleInput(List<int> bytes) => _controller._write(bytes);
}

/// Owns the [PtyHandle] + [TerminalBridge] lifecycle for a single session.
///
/// `claude` is spawned lazily on the first ready handshake so the pty starts at
/// the renderer's real column/row count — spawning at a default size first makes
/// the Ink TUI reflow and duplicate its output. Resize is forwarded to the pty
/// synchronously (no debounce) so the pty width never drifts from what xterm.js
/// is painting, mirroring how `claude` behaves in a real terminal.
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
  String? _projectPath;
  String? _resumeId;
  String? _currentTitle;
  late final TerminalBridge _bridge;

  @override
  TerminalBridge build(String projectId, String sessionId) {
    _bridge = TerminalBridge._(this);
    ref.onDispose(() {
      _disposed = true;
      _reconcileTimer?.cancel();
      _pty?.kill();
    });
    return _bridge;
  }

  void _onReady(int rows, int columns) {
    if (_pty == null) _launch(rows: rows, columns: columns);
  }

  void _onResize(int rows, int columns) {
    if (rows > 0 && columns > 0) _pty?.resize(rows, columns);
  }

  void _write(List<int> bytes) {
    if (bytes.isNotEmpty) _pty?.write(Uint8List.fromList(bytes));
  }

  Future<void> _launch({required int rows, required int columns}) async {
    if (_starting || _pty != null || rows <= 0 || columns <= 0) return;
    _starting = true;
    try {
      final project = _findProject(await ref.read(projectsProvider.future));
      if (project == null) {
        _bridge._emit(_bytes('clio: project not found.\r\n'));
        return;
      }
      final session = _findSession(
        await ref.read(sessionsProvider(projectId).future),
      );
      if (session == null) {
        _bridge._emit(_bytes('clio: session not found.\r\n'));
        return;
      }

      final resumable =
          session.claudeStarted &&
          await ref
              .read(claudeSessionServiceProvider)
              .hasResumableTranscript(
                projectPath: project.path,
                sessionId: session.resumeId,
              );
      final args = resumable
          ? ['--resume', session.resumeId]
          : ['--session-id', session.id];

      final environment = await ref
          .read(shellEnvServiceProvider)
          .buildEnvironment();

      _projectPath = project.path;
      _resumeId = session.resumeId;
      _currentTitle = session.title;

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
      pty.output.listen((data) {
        _bridge._emit(data);
        _scheduleReconcile();
      });

      if (!session.claudeStarted) {
        await ref
            .read(sessionsProvider(projectId).notifier)
            .markStarted(session.id);
      }
    } catch (e) {
      _starting = false;
      _bridge._emit(
        _bytes(
          'clio: failed to launch ${AppConstants.claudeExecutable}: $e\r\n',
        ),
      );
    }
  }

  Uint8List _bytes(String s) => Uint8List.fromList(utf8.encode(s));

  void _scheduleReconcile() {
    if (_disposed) return;
    _reconcileTimer?.cancel();
    _reconcileTimer = Timer(const Duration(milliseconds: 1500), _reconcile);
  }

  Future<void> _reconcile() async {
    if (_disposed) return;
    final pty = _pty;
    final projectPath = _projectPath;
    if (pty == null || projectPath == null) return;

    final service = ref.read(claudeSessionServiceProvider);
    try {
      final info = await service.readSessionByPid(pty.pid);
      if (_disposed || info == null) return;

      final found = info.sessionId;
      if (found != null && found.isNotEmpty && found != _resumeId) {
        _resumeId = found;
        await ref
            .read(sessionsProvider(projectId).notifier)
            .updateResumeId(sessionId, found);
        if (_disposed) return;
      }

      var title = info.name;
      if (title == null || title.isEmpty) {
        title = await service.readTitle(
          projectPath: projectPath,
          sessionId: _resumeId ?? sessionId,
        );
        if (_disposed) return;
      }
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
