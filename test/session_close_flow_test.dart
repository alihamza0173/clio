import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:clio/core/providers/core_providers.dart';
import 'package:clio/core/services/claude_session_service.dart';
import 'package:clio/core/theme/app_theme.dart';
import 'package:clio/features/sessions/domain/entities/session.dart';
import 'package:clio/features/sessions/presentation/providers/sessions_notifier.dart';
import 'package:clio/features/sessions/presentation/providers/terminal_controller.dart';
import 'package:clio/features/sessions/presentation/widgets/session_tab_bar.dart';
import 'package:clio/l10n/app_localizations.dart';

/// Widget tests run under fake async, where real `dart:io` futures never
/// complete — so the tab bar reads canned history instead of `~/.claude`.
class _FakeClaudeSessionService extends ClaudeSessionService {
  const _FakeClaudeSessionService();

  @override
  Future<List<ClaudeProjectSummary>> discoverProjects() async => const [];

  @override
  Future<List<ClaudeChatSummary>> discoverChats(String projectPath) async =>
      const [];

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

Future<List<Session>> _seed(ProviderContainer container, int count) async {
  final notifier = container.read(sessionsProvider('p1').notifier);
  final created = <Session>[];
  for (var i = 0; i < count; i++) {
    created.add(await notifier.create(title: 'tab${i + 1}'));
  }
  return created;
}

/// Tabs render in session order, so the nth close icon closes the nth tab.
Finder _closeButtonAt(int index) => find.byIcon(Icons.close).at(index);

void main() {
  testWidgets('closing a tab removes it and disposes its terminal', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);
    final sessions = await _seed(container, 2);
    final doomed = sessions.first;

    await tester.pumpWidget(
      _host(container, const SessionTabBar(projectId: 'p1')),
    );
    await tester.pumpAndSettle();

    final bridge = container.read(terminalControllerProvider('p1', doomed.id));

    await tester.tap(_closeButtonAt(0));
    await tester.pumpAndSettle();

    expect(container.read(sessionsProvider('p1')).value!.map((s) => s.id), [
      sessions[1].id,
    ], reason: 'the closed session must be gone from the list');
    expect(
      identical(
        container.read(terminalControllerProvider('p1', doomed.id)),
        bridge,
      ),
      false,
      reason:
          'the keepAlive controller must have been invalidated, so its '
          'onDispose ran and killed the pty',
    );
    expect(find.text('tab1'), findsNothing);
    expect(find.text('tab2'), findsOneWidget);
  });

  testWidgets('closing a background tab leaves the active one selected', (
    tester,
  ) async {
    final container = await _container();
    addTearDown(container.dispose);
    final sessions = await _seed(container, 3);
    container
        .read(activeSessionIdProvider('p1').notifier)
        .select(sessions.last.id);

    await tester.pumpWidget(
      _host(container, const SessionTabBar(projectId: 'p1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(_closeButtonAt(0));
    await tester.pumpAndSettle();

    expect(container.read(activeSessionIdProvider('p1')), sessions.last.id);
  });
}
