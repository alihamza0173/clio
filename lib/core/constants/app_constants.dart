abstract final class AppConstants {
  const AppConstants._();

  static const String projectsStorageKey = 'clio.projects';
  static const String sessionsStorageKeyPrefix = 'clio.sessions.';

  static const String claudeExecutable = 'claude';

  static String sessionsStorageKey(String projectId) =>
      '$sessionsStorageKeyPrefix$projectId';
}
