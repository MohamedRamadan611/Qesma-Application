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

  @override
  String get expensesEmptyTitle => 'لسه مفيش مصاريف';

  @override
  String get expensesEmptyBody => 'ضيف أول مصروف وقسّمه على الشلة.';

  @override
  String get expensesAdd => 'إضافة مصروف';

  @override
  String get expensesNoMatchTitle => 'مفيش مصاريف مطابقة';

  @override
  String get expensesNoMatchBody => 'جرّب تغيّر الفلاتر أو امسحها.';

  @override
  String get expensesClearFilters => 'امسح الفلاتر';

  @override
  String get expensesLoadMoreFailed => 'معرفناش نحمّل باقي المصاريف.';

  @override
  String get expensesRefreshFailed =>
      'معرفناش نحدّث المصاريف. المعروض هو آخر نسخة عندنا.';

  @override
  String get expenseFilterDate => 'التاريخ';

  @override
  String get expenseFilterMember => 'العضو';

  @override
  String get expenseFilterAll => 'الكل';

  @override
  String expenseFilterRange(String from, String to) {
    return 'من $from لحد $to';
  }

  @override
  String expenseFilterFrom(String from) {
    return 'من $from';
  }

  @override
  String expenseFilterUntil(String to) {
    return 'لحد $to';
  }

  @override
  String expenseFilterRemove(String label) {
    return 'شيل الفلتر: $label';
  }

  @override
  String get expenseFilterDateTitle => 'فلتر التاريخ';

  @override
  String get expenseFilterFromLabel => 'من تاريخ';

  @override
  String get expenseFilterToLabel => 'لحد تاريخ';

  @override
  String get expenseFilterPickDate => 'اختار التاريخ';

  @override
  String get expenseFilterApply => 'تطبيق';

  @override
  String get expenseFilterClear => 'مسح';

  @override
  String get expenseFilterRangeInvalid =>
      'تاريخ البداية لازم يكون قبل تاريخ النهاية.';

  @override
  String get expenseFilterMemberTitle => 'فلتر العضو';

  @override
  String get expenseFilterMemberHint =>
      'بنعرض المصاريف اللي العضو ده دفع فيها أو شارك فيها.';

  @override
  String get expenseFilterAllMembers => 'كل الأعضاء';

  @override
  String expenseDayToday(String date) {
    return 'النهارده — $date';
  }

  @override
  String expenseDayYesterday(String date) {
    return 'إمبارح — $date';
  }

  @override
  String expensePaidBy(String payers) {
    return 'دفع: $payers';
  }

  @override
  String expensePayerAmount(String name, String amount) {
    return '$name ($amount)';
  }

  @override
  String get expenseListSeparator => '، ';

  @override
  String get expenseUnknownMember => 'عضو';

  @override
  String get expenseSplitAmongOne => 'على فرد واحد';

  @override
  String expenseSplitAmong(String count) {
    return 'مقسومة على $count أفراد';
  }

  @override
  String expenseYourShare(String amount) {
    return 'نصيبك: $amount';
  }

  @override
  String expenseCardSpoken(
    String title,
    String total,
    String split,
    String payers,
    String participants,
  ) {
    return '$title، $total، $split، $payers، $participants';
  }

  @override
  String expenseCardSpokenWithShare(
    String title,
    String total,
    String split,
    String payers,
    String participants,
    String share,
  ) {
    return '$title، $total، $split، $payers، $participants، $share';
  }

  @override
  String get expenseSplitEqual => 'بالتساوي';

  @override
  String get expenseSplitExact => 'مبالغ محددة';

  @override
  String get expenseSplitItemized => 'فاتورة مفصلة';

  @override
  String get expenseDetailsTitle => 'تفاصيل المصروف';

  @override
  String get expenseDetailsTotal => 'إجمالي المصروف';

  @override
  String expenseEditedBadge(String version) {
    return 'معدّل (النسخة $version)';
  }

  @override
  String get expensePayersTitle => 'الدافعون';

  @override
  String get expensePayersCountOne => 'دافع واحد';

  @override
  String expensePayersCount(String count) {
    return '$count دافعين';
  }

  @override
  String expensePaidTotal(String amount) {
    return 'مجموع المدفوع: $amount';
  }

  @override
  String get expenseItemsTitle => 'الأصناف والإضافات';

  @override
  String get expenseItemsCountOne => 'صنف واحد';

  @override
  String expenseItemsCount(String count) {
    return '$count أصناف';
  }

  @override
  String get expenseSubtotal => 'مجموع الأصناف';

  @override
  String get expenseServiceLabel => 'رسوم الخدمة';

  @override
  String get expenseTaxLabel => 'الضريبة';

  @override
  String get expenseTaxBaseSubtotal => 'على مجموع الأصناف';

  @override
  String get expenseTaxBaseSubtotalPlusService => 'على الأصناف + الخدمة';

  @override
  String get expenseAdjustmentLabel => 'تسوية';

  @override
  String get expenseBillTotal => 'إجمالي الفاتورة';

  @override
  String expensePercent(String rate) {
    return '$rate%';
  }

  @override
  String get expenseBreakdownTitle => 'نصيب كل فرد';

  @override
  String get expenseBreakdownCountOne => 'فرد واحد';

  @override
  String expenseBreakdownCount(String count) {
    return '$count أفراد';
  }

  @override
  String expensePartItems(String amount) {
    return 'أصناف $amount';
  }

  @override
  String expensePartService(String amount) {
    return 'خدمة $amount';
  }

  @override
  String expensePartTax(String amount) {
    return 'ضريبة $amount';
  }

  @override
  String expensePartAdjustment(String amount) {
    return 'تسوية $amount';
  }

  @override
  String get expenseEdit => 'تعديل المصروف';

  @override
  String get expenseEditItemized => 'تعديل الفاتورة والأصناف';

  @override
  String get expenseDelete => 'حذف المصروف';

  @override
  String get expenseHistory => 'سجل التعديلات';

  @override
  String get expenseDeleteConfirmTitle => 'تحذف المصروف ده؟';

  @override
  String expenseDeleteConfirmBody(String title) {
    return 'هيتشال «$title» من المصاريف والأرصدة.';
  }

  @override
  String get expenseDeleted => 'اتحذف المصروف.';

  @override
  String get expenseAlreadyDeleted => 'المصروف ده كان اتحذف خلاص.';

  @override
  String get expenseGoneTitle => 'المصروف ده مبقاش موجود';

  @override
  String get expenseBackToList => 'رجوع للمصاريف';

  @override
  String expenseHistoryVersion(String version) {
    return 'النسخة $version';
  }

  @override
  String get expenseChangeCreate => 'إنشاء';

  @override
  String get expenseChangeUpdate => 'تعديل';

  @override
  String get expenseChangeDelete => 'حذف';

  @override
  String expenseHistoryTotal(String amount) {
    return 'الإجمالي: $amount';
  }

  @override
  String get expenseConflictTitle => 'المصروف اتعدّل';

  @override
  String get expenseConflictBody =>
      'حد عدّل المصروف ده من آخر مرة فتحته. حمّل آخر نسخة وراجعها قبل ما تحذفه.';

  @override
  String get expensesRefresh => 'تحديث القائمة';

  @override
  String get expenseHistoryEmpty => 'مفيش سجل تعديلات للمصروف ده.';

  @override
  String expenseAssignedTo(String names) {
    return 'على: $names';
  }

  @override
  String get expenseSplitUnknown => 'تقسيم';

  @override
  String get expenseSplitAmongTwo => 'مقسومة على فردين';

  @override
  String expenseSplitAmongMany(String count) {
    return 'مقسومة على $count فردًا';
  }

  @override
  String get expensePayersCountTwo => 'دافعين';

  @override
  String expensePayersCountMany(String count) {
    return '$count دافعًا';
  }

  @override
  String get expenseItemsCountTwo => 'صنفين';

  @override
  String expenseItemsCountMany(String count) {
    return '$count صنفًا';
  }

  @override
  String get expenseBreakdownCountTwo => 'فردين';

  @override
  String expenseBreakdownCountMany(String count) {
    return '$count فردًا';
  }

  @override
  String get expenseFormTitleLabel => 'اسم المصروف';

  @override
  String get expenseFormTitleHint => 'مثلاً: عشا، بنزين، تذاكر';

  @override
  String get expenseFormTitleRequired => 'اكتب اسم للمصروف.';

  @override
  String get expenseFormAmountLabel => 'المبلغ الإجمالي';

  @override
  String get expenseFormAmountHint => 'مثلاً 250 أو 99.50';

  @override
  String get expenseFormAmountInvalid => 'اكتب مبلغ صحيح أكبر من صفر.';

  @override
  String get expenseFormCurrencyNote => 'العملة: جنيه مصري (ج.م)';

  @override
  String get expenseFormDateLabel => 'التاريخ';

  @override
  String get expenseFormPaidByTitle => 'مين اللي دفع؟';

  @override
  String get expenseFormEditPayers => 'تعديل الدافعين';

  @override
  String get expenseFormPayersMismatch =>
      'مجموع اللي دفعوه مش مطابق للإجمالي. عدّل الدافعين.';

  @override
  String get expenseFormSplitTitle => 'طريقة التقسيم';

  @override
  String get expenseFormSplitAll => 'الكل';

  @override
  String get expenseFormSplitSelected => 'محددين';

  @override
  String expenseFormMemberSpoken(String name, String amount) {
    return '$name، نصيبه $amount';
  }

  @override
  String expenseFormMemberUnchecked(String name) {
    return '$name، مش مشارك';
  }

  @override
  String get expenseFormShareLoading => 'بنحسب الأنصبة…';

  @override
  String get expenseFormShareFailed => 'معرفناش نحسب الأنصبة.';

  @override
  String get expenseFormShareNeedAmount =>
      'اكتب المبلغ الإجمالي عشان تظهر الأنصبة.';

  @override
  String get expenseFormExactHint =>
      'تقدر تعدّل حصة كل عضو بإيدك، أو توزّع بالتساوي من جديد.';

  @override
  String expenseFormExactAmountLabel(String name) {
    return 'نصيب $name';
  }

  @override
  String get expenseFormSpreadEqually => 'وزّع بالتساوي';

  @override
  String expenseFormExactSummary(String sum, String total) {
    return 'مجموع التقسيم: $sum من $total';
  }

  @override
  String expenseFormExactRemaining(String amount) {
    return 'لسه باقي $amount';
  }

  @override
  String expenseFormExactOver(String amount) {
    return 'زيادة $amount عن الإجمالي';
  }

  @override
  String get expenseFormExactMatches => 'مطابق للإجمالي';

  @override
  String get expenseFormSave => 'حفظ المصروف';

  @override
  String get expenseFormSaveChanges => 'حفظ التعديلات';

  @override
  String get expenseFormLeaveTitle => 'تخرج من غير ما تحفظ؟';

  @override
  String get expenseFormLeaveBody => 'اللي كتبته هيضيع.';

  @override
  String get expenseFormLeaveConfirm => 'اخرج';

  @override
  String get expenseFormLeaveKeep => 'كمّل كتابة';

  @override
  String get expenseFormConflictTitle => 'المصروف اتعدّل';

  @override
  String get expenseFormConflictBody =>
      'حد عدّل المصروف ده من آخر مرة فتحته. حمّل آخر نسخة، اللي كتبته هيفضل زي ما هو، وبعدين احفظ تاني.';

  @override
  String get expenseFormConflictNote =>
      'حد عدّل المصروف ده. تعديلاتك لسه موجودة، والحفظ هيبدّل نسخته.';

  @override
  String get expenseFormSaveRetry => 'احفظ تاني';

  @override
  String get expenseFormOutcomeUnknown =>
      'مش متأكدين إن المصروف اتحفظ. لو حفظت تاني مش هيتكرر.';

  @override
  String get expensePayersSheetTitle => 'مين دفع الفاتورة؟';

  @override
  String get expensePayersSheetSubtitle =>
      'حدد الأعضاء اللي دفعوا والمبلغ اللي دفعه كل واحد.';

  @override
  String get expensePayersTotalLabel => 'إجمالي الفاتورة المستحق';

  @override
  String get expensePayersNeedTotal => 'اكتب المبلغ الإجمالي الأول.';

  @override
  String expensePayersRemaining(String amount) {
    return 'المتبقي للتوزيع: $amount';
  }

  @override
  String expensePayersOver(String amount) {
    return 'زيادة $amount عن الفاتورة';
  }

  @override
  String get expensePayersMatched => 'المجموع مظبوط ومطابق للفاتورة';

  @override
  String get expensePayersChecking => 'بنراجع المجموع مع الخادم…';

  @override
  String get expensePayersServerMismatch =>
      'الخادم شايف إن المجموع مش مطابق. راجع المبالغ.';

  @override
  String get expensePayersSplitEqually => 'قسّم بالتساوي على الدافعين';

  @override
  String get expensePayersClear => 'امسح المبالغ';

  @override
  String get expensePayersEntered => 'إجمالي المبالغ المدخلة';

  @override
  String expensePayersConfirm(String amount) {
    return 'تأكيد الدافعين ($amount)';
  }

  @override
  String expensePayersAmountLabel(String name) {
    return 'اللي دفعه $name';
  }

  @override
  String expensePayersRowSpoken(String name, String amount) {
    return '$name، دفع $amount';
  }

  @override
  String expensePayersRowUnchecked(String name) {
    return '$name، لم يدفع';
  }

  @override
  String get expensePayersFailed => 'معرفناش نحسب التقسيم بالتساوي. جرّب تاني.';

  @override
  String get expenseFormSaved => 'اتحفظ المصروف.';

  @override
  String get expenseItemizedTotalNote => 'بيتحسب من الأصناف والخدمة والضريبة.';

  @override
  String get expenseItemizedItemsTitle => 'أصناف الفاتورة';

  @override
  String expenseItemizedItemHeading(String n) {
    return 'الصنف $n';
  }

  @override
  String get expenseItemizedNameLabel => 'اسم الصنف';

  @override
  String get expenseItemizedNameHint => 'مثلاً: بيتزا';

  @override
  String get expenseItemizedNameRequired => 'اكتب اسم الصنف.';

  @override
  String get expenseItemizedAmountLabel => 'سعر الصنف';

  @override
  String get expenseItemizedAmountInvalid => 'اكتب سعر صحيح أكبر من صفر.';

  @override
  String get expenseItemizedAssigneesLabel => 'مين شارك في الصنف ده؟';

  @override
  String get expenseItemizedNoAssignee => 'اختار عضو واحد على الأقل.';

  @override
  String get expenseItemizedAdd => 'إضافة صنف جديد';

  @override
  String get expenseItemizedLimit => 'وصلت للحد الأقصى: 100 صنف.';

  @override
  String get expenseItemizedRemove => 'امسح الصنف';

  @override
  String expenseItemizedRemoveSpoken(String n) {
    return 'امسح الصنف $n';
  }

  @override
  String get expenseItemizedChargesTitle => 'الخدمة والضريبة';

  @override
  String get expenseItemizedPercentLabel => 'النسبة (%)';

  @override
  String get expenseItemizedPercentHint => 'مثلاً 12';

  @override
  String get expenseItemizedPercentInvalid =>
      'اكتب نسبة من 0 لـ 100، بحد أقصى رقمين بعد العلامة.';

  @override
  String get expenseItemizedTaxBaseTitle => 'الضريبة بتتحسب على';

  @override
  String get expenseItemizedTaxBaseSubtotal => 'المجموع فقط';

  @override
  String get expenseItemizedTaxBaseWithService => 'المجموع + الخدمة';

  @override
  String get expenseItemizedAdjustmentTitle => 'فرق التقريب / إكرامية';

  @override
  String get expenseItemizedAdjustmentHint =>
      'لتسوية الكسور أو البقشيش. ممكن يكون بالسالب.';

  @override
  String get expenseItemizedAdjustmentInvalid =>
      'اكتب مبلغ صحيح (ممكن يكون بالسالب).';

  @override
  String get expenseItemizedAdjustmentPlus => 'زوّد قرش';

  @override
  String get expenseItemizedAdjustmentMinus => 'نقّص قرش';

  @override
  String get expenseItemizedLoading => 'بنحسب الفاتورة…';

  @override
  String get expenseItemizedFailed => 'معرفناش نحسب الفاتورة.';

  @override
  String get expenseItemizedIncomplete =>
      'كمّل الأصناف والنسب عشان تظهر الحسابات.';

  @override
  String get expenseItemizedPayersMatch => 'الدافعين مطابقين للفاتورة';

  @override
  String get expenseItemizedPayersMismatch =>
      'الدافعين مش مطابقين للفاتورة. عدّل الدافعين.';

  @override
  String get expenseItemizedPayersChecking => 'بنراجع الدافعين…';

  @override
  String get expenseItemizedBarTotal => 'إجمالي الفاتورة المحسوب';

  @override
  String get expensePayersNeedItems => 'كمّل أصناف الفاتورة الأول.';

  @override
  String get balancesTotalSpent => 'إجمالي مصاريف الجروب';

  @override
  String get balancesNeedOne => 'مطلوب تحويل واحد لإنهاء الحسابات';

  @override
  String get balancesNeedTwo => 'مطلوب تحويلين لإنهاء الحسابات';

  @override
  String balancesNeed(String count) {
    return 'مطلوب $count تحويلات لإنهاء الحسابات';
  }

  @override
  String balancesNeedMany(String count) {
    return 'مطلوب $count تحويلًا لإنهاء الحسابات';
  }

  @override
  String get balancesAllSettledTitle => 'الحسابات متصفّية';

  @override
  String get balancesAllSettledBody => 'مفيش حد عليه فلوس لحد دلوقتي.';

  @override
  String get balancesSuggestedTitle => 'تحويلات مقترحة';

  @override
  String get balancesPays => 'يدفع';

  @override
  String get balancesReceives => 'يستلم';

  @override
  String balancesTransferSpoken(String from, String to, String amount) {
    return '$from يدفع $amount لـ $to';
  }

  @override
  String get balancesRecordPayment => 'تسجيل سداد';

  @override
  String balancesRecordPaymentSpoken(String from, String to, String amount) {
    return 'تسجيل سداد من $from إلى $to، $amount';
  }

  @override
  String get balancesRecordAnother => 'سجّل سداد تاني';

  @override
  String get balancesNetsTitle => 'صافي رصيد كل عضو';

  @override
  String balancesMemberSpoken(String name, String status) {
    return '$name، $status';
  }

  @override
  String get balancesHistoryTitle => 'سجل السداد';

  @override
  String get balancesHistoryEmpty => 'لسه مفيش سداد متسجّل.';

  @override
  String balancesPaymentTitle(String from, String to) {
    return '$from سدد لـ $to';
  }

  @override
  String balancesPaymentSpoken(
    String from,
    String to,
    String amount,
    String date,
  ) {
    return '$from سدد $amount لـ $to، $date';
  }

  @override
  String balancesPaymentNoteSpoken(String base, String note) {
    return '$base، $note';
  }

  @override
  String get balancesDeletePayment => 'امسح السداد';

  @override
  String balancesDeletePaymentSpoken(String from, String to, String amount) {
    return 'امسح سداد $from لـ $to، $amount';
  }

  @override
  String get balancesDeleteTitle => 'تمسح السداد ده؟';

  @override
  String get balancesDeleteBody =>
      'الأرصدة هتتحسب من جديد من غير السداد ده، ومش هينفع نرجّعه بعد كده.';

  @override
  String get balancesDeleted => 'اتمسح السداد.';

  @override
  String get balancesDeleteGone => 'السداد ده كان اتمسح قبل كده.';

  @override
  String get balancesLoadMore => 'حمّل المزيد';

  @override
  String get balancesLoadMoreFailed => 'معرفناش نحمّل باقي السداد.';

  @override
  String get balancesRefresh => 'تحديث الأرصدة';

  @override
  String get balancesRefreshFailed =>
      'معرفناش نحدّث الأرصدة. المعروض هو آخر نسخة عندنا.';

  @override
  String get paymentSubtitle => 'تسوية الحسابات بين أعضاء الجروب';

  @override
  String get paymentFrom => 'من (الدافع)';

  @override
  String get paymentTo => 'إلى (المستلم)';

  @override
  String get paymentPickMember => 'اختار عضو';

  @override
  String get paymentAmountLabel => 'المبلغ المسدد (ج.م)';

  @override
  String get paymentAmountError =>
      'اكتب مبلغ صحيح أكبر من صفر، لحد خانتين عشرية.';

  @override
  String paymentFullAmount(String amount) {
    return 'كامل المبلغ: $amount';
  }

  @override
  String get paymentDateLabel => 'تاريخ السداد';

  @override
  String get paymentDateError => 'اختار تاريخ بين 2000 و2100.';

  @override
  String get paymentNoteLabel => 'ملاحظة (اختياري)';

  @override
  String get paymentNoteHint => 'مثلًا: كاش في الرحلة';

  @override
  String get paymentNoteError => 'الملاحظة أطول من 200 حرف.';

  @override
  String get paymentSameMember => 'اختار عضوين مختلفين.';

  @override
  String paymentConfirm(String amount) {
    return 'تأكيد تسجيل السداد ($amount)';
  }

  @override
  String get paymentConfirmNoAmount => 'تأكيد تسجيل السداد';

  @override
  String get paymentRecorded => 'اتسجّل السداد.';

  @override
  String get paymentDiscardTitle => 'تتجاهل السداد ده؟';

  @override
  String get paymentDiscardBody => 'اللي كتبته مش هيتحفظ.';

  @override
  String get paymentDiscardConfirm => 'تجاهل';
}
