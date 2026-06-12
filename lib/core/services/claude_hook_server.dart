import 'dart:async';
import 'dart:convert';
import 'dart:io';

class ClaudeHookEvent {
  const ClaudeHookEvent({
    required this.projectId,
    required this.sessionId,
    required this.event,
    this.notificationKind,
  });

  final String projectId;
  final String sessionId;
  final String event;
  final String? notificationKind;
}

/// Loopback HTTP listener receiving Claude Code hook callbacks.
///
/// Each spawned `claude` gets a per-invocation `--settings` payload (built by
/// [settingsJson]) whose `http`-type hooks POST back to
/// `/hook/<projectId>/<sessionId>`. Identity lives in the URL — not the hook
/// payload's `session_id` — so it survives `/clear` and `/resume` inside the
/// TUI, where the claude-side session id drifts.
class ClaudeHookServer {
  HttpServer? _server;
  Future<int>? _port;
  final StreamController<ClaudeHookEvent> _events =
      StreamController.broadcast();

  Stream<ClaudeHookEvent> get events => _events.stream;

  Future<int> ensureStarted() => _port ??= _bind();

  Future<int> _bind() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = server;
    server.listen(_handle, onError: (_) {});
    return server.port;
  }

  Future<void> _handle(HttpRequest request) async {
    try {
      final segments = request.uri.pathSegments;
      if (request.method == 'POST' &&
          segments.length == 3 &&
          segments.first == 'hook') {
        final body = await utf8.decoder.bind(request).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        if (!_events.isClosed) {
          _events.add(
            ClaudeHookEvent(
              projectId: segments[1],
              sessionId: segments[2],
              event: json['hook_event_name'] as String? ?? '',
              notificationKind: request.uri.queryParameters['kind'],
            ),
          );
        }
      }
      request.response.statusCode = HttpStatus.ok;
    } catch (_) {
      request.response.statusCode = HttpStatus.badRequest;
    } finally {
      await request.response.close();
    }
  }

  Future<String> settingsJson({
    required String projectId,
    required String sessionId,
  }) async {
    final port = await ensureStarted();
    final endpoint = 'http://127.0.0.1:$port/hook/$projectId/$sessionId';
    Map<String, Object> http(String url) => {'type': 'http', 'url': url};
    List<Map<String, Object>> plain() => [
      {
        'hooks': [http(endpoint)],
      },
    ];
    return jsonEncode({
      'allowedHttpHookUrls': ['http://127.0.0.1:$port/*'],
      'hooks': {
        'UserPromptSubmit': plain(),
        'PostToolUse': plain(),
        'Stop': plain(),
        'StopFailure': plain(),
        'SessionEnd': plain(),
        'Notification': [
          {
            'matcher': 'permission_prompt',
            'hooks': [http('$endpoint?kind=permission_prompt')],
          },
          {
            'matcher': 'idle_prompt',
            'hooks': [http('$endpoint?kind=idle_prompt')],
          },
        ],
      },
    });
  }

  Future<String> settingsFile({
    required String projectId,
    required String sessionId,
  }) async {
    final json = await settingsJson(projectId: projectId, sessionId: sessionId);
    final dir = await Directory.systemTemp.createTemp('clio_hooks_');
    final file = File('${dir.path}${Platform.pathSeparator}settings.json');
    await file.writeAsString(json);
    return file.path;
  }

  Future<void> dispose() async {
    await _server?.close(force: true);
    await _events.close();
  }
}
