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
  String removeProjectConfirm(String name) {
    return 'إزالة \"$name\" من كليو؟ سيتم إغلاق جلسات هذا المشروع.';
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
