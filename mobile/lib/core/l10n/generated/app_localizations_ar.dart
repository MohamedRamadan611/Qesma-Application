// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'قسمة';

  @override
  String get bootstrapReady =>
      'التطبيق جاهز. الشاشات القادمة تُبنى في المراحل التالية.';

  @override
  String get commonRetry => 'حاول تاني';

  @override
  String get commonCancel => 'إلغاء';

  @override
  String get commonOk => 'تمام';

  @override
  String get commonClose => 'إغلاق';

  @override
  String get commonBack => 'رجوع';

  @override
  String get commonSave => 'حفظ';

  @override
  String get commonDelete => 'امسح';

  @override
  String get commonCopy => 'نسخ';

  @override
  String get commonCopied => 'اتنسخ';

  @override
  String get commonLoading => 'جاري التحميل…';

  @override
  String get fieldClear => 'مسح النص';

  @override
  String fieldCounter(String count, String max) {
    return '$count/$max';
  }

  @override
  String get balanceOwed => 'له';

  @override
  String get balanceOwes => 'عليه';

  @override
  String get balanceSettled => 'خالص';

  @override
  String balanceOwedSpoken(String amount) {
    return 'له $amount';
  }

  @override
  String balanceOwesSpoken(String amount) {
    return 'عليه $amount';
  }

  @override
  String get balanceSettledSpoken => 'خالص، مفيش حاجة مستحقة';

  @override
  String get moneyCurrency => 'ج.م';

  @override
  String moneySpokenPounds(String pounds) {
    return '$pounds جنيه';
  }

  @override
  String moneySpokenPoundsPiasters(String pounds, String piasters) {
    return '$pounds جنيه و$piasters قرش';
  }

  @override
  String moneySpokenPiasters(String piasters) {
    return '$piasters قرش';
  }

  @override
  String moneySpokenNegative(String amount) {
    return 'سالب $amount';
  }

  @override
  String get stateErrorTitle => 'حصل خطأ غير متوقع';

  @override
  String get stateErrorMessage =>
      'حاولنا ننفذ طلبك بس حصلت مشكلة. جرّب تاني بعد شوية.';

  @override
  String stateErrorRequestId(String id) {
    return 'رمز الخطأ: $id';
  }

  @override
  String get stateNoInternetTitle => 'مفيش اتصال بالإنترنت';

  @override
  String get stateNoInternetMessage =>
      'التطبيق محتاج إنترنت عشان يحفظ ويسجّل المصاريف. اتأكد من الواي فاي أو باقة الموبايل.';

  @override
  String get stateNoInternetReassure =>
      'اللي سجلته قبل كده محفوظ، وهيظهر أول ما النت يرجع.';

  @override
  String get stateOfflineBanner => 'مفيش اتصال بالإنترنت';

  @override
  String get errorTimeout =>
      'الطلب أخد وقت أطول من اللازم. اتأكد من النت وجرّب تاني.';

  @override
  String get errorNoConnection =>
      'مفيش اتصال بالإنترنت. اتأكد من النت وجرّب تاني.';

  @override
  String get errorUnexpected => 'حصل خطأ غير متوقع. جرّب تاني بعد شوية.';

  @override
  String get errorInternal => 'حصل خطأ من عندنا. جرّب تاني بعد شوية.';

  @override
  String get errorValidation => 'في بيانات مش مظبوطة. راجع الحقول وجرّب تاني.';

  @override
  String get errorPayersTotalMismatch =>
      'مجموع اللي دفعوه لازم يساوي إجمالي المصروف.';

  @override
  String get errorSplitTotalMismatch =>
      'مجموع الأنصبة لازم يساوي إجمالي المصروف.';

  @override
  String get errorMemberNotInGroup =>
      'قائمة الأعضاء اتغيّرت. هنحدّثها وتكمّل من مكانك.';

  @override
  String errorDuplicateMemberName(String name) {
    return 'الاسم «$name» موجود قبل كده في المجموعة. جرّب تضيف اللقب عشان نفرّق بينهم.';
  }

  @override
  String get errorMemberHasTransactionsTitle => 'مينفعش نمسح العضو';

  @override
  String get errorMemberHasTransactionsMessage =>
      'العضو ده مشارك في مصاريف أو تسويات، فمينفعش يتمسح.';

  @override
  String get errorGroupNotEmptyTitle => 'مينفعش نمسح المجموعة';

  @override
  String get errorGroupNotEmptyMessage =>
      'المجموعة فيها مصاريف أو تسويات، فمينفعش تتمسح.';

  @override
  String get errorOwnerMemberProtectedTitle => 'ده حسابك في المجموعة';

  @override
  String get errorOwnerMemberProtectedMessage =>
      'مينفعش تمسح نفسك من المجموعة، بس تقدر تغيّر اسمك.';

  @override
  String get errorVersionConflictTitle => 'اتعدّل من مكان تاني';

  @override
  String get errorVersionConflictMessage =>
      'حد غيّر البيانات دي من وقت ما فتحتها. هنحمّل آخر نسخة وتقدر تعيد تعديلك.';

  @override
  String get errorNotFound => 'ده مبقاش متاح. ممكن يكون اتمسح.';

  @override
  String get errorUnauthorized => 'لازم تسجّل الدخول من جديد.';

  @override
  String get errorRateLimited =>
      'محاولات كتير في وقت قصير. استنى دقيقة وجرّب تاني.';

  @override
  String get errorAuthProviderUnavailable =>
      'مش قادرين نتواصل مع جوجل دلوقتي. جرّب تاني بعد شوية.';

  @override
  String get brandWordmark => 'قِسْمَة';

  @override
  String get brandTagline =>
      'حسابات السفر والطلعات واللمّة .. صافية وسلسة وبدون إحراج';

  @override
  String get welcomeTitle => 'احسب مصاريف الشلة والرحلات والسكن من غير لخبطة';

  @override
  String get welcomeValue1Title => 'حسابات دقيقة بالقرش';

  @override
  String get welcomeValue1Body => 'لكل شخص نصيبه الصافي بدون هدر مليم';

  @override
  String get welcomeValue2Title => 'تقسيم فواتير المطاعم';

  @override
  String get welcomeValue2Body =>
      'توزيع تلقائي لنسب الخدمة والضريبة على اللي أكلوا';

  @override
  String get welcomeValue3Title => 'أسهل طريقة لتصفية الحساب';

  @override
  String get welcomeValue3Body =>
      'بنحسب قايمة تحويلات قصيرة وعملية بين الأصحاب';

  @override
  String get welcomeStart => 'ابدأ الآن';

  @override
  String get legalConsentPrefix => 'بتسجيلك أنت توافق على';

  @override
  String get legalTerms => 'شروط الاستخدام';

  @override
  String get legalAnd => 'و';

  @override
  String get legalPrivacy => 'سياسة الخصوصية';

  @override
  String get legalOpenFailed =>
      'مقدرناش نفتح الرابط دلوقتي. جرّب تاني بعد شوية.';

  @override
  String get signInWithGoogle => 'المتابعة باستخدام Google';

  @override
  String get signInFailed => 'مقدرناش نسجّل دخولك. جرّب تاني.';

  @override
  String get signInNotConfigured =>
      'تسجيل الدخول بجوجل مش متظبط على الجهاز ده (GOOGLE_SERVER_CLIENT_ID).';

  @override
  String get devFakeSignIn => 'دخول تجريبي (للتطوير فقط)';

  @override
  String get sessionExpiredTitle => 'انتهت الجلسة';

  @override
  String get sessionExpiredBody =>
      'سجّل دخولك تاني عشان تكمل بأمان وتحمي حساباتك ومصاريفك المشتركة.';

  @override
  String get sessionExpiredReassure =>
      'بياناتك ومجموعاتك محفوظة بالكامل ولم تتأثر';

  @override
  String get sessionExpiredLeave => 'الرجوع للبداية';

  @override
  String homeSignedInAs(String name) {
    return 'مسجّل دخول باسم $name';
  }

  @override
  String get homeSignOut => 'تسجيل الخروج';

  @override
  String get groupsTitle => 'المجموعات';

  @override
  String get groupsNew => 'جروب جديد';

  @override
  String get groupsMore => 'المزيد';

  @override
  String get groupsEmptyTitle => 'مفيش جروبات لسه';

  @override
  String get groupsEmptyBody => 'ابدأ بجروب جديد وضيف أصحابك، وإحنا نحسبها.';

  @override
  String get groupsNetTotal => 'صافي رصيدك في كل الجروبات';

  @override
  String get groupsRefreshFailed => 'مقدرناش نحدّث القايمة. جرّب تاني.';

  @override
  String get groupsLoadMoreFailed =>
      'مقدرناش نحمّل باقي الجروبات. اسحب لتحت وجرّب تاني.';

  @override
  String get groupTypeTrip => 'رحلة';

  @override
  String get groupTypeHousing => 'سكن';

  @override
  String get groupTypeOuting => 'خروجة';

  @override
  String get groupTypeOther => 'أخرى';

  @override
  String groupLastActivity(String date) {
    return 'آخر نشاط: $date';
  }

  @override
  String get groupNoActivity => 'لسه مفيش مصاريف';

  @override
  String get groupTotalSpent => 'إجمالي المصاريف';

  @override
  String groupMemberCount(String count) {
    return '$count أعضاء';
  }

  @override
  String get groupMemberOne => 'عضو واحد';

  @override
  String groupCardSpoken(
    String name,
    String type,
    String members,
    String total,
    String balance,
  ) {
    return '$name، $type، $members، إجمالي المصاريف $total، $balance';
  }

  @override
  String get groupOpenFailedGone => 'الجروب ده مبقاش متاح.';

  @override
  String get groupBackToList => 'الرجوع للمجموعات';

  @override
  String get groupCreateTitle => 'إنشاء جروب جديد';

  @override
  String get groupCreateSubtitle => 'رحلة أو سكن أو خروجة. ابدأ بالاسم والنوع.';

  @override
  String get groupNameLabel => 'اسم الجروب';

  @override
  String get groupNameHint => 'مثال: رحلة دهب';

  @override
  String get groupTypeLabel => 'نوع الجروب';

  @override
  String get groupCurrencyLabel => 'العملة';

  @override
  String get groupCurrencyValue => 'جنيه مصري (ج.م)';

  @override
  String get groupCurrencyNote => 'العملة ثابتة بعد إنشاء الجروب';

  @override
  String get groupCreateButton => 'إنشاء الجروب';

  @override
  String get groupCreateOutcomeUnknown =>
      'مش متأكدين إن الجروب اتعمل. هنتأكد الأول قبل ما نحاول تاني، عشان ميتكررش.';

  @override
  String get groupEditTitle => 'تعديل الجروب';

  @override
  String groupCreatedOn(String date) {
    return 'تاريخ الإنشاء: $date';
  }

  @override
  String get groupSaveChanges => 'حفظ التعديلات';

  @override
  String get groupDelete => 'امسح الجروب';

  @override
  String get groupDeleteConfirmTitle => 'مسح الجروب؟';

  @override
  String groupDeleteConfirmBody(String name) {
    return 'هيتمسح «$name» نهائيًا ومش هينفع ترجّعه.';
  }

  @override
  String groupBlockedTotal(String amount) {
    return 'إجمالي المصاريف المسجلة: $amount';
  }

  @override
  String get groupBlockedHint =>
      'سوّي الحسابات الأول، وبعدها اتواصل مع الدعم لو لسه عايز تمسحه.';

  @override
  String get groupConflictReload => 'حمّل آخر نسخة';

  @override
  String get groupConflictKeep => 'كمّل بتعديلي';

  @override
  String get groupTabExpenses => 'المصاريف';

  @override
  String get groupTabBalances => 'الأرصدة';

  @override
  String get groupTabMembers => 'الأعضاء';

  @override
  String get groupNotBuiltYet => 'الشاشة دي لسه تحت الإنشاء.';

  @override
  String groupHeaderSubtitle(String members, String total) {
    return '$members • $total';
  }

  @override
  String get membersAdd => 'إضافة عضو';

  @override
  String get membersYouTag => '(أنت)';

  @override
  String membersOptions(String name) {
    return 'خيارات $name';
  }

  @override
  String get membersRename => 'تغيير الاسم';

  @override
  String get membersDelete => 'مسح العضو';

  @override
  String get memberAddTitle => 'إضافة عضو جديد';

  @override
  String get memberAddSubtitle =>
      'أضف اسم الصديق ليتمكن المنظم من توزيع المصاريف عليه بسهولة.';

  @override
  String get memberNameLabel => 'اسم العضو داخل الجروب';

  @override
  String get memberSave => 'حفظ العضو';

  @override
  String get memberRenameTitle => 'تغيير اسم العضو';

  @override
  String get memberDeleteConfirmTitle => 'مسح العضو؟';

  @override
  String memberDeleteConfirmBody(String name) {
    return 'هيتشال «$name» من الجروب.';
  }
}
