import 'package:clio/l10n/app_localizations.dart';

String formatRelativeTime(AppLocalizations l10n, DateTime time) {
  final difference = DateTime.now().difference(time);

  final minutes = difference.inMinutes;
  if (minutes < 1) return l10n.timeJustNow;
  if (minutes < 60) return l10n.timeMinutesAgo(minutes);

  final hours = difference.inHours;
  if (hours < 24) return l10n.timeHoursAgo(hours);

  final days = difference.inDays;
  if (days < 7) return l10n.timeDaysAgo(days);

  return l10n.timeWeeksAgo(days ~/ 7);
}
