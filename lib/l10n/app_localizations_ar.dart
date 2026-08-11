// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'كليو';

  @override
  String get projectsTitle => 'المشاريع';

  @override
  String get addProject => 'إضافة مشروع';

  @override
  String get noProjects => 'لا توجد مشاريع بعد. أضف مجلداً للبدء.';

  @override
  String get removeProject => 'إزالة المشروع';

  @override
  String get hideProject => 'إخفاء المشروع';

  @override
  String get unhideProject => 'إظهار المشروع';

  @override
  String hiddenProjectsHeader(int count) {
    return 'المخفية ($count)';
  }

  @override
  String removeProjectConfirm(String name) {
    return 'إزالة \"$name\" من كليو؟ سيتم إغلاق جلسات هذا المشروع.';
  }

  @override
  String get searchFoldersHint => 'ابحث في المجلدات…';

  @override
  String get fromClaudeHistory => 'من سجل كلود';

  @override
  String get browseForFolder => 'تصفّح المجلدات…';

  @override
  String get projectAlreadyAdded => 'مُضاف';

  @override
  String get noProjectSuggestions =>
      'لا توجد مجلدات سابقة لكلود. تصفّح للاختيار.';

  @override
  String chatCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count محادثة',
      many: '$count محادثة',
      few: '$count محادثات',
      two: 'محادثتان',
      one: 'محادثة واحدة',
      zero: 'لا محادثات',
    );
    return '$_temp0';
  }

  @override
  String promptCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count طلب',
      many: '$count طلباً',
      few: '$count طلبات',
      two: 'طلبان',
      one: 'طلب واحد',
    );
    return '$_temp0';
  }

  @override
  String get previousChatsTitle => 'المحادثات السابقة';

  @override
  String get previousChatsSubtitle =>
      'أعد فتح محادثة من هذا المجلد — تُستأنف من حيث توقفت.';

  @override
  String get restorePreviousChat => 'استعادة محادثة سابقة';

  @override
  String restorePreviousChatCount(int count) {
    return 'استعادة محادثة سابقة ($count)';
  }

  @override
  String get noPreviousChats => 'لا توجد محادثات سابقة لهذا المجلد.';

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int count) {
    return 'قبل $count د';
  }

  @override
  String timeHoursAgo(int count) {
    return 'قبل $count س';
  }

  @override
  String timeDaysAgo(int count) {
    return 'قبل $count ي';
  }

  @override
  String timeWeeksAgo(int count) {
    return 'قبل $count أ';
  }

  @override
  String get sessionsTitle => 'الجلسات';

  @override
  String get newSession => 'جلسة جديدة';

  @override
  String get noSessions => 'لا توجد جلسات بعد. ابدأ واحدة لتشغيل كلود هنا.';

  @override
  String get noSessionSelected => 'اختر جلسة أو أنشئ واحدة للبدء.';

  @override
  String get resumeSession => 'استئناف';

  @override
  String get removeSession => 'إغلاق الجلسة';

  @override
  String get sessionStarting => 'جارٍ تشغيل كلود…';

  @override
  String get cancel => 'إلغاء';

  @override
  String get remove => 'إزالة';
}
