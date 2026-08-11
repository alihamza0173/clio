import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clio/core/providers/core_providers.dart';
import 'package:clio/core/services/claude_session_service.dart';
import 'package:clio/core/theme/app_theme.dart';
import 'package:clio/core/widgets/suggestion_tile.dart';
import 'package:clio/features/projects/presentation/providers/claude_project_suggestions.dart';
import 'package:clio/features/projects/presentation/providers/projects_notifier.dart';
import 'package:clio/features/projects/presentation/widgets/add_project_dialog.dart';
import 'package:clio/features/sessions/presentation/providers/claude_chat_suggestions.dart';
import 'package:clio/features/sessions/presentation/providers/sessions_notifier.dart';
import 'package:clio/l10n/app_localizations.dart';

/// Widget tests run under fake async, where real `dart:io` futures never
/// complete — so the UI tests read canned history instead of `~/.claude`.
class _FakeClaudeSessionService extends ClaudeSessionService {
  const _FakeClaudeSessionService();

  static final DateTime _when = DateTime.now().subtract(
    const Duration(hours: 2),
  );

  static final projects = [
    ClaudeProjectSummary(
      path: '/Users/dev/work/alpha',
      name: 'alpha',
      chatCount: 3,
      lastActiveAt: _when,
    ),
    ClaudeProjectSummary(
      path: '/Users/dev/work/beta',
      name: 'beta',
      chatCount: 1,
      lastActiveAt: _when.subtract(const Duration(days: 2)),
    ),
  ];

  static final chats = [
    ClaudeChatSummary(
      id: 'chat-one',
      promptCount: 12,
      lastActiveAt: _when,
      title: 'Fix login redirect',
      gitBranch: 'main',
    ),
    ClaudeChatSummary(
      id: 'chat-two',
      promptCount: 0,
      lastActiveAt: _when.subtract(const Duration(hours: 5)),
      preview: 'why does the build fail on windows',
    ),
  ];

  @override
  Future<List<ClaudeProjectSummary>> discoverProjects() async => projects;

  @override
  Future<List<ClaudeChatSummary>> discoverChats(String projectPath) async =>
      chats;

  @override
  Future<String?> readTitle({
    required String projectPath,
    required String sessionId,
  }) async => null;
}

Future<ProviderContainer> _container() async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  return ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      claudeSessionServiceProvider.overrideWithValue(
        const _FakeClaudeSessionService(),
      ),
    ],
  );
}

Widget _host(ProviderContainer container, Widget child) =>
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.dark,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    );

void main() {
  const service = ClaudeSessionService();

  group('discovery against the real ~/.claude', () {
    test('discoverProjects returns existing absolute paths', () async {
      final projects = await service.discoverProjects();
      if (projects.isEmpty) {
        markTestSkipped('no ~/.claude/projects history on this machine');
        return;
      }
      for (final project in projects) {
        expect(
          project.path,
          Directory(project.path).absolute.path,
          reason: 'recovered paths must be absolute on every platform',
        );
        expect(Directory(project.path).existsSync(), isTrue);
        expect(project.name, isNot(contains('/')));
        expect(project.chatCount, greaterThan(0));
      }
    });

    test('discoverChats labels every chat it offers', () async {
      final projects = await service.discoverProjects();
      if (projects.isEmpty) {
        markTestSkipped('no ~/.claude/projects history on this machine');
        return;
      }
      var smallest = projects.first;
      for (final project in projects) {
        if (project.chatCount < smallest.chatCount) smallest = project;
      }
      final chats = await service.discoverChats(smallest.path);
      for (final chat in chats) {
        expect(chat.id, isNotEmpty);
        expect(chat.label, isNotEmpty);
      }
    });
  });

  testWidgets('AddProjectDialog lists history and returns the picked path', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);

    String? picked;
    await tester.pumpWidget(
      _host(
        container,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                picked = await AddProjectDialog.show(context),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byType(SuggestionTile), findsNWidgets(2));
    expect(find.text('alpha'), findsOneWidget);
    expect(find.text('3 chats · 2h ago'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'bet');
    await tester.pumpAndSettle();
    expect(find.text('alpha'), findsNothing);
    expect(find.text('beta'), findsOneWidget);

    await tester.tap(find.text('beta'));
    await tester.pumpAndSettle();

    expect(picked, '/Users/dev/work/beta');
    expect(find.byType(SuggestionTile), findsNothing);
  });

  testWidgets('already-added folders are shown but not selectable', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);
    await container
        .read(projectsProvider.notifier)
        .addProjectByPath('/Users/dev/work/alpha');

    var picked = 'untouched';
    await tester.pumpWidget(
      _host(
        container,
        Builder(
          builder: (context) => TextButton(
            onPressed: () async =>
                picked = await AddProjectDialog.show(context) ?? 'dismissed',
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Added'), findsOneWidget);

    await tester.tap(find.text('alpha'));
    await tester.pumpAndSettle();
    expect(
      picked,
      'untouched',
      reason: 'tapping an added folder must be inert',
    );
  });

  test(
    'restoring a chat creates a resumable session and leaves the picker',
    () async {
      final container = await _container();
      addTearDown(container.dispose);

      final project = await container
          .read(projectsProvider.notifier)
          .addProjectByPath('/Users/dev/work/alpha');

      final chats = await container.read(
        claudeChatSuggestionsProvider(project.id).future,
      );
      expect(chats.map((c) => c.id), ['chat-one', 'chat-two']);

      final session = await container
          .read(sessionsProvider(project.id).notifier)
          .restoreChat(chats.first);

      expect(session.resumeId, 'chat-one');
      expect(session.claudeStarted, isTrue);
      expect(session.title, 'Fix login redirect');
      expect(
        session.id,
        isNot('chat-one'),
        reason: 'the internal id stays distinct from the transcript id',
      );

      final stored = await container.read(sessionsProvider(project.id).future);
      expect(stored.single.resumeId, 'chat-one');
      expect(stored.single.claudeStarted, isTrue);

      final remaining = await container.read(
        claudeChatSuggestionsProvider(project.id).future,
      );
      expect(
        remaining.map((c) => c.id),
        ['chat-two'],
        reason: 'a restored chat must not stay in the picker',
      );
    },
  );

  test('a plain new session is not marked as resumable', () async {
    final container = await _container();
    addTearDown(container.dispose);

    final project = await container
        .read(projectsProvider.notifier)
        .addProjectByPath('/Users/dev/work/alpha');
    final session = await container
        .read(sessionsProvider(project.id).notifier)
        .create();

    expect(session.claudeStarted, isFalse);
    expect(session.resumeId, session.id);
  });

  test('adding the same folder twice reuses the project', () async {
    final container = await _container();
    addTearDown(container.dispose);

    final notifier = container.read(projectsProvider.notifier);
    final first = await notifier.addProjectByPath('/Users/dev/work/alpha');
    final second = await notifier.addProjectByPath('/Users/dev/work/alpha');

    expect(second.id, first.id);
    expect((await container.read(projectsProvider.future)).length, 1);
  });

  test('claudeProjectSuggestions surfaces the service list', () async {
    final container = await _container();
    addTearDown(container.dispose);

    final suggestions = await container.read(
      claudeProjectSuggestionsProvider.future,
    );
    expect(suggestions.map((s) => s.name), ['alpha', 'beta']);
  });
}
