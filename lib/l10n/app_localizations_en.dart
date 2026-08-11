// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'clio';

  @override
  String get projectsTitle => 'Projects';

  @override
  String get addProject => 'Add project';

  @override
  String get noProjects => 'No projects yet. Add a folder to get started.';

  @override
  String get removeProject => 'Remove project';

  @override
  String get hideProject => 'Hide project';

  @override
  String get unhideProject => 'Unhide project';

  @override
  String hiddenProjectsHeader(int count) {
    return 'Hidden ($count)';
  }

  @override
  String removeProjectConfirm(String name) {
    return 'Remove \"$name\" from clio? Sessions for this project will be closed.';
  }

  @override
  String get searchFoldersHint => 'Search folders…';

  @override
  String get fromClaudeHistory => 'From your Claude history';

  @override
  String get browseForFolder => 'Browse for folder…';

  @override
  String get projectAlreadyAdded => 'Added';

  @override
  String get noProjectSuggestions =>
      'No previous Claude folders found. Browse for one instead.';

  @override
  String chatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count chats',
      one: '1 chat',
      zero: 'No chats',
    );
    return '$_temp0';
  }

  @override
  String promptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count prompts',
      one: '1 prompt',
    );
    return '$_temp0';
  }

  @override
  String get previousChatsTitle => 'Previous chats';

  @override
  String get previousChatsSubtitle =>
      'Reopen a conversation from this folder — it picks up where you left off.';

  @override
  String get restorePreviousChat => 'Restore previous chat';

  @override
  String restorePreviousChatCount(int count) {
    return 'Restore previous chat ($count)';
  }

  @override
  String get noPreviousChats => 'No previous chats for this folder.';

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String timeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String timeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String timeWeeksAgo(int count) {
    return '${count}w ago';
  }

  @override
  String get sessionsTitle => 'Sessions';

  @override
  String get newSession => 'New session';

  @override
  String get noSessions => 'No sessions yet. Start one to launch Claude here.';

  @override
  String get noSessionSelected => 'Select or create a session to begin.';

  @override
  String get resumeSession => 'Resume';

  @override
  String get removeSession => 'Close session';

  @override
  String get sessionStarting => 'Starting Claude…';

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';
}
