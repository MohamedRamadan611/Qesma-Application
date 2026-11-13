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
  String get stateOfflineBanner => 'الاتصال مقطوع حاليًا';

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
  String get errorForbidden => 'صلاحيتك في المجموعة مش بتسمح بالإجراء ده.';

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

  @override
  String get profileTitle => 'حسابي';

  @override
  String get profileEdit => 'تعديل الملف الشخصي';

  @override
  String get profileGroupsOne => 'مجموعة واحدة';

  @override
  String get profileGroupsTwo => 'مجموعتين';

  @override
  String profileGroups(String count) {
    return '$count مجموعات';
  }

  @override
  String profileGroupsMany(String count) {
    return '$count مجموعة';
  }

  @override
  String get profileSectionPrefs => 'التفضيلات';

  @override
  String get profileSectionAbout => 'عن التطبيق';

  @override
  String get profileLanguage => 'لغة التطبيق';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSheetTitle => 'اختار اللغة';

  @override
  String get profileAccountSettings => 'إعدادات الحساب';

  @override
  String get profileVersion => 'إصدار التطبيق';

  @override
  String get profileSignOutTitle => 'تسجّل خروج؟';

  @override
  String get profileSignOutBody => 'هتحتاج تسجّل دخول بجوجل تاني عشان ترجع.';

  @override
  String get profileEditTitle => 'تعديل الملف الشخصي';

  @override
  String get profileNameLabel => 'الاسم المعروض';

  @override
  String get profileNameHint =>
      'الاسم ده هيظهر لأصحابك في المجموعات والمصاريف.';

  @override
  String get profileNameRequired => 'اكتب اسمك عشان أصحابك يعرفوك.';

  @override
  String get profileNameTooLong => 'الاسم أطول من 60 حرف.';

  @override
  String get profileEmailLabel => 'البريد الإلكتروني';

  @override
  String get profileEmailLocked => 'مرتبط بحساب جوجل ومش بيتعدّل يدويًا.';

  @override
  String get profileSave => 'حفظ التعديلات';

  @override
  String get profileSaved => 'اتحفظ الاسم.';

  @override
  String get profileDiscardTitle => 'تتجاهل التعديلات؟';

  @override
  String get profileDiscardBody => 'الاسم الجديد مش هيتحفظ.';

  @override
  String get profileDiscardConfirm => 'تجاهل';

  @override
  String get accountGoogleTitle => 'حساب جوجل المرتبط';

  @override
  String get accountConnected => 'متصل';

  @override
  String get profileAppearance => 'المظهر';

  @override
  String get appearanceSheetTitle => 'اختار المظهر';

  @override
  String get appearanceSystem => 'زي الموبايل';

  @override
  String get appearanceLight => 'فاتح';

  @override
  String get appearanceDark => 'داكن';

  @override
  String get authUsernameContinue => 'المتابعة باسم المستخدم';

  @override
  String get authUsernameSignInTitle => 'تسجيل الدخول باسم المستخدم';

  @override
  String get authUsernameSignInButton => 'دخول';

  @override
  String get authRegisterTitle => 'إنشاء حساب';

  @override
  String get authRegisterButton => 'إنشاء الحساب';

  @override
  String get authGoRegister => 'معندكش حساب؟ أنشئ حساب جديد';

  @override
  String get authGoSignIn => 'عندك حساب؟ سجّل دخول';

  @override
  String get fieldUsername => 'اسم المستخدم';

  @override
  String get fieldPassword => 'كلمة السر';

  @override
  String get fieldPasswordShow => 'إظهار كلمة السر';

  @override
  String get fieldPasswordHide => 'إخفاء كلمة السر';

  @override
  String get fieldDisplayNameOptional => 'الاسم (اختياري)';

  @override
  String get authPasswordRules =>
      'كلمة السر 8 حروف على الأقل، ومش من الكلمات الشائعة.';

  @override
  String get authErrorUsernameInvalid =>
      'اسم المستخدم من 3 لـ 30 حرف: حروف وأرقام ونقطة وشرطة، من غير مسافات أو @.';

  @override
  String get authErrorPasswordShort => 'كلمة السر لازم تكون 8 حروف على الأقل.';

  @override
  String get authErrorPasswordLong =>
      'كلمة السر طويلة قوي. الحد الأقصى 72 بايت (حوالي 36 حرف عربي).';

  @override
  String get authErrorWrongCredentials =>
      'اسم المستخدم أو كلمة السر مش صح. جرّب تاني.';

  @override
  String get authErrorUsernameTaken =>
      'اسم المستخدم ده مأخوذ. اختار اسم تاني أو سجّل دخول.';

  @override
  String get authErrorPasswordRejected =>
      'كلمة السر دي مش مقبولة. اختار كلمة أقوى وأقل شيوعًا.';

  @override
  String get profileChangePassword => 'تغيير كلمة السر';

  @override
  String get passwordChangeTitle => 'تغيير كلمة السر';

  @override
  String get passwordCurrentLabel => 'كلمة السر الحالية';

  @override
  String get passwordNewLabel => 'كلمة السر الجديدة';

  @override
  String get passwordChangeButton => 'حفظ كلمة السر';

  @override
  String get passwordChanged => 'اتغيرت كلمة السر. باقي الأجهزة اتسجّل خروجها.';

  @override
  String get passwordCurrentWrong =>
      'كلمة السر الحالية مش صح، أو الجديدة مش مقبولة (شائعة قوي).';

  @override
  String get accountSignedInWithPassword =>
      'مسجّل دخول باسم المستخدم وكلمة السر';

  @override
  String get inviteAction => 'دعوة أعضاء';

  @override
  String get inviteSheetTitle => 'دعوة أعضاء للجروب';

  @override
  String inviteSheetSubtitle(String group) {
    return 'جروب «$group»';
  }

  @override
  String get inviteSheetIntro =>
      'شارك الكود أو الرابط مع صحابك عشان يشوفوا الحسابات ويضيفوا مصاريفهم أول بأول.';

  @override
  String get inviteCodeLabel => 'كود الانضمام';

  @override
  String get inviteCopyCode => 'نسخ الكود';

  @override
  String get inviteCodeCopied => 'تم نسخ الكود';

  @override
  String get inviteCopyLink => 'نسخ الرابط';

  @override
  String get inviteLinkCopied => 'تم نسخ الرابط';

  @override
  String get inviteShareLink => 'مشاركة الرابط';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'انضم لجروب «$group» على قسمة:\n$link\nأو اكتب الكود: $code';
  }

  @override
  String inviteExpiresIn(String duration) {
    return 'ينتهي بعد $duration';
  }

  @override
  String get inviteExpiresSoon => 'ينتهي خلال أقل من ساعة';

  @override
  String get inviteExpiryChoiceLabel => 'مدة صلاحية الدعوة الجديدة';

  @override
  String get inviteApprovalTitle => 'يحتاج موافقة الأدمن';

  @override
  String get inviteApprovalBody => 'مراجعة العضو الجديد قبل ما يدخل الجروب';

  @override
  String get inviteApprovalTag => 'بموافقة الأدمن';

  @override
  String get inviteCreateNew => 'إنشاء دعوة جديدة';

  @override
  String get inviteCreate => 'إنشاء دعوة';

  @override
  String get inviteCreated => 'تم إنشاء الدعوة';

  @override
  String get inviteRevoke => 'إلغاء الدعوة';

  @override
  String get inviteRevokeConfirmTitle => 'إلغاء الدعوة؟';

  @override
  String get inviteRevokeConfirmBody =>
      'اللي معاه الكود أو الرابط مش هيقدر ينضم بيه تاني. اللي انضموا قبل كده بيفضلوا في الجروب.';

  @override
  String get inviteKeep => 'لأ، سيبها';

  @override
  String get inviteRevoked => 'تم إلغاء الدعوة';

  @override
  String get inviteOtherActiveTitle => 'دعوات تانية شغالة';

  @override
  String get inviteNoActive =>
      'مفيش دعوة شغالة دلوقتي. اعمل واحدة وابعتها لصحابك.';

  @override
  String inviteUsesProgress(String used, String max) {
    return '$used من $max انضموا';
  }

  @override
  String inviteUsesCount(String used) {
    return 'اللي انضموا: $used';
  }

  @override
  String get inviteJoinTitle => 'الانضمام لجروب';

  @override
  String inviteInvitedBy(String name) {
    return 'دعاك $name';
  }

  @override
  String get inviteWhoAreYou => 'إنت مين من الأعضاء؟';

  @override
  String get inviteWhoBody =>
      'لو المنظّم كان ضاف اسمك وسجّل مصاريفك قبل كده، اختار اسمك عشان نربط حسابك بيها من غير تكرار.';

  @override
  String get inviteNewMember => 'أنا عضو جديد (مش في القائمة)';

  @override
  String get inviteNewMemberBody => 'هنضيف اسمك كعضو جديد في الجروب';

  @override
  String get inviteNameLabel => 'اسمك في الجروب';

  @override
  String get inviteJoinButton => 'انضم';

  @override
  String get inviteJoinNote =>
      'بعد الانضمام هتقدر تسجّل المصاريف وتتابع الحسابات مع باقي الأعضاء.';

  @override
  String get inviteNeedsApprovalNote =>
      'الدعوة دي محتاجة موافقة الأدمن قبل ما تدخل الجروب.';

  @override
  String get inviteClaimedNotice =>
      'الاسم ده اتاخد من شخص تاني. اختار اسم تاني أو انضم كعضو جديد.';

  @override
  String get inviteExpiredTitle => 'الدعوة انتهت';

  @override
  String get inviteExpiredBody =>
      'انتهت صلاحية الدعوة دي. اطلب من أدمن الجروب دعوة جديدة.';

  @override
  String get inviteRevokedTitle => 'الدعوة اتلغت';

  @override
  String get inviteRevokedBody =>
      'أدمن الجروب لغى الدعوة دي. اطلب منه دعوة جديدة لو لسه عايز تنضم.';

  @override
  String get inviteNotFoundTitle => 'الدعوة مش موجودة';

  @override
  String get inviteNotFoundBody => 'راجع الكود وجرّب تاني، أو اطلب دعوة جديدة.';

  @override
  String get inviteAlreadyMemberTitle => 'إنت عضو في الجروب ده بالفعل';

  @override
  String get inviteAlreadyMemberBody => 'مش محتاج دعوة. افتح الجروب من هنا.';

  @override
  String get inviteOpenGroup => 'افتح الجروب';

  @override
  String get inviteWaitingTitle => 'في انتظار موافقة الأدمن';

  @override
  String inviteWaitingBody(String group) {
    return 'طلبك للانضمام لجروب «$group» اتبعت. هتدخل أول ما الأدمن يوافق.';
  }

  @override
  String get inviteRefreshStatus => 'تحديث الحالة';

  @override
  String get inviteStillWaiting => 'لسه في انتظار الموافقة';

  @override
  String get inviteBackHome => 'الرجوع للرئيسية';

  @override
  String get inviteEnterCodeButton => 'عندك كود دعوة؟';

  @override
  String get inviteEnterCodeTitle => 'الانضمام بكود';

  @override
  String get inviteEnterCodeBody =>
      'اكتب كود الدعوة اللي وصلك، أو الصق الرابط.';

  @override
  String get inviteCodeFieldLabel => 'كود الدعوة';

  @override
  String get inviteCodeInvalid => 'الكود 8 حروف وأرقام. راجعه وجرّب تاني.';

  @override
  String get inviteContinue => 'متابعة';

  @override
  String get inviteDayOne => 'يوم';

  @override
  String get inviteDayTwo => 'يومين';

  @override
  String inviteDaysFew(String count) {
    return '$count أيام';
  }

  @override
  String inviteDaysMany(String count) {
    return '$count يوم';
  }

  @override
  String get inviteHourOne => 'ساعة';

  @override
  String get inviteHourTwo => 'ساعتين';

  @override
  String inviteHoursFew(String count) {
    return '$count ساعات';
  }

  @override
  String inviteHoursMany(String count) {
    return '$count ساعة';
  }

  @override
  String get membersBadgeConnected => 'متصل بحساب';

  @override
  String get membersBadgeNameOnly => 'اسم فقط';

  @override
  String get membersRoleOwner => 'مالك';

  @override
  String get membersRoleAdmin => 'أدمن';

  @override
  String get membersLeftChip => 'غادر';

  @override
  String get membersActionPromote => 'ترقية لأدمن';

  @override
  String get membersActionPromoteHint =>
      'يقدر يعدل الجروب ويدير الأعضاء والدعوات.';

  @override
  String get membersActionDemote => 'إلغاء الأدمن';

  @override
  String get membersActionDemoteHint => 'يرجع عضو عادي.';

  @override
  String get membersActionUnlink => 'فصل الحساب';

  @override
  String get membersActionUnlinkHint =>
      'يرجع اسم فقط، وفواتيره وسجله بيفضلوا زي ما هم.';

  @override
  String get membersActionMarkLeft => 'عضو غادر';

  @override
  String get membersActionMarkLeftHint =>
      'يفضل في القائمة ورصيده ظاهر، وميتضافش لمصاريف جديدة.';

  @override
  String get membersActionReactivate => 'إعادة التفعيل';

  @override
  String get membersActionReactivateHint => 'يرجع عضو نشط في الجروب.';

  @override
  String get membersActionTransfer => 'نقل الملكية';

  @override
  String get membersActionTransferHint => 'يبقى هو المالك وإنت تبقى أدمن.';

  @override
  String memberUnlinkConfirmTitle(String name) {
    return 'فصل حساب $name؟';
  }

  @override
  String memberUnlinkConfirmBody(String name) {
    return '$name هيرجع اسم فقط ومش هيدخل الجروب تاني. مصاريفه وسجله بيفضلوا زي ما هم، وتقدر تدعوه من جديد.';
  }

  @override
  String get memberUnlinkConfirmAction => 'فصل الحساب';

  @override
  String memberMarkLeftConfirmTitle(String name) {
    return 'تسجيل $name كغادر؟';
  }

  @override
  String memberMarkLeftConfirmBody(String name) {
    return '$name هيفضل في القائمة ورصيده ظاهر، بس مش هيتضاف لمصاريف جديدة.';
  }

  @override
  String get memberMarkLeftConfirmAction => 'تسجيل كغادر';

  @override
  String memberPromoteConfirmTitle(String name) {
    return 'ترقية $name لأدمن؟';
  }

  @override
  String memberPromoteConfirmBody(String name) {
    return '$name هيقدر يعدل الجروب ويدير الأعضاء والدعوات.';
  }

  @override
  String get memberPromoteConfirmAction => 'ترقية';

  @override
  String memberDemoteConfirmTitle(String name) {
    return 'إلغاء الأدمن عن $name؟';
  }

  @override
  String memberDemoteConfirmBody(String name) {
    return '$name هيرجع عضو عادي.';
  }

  @override
  String get memberDemoteConfirmAction => 'إلغاء الأدمن';

  @override
  String memberReactivatedNotice(String name) {
    return 'رجّعنا $name للجروب.';
  }

  @override
  String get membersLeave => 'غادر الجروب';

  @override
  String get groupLeaveConfirmTitle => 'تغادر الجروب؟';

  @override
  String get groupLeaveConfirmBody =>
      'رصيدك بيفضل محفوظ في الجروب ومش هتشوفه تاني. عشان ترجع لازم دعوة جديدة.';

  @override
  String get groupLeaveConfirmAction => 'غادر الجروب';

  @override
  String get groupLeftNotice => 'خرجت من الجروب.';

  @override
  String get membersTransfer => 'نقل الملكية';

  @override
  String get memberTransferPickerTitle => 'نقل الملكية';

  @override
  String get memberTransferPickerSubtitle =>
      'اختار العضو اللي هيبقى المالك. لازم يكون متصل بحساب.';

  @override
  String get memberTransferPickerEmptyTitle => 'مفيش عضو تنقله له';

  @override
  String get memberTransferPickerEmptyBody =>
      'الملكية بتتنقل لعضو نشط ومتصل بحساب. ادعو حد للجروب الأول.';

  @override
  String memberTransferConfirmTitle(String name) {
    return 'نقل الملكية لـ $name؟';
  }

  @override
  String memberTransferConfirmBody(String name) {
    return '$name هيبقى المالك وإنت هتبقى أدمن. مش هتقدر ترجّعها بنفسك.';
  }

  @override
  String get memberTransferConfirmAction => 'نقل الملكية';

  @override
  String get memberTransferDoneNotice => 'الملكية اتنقلت.';

  @override
  String get errorOwnerMustTransferTitle => 'انقل الملكية الأول';

  @override
  String get errorOwnerMustTransferMessage =>
      'المالك مش بيغادر الجروب. انقل الملكية لعضو تاني وبعدين غادر.';

  @override
  String get errorMemberInactive => 'العضو ده غادر الجروب. حدّثنا القائمة.';

  @override
  String inviteRequestsBanner(String count) {
    return 'طلبات انضمام مستنية: $count';
  }

  @override
  String get inviteRequestsTitle => 'طلبات الانضمام';

  @override
  String get inviteRequestsEmptyTitle => 'مفيش طلبات انضمام';

  @override
  String get inviteRequestsEmptyBody =>
      'لما حد يستخدم دعوة محتاجة موافقة، طلبه هيظهر هنا.';

  @override
  String inviteRequestClaims(String name) {
    return 'عايز يبقى: $name';
  }

  @override
  String inviteRequestNewMember(String name) {
    return 'عضو جديد باسم $name';
  }

  @override
  String inviteRequestWhen(String when) {
    return 'اتطلب $when';
  }

  @override
  String get inviteRequestApprove => 'قبول';

  @override
  String get inviteRequestReject => 'رفض';

  @override
  String inviteRequestApproveLabel(String name) {
    return 'قبول طلب $name';
  }

  @override
  String inviteRequestRejectLabel(String name) {
    return 'رفض طلب $name';
  }

  @override
  String get inviteRequestClaimedNotice =>
      'الاسم ده اتربط بحساب تاني. حدّثنا القائمة.';

  @override
  String get inviteRequestDecidedNotice =>
      'حد تاني قرر في الطلب ده بالفعل. حدّثنا القائمة.';

  @override
  String get inviteRequestApprovedNotice => 'اتقبل الطلب.';

  @override
  String get inviteRequestRejectedNotice => 'اترفض الطلب.';

  @override
  String get inviteRequestUnknownName => 'شخص';

  @override
  String get settlementChipPending => 'في انتظار التأكيد';

  @override
  String get settlementChipConfirmed => 'مؤكّد';

  @override
  String get settlementChipDisputed => 'فيه خلاف';

  @override
  String get settlementChipCancelled => 'اتلغت';

  @override
  String get settlementChipUnknown => 'حالة تانية';

  @override
  String settlementChipSpoken(String status) {
    return 'حالة الدفعة: $status';
  }

  @override
  String get settlementByAdmin => 'اتسجّلت بواسطة الأدمن';

  @override
  String get payNoMoveNote =>
      'التطبيق مبيحوّلش فلوس — حوّل من تطبيق البنك أو المحفظة وبعدين اضغط دفعت';

  @override
  String payHandlesTitle(String name) {
    return 'بيانات الدفع لـ $name';
  }

  @override
  String get payInstapayLabel => 'عنوان إنستا باي';

  @override
  String get payWalletLabel => 'محفظة إلكترونية';

  @override
  String get payCopyOne => 'نسخ';

  @override
  String payCopyOneSpoken(String what) {
    return 'انسخ $what';
  }

  @override
  String get payCopyAll => 'نسخ البيانات';

  @override
  String get payCopied => 'اتنسخ';

  @override
  String payNoHandles(String name) {
    return '$name لسه مضافش بيانات دفع. اتفقوا على طريقة التحويل ودوس دفعت بعد ما تحوّل.';
  }

  @override
  String get payButton => 'دفعت';

  @override
  String payButtonSpoken(String amount, String name) {
    return 'دفعت $amount لـ $name';
  }

  @override
  String get payOnBehalf => 'تسجيل بالنيابة';

  @override
  String get payReceived => 'سجّلت إني استلمت';

  @override
  String payTransferTitle(String name) {
    return 'حوّل لـ $name';
  }

  @override
  String get pendingBadge => 'فيه دفعة في انتظار التأكيد';

  @override
  String pendingExplain(String pending, String amount) {
    return 'الأرصدة بتحسب الدفعات المؤكَّدة بس. فيه دفعة $pending في انتظار التأكيد، والمطلوب لسه $amount لحد ما تتأكد.';
  }

  @override
  String get disputeFlag => 'فيه خلاف على دفعة';

  @override
  String get paymentTitleDeclare => 'دفعت';

  @override
  String get paymentTitleReceived => 'استلمت';

  @override
  String get paymentTitleOnBehalf => 'تسجيل بالنيابة';

  @override
  String paymentHintPending(String name) {
    return 'هتتبعت لـ $name عشان يأكّدها. الأرصدة مش هتتغيّر لحد ما يأكّد.';
  }

  @override
  String get paymentHintConfirmed =>
      'هتتسجّل مؤكّدة على طول وهتتحسب في الأرصدة.';

  @override
  String paymentHintNoAccount(String name) {
    return '$name مالوش حساب في التطبيق، فالأدمن هو اللي يسجّل الدفعة دي.';
  }

  @override
  String get paymentHintNotAllowed =>
      'تقدر تسجّل دفعاتك إنت بس. الأدمن هو اللي بيسجّل بالنيابة عن غيره.';

  @override
  String paymentSentPending(String name) {
    return 'اتبعتت لـ $name عشان يأكّدها.';
  }

  @override
  String get incomingBannerOne => 'فيه دفعة مستنياك تأكّدها';

  @override
  String incomingBannerMany(String count) {
    return 'فيه $count دفعات مستنياك تأكّدها';
  }

  @override
  String get incomingTitle => 'دفعات مستنياك';

  @override
  String receiverCardTitle(String name, String amount) {
    return '$name بيقول إنه دفعلك $amount';
  }

  @override
  String get receiverCardBody =>
      'راجع حسابك واتأكد إن الفلوس وصلت قبل ما تأكّد.';

  @override
  String get receiverConfirm => 'استلمت';

  @override
  String receiverConfirmSpoken(String amount, String name) {
    return 'أكّد إنك استلمت $amount من $name';
  }

  @override
  String get receiverDispute => 'لسه مااستلمتش';

  @override
  String receiverDisputeSpoken(String amount, String name) {
    return 'بلّغ إنك لسه مااستلمتش $amount من $name';
  }

  @override
  String get disputeDialogTitle => 'لسه مااستلمتش الفلوس؟';

  @override
  String disputeDialogBody(String name) {
    return 'هنبلّغ $name إنك مااستلمتش. الدفعة مش هتتحسب لحد ما تتأكد أو تتلغي.';
  }

  @override
  String get disputeDialogConfirm => 'أيوه، مااستلمتش';

  @override
  String get cancelDialogTitle => 'تلغي الدفعة دي؟';

  @override
  String get cancelDialogBody =>
      'الدفعة هتتلغي ومش هتتحسب في الأرصدة. هتفضل ظاهرة في السجل بحالة اتلغت.';

  @override
  String get cancelDialogConfirm => 'إلغاء الدفعة';

  @override
  String get cancelDialogKeep => 'لأ، سيبها';

  @override
  String get settlementConfirmedSnack => 'اتأكّدت الدفعة وهتتحسب في الأرصدة.';

  @override
  String get settlementDisputedSnack => 'اتسجّل إنك مااستلمتش الدفعة.';

  @override
  String get settlementCancelledSnack => 'اتلغت الدفعة.';

  @override
  String get settlementStateChanged => 'الدفعة اتغيّرت: دي حالتها دلوقتي.';

  @override
  String get settlementGone => 'الدفعة دي مبقتش موجودة.';

  @override
  String get settlementDetailTitle => 'تفاصيل الدفعة';

  @override
  String get settlementDetailAmount => 'مبلغ الدفعة';

  @override
  String get settlementPayerRole => 'الدافع';

  @override
  String get settlementReceiverRole => 'المستلم';

  @override
  String get stmtPayerPaid => 'بيقول: دفعت';

  @override
  String get stmtPayerCancelled => 'الدفعة اتلغت';

  @override
  String get stmtReceiverWaiting => 'لسه مردّش';

  @override
  String get stmtReceiverNotReceived => 'بيقول: لسه مااستلمتش';

  @override
  String get stmtReceiverConfirmed => 'أكّد إنه استلم';

  @override
  String get stmtRecordedByAdmin => 'اتسجّلت بواسطة الأدمن';

  @override
  String get detailBannerPending => 'في انتظار تأكيد المستلم';

  @override
  String get detailBannerDisputed => 'فيه خلاف على الدفعة دي';

  @override
  String get detailBannerDisputedBody =>
      'في انتظار اتفاق الطرفين أو تدخّل الأدمن';

  @override
  String get detailBannerConfirmed => 'الدفعة اتأكّدت وبتتحسب في الأرصدة';

  @override
  String get detailBannerCancelled => 'الدفعة اتلغت ومش بتتحسب';

  @override
  String get detailNotCounted => 'الدفعة دي مش بتتحسب في الأرصدة لحد ما تتأكد.';

  @override
  String detailDeclaredAt(String when) {
    return 'اتسجّلت: $when';
  }

  @override
  String detailDisputedAt(String when) {
    return 'اتبلّغ بالخلاف: $when';
  }

  @override
  String detailConfirmedAt(String when) {
    return 'اتأكّدت: $when';
  }

  @override
  String detailCancelledAt(String when) {
    return 'اتلغت: $when';
  }

  @override
  String detailDateOn(String date) {
    return 'تاريخ السداد: $date';
  }

  @override
  String get guidanceTitle => 'إرشاد لحل الخلاف وديًا';

  @override
  String get guidanceBody =>
      'الطرفين والأدمن يقدروا يحلّوا الخلاف بعد ما يراجعوا كشف الحساب ورسايل التحويل. التطبيق مبيحكمش ومبيحوّلش فلوس.';

  @override
  String get detailConfirm => 'تأكيد واستلام الدفعة';
}
