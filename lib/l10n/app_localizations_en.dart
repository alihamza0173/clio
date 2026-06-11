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
