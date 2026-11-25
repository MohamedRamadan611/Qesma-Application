import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// App name shown in the task switcher and as the home title.
  ///
  /// In ar, this message translates to:
  /// **'قسمة'**
  String get appTitle;

  /// Placeholder text on the bootstrap home screen (FL0 only).
  ///
  /// In ar, this message translates to:
  /// **'التطبيق جاهز. الشاشات القادمة تُبنى في المراحل التالية.'**
  String get bootstrapReady;

  /// Button: repeat the failed action.
  ///
  /// In ar, this message translates to:
  /// **'حاول تاني'**
  String get commonRetry;

  /// Button: dismiss without doing anything.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get commonCancel;

  /// Button: acknowledge a message.
  ///
  /// In ar, this message translates to:
  /// **'تمام'**
  String get commonOk;

  /// Close button label and screen-reader label for the X icon.
  ///
  /// In ar, this message translates to:
  /// **'إغلاق'**
  String get commonClose;

  /// Screen-reader label of the back arrow.
  ///
  /// In ar, this message translates to:
  /// **'رجوع'**
  String get commonBack;

  /// Button: save.
  ///
  /// In ar, this message translates to:
  /// **'حفظ'**
  String get commonSave;

  /// Button: delete (always a soft delete in this app).
  ///
  /// In ar, this message translates to:
  /// **'امسح'**
  String get commonDelete;

  /// Button: copy text to the clipboard.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get commonCopy;

  /// Confirmation after copying.
  ///
  /// In ar, this message translates to:
  /// **'اتنسخ'**
  String get commonCopied;

  /// Screen-reader label while content or an action is loading.
  ///
  /// In ar, this message translates to:
  /// **'جاري التحميل…'**
  String get commonLoading;

  /// Screen-reader label of the clear button inside a text field.
  ///
  /// In ar, this message translates to:
  /// **'مسح النص'**
  String get fieldClear;

  /// Character counter under a text field, for example 8/60.
  ///
  /// In ar, this message translates to:
  /// **'{count}/{max}'**
  String fieldCounter(String count, String max);

  /// Status word: this person is owed money (positive balance).
  ///
  /// In ar, this message translates to:
  /// **'له'**
  String get balanceOwed;

  /// Status word: this person owes money (negative balance).
  ///
  /// In ar, this message translates to:
  /// **'عليه'**
  String get balanceOwes;

  /// Status word: balance is zero.
  ///
  /// In ar, this message translates to:
  /// **'خالص'**
  String get balanceSettled;

  /// Screen-reader text of an owed chip.
  ///
  /// In ar, this message translates to:
  /// **'له {amount}'**
  String balanceOwedSpoken(String amount);

  /// Screen-reader text of an owes chip.
  ///
  /// In ar, this message translates to:
  /// **'عليه {amount}'**
  String balanceOwesSpoken(String amount);

  /// Screen-reader text of a settled chip.
  ///
  /// In ar, this message translates to:
  /// **'خالص، مفيش حاجة مستحقة'**
  String get balanceSettledSpoken;

  /// Currency suffix shown after every amount (Egyptian pound).
  ///
  /// In ar, this message translates to:
  /// **'ج.م'**
  String get moneyCurrency;

  /// Spoken whole amount.
  ///
  /// In ar, this message translates to:
  /// **'{pounds} جنيه'**
  String moneySpokenPounds(String pounds);

  /// Spoken amount with piasters.
  ///
  /// In ar, this message translates to:
  /// **'{pounds} جنيه و{piasters} قرش'**
  String moneySpokenPoundsPiasters(String pounds, String piasters);

  /// Spoken amount below one pound.
  ///
  /// In ar, this message translates to:
  /// **'{piasters} قرش'**
  String moneySpokenPiasters(String piasters);

  /// Spoken negative amount, for example 'minus 80 pounds'.
  ///
  /// In ar, this message translates to:
  /// **'سالب {amount}'**
  String moneySpokenNegative(String amount);

  /// Title of the generic error state.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ غير متوقع'**
  String get stateErrorTitle;

  /// Body of the generic error state.
  ///
  /// In ar, this message translates to:
  /// **'حاولنا ننفذ طلبك بس حصلت مشكلة. جرّب تاني بعد شوية.'**
  String get stateErrorMessage;

  /// Support code shown on the generic error state (the server request id).
  ///
  /// In ar, this message translates to:
  /// **'رمز الخطأ: {id}'**
  String stateErrorRequestId(String id);

  /// Title of the offline state.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال بالإنترنت'**
  String get stateNoInternetTitle;

  /// Body of the offline state.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق محتاج إنترنت عشان يحفظ ويسجّل المصاريف. اتأكد من الواي فاي أو باقة الموبايل.'**
  String get stateNoInternetMessage;

  /// Reassurance on the offline state. Must stay true: the app is online-only and data lives on the server.
  ///
  /// In ar, this message translates to:
  /// **'اللي سجلته قبل كده محفوظ، وهيظهر أول ما النت يرجع.'**
  String get stateNoInternetReassure;

  /// Short banner shown at the top of a screen while offline.
  ///
  /// In ar, this message translates to:
  /// **'الاتصال مقطوع حاليًا'**
  String get stateOfflineBanner;

  /// Request timed out.
  ///
  /// In ar, this message translates to:
  /// **'الطلب أخد وقت أطول من اللازم. اتأكد من النت وجرّب تاني.'**
  String get errorTimeout;

  /// No network.
  ///
  /// In ar, this message translates to:
  /// **'مفيش اتصال بالإنترنت. اتأكد من النت وجرّب تاني.'**
  String get errorNoConnection;

  /// Fallback for anything unclassified, including IDEMPOTENCY_KEY_REUSED.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ غير متوقع. جرّب تاني بعد شوية.'**
  String get errorUnexpected;

  /// INTERNAL_ERROR and other 5xx.
  ///
  /// In ar, this message translates to:
  /// **'حصل خطأ من عندنا. جرّب تاني بعد شوية.'**
  String get errorInternal;

  /// VALIDATION_ERROR when it cannot be attributed to one field.
  ///
  /// In ar, this message translates to:
  /// **'في بيانات مش مظبوطة. راجع الحقول وجرّب تاني.'**
  String get errorValidation;

  /// PAYERS_TOTAL_MISMATCH.
  ///
  /// In ar, this message translates to:
  /// **'مجموع اللي دفعوه لازم يساوي إجمالي المصروف.'**
  String get errorPayersTotalMismatch;

  /// SPLIT_TOTAL_MISMATCH.
  ///
  /// In ar, this message translates to:
  /// **'مجموع الأنصبة لازم يساوي إجمالي المصروف.'**
  String get errorSplitTotalMismatch;

  /// MEMBER_NOT_IN_GROUP.
  ///
  /// In ar, this message translates to:
  /// **'قائمة الأعضاء اتغيّرت. هنحدّثها وتكمّل من مكانك.'**
  String get errorMemberNotInGroup;

  /// DUPLICATE_MEMBER_NAME, shown inline under the name field.
  ///
  /// In ar, this message translates to:
  /// **'الاسم «{name}» موجود قبل كده في المجموعة. جرّب تضيف اللقب عشان نفرّق بينهم.'**
  String errorDuplicateMemberName(String name);

  /// MEMBER_HAS_TRANSACTIONS dialog title.
  ///
  /// In ar, this message translates to:
  /// **'مينفعش نمسح العضو'**
  String get errorMemberHasTransactionsTitle;

  /// MEMBER_HAS_TRANSACTIONS dialog body.
  ///
  /// In ar, this message translates to:
  /// **'العضو ده مشارك في مصاريف أو تسويات، فمينفعش يتمسح.'**
  String get errorMemberHasTransactionsMessage;

  /// GROUP_NOT_EMPTY dialog title.
  ///
  /// In ar, this message translates to:
  /// **'مينفعش نمسح المجموعة'**
  String get errorGroupNotEmptyTitle;

  /// GROUP_NOT_EMPTY dialog body.
  ///
  /// In ar, this message translates to:
  /// **'المجموعة لسه فيها حسابات مش متسوّية. سوّي كل الحسابات الأول وبعدين امسحها.'**
  String get errorGroupNotEmptyMessage;

  /// OWNER_MEMBER_PROTECTED dialog title.
  ///
  /// In ar, this message translates to:
  /// **'ده حسابك في المجموعة'**
  String get errorOwnerMemberProtectedTitle;

  /// OWNER_MEMBER_PROTECTED dialog body.
  ///
  /// In ar, this message translates to:
  /// **'مينفعش تمسح نفسك من المجموعة، بس تقدر تغيّر اسمك.'**
  String get errorOwnerMemberProtectedMessage;

  /// VERSION_CONFLICT dialog title.
  ///
  /// In ar, this message translates to:
  /// **'اتعدّل من مكان تاني'**
  String get errorVersionConflictTitle;

  /// VERSION_CONFLICT dialog body.
  ///
  /// In ar, this message translates to:
  /// **'حد غيّر البيانات دي من وقت ما فتحتها. هنحمّل آخر نسخة وتقدر تعيد تعديلك.'**
  String get errorVersionConflictMessage;

  /// NOT_FOUND (also what another user's resource looks like).
  ///
  /// In ar, this message translates to:
  /// **'ده مبقاش متاح. ممكن يكون اتمسح.'**
  String get errorNotFound;

  /// UNAUTHORIZED when the refresh also failed.
  ///
  /// In ar, this message translates to:
  /// **'لازم تسجّل الدخول من جديد.'**
  String get errorUnauthorized;

  /// RATE_LIMITED.
  ///
  /// In ar, this message translates to:
  /// **'محاولات كتير في وقت قصير. استنى دقيقة وجرّب تاني.'**
  String get errorRateLimited;

  /// FORBIDDEN: a member whose role lacks the permission (the app then re-reads the group, the role may have changed).
  ///
  /// In ar, this message translates to:
  /// **'صلاحيتك في المجموعة مش بتسمح بالإجراء ده.'**
  String get errorForbidden;

  /// AUTH_PROVIDER_UNAVAILABLE.
  ///
  /// In ar, this message translates to:
  /// **'مش قادرين نتواصل مع جوجل دلوقتي. جرّب تاني بعد شوية.'**
  String get errorAuthProviderUnavailable;

  /// The app name as a wordmark (Arabic with diacritics, as in the logo).
  ///
  /// In ar, this message translates to:
  /// **'قِسْمَة'**
  String get brandWordmark;

  /// Tagline on the splash screen.
  ///
  /// In ar, this message translates to:
  /// **'حسابات السفر والطلعات واللمّة .. صافية وسلسة وبدون إحراج'**
  String get brandTagline;

  /// Headline on the welcome and sign-in screens.
  ///
  /// In ar, this message translates to:
  /// **'احسب مصاريف الشلة والرحلات والسكن من غير لخبطة'**
  String get welcomeTitle;

  /// Welcome value card 1 title.
  ///
  /// In ar, this message translates to:
  /// **'حسابات دقيقة بالقرش'**
  String get welcomeValue1Title;

  /// Welcome value card 1 body.
  ///
  /// In ar, this message translates to:
  /// **'لكل شخص نصيبه الصافي بدون هدر مليم'**
  String get welcomeValue1Body;

  /// Welcome value card 2 title.
  ///
  /// In ar, this message translates to:
  /// **'تقسيم فواتير المطاعم'**
  String get welcomeValue2Title;

  /// Welcome value card 2 body.
  ///
  /// In ar, this message translates to:
  /// **'توزيع تلقائي لنسب الخدمة والضريبة على اللي أكلوا'**
  String get welcomeValue2Body;

  /// Welcome value card 3 title.
  ///
  /// In ar, this message translates to:
  /// **'أسهل طريقة لتصفية الحساب'**
  String get welcomeValue3Title;

  /// Welcome value card 3 body.
  ///
  /// In ar, this message translates to:
  /// **'بنحسب قايمة تحويلات قصيرة وعملية بين الأصحاب'**
  String get welcomeValue3Body;

  /// Primary button on the welcome screen.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ الآن'**
  String get welcomeStart;

  /// Start of the consent line; followed by the terms link.
  ///
  /// In ar, this message translates to:
  /// **'بتسجيلك أنت توافق على'**
  String get legalConsentPrefix;

  /// Link text: terms of use.
  ///
  /// In ar, this message translates to:
  /// **'شروط الاستخدام'**
  String get legalTerms;

  /// The word between the two legal links.
  ///
  /// In ar, this message translates to:
  /// **'و'**
  String get legalAnd;

  /// Link text: privacy policy.
  ///
  /// In ar, this message translates to:
  /// **'سياسة الخصوصية'**
  String get legalPrivacy;

  /// Snackbar when a legal link cannot be opened.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نفتح الرابط دلوقتي. جرّب تاني بعد شوية.'**
  String get legalOpenFailed;

  /// Google sign-in button. 'Google' stays in Latin script (brand name).
  ///
  /// In ar, this message translates to:
  /// **'المتابعة باستخدام Google'**
  String get signInWithGoogle;

  /// Sign-in failed (rejected token or unknown failure).
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نسجّل دخولك. جرّب تاني.'**
  String get signInFailed;

  /// Developer-facing message in debug builds when the Google client id is missing.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول بجوجل مش متظبط على الجهاز ده (GOOGLE_SERVER_CLIENT_ID).'**
  String get signInNotConfigured;

  /// Debug builds only: sign in with the backend's fake-auth token.
  ///
  /// In ar, this message translates to:
  /// **'دخول تجريبي (للتطوير فقط)'**
  String get devFakeSignIn;

  /// Session-expired dialog title.
  ///
  /// In ar, this message translates to:
  /// **'انتهت الجلسة'**
  String get sessionExpiredTitle;

  /// Session-expired dialog body.
  ///
  /// In ar, this message translates to:
  /// **'سجّل دخولك تاني عشان تكمل بأمان وتحمي حساباتك ومصاريفك المشتركة.'**
  String get sessionExpiredBody;

  /// Reassurance (true: everything is stored on the server).
  ///
  /// In ar, this message translates to:
  /// **'بياناتك ومجموعاتك محفوظة بالكامل ولم تتأثر'**
  String get sessionExpiredReassure;

  /// Secondary action in the session-expired dialog: go to the welcome screen.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع للبداية'**
  String get sessionExpiredLeave;

  /// Placeholder home screen: who is signed in.
  ///
  /// In ar, this message translates to:
  /// **'مسجّل دخول باسم {name}'**
  String homeSignedInAs(String name);

  /// Sign-out button.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الخروج'**
  String get homeSignOut;

  /// Title of the groups list screen.
  ///
  /// In ar, this message translates to:
  /// **'المجموعات'**
  String get groupsTitle;

  /// Floating button: create a group.
  ///
  /// In ar, this message translates to:
  /// **'جروب جديد'**
  String get groupsNew;

  /// Screen-reader label of the overflow menu on the groups list (temporary menu holding sign out until the profile screen exists).
  ///
  /// In ar, this message translates to:
  /// **'المزيد'**
  String get groupsMore;

  /// Empty groups list: title.
  ///
  /// In ar, this message translates to:
  /// **'مفيش جروبات لسه'**
  String get groupsEmptyTitle;

  /// Empty groups list: body.
  ///
  /// In ar, this message translates to:
  /// **'ابدأ بجروب جديد وضيف أصحابك، وإحنا نحسبها.'**
  String get groupsEmptyBody;

  /// Archive screen title and the row in the Account tab.
  ///
  /// In ar, this message translates to:
  /// **'الأرشيف'**
  String get archiveTitle;

  /// Button in Edit group and confirm label.
  ///
  /// In ar, this message translates to:
  /// **'أرشفة الجروب'**
  String get archiveAction;

  /// Confirm dialog title.
  ///
  /// In ar, this message translates to:
  /// **'تأرشف الجروب ده؟'**
  String get archiveConfirmTitle;

  /// Confirm dialog body; days is the retention period.
  ///
  /// In ar, this message translates to:
  /// **'«{name}» هيختفي من قايمة جروباتك وهيتمسح نهائيًا بكل مصاريفه ومدفوعاته بعد {days} يوم. تقدر ترجّعه قبل كده.'**
  String archiveConfirmBody(Object days, Object name);

  /// Snackbar after archiving.
  ///
  /// In ar, this message translates to:
  /// **'الجروب اتأرشف.'**
  String get archiveDone;

  /// Dialog title when the group is not settled.
  ///
  /// In ar, this message translates to:
  /// **'لسه مينفعش نأرشفه'**
  String get archiveBlockedTitle;

  /// Dialog body when the group is not settled.
  ///
  /// In ar, this message translates to:
  /// **'سوّي كل الحسابات وفرّغ الصندوق الأول، وبعدين تقدر تأرشف الجروب.'**
  String get archiveBlocked;

  /// Label of the retention dropdown.
  ///
  /// In ar, this message translates to:
  /// **'مسح الجروبات المؤرشفة بعد'**
  String get archiveRetentionLabel;

  /// Retention option.
  ///
  /// In ar, this message translates to:
  /// **'7 أيام'**
  String get archiveRetention7;

  /// Retention option.
  ///
  /// In ar, this message translates to:
  /// **'15 يوم'**
  String get archiveRetention15;

  /// Retention option (30 days).
  ///
  /// In ar, this message translates to:
  /// **'شهر'**
  String get archiveRetention30;

  /// Explains the retention period.
  ///
  /// In ar, this message translates to:
  /// **'الجروب المؤرشف بيختفي من قايمتك. بعد المدة دي بيتمسح نهائيًا بكل مصاريفه. وقبلها تقدر ترجّعه.'**
  String get archiveRetentionHint;

  /// Empty archive title.
  ///
  /// In ar, this message translates to:
  /// **'مفيش جروبات مؤرشفة'**
  String get archiveEmptyTitle;

  /// Empty archive body.
  ///
  /// In ar, this message translates to:
  /// **'الجروبات اللي بتأرشفها بعد ما تسوّي الحسابات هتظهر هنا.'**
  String get archiveEmptyBody;

  /// Archived group row.
  ///
  /// In ar, this message translates to:
  /// **'اتأرشف في {date}'**
  String archiveArchivedOn(Object date);

  /// Archived group row: when it is deleted.
  ///
  /// In ar, this message translates to:
  /// **'هيتمسح نهائيًا في {date}'**
  String archiveDeletesOn(Object date);

  /// Restore an archived group.
  ///
  /// In ar, this message translates to:
  /// **'استرجاع'**
  String get archiveRestore;

  /// Delete an archived group at once.
  ///
  /// In ar, this message translates to:
  /// **'مسح دلوقتي'**
  String get archiveDeleteNow;

  /// Snackbar after restore.
  ///
  /// In ar, this message translates to:
  /// **'الجروب رجع.'**
  String get archiveRestored;

  /// Snackbar after delete.
  ///
  /// In ar, this message translates to:
  /// **'الجروب اتمسح.'**
  String get archiveDeleted;

  /// Title of the summary card on the Groups screen.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي كل جروباتك'**
  String get summaryAllGroups;

  /// Title of the summary card on a group home.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي مصاريف الجروب'**
  String get summaryGroupTotal;

  /// Chip on the Groups summary card: how many groups.
  ///
  /// In ar, this message translates to:
  /// **'{n} جروبات'**
  String summaryGroupsCount(Object n);

  /// Label above the owed/owe chip on the summary card.
  ///
  /// In ar, this message translates to:
  /// **'موقفك'**
  String get summaryYourPosition;

  /// Label above the settlement status on the summary card.
  ///
  /// In ar, this message translates to:
  /// **'حالة التسوية'**
  String get summaryStatus;

  /// Summary status when nothing is owed.
  ///
  /// In ar, this message translates to:
  /// **'الكل متسوّي'**
  String get summaryAllSettled;

  /// Summary status of a group where the caller still owes or is owed.
  ///
  /// In ar, this message translates to:
  /// **'جاري الجمع'**
  String get summaryOpen;

  /// Summary status on the Groups screen: groups with open balances.
  ///
  /// In ar, this message translates to:
  /// **'{n} جروب مفتوح'**
  String summaryOpenGroups(Object n);

  /// Header card on the groups list: the user's net across all groups (shown only when all groups use one currency).
  ///
  /// In ar, this message translates to:
  /// **'صافي رصيدك في كل الجروبات'**
  String get groupsNetTotal;

  /// Snackbar when pull-to-refresh failed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحدّث القايمة. جرّب تاني.'**
  String get groupsRefreshFailed;

  /// Snackbar when loading the next page failed.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نحمّل باقي الجروبات. اسحب لتحت وجرّب تاني.'**
  String get groupsLoadMoreFailed;

  /// Group type: trip.
  ///
  /// In ar, this message translates to:
  /// **'رحلة'**
  String get groupTypeTrip;

  /// Group type: shared housing.
  ///
  /// In ar, this message translates to:
  /// **'سكن'**
  String get groupTypeHousing;

  /// Group type: outing.
  ///
  /// In ar, this message translates to:
  /// **'خروجة'**
  String get groupTypeOuting;

  /// Group type: other.
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get groupTypeOther;

  /// Group card: date of the last expense.
  ///
  /// In ar, this message translates to:
  /// **'آخر نشاط: {date}'**
  String groupLastActivity(String date);

  /// Group card: the group has no expenses yet.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش مصاريف'**
  String get groupNoActivity;

  /// Label before the group's total spent.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المصاريف'**
  String get groupTotalSpent;

  /// Number of members (2 or more). Count is a string with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} أعضاء'**
  String groupMemberCount(String count);

  /// Number of members when there is exactly one.
  ///
  /// In ar, this message translates to:
  /// **'عضو واحد'**
  String get groupMemberOne;

  /// Screen-reader sentence for a whole group card.
  ///
  /// In ar, this message translates to:
  /// **'{name}، {type}، {members}، إجمالي المصاريف {total}، {balance}'**
  String groupCardSpoken(
    String name,
    String type,
    String members,
    String total,
    String balance,
  );

  /// Shown when a group no longer exists.
  ///
  /// In ar, this message translates to:
  /// **'الجروب ده مبقاش متاح.'**
  String get groupOpenFailedGone;

  /// Button: go back to the groups list.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع للمجموعات'**
  String get groupBackToList;

  /// Create group screen title.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء جروب جديد'**
  String get groupCreateTitle;

  /// Create group screen subtitle.
  ///
  /// In ar, this message translates to:
  /// **'رحلة أو سكن أو خروجة. ابدأ بالاسم والنوع.'**
  String get groupCreateSubtitle;

  /// Field label: group name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الجروب'**
  String get groupNameLabel;

  /// Field hint: group name example.
  ///
  /// In ar, this message translates to:
  /// **'مثال: رحلة دهب'**
  String get groupNameHint;

  /// Label above the group type chips.
  ///
  /// In ar, this message translates to:
  /// **'نوع الجروب'**
  String get groupTypeLabel;

  /// Label above the fixed currency.
  ///
  /// In ar, this message translates to:
  /// **'العملة'**
  String get groupCurrencyLabel;

  /// The only currency in Phase 1.
  ///
  /// In ar, this message translates to:
  /// **'جنيه مصري (ج.م)'**
  String get groupCurrencyValue;

  /// Optional switch on the create-group screen.
  ///
  /// In ar, this message translates to:
  /// **'إضافة أمين صندوق'**
  String get groupPoolToggle;

  /// Hint under the pool switch.
  ///
  /// In ar, this message translates to:
  /// **'واحد بيمسك كاش الجروب.'**
  String get groupPoolToggleHint;

  /// Label above the treasurer choice.
  ///
  /// In ar, this message translates to:
  /// **'مين اللي هيمسك الفلوس؟'**
  String get groupPoolWho;

  /// The creator as treasurer option.
  ///
  /// In ar, this message translates to:
  /// **'أنا'**
  String get groupPoolMe;

  /// A199: label above the none / pool / budget radio group on the create-group screen.
  ///
  /// In ar, this message translates to:
  /// **'تتبّع فلوس الجروب'**
  String get groupMoneyModeLabel;

  /// A199: radio option, neither a pool nor a budget.
  ///
  /// In ar, this message translates to:
  /// **'من غير إضافات'**
  String get groupMoneyModeNone;

  /// A199: hint under the 'nothing extra' option.
  ///
  /// In ar, this message translates to:
  /// **'تسجّلوا مين دفع ومين عليه بس.'**
  String get groupMoneyModeNoneHint;

  /// A199: radio option on the create-group screen.
  ///
  /// In ar, this message translates to:
  /// **'تحديد ميزانية للرحلة'**
  String get groupBudgetToggle;

  /// A199: hint under the budget option.
  ///
  /// In ar, this message translates to:
  /// **'تابعوا صرفكم مقارنة بحد معيّن.'**
  String get groupBudgetToggleHint;

  /// A199: one-line rule under the radio group.
  ///
  /// In ar, this message translates to:
  /// **'الجروب يا صندوق يا ميزانية، مش الاتنين. والصندوق مينفعش يتضاف بعدين.'**
  String get groupMoneyModeLocked;

  /// A199: snackbar when the budget could not be saved right after creating the group.
  ///
  /// In ar, this message translates to:
  /// **'الجروب اتعمل بس الميزانية ماتحفظتش. حدّدوها من إعدادات الجروب.'**
  String get groupBudgetSetFailed;

  /// Snackbar when the treasurer could not be set right after creating the group.
  ///
  /// In ar, this message translates to:
  /// **'الجروب اتعمل بس أمين الصندوق ماتحددش. حدده من إعدادات الجروب.'**
  String get groupPoolSetFailed;

  /// Note under the currency: it cannot change later.
  ///
  /// In ar, this message translates to:
  /// **'العملة ثابتة بعد إنشاء الجروب'**
  String get groupCurrencyNote;

  /// Primary button on the create screen.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الجروب'**
  String get groupCreateButton;

  /// Shown after a create attempt whose result is unknown (lost response): the next tap checks the list before creating again.
  ///
  /// In ar, this message translates to:
  /// **'مش متأكدين إن الجروب اتعمل. هنتأكد الأول قبل ما نحاول تاني، عشان ميتكررش.'**
  String get groupCreateOutcomeUnknown;

  /// Section title on the create-group screen.
  ///
  /// In ar, this message translates to:
  /// **'أعضاء الجروب (اختياري)'**
  String get groupMembersLabel;

  /// Note under the optional members section.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تتخطى الخطوة دي وتضيف الأعضاء بعدين من تبويب الأعضاء. إنت متضاف تلقائي.'**
  String get groupMembersNote;

  /// Hint of the member name field in create group.
  ///
  /// In ar, this message translates to:
  /// **'اسم العضو'**
  String get groupMembersNameHint;

  /// Label of the optional member-name field on create group.
  ///
  /// In ar, this message translates to:
  /// **'اسم العضو داخل الجروب (اختياري)'**
  String get groupMemberNameOptional;

  /// Adds the typed name to the list of members to create.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get groupMembersAddButton;

  /// Inline error for a repeated member name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم ده مضاف بالفعل'**
  String get groupMembersDuplicate;

  /// Semantics label of the remove button on a member chip.
  ///
  /// In ar, this message translates to:
  /// **'إزالة {name}'**
  String groupMembersRemove(String name);

  /// Snackbar after the group was created but some members could not be added.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, one{عضو واحد ما اتضافش} two{عضوين ما اتضافوش} few{{count} أعضاء ما اتضافوش} many{{count} عضو ما اتضافوش} other{{count} عضو ما اتضافوش}}. ضيفهم من تبويب الأعضاء.'**
  String groupMembersPartialFail(int count);

  /// Edit group screen title and the tooltip of the edit button.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الجروب'**
  String get groupEditTitle;

  /// Edit screen: when the group was created.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ الإنشاء: {date}'**
  String groupCreatedOn(String date);

  /// Primary button on the edit screen.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get groupSaveChanges;

  /// Destructive button on the edit screen.
  ///
  /// In ar, this message translates to:
  /// **'امسح الجروب'**
  String get groupDelete;

  /// Delete group confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'مسح الجروب؟'**
  String get groupDeleteConfirmTitle;

  /// Delete group confirmation body.
  ///
  /// In ar, this message translates to:
  /// **'هيتمسح «{name}» بكل مصاريفه ومدفوعاته نهائيًا ومش هينفع ترجّعه.'**
  String groupDeleteConfirmBody(String name);

  /// Blocked delete dialog: the recorded total.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المصاريف المسجلة: {amount}'**
  String groupBlockedTotal(String amount);

  /// Blocked delete dialog: what to do.
  ///
  /// In ar, this message translates to:
  /// **'سوّي الحسابات الأول، وبعدها اتواصل مع الدعم لو لسه عايز تمسحه.'**
  String get groupBlockedHint;

  /// Conflict dialog: reload the latest version (the user's typed changes stay in the form).
  ///
  /// In ar, this message translates to:
  /// **'حمّل آخر نسخة'**
  String get groupConflictReload;

  /// Conflict dialog: close and keep editing.
  ///
  /// In ar, this message translates to:
  /// **'كمّل بتعديلي'**
  String get groupConflictKeep;

  /// Group tab: expenses.
  ///
  /// In ar, this message translates to:
  /// **'المصاريف'**
  String get groupTabExpenses;

  /// Group tab: balances.
  ///
  /// In ar, this message translates to:
  /// **'الأرصدة'**
  String get groupTabBalances;

  /// Group tab: members.
  ///
  /// In ar, this message translates to:
  /// **'الأعضاء'**
  String get groupTabMembers;

  /// Group screen subtitle: member count and total spent.
  ///
  /// In ar, this message translates to:
  /// **'{members} • {total}'**
  String groupHeaderSubtitle(String members, String total);

  /// Button: add a member.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عضو'**
  String get membersAdd;

  /// Badge next to the user's own member.
  ///
  /// In ar, this message translates to:
  /// **'(أنت)'**
  String get membersYouTag;

  /// Screen-reader label of a member's options button.
  ///
  /// In ar, this message translates to:
  /// **'خيارات {name}'**
  String membersOptions(String name);

  /// Member option: rename.
  ///
  /// In ar, this message translates to:
  /// **'تغيير الاسم'**
  String get membersRename;

  /// Member option: delete.
  ///
  /// In ar, this message translates to:
  /// **'مسح العضو'**
  String get membersDelete;

  /// Add member sheet title.
  ///
  /// In ar, this message translates to:
  /// **'إضافة عضو جديد'**
  String get memberAddTitle;

  /// Add member sheet subtitle.
  ///
  /// In ar, this message translates to:
  /// **'أضف اسم الصديق ليتمكن المنظم من توزيع المصاريف عليه بسهولة.'**
  String get memberAddSubtitle;

  /// Field label: member name.
  ///
  /// In ar, this message translates to:
  /// **'اسم العضو داخل الجروب'**
  String get memberNameLabel;

  /// Primary button of the add and rename sheets.
  ///
  /// In ar, this message translates to:
  /// **'حفظ العضو'**
  String get memberSave;

  /// Rename member sheet title.
  ///
  /// In ar, this message translates to:
  /// **'تغيير اسم العضو'**
  String get memberRenameTitle;

  /// Delete member confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'مسح العضو؟'**
  String get memberDeleteConfirmTitle;

  /// Delete member confirmation body.
  ///
  /// In ar, this message translates to:
  /// **'هيتشال «{name}» من الجروب.'**
  String memberDeleteConfirmBody(String name);

  /// Expenses tab empty state title (the group has no expenses).
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش مصاريف'**
  String get expensesEmptyTitle;

  /// Expenses tab empty state body.
  ///
  /// In ar, this message translates to:
  /// **'ضيف أول مصروف وقسّمه على الشلة.'**
  String get expensesEmptyBody;

  /// Button and floating button: add an expense.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مصروف'**
  String get expensesAdd;

  /// Filtered list is empty.
  ///
  /// In ar, this message translates to:
  /// **'مفيش مصاريف مطابقة'**
  String get expensesNoMatchTitle;

  /// Filtered list is empty: body.
  ///
  /// In ar, this message translates to:
  /// **'جرّب تغيّر الفلاتر أو امسحها.'**
  String get expensesNoMatchBody;

  /// Button that removes every filter.
  ///
  /// In ar, this message translates to:
  /// **'امسح الفلاتر'**
  String get expensesClearFilters;

  /// Snackbar when the next page fails.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحمّل باقي المصاريف.'**
  String get expensesLoadMoreFailed;

  /// Snackbar when pull to refresh fails.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحدّث المصاريف. المعروض هو آخر نسخة عندنا.'**
  String get expensesRefreshFailed;

  /// Filter chip: date range.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get expenseFilterDate;

  /// Filter chip: member.
  ///
  /// In ar, this message translates to:
  /// **'العضو'**
  String get expenseFilterMember;

  /// Filter chip value when no filter is set.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get expenseFilterAll;

  /// Filter chip value: date range.
  ///
  /// In ar, this message translates to:
  /// **'من {from} لحد {to}'**
  String expenseFilterRange(String from, String to);

  /// Filter chip value: only a start date.
  ///
  /// In ar, this message translates to:
  /// **'من {from}'**
  String expenseFilterFrom(String from);

  /// Filter chip value: only an end date.
  ///
  /// In ar, this message translates to:
  /// **'لحد {to}'**
  String expenseFilterUntil(String to);

  /// Screen-reader label of a removable filter chip.
  ///
  /// In ar, this message translates to:
  /// **'شيل الفلتر: {label}'**
  String expenseFilterRemove(String label);

  /// Date filter sheet title.
  ///
  /// In ar, this message translates to:
  /// **'فلتر التاريخ'**
  String get expenseFilterDateTitle;

  /// Date filter: start date button label.
  ///
  /// In ar, this message translates to:
  /// **'من تاريخ'**
  String get expenseFilterFromLabel;

  /// Date filter: end date button label.
  ///
  /// In ar, this message translates to:
  /// **'لحد تاريخ'**
  String get expenseFilterToLabel;

  /// Date filter: shown before a date is picked.
  ///
  /// In ar, this message translates to:
  /// **'اختار التاريخ'**
  String get expenseFilterPickDate;

  /// Filter sheet: apply.
  ///
  /// In ar, this message translates to:
  /// **'تطبيق'**
  String get expenseFilterApply;

  /// Filter sheet: clear this filter.
  ///
  /// In ar, this message translates to:
  /// **'مسح'**
  String get expenseFilterClear;

  /// Date filter: backwards range.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ البداية لازم يكون قبل تاريخ النهاية.'**
  String get expenseFilterRangeInvalid;

  /// Member filter sheet title.
  ///
  /// In ar, this message translates to:
  /// **'فلتر العضو'**
  String get expenseFilterMemberTitle;

  /// Member filter sheet subtitle.
  ///
  /// In ar, this message translates to:
  /// **'بنعرض المصاريف اللي العضو ده دفع فيها أو شارك فيها.'**
  String get expenseFilterMemberHint;

  /// Member filter: no member selected.
  ///
  /// In ar, this message translates to:
  /// **'كل الأعضاء'**
  String get expenseFilterAllMembers;

  /// Date header of the list: today. Date is yyyy-mm-dd.
  ///
  /// In ar, this message translates to:
  /// **'النهارده — {date}'**
  String expenseDayToday(String date);

  /// Date header of the list: yesterday.
  ///
  /// In ar, this message translates to:
  /// **'إمبارح — {date}'**
  String expenseDayYesterday(String date);

  /// Who paid, on an expense row.
  ///
  /// In ar, this message translates to:
  /// **'دفع: {payers}'**
  String expensePaidBy(String payers);

  /// One payer with the amount they paid, when several people paid.
  ///
  /// In ar, this message translates to:
  /// **'{name} ({amount})'**
  String expensePayerAmount(String name, String amount);

  /// Separator between names in a list.
  ///
  /// In ar, this message translates to:
  /// **'، '**
  String get expenseListSeparator;

  /// Name shown when a member id is not in the group.
  ///
  /// In ar, this message translates to:
  /// **'عضو'**
  String get expenseUnknownMember;

  /// Participant count when it is one.
  ///
  /// In ar, this message translates to:
  /// **'على فرد واحد'**
  String get expenseSplitAmongOne;

  /// Participant count (2 or more). Count is a string with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'مقسومة على {count} أفراد'**
  String expenseSplitAmong(String count);

  /// Your share of an expense.
  ///
  /// In ar, this message translates to:
  /// **'نصيبك: {amount}'**
  String expenseYourShare(String amount);

  /// Screen-reader label of an expense row.
  ///
  /// In ar, this message translates to:
  /// **'{title}، {total}، {split}، {payers}، {participants}'**
  String expenseCardSpoken(
    String title,
    String total,
    String split,
    String payers,
    String participants,
  );

  /// Screen-reader label of an expense row that has your share.
  ///
  /// In ar, this message translates to:
  /// **'{title}، {total}، {split}، {payers}، {participants}، {share}'**
  String expenseCardSpokenWithShare(
    String title,
    String total,
    String split,
    String payers,
    String participants,
    String share,
  );

  /// Split type chip: equal.
  ///
  /// In ar, this message translates to:
  /// **'بالتساوي'**
  String get expenseSplitEqual;

  /// Split type chip: exact amounts.
  ///
  /// In ar, this message translates to:
  /// **'مبالغ محددة'**
  String get expenseSplitExact;

  /// Split type chip: itemized.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة مفصلة'**
  String get expenseSplitItemized;

  /// Split type chip: SHARES (weighted units, optionally by days present; BSA3).
  ///
  /// In ar, this message translates to:
  /// **'بالحصص'**
  String get expenseSplitShares;

  /// Title of the expense details screen.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل المصروف'**
  String get expenseDetailsTitle;

  /// Label above the expense total.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المصروف'**
  String get expenseDetailsTotal;

  /// Badge on an expense that was edited. Version is a string.
  ///
  /// In ar, this message translates to:
  /// **'معدّل (النسخة {version})'**
  String expenseEditedBadge(String version);

  /// Details: payers block title.
  ///
  /// In ar, this message translates to:
  /// **'الدافعون'**
  String get expensePayersTitle;

  /// Details: payers count of one.
  ///
  /// In ar, this message translates to:
  /// **'دافع واحد'**
  String get expensePayersCountOne;

  /// Details: payers count (2 or more).
  ///
  /// In ar, this message translates to:
  /// **'{count} دافعين'**
  String expensePayersCount(String count);

  /// Details: the payers added up.
  ///
  /// In ar, this message translates to:
  /// **'مجموع المدفوع: {amount}'**
  String expensePaidTotal(String amount);

  /// Details: items block title.
  ///
  /// In ar, this message translates to:
  /// **'الأصناف والإضافات'**
  String get expenseItemsTitle;

  /// Details: items count of one.
  ///
  /// In ar, this message translates to:
  /// **'صنف واحد'**
  String get expenseItemsCountOne;

  /// Details: items count (2 or more).
  ///
  /// In ar, this message translates to:
  /// **'{count} أصناف'**
  String expenseItemsCount(String count);

  /// Details: subtotal row.
  ///
  /// In ar, this message translates to:
  /// **'مجموع الأصناف'**
  String get expenseSubtotal;

  /// Details: service row.
  ///
  /// In ar, this message translates to:
  /// **'رسوم الخدمة'**
  String get expenseServiceLabel;

  /// Details: tax row.
  ///
  /// In ar, this message translates to:
  /// **'الضريبة'**
  String get expenseTaxLabel;

  /// Details: tax base is the subtotal.
  ///
  /// In ar, this message translates to:
  /// **'على مجموع الأصناف'**
  String get expenseTaxBaseSubtotal;

  /// Details: tax base is subtotal plus service.
  ///
  /// In ar, this message translates to:
  /// **'على الأصناف + الخدمة'**
  String get expenseTaxBaseSubtotalPlusService;

  /// Details: adjustment row.
  ///
  /// In ar, this message translates to:
  /// **'تسوية'**
  String get expenseAdjustmentLabel;

  /// Details: total row of the charges block.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الفاتورة'**
  String get expenseBillTotal;

  /// A percentage rate, Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{rate}%'**
  String expensePercent(String rate);

  /// Details: per-person block title.
  ///
  /// In ar, this message translates to:
  /// **'نصيب كل فرد'**
  String get expenseBreakdownTitle;

  /// Details: per-person count of one.
  ///
  /// In ar, this message translates to:
  /// **'فرد واحد'**
  String get expenseBreakdownCountOne;

  /// Details: per-person count (2 or more).
  ///
  /// In ar, this message translates to:
  /// **'{count} أفراد'**
  String expenseBreakdownCount(String count);

  /// Under a person's share on the details page: the names of the items they take part in.
  ///
  /// In ar, this message translates to:
  /// **'الأصناف: {names}'**
  String expensePersonItemsList(String names);

  /// Share breakdown part: items.
  ///
  /// In ar, this message translates to:
  /// **'أصناف {amount}'**
  String expensePartItems(String amount);

  /// Share breakdown part: service.
  ///
  /// In ar, this message translates to:
  /// **'خدمة {amount}'**
  String expensePartService(String amount);

  /// Share breakdown part: tax.
  ///
  /// In ar, this message translates to:
  /// **'ضريبة {amount}'**
  String expensePartTax(String amount);

  /// Share breakdown part: adjustment.
  ///
  /// In ar, this message translates to:
  /// **'تسوية {amount}'**
  String expensePartAdjustment(String amount);

  /// Details: edit button.
  ///
  /// In ar, this message translates to:
  /// **'تعديل المصروف'**
  String get expenseEdit;

  /// Details: edit button of an itemized bill.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الفاتورة والأصناف'**
  String get expenseEditItemized;

  /// Details: delete button.
  ///
  /// In ar, this message translates to:
  /// **'حذف المصروف'**
  String get expenseDelete;

  /// Details: history button and sheet title.
  ///
  /// In ar, this message translates to:
  /// **'سجل التعديلات'**
  String get expenseHistory;

  /// Delete expense confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'تحذف المصروف ده؟'**
  String get expenseDeleteConfirmTitle;

  /// Delete expense confirmation body.
  ///
  /// In ar, this message translates to:
  /// **'هيتشال «{title}» من المصاريف والأرصدة.'**
  String expenseDeleteConfirmBody(String title);

  /// Snackbar after a delete.
  ///
  /// In ar, this message translates to:
  /// **'اتحذف المصروف.'**
  String get expenseDeleted;

  /// Snackbar when a delete finds the expense already gone.
  ///
  /// In ar, this message translates to:
  /// **'المصروف ده كان اتحذف خلاص.'**
  String get expenseAlreadyDeleted;

  /// Details: the expense does not exist any more.
  ///
  /// In ar, this message translates to:
  /// **'المصروف ده مبقاش موجود'**
  String get expenseGoneTitle;

  /// Button back to the expenses list.
  ///
  /// In ar, this message translates to:
  /// **'رجوع للمصاريف'**
  String get expenseBackToList;

  /// History row: version number.
  ///
  /// In ar, this message translates to:
  /// **'النسخة {version}'**
  String expenseHistoryVersion(String version);

  /// History row: change type create.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء'**
  String get expenseChangeCreate;

  /// History row: change type update.
  ///
  /// In ar, this message translates to:
  /// **'تعديل'**
  String get expenseChangeUpdate;

  /// History row: change type delete.
  ///
  /// In ar, this message translates to:
  /// **'حذف'**
  String get expenseChangeDelete;

  /// History row: total of that version.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي: {amount}'**
  String expenseHistoryTotal(String amount);

  /// Dialog title when deleting hits a version conflict.
  ///
  /// In ar, this message translates to:
  /// **'المصروف اتعدّل'**
  String get expenseConflictTitle;

  /// Dialog body when deleting an expense hits a version conflict.
  ///
  /// In ar, this message translates to:
  /// **'حد عدّل المصروف ده من آخر مرة فتحته. حمّل آخر نسخة وراجعها قبل ما تحذفه.'**
  String get expenseConflictBody;

  /// Screen-reader action that refreshes the expenses list (the alternative to pull to refresh).
  ///
  /// In ar, this message translates to:
  /// **'تحديث القائمة'**
  String get expensesRefresh;

  /// History sheet: the server has no revisions for this expense.
  ///
  /// In ar, this message translates to:
  /// **'مفيش سجل تعديلات للمصروف ده.'**
  String get expenseHistoryEmpty;

  /// Screen-reader label of the people an item is assigned to.
  ///
  /// In ar, this message translates to:
  /// **'على: {names}'**
  String expenseAssignedTo(String names);

  /// Spoken split type when the app does not know the type.
  ///
  /// In ar, this message translates to:
  /// **'تقسيم'**
  String get expenseSplitUnknown;

  /// Participant count of exactly two (Arabic dual).
  ///
  /// In ar, this message translates to:
  /// **'مقسومة على فردين'**
  String get expenseSplitAmongTwo;

  /// Participant count of 11 or more (Arabic singular accusative).
  ///
  /// In ar, this message translates to:
  /// **'مقسومة على {count} فردًا'**
  String expenseSplitAmongMany(String count);

  /// Details: payers count of exactly two.
  ///
  /// In ar, this message translates to:
  /// **'دافعين'**
  String get expensePayersCountTwo;

  /// Details: payers count of 11 or more.
  ///
  /// In ar, this message translates to:
  /// **'{count} دافعًا'**
  String expensePayersCountMany(String count);

  /// Details: items count of exactly two.
  ///
  /// In ar, this message translates to:
  /// **'صنفين'**
  String get expenseItemsCountTwo;

  /// Details: items count of 11 or more.
  ///
  /// In ar, this message translates to:
  /// **'{count} صنفًا'**
  String expenseItemsCountMany(String count);

  /// Details: per-person count of exactly two.
  ///
  /// In ar, this message translates to:
  /// **'فردين'**
  String get expenseBreakdownCountTwo;

  /// Details: per-person count of 11 or more.
  ///
  /// In ar, this message translates to:
  /// **'{count} فردًا'**
  String expenseBreakdownCountMany(String count);

  /// Add/edit expense: title field label.
  ///
  /// In ar, this message translates to:
  /// **'اسم المصروف'**
  String get expenseFormTitleLabel;

  /// Add/edit expense: title field hint.
  ///
  /// In ar, this message translates to:
  /// **'مثلاً: عشا، بنزين، تذاكر'**
  String get expenseFormTitleHint;

  /// Add/edit expense: the title is empty.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم للمصروف.'**
  String get expenseFormTitleRequired;

  /// Add/edit expense: amount field label.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ الإجمالي'**
  String get expenseFormAmountLabel;

  /// Add/edit expense: amount field hint (Western digits).
  ///
  /// In ar, this message translates to:
  /// **'مثلاً 250 أو 99.50'**
  String get expenseFormAmountHint;

  /// Add/edit expense: the amount cannot be read.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مبلغ صحيح أكبر من صفر.'**
  String get expenseFormAmountInvalid;

  /// Add/edit expense: the fixed currency.
  ///
  /// In ar, this message translates to:
  /// **'العملة: جنيه مصري (ج.م)'**
  String get expenseFormCurrencyNote;

  /// Add/edit expense: date button label.
  ///
  /// In ar, this message translates to:
  /// **'التاريخ'**
  String get expenseFormDateLabel;

  /// Add/edit expense: paid-by section title.
  ///
  /// In ar, this message translates to:
  /// **'مين اللي دفع؟'**
  String get expenseFormPaidByTitle;

  /// Add/edit expense: opens the payers sheet.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الدافعين'**
  String get expenseFormEditPayers;

  /// Add/edit expense: the payers no longer add up to the total.
  ///
  /// In ar, this message translates to:
  /// **'مجموع اللي دفعوه مش مطابق للإجمالي. عدّل الدافعين.'**
  String get expenseFormPayersMismatch;

  /// Add/edit expense: split section title.
  ///
  /// In ar, this message translates to:
  /// **'طريقة التقسيم'**
  String get expenseFormSplitTitle;

  /// Split tab: equal among all members.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get expenseFormSplitAll;

  /// Split tab: equal among the selected members.
  ///
  /// In ar, this message translates to:
  /// **'محددين'**
  String get expenseFormSplitSelected;

  /// Screen-reader label of a member row with their share.
  ///
  /// In ar, this message translates to:
  /// **'{name}، نصيبه {amount}'**
  String expenseFormMemberSpoken(String name, String amount);

  /// Screen-reader label of an unchecked member row.
  ///
  /// In ar, this message translates to:
  /// **'{name}، مش مشارك'**
  String expenseFormMemberUnchecked(String name);

  /// Shown instead of the amounts while the server calculates them.
  ///
  /// In ar, this message translates to:
  /// **'بنحسب الأنصبة…'**
  String get expenseFormShareLoading;

  /// The preview failed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحسب الأنصبة.'**
  String get expenseFormShareFailed;

  /// Shown while the total is not valid yet.
  ///
  /// In ar, this message translates to:
  /// **'اكتب المبلغ الإجمالي عشان تظهر الأنصبة.'**
  String get expenseFormShareNeedAmount;

  /// Exact tab: hint under the list.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تعدّل حصة كل عضو بإيدك، أو توزّع بالتساوي من جديد.'**
  String get expenseFormExactHint;

  /// Screen-reader label of the amount box of a member in Exact mode.
  ///
  /// In ar, this message translates to:
  /// **'نصيب {name}'**
  String expenseFormExactAmountLabel(String name);

  /// Exact tab: ask the server for the equal split again.
  ///
  /// In ar, this message translates to:
  /// **'وزّع بالتساوي'**
  String get expenseFormSpreadEqually;

  /// Exact tab: what was typed against the total.
  ///
  /// In ar, this message translates to:
  /// **'مجموع التقسيم: {sum} من {total}'**
  String expenseFormExactSummary(String sum, String total);

  /// Exact tab: part of the total not yet given to anyone.
  ///
  /// In ar, this message translates to:
  /// **'لسه باقي {amount}'**
  String expenseFormExactRemaining(String amount);

  /// Exact tab: the typed amounts exceed the total.
  ///
  /// In ar, this message translates to:
  /// **'زيادة {amount} عن الإجمالي'**
  String expenseFormExactOver(String amount);

  /// Exact tab: the typed amounts equal the total.
  ///
  /// In ar, this message translates to:
  /// **'مطابق للإجمالي'**
  String get expenseFormExactMatches;

  /// Add/edit expense: save button (add).
  ///
  /// In ar, this message translates to:
  /// **'حفظ المصروف'**
  String get expenseFormSave;

  /// Add/edit expense: save button (edit).
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get expenseFormSaveChanges;

  /// Discard dialog title.
  ///
  /// In ar, this message translates to:
  /// **'تخرج من غير ما تحفظ؟'**
  String get expenseFormLeaveTitle;

  /// Discard dialog body.
  ///
  /// In ar, this message translates to:
  /// **'اللي كتبته هيضيع.'**
  String get expenseFormLeaveBody;

  /// Discard dialog: leave.
  ///
  /// In ar, this message translates to:
  /// **'اخرج'**
  String get expenseFormLeaveConfirm;

  /// Discard dialog: stay.
  ///
  /// In ar, this message translates to:
  /// **'كمّل كتابة'**
  String get expenseFormLeaveKeep;

  /// Edit conflict dialog title.
  ///
  /// In ar, this message translates to:
  /// **'المصروف اتعدّل'**
  String get expenseFormConflictTitle;

  /// Edit conflict dialog body.
  ///
  /// In ar, this message translates to:
  /// **'حد عدّل المصروف ده من آخر مرة فتحته. حمّل آخر نسخة، اللي كتبته هيفضل زي ما هو، وبعدين احفظ تاني.'**
  String get expenseFormConflictBody;

  /// Banner after the latest version was loaded following a conflict.
  ///
  /// In ar, this message translates to:
  /// **'حد عدّل المصروف ده. تعديلاتك لسه موجودة، والحفظ هيبدّل نسخته.'**
  String get expenseFormConflictNote;

  /// Button after a failed save (same request, no duplicate).
  ///
  /// In ar, this message translates to:
  /// **'احفظ تاني'**
  String get expenseFormSaveRetry;

  /// Message after a save whose reply was lost.
  ///
  /// In ar, this message translates to:
  /// **'مش متأكدين إن المصروف اتحفظ. لو حفظت تاني مش هيتكرر.'**
  String get expenseFormOutcomeUnknown;

  /// Payers sheet title.
  ///
  /// In ar, this message translates to:
  /// **'مين دفع الفاتورة؟'**
  String get expensePayersSheetTitle;

  /// Payers sheet subtitle.
  ///
  /// In ar, this message translates to:
  /// **'حدد الأعضاء اللي دفعوا والمبلغ اللي دفعه كل واحد.'**
  String get expensePayersSheetSubtitle;

  /// Payers sheet: the total.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الفاتورة المستحق'**
  String get expensePayersTotalLabel;

  /// Payers sheet: the total is not valid yet.
  ///
  /// In ar, this message translates to:
  /// **'اكتب المبلغ الإجمالي الأول.'**
  String get expensePayersNeedTotal;

  /// Payers sheet: part of the total nobody has paid yet.
  ///
  /// In ar, this message translates to:
  /// **'المتبقي للتوزيع: {amount}'**
  String expensePayersRemaining(String amount);

  /// Payers sheet: the amounts exceed the total.
  ///
  /// In ar, this message translates to:
  /// **'زيادة {amount} عن الفاتورة'**
  String expensePayersOver(String amount);

  /// Payers sheet: typed amounts equal the total and the server agrees.
  ///
  /// In ar, this message translates to:
  /// **'المجموع مظبوط ومطابق للفاتورة'**
  String get expensePayersMatched;

  /// Payers sheet: waiting for the server to confirm the match.
  ///
  /// In ar, this message translates to:
  /// **'بنراجع المجموع مع الخادم…'**
  String get expensePayersChecking;

  /// Payers sheet: the server disagrees with the typed sum.
  ///
  /// In ar, this message translates to:
  /// **'الخادم شايف إن المجموع مش مطابق. راجع المبالغ.'**
  String get expensePayersServerMismatch;

  /// Payers sheet: ask the server for the equal split among the selected payers.
  ///
  /// In ar, this message translates to:
  /// **'قسّم بالتساوي على الدافعين'**
  String get expensePayersSplitEqually;

  /// Payers sheet: empty every amount.
  ///
  /// In ar, this message translates to:
  /// **'امسح المبالغ'**
  String get expensePayersClear;

  /// Payers sheet: the typed amounts added up.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المبالغ المدخلة'**
  String get expensePayersEntered;

  /// Payers sheet: confirm button.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد الدافعين ({amount})'**
  String expensePayersConfirm(String amount);

  /// Screen-reader label of a payer’s amount box.
  ///
  /// In ar, this message translates to:
  /// **'اللي دفعه {name}'**
  String expensePayersAmountLabel(String name);

  /// Screen-reader label of a payer row with an amount.
  ///
  /// In ar, this message translates to:
  /// **'{name}، دفع {amount}'**
  String expensePayersRowSpoken(String name, String amount);

  /// Screen-reader label of an unchecked payer row.
  ///
  /// In ar, this message translates to:
  /// **'{name}، لم يدفع'**
  String expensePayersRowUnchecked(String name);

  /// Payers sheet: the equal split could not be calculated.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحسب التقسيم بالتساوي. جرّب تاني.'**
  String get expensePayersFailed;

  /// Snackbar after the expense was saved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظ المصروف.'**
  String get expenseFormSaved;

  /// Restaurant bill: note under the total (it is not typed).
  ///
  /// In ar, this message translates to:
  /// **'بيتحسب من الأصناف والخدمة والضريبة.'**
  String get expenseItemizedTotalNote;

  /// Restaurant bill: items section title.
  ///
  /// In ar, this message translates to:
  /// **'أصناف الفاتورة'**
  String get expenseItemizedItemsTitle;

  /// Restaurant bill: heading of one item card.
  ///
  /// In ar, this message translates to:
  /// **'الصنف {n}'**
  String expenseItemizedItemHeading(String n);

  /// Restaurant bill: item name field label.
  ///
  /// In ar, this message translates to:
  /// **'اسم الصنف'**
  String get expenseItemizedNameLabel;

  /// Restaurant bill: item name hint.
  ///
  /// In ar, this message translates to:
  /// **'مثلاً: بيتزا'**
  String get expenseItemizedNameHint;

  /// Restaurant bill: the item name is empty.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسم الصنف.'**
  String get expenseItemizedNameRequired;

  /// Restaurant bill: item price field label.
  ///
  /// In ar, this message translates to:
  /// **'سعر الصنف'**
  String get expenseItemizedAmountLabel;

  /// Restaurant bill: the item price cannot be read.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سعر صحيح أكبر من صفر.'**
  String get expenseItemizedAmountInvalid;

  /// Restaurant bill: label above the assignee chips.
  ///
  /// In ar, this message translates to:
  /// **'مين شارك في الصنف ده؟'**
  String get expenseItemizedAssigneesLabel;

  /// Restaurant bill: an item without an assignee.
  ///
  /// In ar, this message translates to:
  /// **'اختار عضو واحد على الأقل.'**
  String get expenseItemizedNoAssignee;

  /// Restaurant bill: add an item button.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صنف جديد'**
  String get expenseItemizedAdd;

  /// Restaurant bill: no more items can be added.
  ///
  /// In ar, this message translates to:
  /// **'وصلت للحد الأقصى: 100 صنف.'**
  String get expenseItemizedLimit;

  /// Restaurant bill: remove an item (tooltip).
  ///
  /// In ar, this message translates to:
  /// **'امسح الصنف'**
  String get expenseItemizedRemove;

  /// Restaurant bill: screen-reader label of an item’s remove button.
  ///
  /// In ar, this message translates to:
  /// **'امسح الصنف {n}'**
  String expenseItemizedRemoveSpoken(String n);

  /// Restaurant bill: service and tax section title.
  ///
  /// In ar, this message translates to:
  /// **'الخدمة والضريبة'**
  String get expenseItemizedChargesTitle;

  /// Restaurant bill: percentage field label.
  ///
  /// In ar, this message translates to:
  /// **'النسبة (%)'**
  String get expenseItemizedPercentLabel;

  /// Restaurant bill: percentage field hint.
  ///
  /// In ar, this message translates to:
  /// **'مثلاً 12'**
  String get expenseItemizedPercentHint;

  /// Restaurant bill: the percentage cannot be read.
  ///
  /// In ar, this message translates to:
  /// **'اكتب نسبة من 0 لـ 100، بحد أقصى رقمين بعد العلامة.'**
  String get expenseItemizedPercentInvalid;

  /// Restaurant bill: tax base chips title.
  ///
  /// In ar, this message translates to:
  /// **'الضريبة بتتحسب على'**
  String get expenseItemizedTaxBaseTitle;

  /// Restaurant bill: tax base chip, the subtotal.
  ///
  /// In ar, this message translates to:
  /// **'المجموع فقط'**
  String get expenseItemizedTaxBaseSubtotal;

  /// Restaurant bill: tax base chip, the subtotal plus service.
  ///
  /// In ar, this message translates to:
  /// **'المجموع + الخدمة'**
  String get expenseItemizedTaxBaseWithService;

  /// Restaurant bill: adjustment section title.
  ///
  /// In ar, this message translates to:
  /// **'فرق التقريب / إكرامية'**
  String get expenseItemizedAdjustmentTitle;

  /// Restaurant bill: adjustment helper text.
  ///
  /// In ar, this message translates to:
  /// **'لتسوية الكسور أو البقشيش. ممكن يكون بالسالب.'**
  String get expenseItemizedAdjustmentHint;

  /// Restaurant bill: the adjustment cannot be read.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مبلغ صحيح (ممكن يكون بالسالب).'**
  String get expenseItemizedAdjustmentInvalid;

  /// Restaurant bill: increase the adjustment by 0.01 (screen-reader label).
  ///
  /// In ar, this message translates to:
  /// **'زوّد قرش'**
  String get expenseItemizedAdjustmentPlus;

  /// Restaurant bill: decrease the adjustment by 0.01 (screen-reader label).
  ///
  /// In ar, this message translates to:
  /// **'نقّص قرش'**
  String get expenseItemizedAdjustmentMinus;

  /// Restaurant bill: shown instead of the numbers while the server calculates.
  ///
  /// In ar, this message translates to:
  /// **'بنحسب الفاتورة…'**
  String get expenseItemizedLoading;

  /// Restaurant bill: the preview failed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحسب الفاتورة.'**
  String get expenseItemizedFailed;

  /// Restaurant bill: the bill is not complete enough to calculate.
  ///
  /// In ar, this message translates to:
  /// **'كمّل الأصناف والنسب عشان تظهر الحسابات.'**
  String get expenseItemizedIncomplete;

  /// Restaurant bill: the server says the payers cover the total.
  ///
  /// In ar, this message translates to:
  /// **'الدافعين مطابقين للفاتورة'**
  String get expenseItemizedPayersMatch;

  /// Restaurant bill: the server says the payers do not cover the total.
  ///
  /// In ar, this message translates to:
  /// **'الدافعين مش مطابقين للفاتورة. عدّل الدافعين.'**
  String get expenseItemizedPayersMismatch;

  /// Restaurant bill: waiting for the server to confirm the payers.
  ///
  /// In ar, this message translates to:
  /// **'بنراجع الدافعين…'**
  String get expenseItemizedPayersChecking;

  /// Restaurant bill: label of the total next to the save button.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الفاتورة المحسوب'**
  String get expenseItemizedBarTotal;

  /// Payers sheet: a restaurant bill whose total is not known yet.
  ///
  /// In ar, this message translates to:
  /// **'كمّل أصناف الفاتورة الأول.'**
  String get expensePayersNeedItems;

  /// Balances tab: label above the total spent.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي مصاريف الجروب'**
  String get balancesTotalSpent;

  /// Balances status when exactly one transfer is suggested.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب تحويل واحد لإنهاء الحسابات'**
  String get balancesNeedOne;

  /// Balances status for exactly two transfers (Arabic dual).
  ///
  /// In ar, this message translates to:
  /// **'مطلوب تحويلين لإنهاء الحسابات'**
  String get balancesNeedTwo;

  /// Balances status for 3 to 10 transfers. Count is a string with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب {count} تحويلات لإنهاء الحسابات'**
  String balancesNeed(String count);

  /// Balances status for 11 or more transfers.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب {count} تحويلًا لإنهاء الحسابات'**
  String balancesNeedMany(String count);

  /// Balances tab: no transfers are needed.
  ///
  /// In ar, this message translates to:
  /// **'الحسابات متصفّية'**
  String get balancesAllSettledTitle;

  /// Balances tab: explanation under the all-settled title.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حد عليه فلوس لحد دلوقتي.'**
  String get balancesAllSettledBody;

  /// Section title of the suggested transfers.
  ///
  /// In ar, this message translates to:
  /// **'تحويلات مقترحة'**
  String get balancesSuggestedTitle;

  /// Transfer row: the one who pays.
  ///
  /// In ar, this message translates to:
  /// **'يدفع'**
  String get balancesPays;

  /// Transfer row: the one who receives.
  ///
  /// In ar, this message translates to:
  /// **'يستلم'**
  String get balancesReceives;

  /// Screen-reader text of a suggested transfer.
  ///
  /// In ar, this message translates to:
  /// **'{from} يدفع {amount} لـ {to}'**
  String balancesTransferSpoken(String from, String to, String amount);

  /// Button and sheet title: record a payment.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل سداد'**
  String get balancesRecordPayment;

  /// Screen-reader label of the Record payment button on a transfer.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل سداد من {from} إلى {to}، {amount}'**
  String balancesRecordPaymentSpoken(String from, String to, String amount);

  /// Button: record a payment that is not one of the suggestions.
  ///
  /// In ar, this message translates to:
  /// **'سجّل سداد تاني'**
  String get balancesRecordAnother;

  /// Section title of the per-member balances.
  ///
  /// In ar, this message translates to:
  /// **'صافي رصيد كل عضو'**
  String get balancesNetsTitle;

  /// Screen-reader text of a member balance row.
  ///
  /// In ar, this message translates to:
  /// **'{name}، {status}'**
  String balancesMemberSpoken(String name, String status);

  /// Section title of the settlement history.
  ///
  /// In ar, this message translates to:
  /// **'سجل السداد'**
  String get balancesHistoryTitle;

  /// Payment history when it is empty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش سداد متسجّل.'**
  String get balancesHistoryEmpty;

  /// History row title.
  ///
  /// In ar, this message translates to:
  /// **'{from} سدد لـ {to}'**
  String balancesPaymentTitle(String from, String to);

  /// Screen-reader text of a history row.
  ///
  /// In ar, this message translates to:
  /// **'{from} سدد {amount} لـ {to}، {date}'**
  String balancesPaymentSpoken(
    String from,
    String to,
    String amount,
    String date,
  );

  /// History row text with its note appended.
  ///
  /// In ar, this message translates to:
  /// **'{base}، {note}'**
  String balancesPaymentNoteSpoken(String base, String note);

  /// Button under the history: next page.
  ///
  /// In ar, this message translates to:
  /// **'حمّل المزيد'**
  String get balancesLoadMore;

  /// History: the next page failed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحمّل باقي السداد.'**
  String get balancesLoadMoreFailed;

  /// Screen-reader action that refreshes the tab.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الأرصدة'**
  String get balancesRefresh;

  /// Snackbar when a refresh fails.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحدّث الأرصدة. المعروض هو آخر نسخة عندنا.'**
  String get balancesRefreshFailed;

  /// Record payment sheet subtitle.
  ///
  /// In ar, this message translates to:
  /// **'تسوية الحسابات بين أعضاء الجروب'**
  String get paymentSubtitle;

  /// Record payment: who paid.
  ///
  /// In ar, this message translates to:
  /// **'من (الدافع)'**
  String get paymentFrom;

  /// Record payment: who received.
  ///
  /// In ar, this message translates to:
  /// **'إلى (المستلم)'**
  String get paymentTo;

  /// Title of the member picker.
  ///
  /// In ar, this message translates to:
  /// **'اختار عضو'**
  String get paymentPickMember;

  /// Record payment: amount field label.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ المسدد (ج.م)'**
  String get paymentAmountLabel;

  /// Record payment: amount error.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مبلغ صحيح أكبر من صفر، لحد خانتين عشرية.'**
  String get paymentAmountError;

  /// Chip that puts the suggested transfer amount back.
  ///
  /// In ar, this message translates to:
  /// **'كامل المبلغ: {amount}'**
  String paymentFullAmount(String amount);

  /// Record payment: date field label.
  ///
  /// In ar, this message translates to:
  /// **'تاريخ السداد'**
  String get paymentDateLabel;

  /// Record payment: date error.
  ///
  /// In ar, this message translates to:
  /// **'اختار تاريخ بين 2000 و2100.'**
  String get paymentDateError;

  /// Record payment: note field label.
  ///
  /// In ar, this message translates to:
  /// **'ملاحظة (اختياري)'**
  String get paymentNoteLabel;

  /// Record payment: note hint.
  ///
  /// In ar, this message translates to:
  /// **'مثلًا: كاش في الرحلة'**
  String get paymentNoteHint;

  /// Record payment: note error.
  ///
  /// In ar, this message translates to:
  /// **'الملاحظة أطول من 200 حرف.'**
  String get paymentNoteError;

  /// Record payment: from and to are the same.
  ///
  /// In ar, this message translates to:
  /// **'اختار عضوين مختلفين.'**
  String get paymentSameMember;

  /// Record payment: confirm button with the typed amount.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد تسجيل السداد ({amount})'**
  String paymentConfirm(String amount);

  /// Record payment: confirm button while the amount is not valid.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد تسجيل السداد'**
  String get paymentConfirmNoAmount;

  /// Snackbar after a payment was recorded.
  ///
  /// In ar, this message translates to:
  /// **'اتسجّل السداد.'**
  String get paymentRecorded;

  /// Question when closing the sheet with changes.
  ///
  /// In ar, this message translates to:
  /// **'تتجاهل السداد ده؟'**
  String get paymentDiscardTitle;

  /// Body of the discard question.
  ///
  /// In ar, this message translates to:
  /// **'اللي كتبته مش هيتحفظ.'**
  String get paymentDiscardBody;

  /// Confirm button of the discard question.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get paymentDiscardConfirm;

  /// Title of the Account tab (profile hub).
  ///
  /// In ar, this message translates to:
  /// **'حسابي'**
  String get profileTitle;

  /// Button on the profile hub.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get profileEdit;

  /// Group count on the hub when it is one.
  ///
  /// In ar, this message translates to:
  /// **'مجموعة واحدة'**
  String get profileGroupsOne;

  /// Group count on the hub when it is two (Arabic dual).
  ///
  /// In ar, this message translates to:
  /// **'مجموعتين'**
  String get profileGroupsTwo;

  /// Group count 3 to 10. Count is a string with Western digits.
  ///
  /// In ar, this message translates to:
  /// **'{count} مجموعات'**
  String profileGroups(String count);

  /// Group count 11 or more.
  ///
  /// In ar, this message translates to:
  /// **'{count} مجموعة'**
  String profileGroupsMany(String count);

  /// Hub section title.
  ///
  /// In ar, this message translates to:
  /// **'التفضيلات'**
  String get profileSectionPrefs;

  /// Hub section title.
  ///
  /// In ar, this message translates to:
  /// **'عن التطبيق'**
  String get profileSectionAbout;

  /// Hub row: language.
  ///
  /// In ar, this message translates to:
  /// **'لغة التطبيق'**
  String get profileLanguage;

  /// Language name (shown in its own language).
  ///
  /// In ar, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// Language name (shown in its own language).
  ///
  /// In ar, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Title of the language sheet.
  ///
  /// In ar, this message translates to:
  /// **'اختار اللغة'**
  String get languageSheetTitle;

  /// Hub row: opens the account settings page.
  ///
  /// In ar, this message translates to:
  /// **'إعدادات الحساب'**
  String get profileAccountSettings;

  /// Hub row: version.
  ///
  /// In ar, this message translates to:
  /// **'إصدار التطبيق'**
  String get profileVersion;

  /// Sign-out confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'تسجّل خروج؟'**
  String get profileSignOutTitle;

  /// Sign-out confirmation body.
  ///
  /// In ar, this message translates to:
  /// **'هتحتاج تسجّل دخول بجوجل تاني عشان ترجع.'**
  String get profileSignOutBody;

  /// Edit profile screen title.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الملف الشخصي'**
  String get profileEditTitle;

  /// Edit profile: name label.
  ///
  /// In ar, this message translates to:
  /// **'الاسم'**
  String get profileNameLabel;

  /// Edit profile: helper under the name.
  ///
  /// In ar, this message translates to:
  /// **'الاسم ده هيظهر لأصحابك في المجموعات والمصاريف.'**
  String get profileNameHint;

  /// Edit profile: name is empty.
  ///
  /// In ar, this message translates to:
  /// **'اكتب اسمك عشان أصحابك يعرفوك.'**
  String get profileNameRequired;

  /// Edit profile: name too long.
  ///
  /// In ar, this message translates to:
  /// **'الاسم أطول من 60 حرف.'**
  String get profileNameTooLong;

  /// Edit profile: email label.
  ///
  /// In ar, this message translates to:
  /// **'البريد الإلكتروني'**
  String get profileEmailLabel;

  /// Edit profile: why the email is read only.
  ///
  /// In ar, this message translates to:
  /// **'مرتبط بحساب جوجل ومش بيتعدّل يدويًا.'**
  String get profileEmailLocked;

  /// Edit profile: save button.
  ///
  /// In ar, this message translates to:
  /// **'حفظ التعديلات'**
  String get profileSave;

  /// Snackbar after the name was saved.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظ الاسم.'**
  String get profileSaved;

  /// Question when leaving edit profile with changes.
  ///
  /// In ar, this message translates to:
  /// **'تتجاهل التعديلات؟'**
  String get profileDiscardTitle;

  /// Body of the discard question.
  ///
  /// In ar, this message translates to:
  /// **'الاسم الجديد مش هيتحفظ.'**
  String get profileDiscardBody;

  /// Confirm of the discard question.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get profileDiscardConfirm;

  /// Account settings and hub: the Google account.
  ///
  /// In ar, this message translates to:
  /// **'حساب جوجل المرتبط'**
  String get accountGoogleTitle;

  /// Tag: the Google account is connected.
  ///
  /// In ar, this message translates to:
  /// **'متصل'**
  String get accountConnected;

  /// Hub row: light or dark appearance.
  ///
  /// In ar, this message translates to:
  /// **'المظهر'**
  String get profileAppearance;

  /// Title of the appearance sheet.
  ///
  /// In ar, this message translates to:
  /// **'اختار المظهر'**
  String get appearanceSheetTitle;

  /// Appearance: follow the phone setting (default).
  ///
  /// In ar, this message translates to:
  /// **'زي الموبايل'**
  String get appearanceSystem;

  /// Appearance: light.
  ///
  /// In ar, this message translates to:
  /// **'فاتح'**
  String get appearanceLight;

  /// Appearance: dark.
  ///
  /// In ar, this message translates to:
  /// **'داكن'**
  String get appearanceDark;

  /// Button on the sign-in screen: sign in with email and password.
  ///
  /// In ar, this message translates to:
  /// **'المتابعة باسم المستخدم'**
  String get authUsernameContinue;

  /// Title of the email sign-in screen.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل الدخول باسم المستخدم'**
  String get authUsernameSignInTitle;

  /// Button: sign in with email and password.
  ///
  /// In ar, this message translates to:
  /// **'دخول'**
  String get authUsernameSignInButton;

  /// Title of the registration screen.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء حساب'**
  String get authRegisterTitle;

  /// Button: register with email and password.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء الحساب'**
  String get authRegisterButton;

  /// Link from sign-in to registration.
  ///
  /// In ar, this message translates to:
  /// **'معندكش حساب؟ أنشئ حساب جديد'**
  String get authGoRegister;

  /// Link from registration to sign-in.
  ///
  /// In ar, this message translates to:
  /// **'عندك حساب؟ سجّل دخول'**
  String get authGoSignIn;

  /// Field label: email address.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم'**
  String get fieldUsername;

  /// Field label: password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر'**
  String get fieldPassword;

  /// Button: show the password text.
  ///
  /// In ar, this message translates to:
  /// **'إظهار كلمة السر'**
  String get fieldPasswordShow;

  /// Button: hide the password text.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء كلمة السر'**
  String get fieldPasswordHide;

  /// Registration: display name label.
  ///
  /// In ar, this message translates to:
  /// **'الاسم (اختياري)'**
  String get fieldDisplayNameOptional;

  /// Helper under the new-password field.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر 8 حروف على الأقل، ومش من الكلمات الشائعة.'**
  String get authPasswordRules;

  /// Email field error.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم من 3 لـ 30 حرف: حروف وأرقام ونقطة وشرطة، من غير مسافات أو @.'**
  String get authErrorUsernameInvalid;

  /// Password too short.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر لازم تكون 8 حروف على الأقل.'**
  String get authErrorPasswordShort;

  /// Password too long.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر طويلة قوي. الحد الأقصى 72 بايت (حوالي 36 حرف عربي).'**
  String get authErrorPasswordLong;

  /// Email sign-in refused (wrong credentials, locked account, or no password account: never says which).
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم أو كلمة السر مش صح. جرّب تاني.'**
  String get authErrorWrongCredentials;

  /// Registration refused: the address is taken.
  ///
  /// In ar, this message translates to:
  /// **'اسم المستخدم ده مأخوذ. اختار اسم تاني أو سجّل دخول.'**
  String get authErrorUsernameTaken;

  /// The server refused the password.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر دي مش مقبولة. اختار كلمة أقوى وأقل شيوعًا.'**
  String get authErrorPasswordRejected;

  /// Hub row: change the password.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة السر'**
  String get profileChangePassword;

  /// Title of the change-password screen.
  ///
  /// In ar, this message translates to:
  /// **'تغيير كلمة السر'**
  String get passwordChangeTitle;

  /// Change password: current password field.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر الحالية'**
  String get passwordCurrentLabel;

  /// Change password: new password field.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر الجديدة'**
  String get passwordNewLabel;

  /// Change password: save button.
  ///
  /// In ar, this message translates to:
  /// **'حفظ كلمة السر'**
  String get passwordChangeButton;

  /// Snackbar after a password change.
  ///
  /// In ar, this message translates to:
  /// **'اتغيرت كلمة السر. باقي الأجهزة اتسجّل خروجها.'**
  String get passwordChanged;

  /// Change password: the current password was refused.
  ///
  /// In ar, this message translates to:
  /// **'كلمة السر الحالية مش صح، أو الجديدة مش مقبولة (شائعة قوي).'**
  String get passwordCurrentWrong;

  /// Account settings: the sign-in method is email.
  ///
  /// In ar, this message translates to:
  /// **'مسجّل دخول باسم المستخدم وكلمة السر'**
  String get accountSignedInWithPassword;

  /// Group menu and members tab: opens the invite sheet.
  ///
  /// In ar, this message translates to:
  /// **'دعوة أعضاء'**
  String get inviteAction;

  /// Invite sheet title.
  ///
  /// In ar, this message translates to:
  /// **'دعوة أعضاء للجروب'**
  String get inviteSheetTitle;

  /// Invite sheet subtitle with the group name.
  ///
  /// In ar, this message translates to:
  /// **'جروب «{group}»'**
  String inviteSheetSubtitle(String group);

  /// Invite sheet intro.
  ///
  /// In ar, this message translates to:
  /// **'شارك الكود أو الرابط مع صحابك عشان يشوفوا الحسابات ويضيفوا مصاريفهم أول بأول.'**
  String get inviteSheetIntro;

  /// Label above the big code.
  ///
  /// In ar, this message translates to:
  /// **'كود الانضمام'**
  String get inviteCodeLabel;

  /// Button.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الكود'**
  String get inviteCopyCode;

  /// Snackbar after copying the code.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الكود'**
  String get inviteCodeCopied;

  /// Tooltip of the copy button next to the link.
  ///
  /// In ar, this message translates to:
  /// **'نسخ الرابط'**
  String get inviteCopyLink;

  /// Snackbar after copying the link.
  ///
  /// In ar, this message translates to:
  /// **'تم نسخ الرابط'**
  String get inviteLinkCopied;

  /// Opens the system share sheet.
  ///
  /// In ar, this message translates to:
  /// **'مشاركة الرابط'**
  String get inviteShareLink;

  /// Text sent through the share sheet.
  ///
  /// In ar, this message translates to:
  /// **'انضم لجروب «{group}» على قسمة:\n{link}\nأو اكتب الكود: {code}'**
  String inviteShareText(String group, String link, String code);

  /// Expiry text computed from the server expiry time.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي بعد {duration}'**
  String inviteExpiresIn(String duration);

  /// Expiry text.
  ///
  /// In ar, this message translates to:
  /// **'ينتهي خلال أقل من ساعة'**
  String get inviteExpiresSoon;

  /// Label above the 1/7/30 day chips.
  ///
  /// In ar, this message translates to:
  /// **'مدة صلاحية الدعوة الجديدة'**
  String get inviteExpiryChoiceLabel;

  /// Toggle title.
  ///
  /// In ar, this message translates to:
  /// **'يحتاج موافقة الأدمن'**
  String get inviteApprovalTitle;

  /// Toggle description.
  ///
  /// In ar, this message translates to:
  /// **'مراجعة العضو الجديد قبل ما يدخل الجروب'**
  String get inviteApprovalBody;

  /// Small tag on an invite that needs approval.
  ///
  /// In ar, this message translates to:
  /// **'بموافقة الأدمن'**
  String get inviteApprovalTag;

  /// Section title of the settings.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء دعوة جديدة'**
  String get inviteCreateNew;

  /// Button.
  ///
  /// In ar, this message translates to:
  /// **'إنشاء دعوة'**
  String get inviteCreate;

  /// Snackbar.
  ///
  /// In ar, this message translates to:
  /// **'تم إنشاء الدعوة'**
  String get inviteCreated;

  /// Text button and confirm label.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الدعوة'**
  String get inviteRevoke;

  /// Dialog title.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الدعوة؟'**
  String get inviteRevokeConfirmTitle;

  /// Dialog body.
  ///
  /// In ar, this message translates to:
  /// **'اللي معاه الكود أو الرابط مش هيقدر ينضم بيه تاني. اللي انضموا قبل كده بيفضلوا في الجروب.'**
  String get inviteRevokeConfirmBody;

  /// Dialog button that does nothing.
  ///
  /// In ar, this message translates to:
  /// **'لأ، سيبها'**
  String get inviteKeep;

  /// Snackbar.
  ///
  /// In ar, this message translates to:
  /// **'تم إلغاء الدعوة'**
  String get inviteRevoked;

  /// List title.
  ///
  /// In ar, this message translates to:
  /// **'دعوات تانية شغالة'**
  String get inviteOtherActiveTitle;

  /// Empty state of the invite sheet.
  ///
  /// In ar, this message translates to:
  /// **'مفيش دعوة شغالة دلوقتي. اعمل واحدة وابعتها لصحابك.'**
  String get inviteNoActive;

  /// Use count of an invite with a limit.
  ///
  /// In ar, this message translates to:
  /// **'{used} من {max} انضموا'**
  String inviteUsesProgress(String used, String max);

  /// Use count of an invite without a limit.
  ///
  /// In ar, this message translates to:
  /// **'اللي انضموا: {used}'**
  String inviteUsesCount(String used);

  /// Join screen title.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام لجروب'**
  String get inviteJoinTitle;

  /// Who invited.
  ///
  /// In ar, this message translates to:
  /// **'دعاك {name}'**
  String inviteInvitedBy(String name);

  /// Question above the radio cards.
  ///
  /// In ar, this message translates to:
  /// **'إنت مين من الأعضاء؟'**
  String get inviteWhoAreYou;

  /// Explanation under the question.
  ///
  /// In ar, this message translates to:
  /// **'لو المنظّم كان ضاف اسمك وسجّل مصاريفك قبل كده، اختار اسمك عشان نربط حسابك بيها من غير تكرار.'**
  String get inviteWhoBody;

  /// Radio card.
  ///
  /// In ar, this message translates to:
  /// **'أنا عضو جديد (مش في القائمة)'**
  String get inviteNewMember;

  /// Radio card description.
  ///
  /// In ar, this message translates to:
  /// **'هنضيف اسمك كعضو جديد في الجروب'**
  String get inviteNewMemberBody;

  /// Name field label.
  ///
  /// In ar, this message translates to:
  /// **'اسمك في الجروب'**
  String get inviteNameLabel;

  /// Primary button.
  ///
  /// In ar, this message translates to:
  /// **'انضم'**
  String get inviteJoinButton;

  /// Note under the join button.
  ///
  /// In ar, this message translates to:
  /// **'بعد الانضمام هتقدر تسجّل المصاريف وتتابع الحسابات مع باقي الأعضاء.'**
  String get inviteJoinNote;

  /// Note when the invite needs approval.
  ///
  /// In ar, this message translates to:
  /// **'الدعوة دي محتاجة موافقة الأدمن قبل ما تدخل الجروب.'**
  String get inviteNeedsApprovalNote;

  /// Shown after MEMBER_ALREADY_CLAIMED.
  ///
  /// In ar, this message translates to:
  /// **'الاسم ده اتاخد من شخص تاني. اختار اسم تاني أو انضم كعضو جديد.'**
  String get inviteClaimedNotice;

  /// State title.
  ///
  /// In ar, this message translates to:
  /// **'الدعوة انتهت'**
  String get inviteExpiredTitle;

  /// State body (also the INVITE_EXPIRED error).
  ///
  /// In ar, this message translates to:
  /// **'انتهت صلاحية الدعوة دي. اطلب من أدمن الجروب دعوة جديدة.'**
  String get inviteExpiredBody;

  /// State title.
  ///
  /// In ar, this message translates to:
  /// **'الدعوة اتلغت'**
  String get inviteRevokedTitle;

  /// State body (also the INVITE_REVOKED error).
  ///
  /// In ar, this message translates to:
  /// **'أدمن الجروب لغى الدعوة دي. اطلب منه دعوة جديدة لو لسه عايز تنضم.'**
  String get inviteRevokedBody;

  /// State title.
  ///
  /// In ar, this message translates to:
  /// **'الدعوة مش موجودة'**
  String get inviteNotFoundTitle;

  /// State body.
  ///
  /// In ar, this message translates to:
  /// **'راجع الكود وجرّب تاني، أو اطلب دعوة جديدة.'**
  String get inviteNotFoundBody;

  /// State title (also the ALREADY_MEMBER error).
  ///
  /// In ar, this message translates to:
  /// **'إنت عضو في الجروب ده بالفعل'**
  String get inviteAlreadyMemberTitle;

  /// State body.
  ///
  /// In ar, this message translates to:
  /// **'مش محتاج دعوة. افتح الجروب من هنا.'**
  String get inviteAlreadyMemberBody;

  /// Button.
  ///
  /// In ar, this message translates to:
  /// **'افتح الجروب'**
  String get inviteOpenGroup;

  /// State title.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار موافقة الأدمن'**
  String get inviteWaitingTitle;

  /// State body.
  ///
  /// In ar, this message translates to:
  /// **'طلبك للانضمام لجروب «{group}» اتبعت. هتدخل أول ما الأدمن يوافق.'**
  String inviteWaitingBody(String group);

  /// Button.
  ///
  /// In ar, this message translates to:
  /// **'تحديث الحالة'**
  String get inviteRefreshStatus;

  /// Snackbar after a refresh that changed nothing.
  ///
  /// In ar, this message translates to:
  /// **'لسه في انتظار الموافقة'**
  String get inviteStillWaiting;

  /// Button.
  ///
  /// In ar, this message translates to:
  /// **'الرجوع للرئيسية'**
  String get inviteBackHome;

  /// Entry point on the groups list.
  ///
  /// In ar, this message translates to:
  /// **'عندك كود دعوة؟'**
  String get inviteEnterCodeButton;

  /// Code entry screen title.
  ///
  /// In ar, this message translates to:
  /// **'الانضمام بكود'**
  String get inviteEnterCodeTitle;

  /// Code entry explanation.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كود الدعوة اللي وصلك، أو الصق الرابط.'**
  String get inviteEnterCodeBody;

  /// Field label.
  ///
  /// In ar, this message translates to:
  /// **'كود الدعوة'**
  String get inviteCodeFieldLabel;

  /// Inline error.
  ///
  /// In ar, this message translates to:
  /// **'الكود 8 حروف وأرقام. راجعه وجرّب تاني.'**
  String get inviteCodeInvalid;

  /// Button.
  ///
  /// In ar, this message translates to:
  /// **'متابعة'**
  String get inviteContinue;

  /// Length of time: one day.
  ///
  /// In ar, this message translates to:
  /// **'يوم'**
  String get inviteDayOne;

  /// Length of time: two days.
  ///
  /// In ar, this message translates to:
  /// **'يومين'**
  String get inviteDayTwo;

  /// Length of time: 3 to 10 days.
  ///
  /// In ar, this message translates to:
  /// **'{count} أيام'**
  String inviteDaysFew(String count);

  /// Length of time: 11 days or more.
  ///
  /// In ar, this message translates to:
  /// **'{count} يوم'**
  String inviteDaysMany(String count);

  /// Length of time: one hour.
  ///
  /// In ar, this message translates to:
  /// **'ساعة'**
  String get inviteHourOne;

  /// Length of time: two hours.
  ///
  /// In ar, this message translates to:
  /// **'ساعتين'**
  String get inviteHourTwo;

  /// Length of time: 3 to 10 hours.
  ///
  /// In ar, this message translates to:
  /// **'{count} ساعات'**
  String inviteHoursFew(String count);

  /// Length of time: 11 hours or more.
  ///
  /// In ar, this message translates to:
  /// **'{count} ساعة'**
  String inviteHoursMany(String count);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'متصل بحساب'**
  String get membersBadgeConnected;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'اسم فقط'**
  String get membersBadgeNameOnly;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'مالك'**
  String get membersRoleOwner;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'أدمن'**
  String get membersRoleAdmin;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'غادر'**
  String get membersLeftChip;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'ترقية لأدمن'**
  String get membersActionPromote;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'يقدر يعدل الجروب ويدير الأعضاء والدعوات.'**
  String get membersActionPromoteHint;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الأدمن'**
  String get membersActionDemote;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'يرجع عضو عادي.'**
  String get membersActionDemoteHint;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'فصل الحساب'**
  String get membersActionUnlink;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'يرجع اسم فقط، وفواتيره وسجله بيفضلوا زي ما هم.'**
  String get membersActionUnlinkHint;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'عضو غادر'**
  String get membersActionMarkLeft;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'يفضل في القائمة ورصيده ظاهر، وميتضافش لمصاريف جديدة.'**
  String get membersActionMarkLeftHint;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'إعادة التفعيل'**
  String get membersActionReactivate;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'يرجع عضو نشط في الجروب.'**
  String get membersActionReactivateHint;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'نقل الملكية'**
  String get membersActionTransfer;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'يبقى هو المالك وإنت تبقى أدمن.'**
  String get membersActionTransferHint;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'فصل حساب {name}؟'**
  String memberUnlinkConfirmTitle(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'{name} هيرجع اسم فقط ومش هيدخل الجروب تاني. مصاريفه وسجله بيفضلوا زي ما هم، وتقدر تدعوه من جديد.'**
  String memberUnlinkConfirmBody(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'فصل الحساب'**
  String get memberUnlinkConfirmAction;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل {name} كغادر؟'**
  String memberMarkLeftConfirmTitle(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'{name} هيفضل في القائمة ورصيده ظاهر، بس مش هيتضاف لمصاريف جديدة.'**
  String memberMarkLeftConfirmBody(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل كغادر'**
  String get memberMarkLeftConfirmAction;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'ترقية {name} لأدمن؟'**
  String memberPromoteConfirmTitle(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'{name} هيقدر يعدل الجروب ويدير الأعضاء والدعوات.'**
  String memberPromoteConfirmBody(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'ترقية'**
  String get memberPromoteConfirmAction;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الأدمن عن {name}؟'**
  String memberDemoteConfirmTitle(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'{name} هيرجع عضو عادي.'**
  String memberDemoteConfirmBody(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الأدمن'**
  String get memberDemoteConfirmAction;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'رجّعنا {name} للجروب.'**
  String memberReactivatedNotice(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'غادر الجروب'**
  String get membersLeave;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'تغادر الجروب؟'**
  String get groupLeaveConfirmTitle;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'رصيدك بيفضل محفوظ في الجروب ومش هتشوفه تاني. عشان ترجع لازم دعوة جديدة.'**
  String get groupLeaveConfirmBody;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'غادر الجروب'**
  String get groupLeaveConfirmAction;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'خرجت من الجروب.'**
  String get groupLeftNotice;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'نقل الملكية'**
  String get membersTransfer;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'نقل الملكية'**
  String get memberTransferPickerTitle;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'اختار العضو اللي هيبقى المالك. لازم يكون متصل بحساب.'**
  String get memberTransferPickerSubtitle;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'مفيش عضو تنقله له'**
  String get memberTransferPickerEmptyTitle;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'الملكية بتتنقل لعضو نشط ومتصل بحساب. ادعو حد للجروب الأول.'**
  String get memberTransferPickerEmptyBody;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'نقل الملكية لـ {name}؟'**
  String memberTransferConfirmTitle(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'{name} هيبقى المالك وإنت هتبقى أدمن. مش هتقدر ترجّعها بنفسك.'**
  String memberTransferConfirmBody(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'نقل الملكية'**
  String get memberTransferConfirmAction;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'الملكية اتنقلت.'**
  String get memberTransferDoneNotice;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'انقل الملكية الأول'**
  String get errorOwnerMustTransferTitle;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'المالك مش بيغادر الجروب. انقل الملكية لعضو تاني وبعدين غادر.'**
  String get errorOwnerMustTransferMessage;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'العضو ده غادر الجروب. حدّثنا القائمة.'**
  String get errorMemberInactive;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'طلبات انضمام مستنية: {count}'**
  String inviteRequestsBanner(String count);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'طلبات الانضمام'**
  String get inviteRequestsTitle;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'مفيش طلبات انضمام'**
  String get inviteRequestsEmptyTitle;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'لما حد يستخدم دعوة محتاجة موافقة، طلبه هيظهر هنا.'**
  String get inviteRequestsEmptyBody;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'عايز يبقى: {name}'**
  String inviteRequestClaims(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'عضو جديد باسم {name}'**
  String inviteRequestNewMember(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'اتطلب {when}'**
  String inviteRequestWhen(String when);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'قبول'**
  String get inviteRequestApprove;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'رفض'**
  String get inviteRequestReject;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'قبول طلب {name}'**
  String inviteRequestApproveLabel(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'رفض طلب {name}'**
  String inviteRequestRejectLabel(String name);

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'الاسم ده اتربط بحساب تاني. حدّثنا القائمة.'**
  String get inviteRequestClaimedNotice;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'حد تاني قرر في الطلب ده بالفعل. حدّثنا القائمة.'**
  String get inviteRequestDecidedNotice;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'اتقبل الطلب.'**
  String get inviteRequestApprovedNotice;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'اترفض الطلب.'**
  String get inviteRequestRejectedNotice;

  /// FL12 members tab v2.
  ///
  /// In ar, this message translates to:
  /// **'شخص'**
  String get inviteRequestUnknownName;

  /// Status chip: the payer declared it, the receiver has not answered.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار التأكيد'**
  String get settlementChipPending;

  /// Status chip: confirmed, counted in the balances.
  ///
  /// In ar, this message translates to:
  /// **'مؤكّد'**
  String get settlementChipConfirmed;

  /// Status chip: the receiver says the money did not arrive.
  ///
  /// In ar, this message translates to:
  /// **'فيه خلاف'**
  String get settlementChipDisputed;

  /// Status chip: cancelled, never counted.
  ///
  /// In ar, this message translates to:
  /// **'اتلغت'**
  String get settlementChipCancelled;

  /// Status chip for a status this app version does not know.
  ///
  /// In ar, this message translates to:
  /// **'حالة تانية'**
  String get settlementChipUnknown;

  /// Screen-reader label of a status chip.
  ///
  /// In ar, this message translates to:
  /// **'حالة الدفعة: {status}'**
  String settlementChipSpoken(String status);

  /// Small tag on a payment an Owner/Admin recorded on behalf.
  ///
  /// In ar, this message translates to:
  /// **'اتسجّلت بواسطة الأدمن'**
  String get settlementByAdmin;

  /// Fixed note on the transfer card (P13-01). Contains the word wallet: allowed in the scope guard.
  ///
  /// In ar, this message translates to:
  /// **'التطبيق مبيحوّلش فلوس — حوّل من تطبيق البنك أو المحفظة وبعدين اضغط دفعت'**
  String get payNoMoveNote;

  /// Heading above the receiver's handles.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الدفع لـ {name}'**
  String payHandlesTitle(String name);

  /// Label of the receiver's InstaPay address.
  ///
  /// In ar, this message translates to:
  /// **'عنوان أو لينك إنستا باي'**
  String get payInstapayLabel;

  /// Label of the receiver's mobile wallet number.
  ///
  /// In ar, this message translates to:
  /// **'محفظة إلكترونية'**
  String get payWalletLabel;

  /// Button next to one handle.
  ///
  /// In ar, this message translates to:
  /// **'نسخ'**
  String get payCopyOne;

  /// Screen-reader label of a copy button.
  ///
  /// In ar, this message translates to:
  /// **'انسخ {what}'**
  String payCopyOneSpoken(String what);

  /// Button that copies every handle shown.
  ///
  /// In ar, this message translates to:
  /// **'نسخ البيانات'**
  String get payCopyAll;

  /// Snackbar after copying.
  ///
  /// In ar, this message translates to:
  /// **'اتنسخ'**
  String get payCopied;

  /// Card text when the receiver has no handles.
  ///
  /// In ar, this message translates to:
  /// **'{name} لسه مضافش بيانات دفع. اتفقوا على طريقة التحويل ودوس دفعت بعد ما تحوّل.'**
  String payNoHandles(String name);

  /// Primary button of the transfer card.
  ///
  /// In ar, this message translates to:
  /// **'دفعت'**
  String get payButton;

  /// Screen-reader label of the I paid button.
  ///
  /// In ar, this message translates to:
  /// **'دفعت {amount} لـ {name}'**
  String payButtonSpoken(String amount, String name);

  /// Owner/Admin button on a transfer that is not theirs.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل بالنيابة'**
  String get payOnBehalf;

  /// Button on a transfer the person is owed (records cash received).
  ///
  /// In ar, this message translates to:
  /// **'سجّلت إني استلمت'**
  String get payReceived;

  /// Title of the payer card.
  ///
  /// In ar, this message translates to:
  /// **'حوّل لـ {name}'**
  String payTransferTitle(String name);

  /// Badge on a transfer with pendingMinor > 0.
  ///
  /// In ar, this message translates to:
  /// **'فيه دفعة في انتظار التأكيد'**
  String get pendingBadge;

  /// Explains pending vs confirmed. Both amounts are the server's, never subtracted.
  ///
  /// In ar, this message translates to:
  /// **'الأرصدة بتحسب الدفعات المؤكَّدة بس. فيه دفعة {pending} في انتظار التأكيد، والمطلوب لسه {amount} لحد ما تتأكد.'**
  String pendingExplain(String pending, String amount);

  /// Flag on a transfer with hasDispute.
  ///
  /// In ar, this message translates to:
  /// **'فيه خلاف على دفعة'**
  String get disputeFlag;

  /// Payment sheet title (a member declares their payment).
  ///
  /// In ar, this message translates to:
  /// **'دفعت'**
  String get paymentTitleDeclare;

  /// Payment sheet title (the receiver records it).
  ///
  /// In ar, this message translates to:
  /// **'استلمت'**
  String get paymentTitleReceived;

  /// Payment sheet title for an Owner/Admin.
  ///
  /// In ar, this message translates to:
  /// **'تسجيل بالنيابة'**
  String get paymentTitleOnBehalf;

  /// Hint in the payment sheet.
  ///
  /// In ar, this message translates to:
  /// **'هتتبعت لـ {name} عشان يأكّدها. الأرصدة مش هتتغيّر لحد ما يأكّد.'**
  String paymentHintPending(String name);

  /// Hint in the payment sheet.
  ///
  /// In ar, this message translates to:
  /// **'هتتسجّل مؤكّدة على طول وهتتحسب في الأرصدة.'**
  String get paymentHintConfirmed;

  /// Shown instead of the send button for a member paying a member without an account.
  ///
  /// In ar, this message translates to:
  /// **'{name} مالوش حساب في التطبيق، فالأدمن هو اللي يسجّل الدفعة دي.'**
  String paymentHintNoAccount(String name);

  /// Hint when the chosen pair is not allowed for a plain member.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تسجّل دفعاتك إنت بس. الأدمن هو اللي بيسجّل بالنيابة عن غيره.'**
  String get paymentHintNotAllowed;

  /// Snackbar after a PENDING payment was created.
  ///
  /// In ar, this message translates to:
  /// **'اتبعتت لـ {name} عشان يأكّدها.'**
  String paymentSentPending(String name);

  /// Group home banner, one payment.
  ///
  /// In ar, this message translates to:
  /// **'فيه دفعة مستنياك تأكّدها'**
  String get incomingBannerOne;

  /// Group home banner, several payments.
  ///
  /// In ar, this message translates to:
  /// **'فيه {count} دفعات مستنياك تأكّدها'**
  String incomingBannerMany(String count);

  /// Title of the incoming payments sheet and section.
  ///
  /// In ar, this message translates to:
  /// **'دفعات مستنياك'**
  String get incomingTitle;

  /// Receiver card (P13-02).
  ///
  /// In ar, this message translates to:
  /// **'{name} بيقول إنه دفعلك {amount}'**
  String receiverCardTitle(String name, String amount);

  /// Receiver card body.
  ///
  /// In ar, this message translates to:
  /// **'راجع حسابك واتأكد إن الفلوس وصلت قبل ما تأكّد.'**
  String get receiverCardBody;

  /// Receiver button: confirm.
  ///
  /// In ar, this message translates to:
  /// **'استلمت'**
  String get receiverConfirm;

  /// Screen-reader label.
  ///
  /// In ar, this message translates to:
  /// **'أكّد إنك استلمت {amount} من {name}'**
  String receiverConfirmSpoken(String amount, String name);

  /// Receiver button: dispute.
  ///
  /// In ar, this message translates to:
  /// **'لسه مااستلمتش'**
  String get receiverDispute;

  /// Screen-reader label.
  ///
  /// In ar, this message translates to:
  /// **'بلّغ إنك لسه مااستلمتش {amount} من {name}'**
  String receiverDisputeSpoken(String amount, String name);

  /// Dispute confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'لسه مااستلمتش الفلوس؟'**
  String get disputeDialogTitle;

  /// Dispute confirmation body.
  ///
  /// In ar, this message translates to:
  /// **'هنبلّغ {name} إنك مااستلمتش. الدفعة مش هتتحسب لحد ما تتأكد أو تتلغي.'**
  String disputeDialogBody(String name);

  /// Dispute confirmation button.
  ///
  /// In ar, this message translates to:
  /// **'أيوه، مااستلمتش'**
  String get disputeDialogConfirm;

  /// Cancel confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'تلغي الدفعة دي؟'**
  String get cancelDialogTitle;

  /// Cancel confirmation body.
  ///
  /// In ar, this message translates to:
  /// **'الدفعة هتتلغي ومش هتتحسب في الأرصدة. هتفضل ظاهرة في السجل بحالة اتلغت.'**
  String get cancelDialogBody;

  /// Cancel confirmation button and detail action.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء الدفعة'**
  String get cancelDialogConfirm;

  /// Cancel confirmation: dismiss.
  ///
  /// In ar, this message translates to:
  /// **'لأ، سيبها'**
  String get cancelDialogKeep;

  /// Snackbar after confirm.
  ///
  /// In ar, this message translates to:
  /// **'اتأكّدت الدفعة وهتتحسب في الأرصدة.'**
  String get settlementConfirmedSnack;

  /// Snackbar after dispute.
  ///
  /// In ar, this message translates to:
  /// **'اتسجّل إنك مااستلمتش الدفعة.'**
  String get settlementDisputedSnack;

  /// Snackbar after cancel.
  ///
  /// In ar, this message translates to:
  /// **'اتلغت الدفعة.'**
  String get settlementCancelledSnack;

  /// Snackbar/error for INVALID_STATE_TRANSITION (everything is re-read).
  ///
  /// In ar, this message translates to:
  /// **'الدفعة اتغيّرت: دي حالتها دلوقتي.'**
  String get settlementStateChanged;

  /// Snackbar/state for a 404 on a settlement.
  ///
  /// In ar, this message translates to:
  /// **'الدفعة دي مبقتش موجودة.'**
  String get settlementGone;

  /// Detail screen title.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الدفعة'**
  String get settlementDetailTitle;

  /// Detail: amount label.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ الدفعة'**
  String get settlementDetailAmount;

  /// Detail: payer label.
  ///
  /// In ar, this message translates to:
  /// **'الدافع'**
  String get settlementPayerRole;

  /// Detail: receiver label.
  ///
  /// In ar, this message translates to:
  /// **'المستلم'**
  String get settlementReceiverRole;

  /// Payer statement (from the status).
  ///
  /// In ar, this message translates to:
  /// **'بيقول: دفعت'**
  String get stmtPayerPaid;

  /// Payer statement when cancelled.
  ///
  /// In ar, this message translates to:
  /// **'الدفعة اتلغت'**
  String get stmtPayerCancelled;

  /// Receiver statement while PENDING.
  ///
  /// In ar, this message translates to:
  /// **'لسه مردّش'**
  String get stmtReceiverWaiting;

  /// Receiver statement while DISPUTED.
  ///
  /// In ar, this message translates to:
  /// **'بيقول: لسه مااستلمتش'**
  String get stmtReceiverNotReceived;

  /// Receiver statement when CONFIRMED.
  ///
  /// In ar, this message translates to:
  /// **'أكّد إنه استلم'**
  String get stmtReceiverConfirmed;

  /// Receiver line when an admin recorded it.
  ///
  /// In ar, this message translates to:
  /// **'اتسجّلت بواسطة الأدمن'**
  String get stmtRecordedByAdmin;

  /// Detail banner, PENDING.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار تأكيد المستلم'**
  String get detailBannerPending;

  /// Detail banner title, DISPUTED.
  ///
  /// In ar, this message translates to:
  /// **'فيه خلاف على الدفعة دي'**
  String get detailBannerDisputed;

  /// Detail banner body, DISPUTED.
  ///
  /// In ar, this message translates to:
  /// **'في انتظار اتفاق الطرفين أو تدخّل الأدمن'**
  String get detailBannerDisputedBody;

  /// Detail banner, CONFIRMED.
  ///
  /// In ar, this message translates to:
  /// **'الدفعة اتأكّدت وبتتحسب في الأرصدة'**
  String get detailBannerConfirmed;

  /// Detail banner, CANCELLED.
  ///
  /// In ar, this message translates to:
  /// **'الدفعة اتلغت ومش بتتحسب'**
  String get detailBannerCancelled;

  /// Detail note for PENDING and DISPUTED.
  ///
  /// In ar, this message translates to:
  /// **'الدفعة دي مش بتتحسب في الأرصدة لحد ما تتأكد.'**
  String get detailNotCounted;

  /// Detail date line.
  ///
  /// In ar, this message translates to:
  /// **'اتسجّلت: {when}'**
  String detailDeclaredAt(String when);

  /// Detail date line.
  ///
  /// In ar, this message translates to:
  /// **'اتبلّغ بالخلاف: {when}'**
  String detailDisputedAt(String when);

  /// Detail date line.
  ///
  /// In ar, this message translates to:
  /// **'اتأكّدت: {when}'**
  String detailConfirmedAt(String when);

  /// Detail date line.
  ///
  /// In ar, this message translates to:
  /// **'اتلغت: {when}'**
  String detailCancelledAt(String when);

  /// Detail date line (settledOn).
  ///
  /// In ar, this message translates to:
  /// **'تاريخ السداد: {date}'**
  String detailDateOn(String date);

  /// Guidance box title (disputed detail).
  ///
  /// In ar, this message translates to:
  /// **'إرشاد لحل الخلاف وديًا'**
  String get guidanceTitle;

  /// Guidance box body: the app does not arbitrate.
  ///
  /// In ar, this message translates to:
  /// **'الطرفين والأدمن يقدروا يحلّوا الخلاف بعد ما يراجعوا كشف الحساب ورسايل التحويل. التطبيق مبيحكمش ومبيحوّلش فلوس.'**
  String get guidanceBody;

  /// Detail action: confirm.
  ///
  /// In ar, this message translates to:
  /// **'تأكيد واستلام الدفعة'**
  String get detailConfirm;

  /// Profile hub row and title of the payment details screen (FL14).
  ///
  /// In ar, this message translates to:
  /// **'بيانات الدفع'**
  String get profilePaymentDetails;

  /// Privacy note, always visible on the payment details screen.
  ///
  /// In ar, this message translates to:
  /// **'بتظهر لأعضاء مجموعاتك بس'**
  String get handlesPrivacy;

  /// One line under the privacy note: what the details are for and that the app moves no money.
  ///
  /// In ar, this message translates to:
  /// **'اكتب عنوان إنستا باي أو رقم المحفظة أو الاتنين، وزمايلك هيشوفوهم لما يحبّوا يحوّلولك. التطبيق مبيحوّلش فلوس.'**
  String get handlesIntro;

  /// Hint of the InstaPay field.
  ///
  /// In ar, this message translates to:
  /// **'username@instapay أو https://ipn.eg/S/...'**
  String get handlesInstapayHint;

  /// Hint of the wallet field.
  ///
  /// In ar, this message translates to:
  /// **'انستا باي، فودافون كاش، أورنج، وي، اتصالات أو محفظة بنكية'**
  String get handlesWalletHint;

  /// Inline error of the InstaPay field.
  ///
  /// In ar, this message translates to:
  /// **'اكتب العنوان بالشكل ده name@bank (حروف إنجليزي وأرقام من غير مسافات) أو الصق لينك إنستا باي اللي بيبدأ بـ https://ipn.eg/'**
  String get handlesInstapayInvalid;

  /// Inline error of the wallet field.
  ///
  /// In ar, this message translates to:
  /// **'رقم المحفظة لازم يبقى 11 رقم ويبدأ بـ 010 أو 011 أو 012 أو 015.'**
  String get handlesWalletInvalid;

  /// Shown while both fields are empty.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش بيانات دفع. اكتب واحدة على الأقل عشان زمايلك يعرفوا يحوّلولك.'**
  String get handlesEmpty;

  /// Body of the discard question when leaving with unsaved changes.
  ///
  /// In ar, this message translates to:
  /// **'التعديلات على بيانات الدفع مش هتتحفظ.'**
  String get handlesDiscardBody;

  /// Save button.
  ///
  /// In ar, this message translates to:
  /// **'حفظ بيانات الدفع'**
  String get handlesSave;

  /// Snackbar after a successful save.
  ///
  /// In ar, this message translates to:
  /// **'اتحفظت بيانات الدفع'**
  String get handlesSaved;

  /// Confirm before saving with an emptied field.
  ///
  /// In ar, this message translates to:
  /// **'هتمسح {what}؟'**
  String handlesRemoveTitle(String what);

  /// Body of the remove confirmation.
  ///
  /// In ar, this message translates to:
  /// **'زمايلك مش هيشوفوه تاني.'**
  String get handlesRemoveBody;

  /// Confirm button of the remove confirmation.
  ///
  /// In ar, this message translates to:
  /// **'امسح واحفظ'**
  String get handlesRemoveConfirm;

  /// Banner when a save failed because of the connection or the server.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحفظ بيانات الدفع. اتأكد من الاتصال وجرّب تاني.'**
  String get handlesSaveFailed;

  /// Banner when the server answered 422 although the client check passed.
  ///
  /// In ar, this message translates to:
  /// **'السيرفر مقبلش البيانات دي. راجع الرقم والعنوان وجرّب تاني.'**
  String get handlesRejected;

  /// Remind button on a transfer you are owed.
  ///
  /// In ar, this message translates to:
  /// **'ذكّره'**
  String get remindButton;

  /// Screen-reader label of the remind button.
  ///
  /// In ar, this message translates to:
  /// **'ذكّر {name} بالتحويل'**
  String remindButtonSpoken(String name);

  /// Disabled remind button: a reminder was already sent (also the rate-limit message).
  ///
  /// In ar, this message translates to:
  /// **'اتبعت تذكير النهاردة'**
  String get remindSentToday;

  /// Under the disabled button: the server's next-allowed time.
  ///
  /// In ar, this message translates to:
  /// **'تقدر تبعت تاني بعد {time}'**
  String remindNextAt(String time);

  /// Caption instead of the button when the debtor has no account.
  ///
  /// In ar, this message translates to:
  /// **'{name} مالوش حساب على التطبيق، فمش هينفع نبعتله تذكير.'**
  String remindNoAccount(String name);

  /// Snackbar after a reminder was sent.
  ///
  /// In ar, this message translates to:
  /// **'اتبعت التذكير'**
  String get remindSent;

  /// Snackbar when the transfer no longer exists (the balances are re-read).
  ///
  /// In ar, this message translates to:
  /// **'التحويل ده اتغيّر. حدّثنا الأرصدة.'**
  String get remindGone;

  /// Snackbar when the reminder could not be sent (offline, server error).
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نبعت التذكير. جرّب تاني.'**
  String get remindRetry;

  /// Local mode onboarding: title above the one name field.
  ///
  /// In ar, this message translates to:
  /// **'اسمك إيه؟'**
  String get onboardingNameTitle;

  /// Local onboarding: heading of the optional InstaPay / wallet fields.
  ///
  /// In ar, this message translates to:
  /// **'بيانات الدفع (اختياري)'**
  String get onboardingPaymentTitle;

  /// Local onboarding: helper under the payment details heading.
  ///
  /// In ar, this message translates to:
  /// **'علشان صحابك يعرفوا يبعتولك فلوسك فين. تقدر تضيفها أو تغيّرها بعدين.'**
  String get onboardingPaymentHelper;

  /// Local mode onboarding: helper under the name field.
  ///
  /// In ar, this message translates to:
  /// **'الاسم ده هيظهر في مجموعاتك. تقدر تغيّره بعدين.'**
  String get onboardingNameHelper;

  /// Local mode onboarding: save the name and go to the groups list.
  ///
  /// In ar, this message translates to:
  /// **'كمّل'**
  String get onboardingContinue;

  /// Profile hub: section title for export and restore.
  ///
  /// In ar, this message translates to:
  /// **'النسخة الاحتياطية'**
  String get backupSectionTitle;

  /// Profile hub row and confirm dialog title: save a backup file.
  ///
  /// In ar, this message translates to:
  /// **'احفظ نسخة احتياطية'**
  String get backupExportTitle;

  /// Export confirm dialog body: privacy warning.
  ///
  /// In ar, this message translates to:
  /// **'هنجهّز ملف فيه كل مجموعاتك ومصاريفك بالأسماء والمبالغ. احتفظ بيه في مكان آمن وماتبعتوش غير لحد بتثق فيه.'**
  String get backupExportBody;

  /// Export confirm dialog: confirm button.
  ///
  /// In ar, this message translates to:
  /// **'جهّز الملف'**
  String get backupExportConfirm;

  /// Text sent with the backup file in the share sheet.
  ///
  /// In ar, this message translates to:
  /// **'نسخة قسمة الاحتياطية. الملف فيه أسماء ومبالغ، فاحتفظ بيه في مكان آمن وماتبعتوش غير لحد بتثق فيه.'**
  String get backupShareText;

  /// Snackbar after the backup file was handed to the share sheet.
  ///
  /// In ar, this message translates to:
  /// **'النسخة الاحتياطية اتجهزت.'**
  String get backupExportDone;

  /// Snackbar when the export failed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نجهّز النسخة الاحتياطية. جرّب تاني.'**
  String get backupExportFailed;

  /// Profile hub row: restore from a backup file.
  ///
  /// In ar, this message translates to:
  /// **'استرجع من نسخة احتياطية'**
  String get backupRestoreTitle;

  /// Profile hub row value: date of the last export (ISO date).
  ///
  /// In ar, this message translates to:
  /// **'آخر نسخة: {date}'**
  String backupLastExport(String date);

  /// Profile hub row value: never exported.
  ///
  /// In ar, this message translates to:
  /// **'لسه ماعملتش نسخة'**
  String get backupNeverExported;

  /// Restore confirm dialog title.
  ///
  /// In ar, this message translates to:
  /// **'نسترجع النسخة دي؟'**
  String get backupRestoreConfirmTitle;

  /// Restore confirm dialog body with counts.
  ///
  /// In ar, this message translates to:
  /// **'النسخة فيها {groups} مجموعة و{expenses} مصروف (اتعملت {date}). هنمسح كل البيانات اللي على التليفون دلوقتي ونحط بياناتها مكانها. مينفعش نرجّع اللي اتمسح.'**
  String backupRestoreConfirmBody(String groups, String expenses, String date);

  /// Restore confirm dialog: destructive confirm button.
  ///
  /// In ar, this message translates to:
  /// **'استرجع وامسح الحالي'**
  String get backupRestoreConfirm;

  /// Snackbar after a successful restore.
  ///
  /// In ar, this message translates to:
  /// **'البيانات اتسترجعت.'**
  String get backupRestoreDone;

  /// Restore error: not a backup file.
  ///
  /// In ar, this message translates to:
  /// **'الملف ده مش نسخة احتياطية من قسمة، أو باظ. بياناتك زي ما هي.'**
  String get backupErrorUnreadable;

  /// Restore error: file or content too large.
  ///
  /// In ar, this message translates to:
  /// **'الملف كبير أوي ومينفعش نفتحه. بياناتك زي ما هي.'**
  String get backupErrorTooLarge;

  /// Restore error: newer format version.
  ///
  /// In ar, this message translates to:
  /// **'النسخة دي اتعملت بإصدار أحدث من قسمة. حدّث التطبيق وجرّب تاني. بياناتك زي ما هي.'**
  String get backupErrorNewer;

  /// Restore error: invalid structure.
  ///
  /// In ar, this message translates to:
  /// **'الملف ناقص أو فيه بيانات غلط. بياناتك زي ما هي.'**
  String get backupErrorInvalid;

  /// Restore error: recompute check failed.
  ///
  /// In ar, this message translates to:
  /// **'حسابات الملف مش مظبوطة، فمرجّعناش حاجة. بياناتك زي ما هي.'**
  String get backupErrorInconsistent;

  /// Restore error: write failed and was rolled back.
  ///
  /// In ar, this message translates to:
  /// **'حصلت مشكلة وإحنا بنسترجع، ومحدش اتغيّر. بياناتك زي ما هي.'**
  String get backupErrorFailed;

  /// Reminder banner: title.
  ///
  /// In ar, this message translates to:
  /// **'احفظ نسخة احتياطية'**
  String get backupBannerTitle;

  /// Reminder banner: body.
  ///
  /// In ar, this message translates to:
  /// **'التليفون ده هو النسخة الوحيدة من بياناتك. احفظ نسخة دلوقتي عشان ماتضيعش.'**
  String get backupBannerBody;

  /// Reminder banner: action.
  ///
  /// In ar, this message translates to:
  /// **'احفظ نسخة'**
  String get backupBannerAction;

  /// Reminder banner: dismiss tooltip.
  ///
  /// In ar, this message translates to:
  /// **'تجاهل'**
  String get backupBannerDismiss;

  /// تصنيف: طعام ومشروبات
  ///
  /// In ar, this message translates to:
  /// **'طعام ومشروبات'**
  String get categoryFood;

  /// تصنيف: مواصلات
  ///
  /// In ar, this message translates to:
  /// **'مواصلات'**
  String get categoryTransport;

  /// تصنيف: بنزين
  ///
  /// In ar, this message translates to:
  /// **'بنزين'**
  String get categoryFuel;

  /// تصنيف: سكن وإقامة
  ///
  /// In ar, this message translates to:
  /// **'سكن وإقامة'**
  String get categoryAccommodation;

  /// تصنيف: بقالة وسوبرماركت
  ///
  /// In ar, this message translates to:
  /// **'بقالة وسوبرماركت'**
  String get categoryGroceries;

  /// تصنيف: تسوق ومشتريات
  ///
  /// In ar, this message translates to:
  /// **'تسوق ومشتريات'**
  String get categoryShopping;

  /// تصنيف: ترفيه وخروجات
  ///
  /// In ar, this message translates to:
  /// **'ترفيه وخروجات'**
  String get categoryEntertainment;

  /// تصنيف: فواتير وخدمات
  ///
  /// In ar, this message translates to:
  /// **'فواتير وخدمات'**
  String get categoryBills;

  /// تصنيف: أخرى
  ///
  /// In ar, this message translates to:
  /// **'أخرى'**
  String get categoryOther;

  /// عنوان زر تصفية التصنيف
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get expenseFilterCategory;

  /// عنوان صفحة اختيار تصنيف التصفية
  ///
  /// In ar, this message translates to:
  /// **'تصفية حسب التصنيف'**
  String get expenseFilterCategoryTitle;

  /// وصف صفحة اختيار تصنيف التصفية
  ///
  /// In ar, this message translates to:
  /// **'عرض مصاريف تصنيف واحد فقط'**
  String get expenseFilterCategoryHint;

  /// خيار عرض كل التصنيفات
  ///
  /// In ar, this message translates to:
  /// **'كل التصنيفات'**
  String get expenseFilterAllCategories;

  /// عنوان اختيار التصنيف في نموذج المصروف
  ///
  /// In ar, this message translates to:
  /// **'التصنيف'**
  String get expenseCategoryPickerTitle;

  /// عنوان صفحة نصيبي
  ///
  /// In ar, this message translates to:
  /// **'نصيبي'**
  String get myShareTitle;

  /// وصف مختصر لصفحة نصيبي في الإعدادات
  ///
  /// In ar, this message translates to:
  /// **'استهلاكك ومصاريفك الشهرية'**
  String get myShareSubtitle;

  /// عنوان فرعي للمصاريف الشهرية
  ///
  /// In ar, this message translates to:
  /// **'المصاريف الشهرية'**
  String get myShareMonthlySpend;

  /// إجمالي ما استهلكه المستخدم في الشهر
  ///
  /// In ar, this message translates to:
  /// **'استهلاكك'**
  String get myShareConsumed;

  /// إجمالي ما دفعه المستخدم مقدمًا في الشهر
  ///
  /// In ar, this message translates to:
  /// **'دفعت مقدمًا'**
  String get mySharePaidUpFront;

  /// الفرق بين ما دفعه المستخدم وما استهلكه
  ///
  /// In ar, this message translates to:
  /// **'الفرق'**
  String get myShareDifference;

  /// حالة عندما يدفع المستخدم أكثر مما يستهلك
  ///
  /// In ar, this message translates to:
  /// **'دفعت أكثر مما استهلكت'**
  String get myShareYouPaidMore;

  /// حالة عندما يستهلك المستخدم أكثر مما يدفع
  ///
  /// In ar, this message translates to:
  /// **'استهلكت أكثر مما دفعت'**
  String get myShareYouConsumedMore;

  /// حالة التساوي بين الدفع والاستهلاك
  ///
  /// In ar, this message translates to:
  /// **'استهلاكك مساوٍ لما دفعته'**
  String get myShareBalanced;

  /// تلميح أسفل عنوان المصاريف الشهرية
  ///
  /// In ar, this message translates to:
  /// **'اضغط على فئة لعرض المصاريف الخاصة بها'**
  String get myShareHint;

  /// توضيح أن صفحة نصيبي ليست ديونًا
  ///
  /// In ar, this message translates to:
  /// **'هذه أرقام إنفاقك أنت وليست مبالغ عليك. لمعرفة من يدين لمن افتح تبويب الأرصدة.'**
  String get myShareExplainer;

  /// وصف قارئ الشاشة لبطاقة الفئة
  ///
  /// In ar, this message translates to:
  /// **'{category}، {percent} بالمئة من استهلاكك، {amount}'**
  String myShareCategorySemantics(
    String category,
    String percent,
    String amount,
  );

  /// عنوان الحالة الفارغة لصفحة نصيبي
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مصاريف بعد'**
  String get myShareEmptyTitle;

  /// وصف الحالة الفارغة لصفحة نصيبي
  ///
  /// In ar, this message translates to:
  /// **'عند تسجيل المصاريف في مجموعاتك، ستظهر تفاصيل استهلاكك هنا.'**
  String get myShareEmptyBody;

  /// عنوان نافذة تفاصيل مصاريف الفئة
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الفئة'**
  String get myShareDrilldownTitle;

  /// عدد المصاريف في الفئة
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{مصروف واحد} =2{مصروفان} few{{count} مصاريف} many{{count} مصروفًا} other{{count} مصروف}}'**
  String myShareExpensesCount(int count);

  /// نص عند عدم وجود مصاريف للفئة
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مصاريف لهذه الفئة'**
  String get myShareNoExpensesInCategory;

  /// عنوان صفحة ملخص الرحلة
  ///
  /// In ar, this message translates to:
  /// **'ملخص الرحلة'**
  String get recapTitle;

  /// زر مشاركة الملخص كصورة
  ///
  /// In ar, this message translates to:
  /// **'مشاركة كصورة'**
  String get recapShareImage;

  /// عنوان قائمة المبالغ في صورة المصروف المشتركة
  ///
  /// In ar, this message translates to:
  /// **'كل واحد عليه كام'**
  String get shareWhoOwes;

  /// زر مشاركة الملخص كنص
  ///
  /// In ar, this message translates to:
  /// **'مشاركة كنص'**
  String get recapShareText;

  /// عنوان نافذة تأكيد مشاركة الملخص
  ///
  /// In ar, this message translates to:
  /// **'مشاركة ملخص الرحلة'**
  String get recapConfirmShareTitle;

  /// نص نافذة تأكيد مشاركة الملخص والأسماء
  ///
  /// In ar, this message translates to:
  /// **'ستظهر أسماء أعضاء المجموعة في الملخص المشترك. هل تريد المتابعة؟'**
  String get recapConfirmShareBody;

  /// زر تأكيد المشاركة
  ///
  /// In ar, this message translates to:
  /// **'مشاركة'**
  String get recapConfirmShareAction;

  /// عنوان إجمالي المصاريف في الملخص
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المصاريف'**
  String get recapTotalSpent;

  /// عدد المصاريف في ملخص الرحلة
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{مصروف واحد} =2{مصروفان} few{{count} مصاريف} many{{count} مصروفًا} other{{count} مصروف}}'**
  String recapExpensesCount(int count);

  /// عنوان العضو الأكثر دفعًا
  ///
  /// In ar, this message translates to:
  /// **'أكثر من دفع'**
  String get recapTopPayer;

  /// عنوان أكبر مصروف منفرد
  ///
  /// In ar, this message translates to:
  /// **'أكبر مصروف'**
  String get recapBiggestExpense;

  /// عنوان قسم توزيع المصاريف حسب الفئات
  ///
  /// In ar, this message translates to:
  /// **'توزيع المصاريف'**
  String get recapCategoriesTitle;

  /// عنوان الحالة الفارغة لملخص الرحلة
  ///
  /// In ar, this message translates to:
  /// **'لا توجد مصاريف بعد'**
  String get recapEmptyTitle;

  /// نص الحالة الفارغة لملخص الرحلة
  ///
  /// In ar, this message translates to:
  /// **'عند تسجيل مصاريف في هذه المجموعة، سيظهر ملخص الرحلة هنا.'**
  String get recapEmptyBody;

  /// العلامة المائية للتطبيق
  ///
  /// In ar, this message translates to:
  /// **'قسمة • Qesma'**
  String get recapWatermark;

  /// رابط تحميل التطبيق في أسفل الصورة
  ///
  /// In ar, this message translates to:
  /// **'qesma.app'**
  String get recapPlayLink;

  /// زر فتح شاشة ملخص الرحلة
  ///
  /// In ar, this message translates to:
  /// **'عرض ملخص الرحلة'**
  String get recapViewButton;

  /// عنوان الملخص النصي للمجموعة
  ///
  /// In ar, this message translates to:
  /// **'ملخص مصاريف {groupName}'**
  String recapTextSummaryHeader(String groupName);

  /// سطر إجمالي المصاريف في الملخص النصي
  ///
  /// In ar, this message translates to:
  /// **'إجمالي المصاريف: {amount} ({count})'**
  String recapTextSummaryTotal(String amount, String count);

  /// عنوان قسم التسويات في الملخص النصي
  ///
  /// In ar, this message translates to:
  /// **'التسويات المقترحة:'**
  String get recapTextSummaryTransfersHeader;

  /// سطر تسوية فردية في الملخص النصي
  ///
  /// In ar, this message translates to:
  /// **'• {from} يدفع لـ {to}: {amount}'**
  String recapTextSummaryTransferLine(String from, String to, String amount);

  /// نص تسوية كافة المصاريف في الملخص النصي
  ///
  /// In ar, this message translates to:
  /// **'تمت تسوية جميع المصاريف!'**
  String get recapTextSummaryAllSettled;

  /// تذييل الملخص النصي
  ///
  /// In ar, this message translates to:
  /// **'تم الحساب بواسطة تطبيق قسمة • qesma.app'**
  String get recapTextSummaryFooter;

  /// عنوان نافذة إرسال تذكير بالتحويل
  ///
  /// In ar, this message translates to:
  /// **'تذكير بالتحويل'**
  String get reminderSheetTitle;

  /// وصف نافذة إرسال تذكير بالتحويل
  ///
  /// In ar, this message translates to:
  /// **'رسالة واتساب جاهزة للتعديل والإرسال'**
  String get reminderSheetSubtitle;

  /// عنوان اختيار نبرة التذكير
  ///
  /// In ar, this message translates to:
  /// **'طريقة الكلام'**
  String get reminderToneLabel;

  /// نبرة التذكير الهادئة
  ///
  /// In ar, this message translates to:
  /// **'هادي'**
  String get reminderToneSoftChip;

  /// نبرة التذكير الواضحة والمباشرة
  ///
  /// In ar, this message translates to:
  /// **'واضح'**
  String get reminderToneFirmChip;

  /// نبرة التذكير المرحة
  ///
  /// In ar, this message translates to:
  /// **'هزار'**
  String get reminderToneFunnyChip;

  /// زر تفعيل إضافة إنستاباي إلى الرسالة
  ///
  /// In ar, this message translates to:
  /// **'إضافة حساب إنستاباي للرسالة'**
  String get reminderIncludeInstapay;

  /// عنوان حقل تعديل نص الرسالة
  ///
  /// In ar, this message translates to:
  /// **'نص الرسالة'**
  String get reminderMessageFieldLabel;

  /// رسالة تظهر لما واتساب ولا قائمة المشاركة اتفتحوا
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نفتح واتساب أو المشاركة. جرّب تاني.'**
  String get reminderLaunchFailed;

  /// زر فتح تطبيق واتساب بالمحادثة
  ///
  /// In ar, this message translates to:
  /// **'فتح واتساب'**
  String get reminderOpenWhatsapp;

  /// Secondary button that opens the system share sheet so the user picks WhatsApp, WhatsApp Business or another app
  ///
  /// In ar, this message translates to:
  /// **'اختار التطبيق (واتساب، واتساب بيزنس...)'**
  String get reminderChooseApp;

  /// سطر إضافة عنوان إنستاباي
  ///
  /// In ar, this message translates to:
  /// **'\n\nده الانستا باي بتاعي : {handle}'**
  String reminderInstapayLine(String handle);

  /// سطر إضافة رقم المحفظة
  ///
  /// In ar, this message translates to:
  /// **'\n\nرقم المحفظة بتاعتي : {handle}'**
  String reminderWalletLine(String handle);

  /// Label above the InstaPay/wallet choice in the reminder sheet
  ///
  /// In ar, this message translates to:
  /// **'تحب نكتب أنهي وسيلة دفع؟'**
  String get reminderPayMethodLabel;

  /// InstaPay choice chip
  ///
  /// In ar, this message translates to:
  /// **'إنستا باي'**
  String get reminderMethodInstapay;

  /// Mobile wallet choice chip
  ///
  /// In ar, this message translates to:
  /// **'محفظة إلكترونية'**
  String get reminderMethodWallet;

  /// Toggle label to include payment details
  ///
  /// In ar, this message translates to:
  /// **'أضيف بيانات الدفع بتاعتي'**
  String get reminderIncludePayment;

  /// قالب التذكير الهادئ
  ///
  /// In ar, this message translates to:
  /// **'صباح الفل يا {name}، تذكير بسيط بس بخصوص قعدتنا في {group}، كان عليك {amount}. لما تفضى ابعتهم براحتك يا غالي{handle}'**
  String reminderToneSoft(
    String name,
    String group,
    String amount,
    String handle,
  );

  /// قالب التذكير الواضح والمباشر
  ///
  /// In ar, this message translates to:
  /// **'يا {name}، بنقفل حسابات {group} ومتبقي عليك {amount}. يا ريت تحولهم أول ما تشوف الرسالة{handle}'**
  String reminderToneFirm(
    String name,
    String group,
    String amount,
    String handle,
  );

  /// قالب التذكير الفكاهي واللطيف
  ///
  /// In ar, this message translates to:
  /// **'يا {name} يا فنان، تذكير لطيف قبل ما الجيب يعلن إفلاسه بخصوص {group}: عليك {amount}. متخليش المحفظة تعيط!{handle}'**
  String reminderToneFunny(
    String name,
    String group,
    String amount,
    String handle,
  );

  /// SA10: edit-group section and pool screen title (the pooled kitty).
  ///
  /// In ar, this message translates to:
  /// **'الصندوق'**
  String get poolSectionTitle;

  /// SA10: one-line explanation of the pool under the edit-group section title.
  ///
  /// In ar, this message translates to:
  /// **'واحد بيمسك كاش الجروب.'**
  String get poolSectionHint;

  /// SA10: label of the treasurer field.
  ///
  /// In ar, this message translates to:
  /// **'أمين الصندوق'**
  String get poolTreasurerLabel;

  /// SA10: treasurer field value when none is chosen.
  ///
  /// In ar, this message translates to:
  /// **'مفيش أمين صندوق لسه'**
  String get poolTreasurerNone;

  /// SA10: title of the treasurer picker and the field's action.
  ///
  /// In ar, this message translates to:
  /// **'اختار أمين الصندوق'**
  String get poolTreasurerChoose;

  /// SA10: why the treasurer field is disabled (A137); also the copy of the 409 on save.
  ///
  /// In ar, this message translates to:
  /// **'مينفعش تغيّر أمين الصندوق بعد أول إيداع أو أول مصروف من الصندوق.'**
  String get poolTreasurerLocked;

  /// SA10: who holds the pool, on the pool card and screen.
  ///
  /// In ar, this message translates to:
  /// **'أمين الصندوق: {name}'**
  String poolTreasurerIs(String name);

  /// SA10: meter row, what is left in the pool.
  ///
  /// In ar, this message translates to:
  /// **'الباقي في الصندوق'**
  String get poolRemaining;

  /// SA10: meter row, sum of received deposits.
  ///
  /// In ar, this message translates to:
  /// **'إجمالي الإيداعات'**
  String get poolDeposited;

  /// SA10: meter row, sum of pool expenses.
  ///
  /// In ar, this message translates to:
  /// **'اتصرف من الصندوق'**
  String get poolSpent;

  /// SA10: the meter is negative; the words carry the meaning, not the colour.
  ///
  /// In ar, this message translates to:
  /// **'أمين الصندوق دفع من جيبه {amount}'**
  String poolCovered(String amount);

  /// SA10: under a negative meter: the treasurer gets it back through the balances transfers.
  ///
  /// In ar, this message translates to:
  /// **'هيرجعلهم في التحويلات اللي في تبويب الحسابات.'**
  String get poolCoveredHint;

  /// SA10: the meter is exactly zero.
  ///
  /// In ar, this message translates to:
  /// **'الصندوق فاضي'**
  String get poolEmptyMeter;

  /// SA10: accessible name of the tap on the pool card.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الصندوق'**
  String get poolOpenDetails;

  /// SA10: button that opens the deposit sheet.
  ///
  /// In ar, this message translates to:
  /// **'إضافة إيداع'**
  String get poolAddDeposit;

  /// SA10: title of the deposits list on the pool screen.
  ///
  /// In ar, this message translates to:
  /// **'الإيداعات'**
  String get poolDepositsTitle;

  /// SA10: empty deposits list title.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش إيداعات'**
  String get poolDepositsEmpty;

  /// SA10: empty deposits list body.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الفلوس اللي كل واحد سلّمها لأمين الصندوق.'**
  String get poolDepositsEmptyBody;

  /// SA10: title of the deposit sheet.
  ///
  /// In ar, this message translates to:
  /// **'إيداع في الصندوق'**
  String get poolDepositSheetTitle;

  /// Title of the deposit sheet when correcting a recorded deposit.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الإيداع'**
  String get poolEditDepositTitle;

  /// Tooltip and confirm label of the remove button on a deposit row.
  ///
  /// In ar, this message translates to:
  /// **'حذف الإيداع'**
  String get poolRemoveDeposit;

  /// Confirm dialog title when removing a pool deposit.
  ///
  /// In ar, this message translates to:
  /// **'تحذف الإيداع ده؟'**
  String get poolRemoveDepositTitle;

  /// Confirm dialog body when removing a pool deposit.
  ///
  /// In ar, this message translates to:
  /// **'استخدمها لو كتبت المبلغ غلط. الإيداع هيفضل في القايمة بحالة «ملغي» ومش هيتحسب في الصندوق.'**
  String get poolRemoveDepositBody;

  /// Snackbar after removing a deposit.
  ///
  /// In ar, this message translates to:
  /// **'اتحذف الإيداع.'**
  String get poolDepositRemoved;

  /// Snackbar when removing a deposit failed.
  ///
  /// In ar, this message translates to:
  /// **'معرفناش نحذف الإيداع. جرّب تاني.'**
  String get poolRemoveDepositFailed;

  /// Tooltip of the edit button on a deposit row.
  ///
  /// In ar, this message translates to:
  /// **'تعديل الإيداع ده'**
  String get poolEditDeposit;

  /// SA10: deposit sheet, the depositor field.
  ///
  /// In ar, this message translates to:
  /// **'مين اللي سلّم الفلوس؟'**
  String get poolDepositFrom;

  /// SA10: deposit sheet, fixed receiver line.
  ///
  /// In ar, this message translates to:
  /// **'لأمين الصندوق: {name}'**
  String poolDepositTo(String name);

  /// SA10: deposit amount field label.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ (ج.م)'**
  String get poolDepositAmountLabel;

  /// SA10: deposit sheet primary button.
  ///
  /// In ar, this message translates to:
  /// **'سجّل الإيداع'**
  String get poolDepositSave;

  /// SA10: snackbar after a deposit is recorded.
  ///
  /// In ar, this message translates to:
  /// **'اتسجّل الإيداع'**
  String get poolDepositSaved;

  /// SA10: deposit sheet when nobody but the treasurer can deposit (A138).
  ///
  /// In ar, this message translates to:
  /// **'محدش غير أمين الصندوق في المجموعة. أضف أعضاء الأول عشان يودعوا.'**
  String get poolDepositOnlyTreasurer;

  /// SA10: expense form switch.
  ///
  /// In ar, this message translates to:
  /// **'اتدفع من الصندوق'**
  String get expensePaidFromPool;

  /// SA10: under the switch when on; the payer editor is off.
  ///
  /// In ar, this message translates to:
  /// **'{name} (أمين الصندوق) دفع من فلوس الصندوق، فهو الدافع الوحيد.'**
  String expensePaidFromPoolHint(String name);

  /// SA10: tag on an expense paid from the pool.
  ///
  /// In ar, this message translates to:
  /// **'من الصندوق'**
  String get expensePoolTag;

  /// SA10: one line on the balances tab when the group has a pool.
  ///
  /// In ar, this message translates to:
  /// **'الفلوس اللي فاضلة في الصندوق، أو اللي دفعها أمين الصندوق من جيبه، بتتسوّى في التحويلات اللي تحت.'**
  String get balancesPoolNote;

  /// SA11: title of the fuel and ride calculator screen.
  ///
  /// In ar, this message translates to:
  /// **'حاسبة الخروجة'**
  String get calcTitle;

  /// SA11: FAB menu row that opens the add-expense form.
  ///
  /// In ar, this message translates to:
  /// **'إضافة مصروف'**
  String get calcMenuAddExpense;

  /// SA11: FAB menu row subtitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب المبلغ ومين هيتقسم عليهم'**
  String get calcMenuAddExpenseHint;

  /// SA11: FAB menu row that opens the calculator.
  ///
  /// In ar, this message translates to:
  /// **'حاسبة البنزين والمشوار'**
  String get calcMenuCalculator;

  /// SA11: FAB menu row subtitle.
  ///
  /// In ar, this message translates to:
  /// **'قسّم البنزين والكارتة، أو مشوار مشترك فيه محطات'**
  String get calcMenuCalculatorHint;

  /// No description provided for @calcMenuFlatShare.
  ///
  /// In ar, this message translates to:
  /// **'فاتورة السكن المشترك'**
  String get calcMenuFlatShare;

  /// No description provided for @calcMenuFlatShareHint.
  ///
  /// In ar, this message translates to:
  /// **'إيجار أو كهرباء أو إنترنت، بالحصص أو بأيام الإقامة'**
  String get calcMenuFlatShareHint;

  /// No description provided for @expenseFilterButton.
  ///
  /// In ar, this message translates to:
  /// **'تصفية'**
  String get expenseFilterButton;

  /// No description provided for @expenseFilterSheetTitle.
  ///
  /// In ar, this message translates to:
  /// **'تصفية المصاريف'**
  String get expenseFilterSheetTitle;

  /// SA11: calculator tab: road-trip fuel and tolls.
  ///
  /// In ar, this message translates to:
  /// **'بنزين'**
  String get calcTabFuel;

  /// SA11: calculator tab: a shared ride (taxi/app) with stops.
  ///
  /// In ar, this message translates to:
  /// **'مشوار مشترك'**
  String get calcTabRide;

  /// SA11: distance field label.
  ///
  /// In ar, this message translates to:
  /// **'المسافة (كم)'**
  String get calcDistance;

  /// SA11: invalid distance.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مسافة لحد 10,000 كم، وبعد العلامة رقم واحد بس'**
  String get calcDistanceError;

  /// SA11: consumption field label.
  ///
  /// In ar, this message translates to:
  /// **'الاستهلاك (لتر لكل 100 كم)'**
  String get calcConsumption;

  /// SA11: consumption helper.
  ///
  /// In ar, this message translates to:
  /// **'أغلب العربيات بين 6 و 10'**
  String get calcConsumptionHint;

  /// SA11: invalid consumption.
  ///
  /// In ar, this message translates to:
  /// **'اكتب رقم من 1 لـ 30، وبعد العلامة رقم واحد بس'**
  String get calcConsumptionError;

  /// SA11: fuel type chips label.
  ///
  /// In ar, this message translates to:
  /// **'نوع البنزين'**
  String get calcFuelType;

  /// SA11: fuel type chip.
  ///
  /// In ar, this message translates to:
  /// **'بنزين 80'**
  String get calcFuel80;

  /// SA11: fuel type chip.
  ///
  /// In ar, this message translates to:
  /// **'بنزين 92'**
  String get calcFuel92;

  /// SA11: fuel type chip.
  ///
  /// In ar, this message translates to:
  /// **'بنزين 95'**
  String get calcFuel95;

  /// SA11: fuel type chip: diesel.
  ///
  /// In ar, this message translates to:
  /// **'سولار'**
  String get calcFuelDiesel;

  /// SA11: no saved price for the chosen fuel type.
  ///
  /// In ar, this message translates to:
  /// **'مفيش سعر متسجّل. اكتب سعر البنزينة النهارده.'**
  String get calcPriceNotSet;

  /// SA11: saved price line.
  ///
  /// In ar, this message translates to:
  /// **'{price} للتر · آخر تحديث {date}'**
  String calcPriceSaved(String price, String date);

  /// SA11: button: edit the saved price.
  ///
  /// In ar, this message translates to:
  /// **'تعديل السعر'**
  String get calcPriceEdit;

  /// SA11: button: add a price when none is saved.
  ///
  /// In ar, this message translates to:
  /// **'إضافة السعر'**
  String get calcPriceSet;

  /// Chip that fills the fuel price with the bundled reference price.
  ///
  /// In ar, this message translates to:
  /// **'استخدم {price} (السعر الرسمي، {date})'**
  String calcPriceSuggest(String price, String date);

  /// SA11: price dialog title.
  ///
  /// In ar, this message translates to:
  /// **'سعر اللتر: {fuel}'**
  String calcPriceDialogTitle(String fuel);

  /// SA11: price dialog helper (A142: no fetched price).
  ///
  /// In ar, this message translates to:
  /// **'اكتب السعر اللي دفعته في البنزينة. قسمة مش بتجيب الأسعار من أي مكان.'**
  String get calcPriceDialogHint;

  /// SA11: invalid price.
  ///
  /// In ar, this message translates to:
  /// **'اكتب سعر لحد 1,000 جنيه'**
  String get calcPriceError;

  /// SA11: tolls section title.
  ///
  /// In ar, this message translates to:
  /// **'الكارتة'**
  String get calcTolls;

  /// SA11: one toll row label.
  ///
  /// In ar, this message translates to:
  /// **'كارتة {number}'**
  String calcTollLabel(String number);

  /// SA11: add a toll row.
  ///
  /// In ar, this message translates to:
  /// **'إضافة كارتة'**
  String get calcTollAdd;

  /// SA11: remove a toll row (tooltip).
  ///
  /// In ar, this message translates to:
  /// **'شيل الكارتة دي'**
  String get calcTollRemove;

  /// SA11: invalid toll amount.
  ///
  /// In ar, this message translates to:
  /// **'اكتب المبلغ، أو شيل الكارتة دي'**
  String get calcTollError;

  /// SA11: driver picker; the driver is the payer.
  ///
  /// In ar, this message translates to:
  /// **'السواق (دفع البنزين)'**
  String get calcDriver;

  /// SA11: switch: the driver shares the cost.
  ///
  /// In ar, this message translates to:
  /// **'السواق بيدفع نصيب هو كمان'**
  String get calcDriverShares;

  /// SA11: passenger chips label.
  ///
  /// In ar, this message translates to:
  /// **'مين في العربية'**
  String get calcPassengers;

  /// SA11: total fare field.
  ///
  /// In ar, this message translates to:
  /// **'الأجرة كلها'**
  String get calcFare;

  /// SA11: payer of the ride fare.
  ///
  /// In ar, this message translates to:
  /// **'مين دفع الأجرة'**
  String get calcFarePayer;

  /// SA11: stops section title.
  ///
  /// In ar, this message translates to:
  /// **'المحطات'**
  String get calcStops;

  /// SA11: a numbered stop.
  ///
  /// In ar, this message translates to:
  /// **'محطة {number}'**
  String calcStopName(String number);

  /// SA11: distance of one leg.
  ///
  /// In ar, this message translates to:
  /// **'من محطة {from} لمحطة {to} (كم)'**
  String calcLegDistance(String from, String to);

  /// SA11: add a stop.
  ///
  /// In ar, this message translates to:
  /// **'إضافة محطة'**
  String get calcStopAdd;

  /// SA11: remove the last stop.
  ///
  /// In ar, this message translates to:
  /// **'شيل آخر محطة'**
  String get calcStopRemove;

  /// SA11: riders section title.
  ///
  /// In ar, this message translates to:
  /// **'مين ركب'**
  String get calcRiders;

  /// SA11: boarding stop picker.
  ///
  /// In ar, this message translates to:
  /// **'ركب من'**
  String get calcGetsIn;

  /// SA11: leaving stop picker.
  ///
  /// In ar, this message translates to:
  /// **'نزل عند'**
  String get calcGetsOut;

  /// SA11: result card title.
  ///
  /// In ar, this message translates to:
  /// **'نصيب كل واحد'**
  String get calcResultTitle;

  /// SA11: result row: fuel cost.
  ///
  /// In ar, this message translates to:
  /// **'البنزين'**
  String get calcFuelCost;

  /// SA11: result row: tolls.
  ///
  /// In ar, this message translates to:
  /// **'الكارتة'**
  String get calcTollsCost;

  /// SA11: result row: total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي'**
  String get calcTotal;

  /// SA11: result row: one leg's fare.
  ///
  /// In ar, this message translates to:
  /// **'من محطة {from} لمحطة {to}'**
  String calcLegFare(String from, String to);

  /// SA11: nobody shares the cost.
  ///
  /// In ar, this message translates to:
  /// **'اختار شخص واحد على الأقل يشارك في التكلفة.'**
  String get calcErrorNoSharers;

  /// SA11: a leg without riders (A141).
  ///
  /// In ar, this message translates to:
  /// **'مفيش حد راكب من محطة {from} لمحطة {to}. غيّر مين ركب أو نزل فين.'**
  String calcErrorEmptyLeg(String from, String to);

  /// SA11: total is zero.
  ///
  /// In ar, this message translates to:
  /// **'اكتب المسافة والسعر، أو كارتة، عشان تشوف النصيب.'**
  String get calcErrorZero;

  /// SA11: total above the limit.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ ده كبير أوي.'**
  String get calcErrorTooLarge;

  /// SA11: any other invalid input.
  ///
  /// In ar, this message translates to:
  /// **'راجع الأرقام اللي فوق.'**
  String get calcErrorRange;

  /// SA11: button: open the add-expense form filled in.
  ///
  /// In ar, this message translates to:
  /// **'اعمل المصروف'**
  String get calcCreateExpense;

  /// SA11: under the create button: nothing is saved yet.
  ///
  /// In ar, this message translates to:
  /// **'هتراجعه قبل ما يتحفظ.'**
  String get calcCreateHint;

  /// SA11: title of the prefilled fuel expense.
  ///
  /// In ar, this message translates to:
  /// **'بنزين، {km} كم'**
  String calcDraftFuelTitle(String km);

  /// SA11: title of the prefilled expense when there is only tolls.
  ///
  /// In ar, this message translates to:
  /// **'كارتة'**
  String get calcDraftTollsTitle;

  /// SA11: title of the prefilled ride expense.
  ///
  /// In ar, this message translates to:
  /// **'مشوار مشترك'**
  String get calcDraftRideTitle;

  /// SA12: menu item and button that fill the bill from a receipt photo.
  ///
  /// In ar, this message translates to:
  /// **'تصوير الإيصال'**
  String get scanReceiptAction;

  /// SA12: one-line explanation under the scan menu item.
  ///
  /// In ar, this message translates to:
  /// **'الأصناف تتكتب من الصورة، وانت بتراجع كل رقم.'**
  String get scanReceiptHint;

  /// SA12: title of the camera/gallery sheet.
  ///
  /// In ar, this message translates to:
  /// **'صورة الإيصال'**
  String get scanSourceTitle;

  /// SA12: take a photo with the camera.
  ///
  /// In ar, this message translates to:
  /// **'صوّر دلوقتي'**
  String get scanSourceCamera;

  /// SA12: pick a photo from the gallery.
  ///
  /// In ar, this message translates to:
  /// **'اختار من المعرض'**
  String get scanSourceGallery;

  /// SA12: fall back to typing the items by hand.
  ///
  /// In ar, this message translates to:
  /// **'اكتب بإيدك'**
  String get scanTypeManually;

  /// SA12: progress text while the photo is read.
  ///
  /// In ar, this message translates to:
  /// **'بنقرأ الإيصال…'**
  String get scanReading;

  /// SA12: progress hint.
  ///
  /// In ar, this message translates to:
  /// **'ممكن ياخد كام ثانية.'**
  String get scanReadingHint;

  /// SA12: title of the scan failure sheet.
  ///
  /// In ar, this message translates to:
  /// **'مقدرناش نقرأ الإيصال'**
  String get scanErrorTitle;

  /// SA12: failure, no internet.
  ///
  /// In ar, this message translates to:
  /// **'مفيش إنترنت. اتصل وجرب تاني، أو اكتب الأصناف بنفسك.'**
  String get scanErrorOffline;

  /// SA12: failure, timeout.
  ///
  /// In ar, this message translates to:
  /// **'أخد وقت طويل. جرب تاني، أو اكتب الأصناف بنفسك.'**
  String get scanErrorTimeout;

  /// SA12: failure, free quota used up.
  ///
  /// In ar, this message translates to:
  /// **'القراءة المجانية خلصت دلوقتي. جرب بعدين، أو اكتب الأصناف بنفسك.'**
  String get scanErrorQuota;

  /// SA12: failure, App Check or permission refused.
  ///
  /// In ar, this message translates to:
  /// **'قراءة الإيصال مش متاحة على التليفون ده دلوقتي. اكتب الأصناف بنفسك.'**
  String get scanErrorPermission;

  /// SA12: failure, nothing readable in the photo.
  ///
  /// In ar, this message translates to:
  /// **'ملقيناش أصناف في الصورة دي. صوّر الإيصال مستقيم وواضح أكتر، أو اكتب الأصناف بنفسك.'**
  String get scanErrorPhoto;

  /// SA12: failure, the answer was not valid.
  ///
  /// In ar, this message translates to:
  /// **'الرد مكانش مفهوم. جرب تاني، أو اكتب الأصناف بنفسك.'**
  String get scanErrorInvalid;

  /// SA12: failure, the daily limit of 20 scans was reached.
  ///
  /// In ar, this message translates to:
  /// **'وصلت للحد النهاردة: 20 إيصال. اكتب الأصناف بنفسك، أو صوّر بكرة.'**
  String get scanErrorCap;

  /// SA12: failure, scanning is not available.
  ///
  /// In ar, this message translates to:
  /// **'قراءة الإيصال مش متاحة دلوقتي. اكتب الأصناف بنفسك.'**
  String get scanErrorUnavailable;

  /// SA12: retry the scan.
  ///
  /// In ar, this message translates to:
  /// **'جرب تاني'**
  String get scanTryAgain;

  /// SA12: consent screen title.
  ///
  /// In ar, this message translates to:
  /// **'قبل ما تصوّر'**
  String get scanConsentTitle;

  /// SA12: consent, what is sent and to whom.
  ///
  /// In ar, this message translates to:
  /// **'صورة الإيصال بتتبعت لجوجل (Gemini) عشان تتقرأ. مفيش حاجة تانية بتتبعت: لا أسماء ولا بيانات المجموعة.'**
  String get scanConsentSent;

  /// SA12: consent, free-tier data use (A146).
  ///
  /// In ar, this message translates to:
  /// **'ده بيستخدم الخدمة المجانية من جوجل. ممكن جوجل تستخدم اللي بتبعته لتحسين منتجاتها، وممكن ناس تراجعه. متصوّرش حاجة خاصة.'**
  String get scanConsentFree;

  /// SA12: consent, the photo is not kept.
  ///
  /// In ar, this message translates to:
  /// **'قسمة مش بتحتفظ بالصورة. بتتمسح بعد القراءة على طول.'**
  String get scanConsentKept;

  /// SA12: consent, how to avoid it.
  ///
  /// In ar, this message translates to:
  /// **'مش لازم تصوّر. تقدر دايمًا تكتب الأصناف بنفسك.'**
  String get scanConsentAvoid;

  /// SA12: consent, it can be revoked in the profile.
  ///
  /// In ar, this message translates to:
  /// **'تقدر توقّف ده في أي وقت من الملف الشخصي.'**
  String get scanConsentRevoke;

  /// SA12: consent, agree.
  ///
  /// In ar, this message translates to:
  /// **'موافق، كمّل'**
  String get scanConsentAccept;

  /// SA12: consent, decline and type manually.
  ///
  /// In ar, this message translates to:
  /// **'اكتب بإيدك بدل كده'**
  String get scanConsentDecline;

  /// SA12: profile switch title.
  ///
  /// In ar, this message translates to:
  /// **'قراءة الإيصالات'**
  String get scanProfileTitle;

  /// SA12: profile switch, on.
  ///
  /// In ar, this message translates to:
  /// **'شغّالة. الصورة بتتبعت لجوجل عشان تتقرأ.'**
  String get scanProfileOn;

  /// SA12: profile switch, off.
  ///
  /// In ar, this message translates to:
  /// **'مقفولة. هنسألك قبل المرة الجاية.'**
  String get scanProfileOff;

  /// SA12: profile switch, hidden after repeated permission errors.
  ///
  /// In ar, this message translates to:
  /// **'مش متاحة دلوقتي. اكتب الأصناف بنفسك.'**
  String get scanProfileHidden;

  /// SA12: confirm replacing typed items.
  ///
  /// In ar, this message translates to:
  /// **'تستبدل الأصناف؟'**
  String get scanReplaceTitle;

  /// SA12: confirm replacing typed items, body.
  ///
  /// In ar, this message translates to:
  /// **'القراءة هتستبدل الأصناف اللي كتبتها.'**
  String get scanReplaceBody;

  /// SA12: confirm replacing typed items, button.
  ///
  /// In ar, this message translates to:
  /// **'استبدل'**
  String get scanReplaceConfirm;

  /// SA12: the bill total equals the printed total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي زي إجمالي الإيصال ({total}).'**
  String scanTotalMatches(String total);

  /// SA12: the bill total differs from the printed total.
  ///
  /// In ar, this message translates to:
  /// **'الإجمالي مش زي إجمالي الإيصال ({total}). راجع المبالغ.'**
  String scanTotalDiffers(String total);

  /// SA12: some amounts could not be read.
  ///
  /// In ar, this message translates to:
  /// **'في مبالغ مقدرناش نقرأها. راجع الأصناف المعلّمة.'**
  String get scanFlaggedHint;

  /// SA17: a printed quantity could not be read; those items opened as quantity 1.
  ///
  /// In ar, this message translates to:
  /// **'في كميات مقدرناش نقرأها فكتبناها 1. راجع الكميات.'**
  String get scanQuantityCheck;

  /// SA17: a quantity above 1 was printed without a unit price; the line total was entered with quantity 1.
  ///
  /// In ar, this message translates to:
  /// **'في أصناف عليها كمية من غير سعر الوحدة. كتبنا إجمالي السطر والكمية 1، راجعها.'**
  String get scanUnitPriceCheck;

  /// SA17: a discount was read from the receipt and filled in.
  ///
  /// In ar, this message translates to:
  /// **'لقينا خصم على الإيصال وحطيناه. راجعه.'**
  String get scanDiscountFound;

  /// SA17: the discount was printed as a percentage and an amount; the percentage was kept.
  ///
  /// In ar, this message translates to:
  /// **'الخصم مكتوب نسبة ومبلغ مع بعض. استخدمنا النسبة، راجعها.'**
  String get scanDiscountPercentKept;

  /// SA17: a discount as large as the items total (or 100%) was left out.
  ///
  /// In ar, this message translates to:
  /// **'في خصم على الإيصال بس مش أصغر من إجمالي الأصناف، فمحطيناهوش. اكتبه بنفسك لو محتاجه.'**
  String get scanDiscountDropped;

  /// SA17: the title and/or category were filled from the receipt.
  ///
  /// In ar, this message translates to:
  /// **'كتبنا الاسم أو النوع من الإيصال. غيّرهم لو مش مظبوطين.'**
  String get scanTitleCategorySuggested;

  /// SA12: more than 100 items, the rest were dropped.
  ///
  /// In ar, this message translates to:
  /// **'الإيصال فيه أكتر من 100 صنف. قرأنا أول 100 بس.'**
  String get scanTruncated;

  /// SA16: assignment mode, one card per item.
  ///
  /// In ar, this message translates to:
  /// **'حسب الصنف'**
  String get expenseItzModeByItem;

  /// SA16: assignment mode, choose a person then tick items.
  ///
  /// In ar, this message translates to:
  /// **'حسب الشخص'**
  String get expenseItzModeByPerson;

  /// SA16: screen-reader label of the mode switch.
  ///
  /// In ar, this message translates to:
  /// **'طريقة توزيع الأصناف'**
  String get expenseItzModeLabel;

  /// SA16: item quantity.
  ///
  /// In ar, this message translates to:
  /// **'الكمية'**
  String get expenseItzQuantityLabel;

  /// SA16: stepper button.
  ///
  /// In ar, this message translates to:
  /// **'قلّل الكمية'**
  String get expenseItzQuantityMinus;

  /// SA16: stepper button.
  ///
  /// In ar, this message translates to:
  /// **'زوّد الكمية'**
  String get expenseItzQuantityPlus;

  /// SA16: spoken stepper value.
  ///
  /// In ar, this message translates to:
  /// **'الكمية {n}'**
  String expenseItzQuantitySpoken(String n);

  /// SA16: quantity error.
  ///
  /// In ar, this message translates to:
  /// **'الكمية من 1 لـ 999.'**
  String get expenseItzQuantityInvalid;

  /// SA16: price field when quantity is above 1.
  ///
  /// In ar, this message translates to:
  /// **'سعر الوحدة'**
  String get expenseItzUnitPriceLabel;

  /// SA16: screen-reader suffix of a required field.
  ///
  /// In ar, this message translates to:
  /// **'مطلوب'**
  String get expenseItzRequired;

  /// Open item card: label of the typed price line.
  ///
  /// In ar, this message translates to:
  /// **'سعر الصنف'**
  String get expenseItzLineLabel;

  /// By person: closes the inline add-item form.
  ///
  /// In ar, this message translates to:
  /// **'إلغاء'**
  String get expenseItzAddItemCancel;

  /// SA16: quantity times unit price, shown as typed (never multiplied).
  ///
  /// In ar, this message translates to:
  /// **'{qty} × {price}'**
  String expenseItzLineTimes(String qty, String price);

  /// SA16: tooltip of the item menu.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الصنف'**
  String get expenseItzItemMenu;

  /// SA16: spoken item menu.
  ///
  /// In ar, this message translates to:
  /// **'خيارات الصنف {n}'**
  String expenseItzItemMenuSpoken(String n);

  /// SA16: item menu.
  ///
  /// In ar, this message translates to:
  /// **'تكرار الصنف'**
  String get expenseItzDuplicate;

  /// SA16: item menu (quantity above 1).
  ///
  /// In ar, this message translates to:
  /// **'وزّع الوحدات على الأشخاص'**
  String get expenseItzSplitUnits;

  /// SA16: item menu.
  ///
  /// In ar, this message translates to:
  /// **'حذف الصنف'**
  String get expenseItzDeleteItem;

  /// SA16: snackbar after deleting an item.
  ///
  /// In ar, this message translates to:
  /// **'اتحذف الصنف.'**
  String get expenseItzItemDeleted;

  /// SA16: snackbar action.
  ///
  /// In ar, this message translates to:
  /// **'تراجع'**
  String get expenseItzUndo;

  /// SA16: split sheet title.
  ///
  /// In ar, this message translates to:
  /// **'وزّع الوحدات'**
  String get expenseItzSplitTitle;

  /// SA16: split sheet subtitle.
  ///
  /// In ar, this message translates to:
  /// **'اكتب كام وحدة من «{name}» لكل شخص (الإجمالي {n}). هيتحوّل لصنف لكل شخص.'**
  String expenseItzSplitHint(String name, String n);

  /// SA16: units not yet given to anyone.
  ///
  /// In ar, this message translates to:
  /// **'فاضل {n} وحدة'**
  String expenseItzSplitRemaining(String n);

  /// SA16: more units than the item has.
  ///
  /// In ar, this message translates to:
  /// **'زيادة {n} وحدة'**
  String expenseItzSplitOver(String n);

  /// SA16: split matches the quantity.
  ///
  /// In ar, this message translates to:
  /// **'كل الوحدات موزّعة'**
  String get expenseItzSplitMatches;

  /// SA16: split sheet button.
  ///
  /// In ar, this message translates to:
  /// **'تقسيم'**
  String get expenseItzSplitConfirm;

  /// SA16: spoken row of the split sheet.
  ///
  /// In ar, this message translates to:
  /// **'{name}: {n} وحدة'**
  String expenseItzSplitPersonSpoken(String name, String n);

  /// SA16: assignee summary chip when everyone shares.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get expenseItzSummaryAll;

  /// SA16: summary chip with nobody chosen.
  ///
  /// In ar, this message translates to:
  /// **'اختر المشاركين'**
  String get expenseItzSummaryNone;

  /// SA16: more people than avatars.
  ///
  /// In ar, this message translates to:
  /// **'+{n}'**
  String expenseItzSummaryMore(String n);

  /// SA16: spoken summary chip.
  ///
  /// In ar, this message translates to:
  /// **'المشاركون: {names}. اضغط للتعديل.'**
  String expenseItzSummarySpoken(String names);

  /// Picker title; the item name is the subtitle.
  ///
  /// In ar, this message translates to:
  /// **'مين شارك في الصنف ده؟'**
  String get expenseItzPickerTitleShort;

  /// SA16: picker sheet title.
  ///
  /// In ar, this message translates to:
  /// **'مين شارك في «{item}»؟'**
  String expenseItzPickerTitle(String item);

  /// SA16: picker search field.
  ///
  /// In ar, this message translates to:
  /// **'دوّر على عضو'**
  String get expenseItzPickerSearch;

  /// SA16: select everyone.
  ///
  /// In ar, this message translates to:
  /// **'الكل'**
  String get expenseItzPickerAll;

  /// SA16: clear the selection.
  ///
  /// In ar, this message translates to:
  /// **'لا أحد'**
  String get expenseItzPickerNone;

  /// SA16: picker selection count.
  ///
  /// In ar, this message translates to:
  /// **'{n} من {total}'**
  String expenseItzPickerCount(String n, String total);

  /// SA16: sticky confirm button of the picker.
  ///
  /// In ar, this message translates to:
  /// **'تم ({n})'**
  String expenseItzPickerDone(String n);

  /// SA16: empty search result.
  ///
  /// In ar, this message translates to:
  /// **'مفيش حد بالاسم ده.'**
  String get expenseItzPickerNoResults;

  /// SA16: person selector label.
  ///
  /// In ar, this message translates to:
  /// **'اختر الشخص'**
  String get expenseItzPersonPick;

  /// SA16: by-person hint.
  ///
  /// In ar, this message translates to:
  /// **'علّم الأصناف اللي شارك فيها {name}.'**
  String expenseItzPersonHint(String name);

  /// SA16: by-person: tick everything.
  ///
  /// In ar, this message translates to:
  /// **'كل الأصناف'**
  String get expenseItzPersonAllItems;

  /// SA16: by-person: clear everything.
  ///
  /// In ar, this message translates to:
  /// **'ولا صنف'**
  String get expenseItzPersonNoItems;

  /// SA16: flag of an item with nobody.
  ///
  /// In ar, this message translates to:
  /// **'«{item}» لم يشارك فيه أحد'**
  String expenseItzPersonUnassigned(String item);

  /// SA16: by-person with no items.
  ///
  /// In ar, this message translates to:
  /// **'أضف أصناف الأول.'**
  String get expenseItzPersonNoItemsYet;

  /// SA16: charges card title.
  ///
  /// In ar, this message translates to:
  /// **'الخصم والتوصيل والخدمة والضريبة'**
  String get expenseItzChargesTitle;

  /// SA16: discount row.
  ///
  /// In ar, this message translates to:
  /// **'الخصم'**
  String get expenseItzDiscountLabel;

  /// SA16: percent toggle label.
  ///
  /// In ar, this message translates to:
  /// **'%'**
  String get expenseItzModePercent;

  /// SA16: amount toggle label.
  ///
  /// In ar, this message translates to:
  /// **'ج.م'**
  String get expenseItzModeAmount;

  /// SA16: spoken toggle.
  ///
  /// In ar, this message translates to:
  /// **'{title}: نسبة مئوية أم مبلغ'**
  String expenseItzModeSpoken(String title);

  /// SA16: spoken percent option.
  ///
  /// In ar, this message translates to:
  /// **'نسبة مئوية'**
  String get expenseItzModePercentSpoken;

  /// SA16: spoken amount option.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ بالجنيه'**
  String get expenseItzModeAmountSpoken;

  /// SA16: charge amount box label.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ (ج.م)'**
  String get expenseItzAmountLabel;

  /// SA16: charge amount hint.
  ///
  /// In ar, this message translates to:
  /// **'مثال 50'**
  String get expenseItzAmountHint;

  /// SA16: discount rate error.
  ///
  /// In ar, this message translates to:
  /// **'اكتب خصم من 0.01 لـ 99.99%.'**
  String get expenseItzDiscountPercentInvalid;

  /// SA16: charge amount error.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مبلغ صحيح أكبر من صفر.'**
  String get expenseItzChargeAmountInvalid;

  /// SA16: discount amount error.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مبلغ الخصم.'**
  String get expenseItzDiscountNeedsAmount;

  /// SA16: note after the printed-total tolerance set the adjustment.
  ///
  /// In ar, this message translates to:
  /// **'تم ضبط فرق {x} قرش تلقائيًا لمطابقة إجمالي الإيصال'**
  String expenseItzAutoAdjusted(String x);

  /// SA16: spoken expand.
  ///
  /// In ar, this message translates to:
  /// **'عرض تفاصيل {name}'**
  String expenseItzExpandPerson(String name);

  /// SA16: spoken collapse.
  ///
  /// In ar, this message translates to:
  /// **'إخفاء تفاصيل {name}'**
  String expenseItzCollapsePerson(String name);

  /// SA16: share breakdown part: discount.
  ///
  /// In ar, this message translates to:
  /// **'خصم {amount}'**
  String expenseItzPartDiscount(String amount);

  /// SA16: bottom bar count of missing fields.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{حقل واحد ناقص} =2{حقلان ناقصان} few{{count} حقول ناقصة} many{{count} حقلًا ناقصًا} other{{count} حقل ناقص}}'**
  String expenseItzMissingCount(int count);

  /// SA16: primary button of the restaurant bill (add).
  ///
  /// In ar, this message translates to:
  /// **'حفظ الفاتورة'**
  String get expenseItzSave;

  /// SA16: note under the items title.
  ///
  /// In ar, this message translates to:
  /// **'الحقول اللي عليها * مطلوبة.'**
  String get expenseItzRequiredFieldsNote;

  /// SA16: details: discount row.
  ///
  /// In ar, this message translates to:
  /// **'خصم'**
  String get expenseItzDetailsDiscount;

  /// SA16: details: first names and how many more.
  ///
  /// In ar, this message translates to:
  /// **'{names} +{n}'**
  String expenseItzAssigneesMore(String names, String n);

  /// SA16: details: expand.
  ///
  /// In ar, this message translates to:
  /// **'عرض كل الأسماء'**
  String get expenseItzAssigneesExpandSpoken;

  /// SA16: details: collapse.
  ///
  /// In ar, this message translates to:
  /// **'عرض أقل'**
  String get expenseItzAssigneesCollapseSpoken;

  /// A180: delivery charge row label.
  ///
  /// In ar, this message translates to:
  /// **'التوصيل'**
  String get expenseItzDeliveryLabel;

  /// A180: delivery hint with the server's per-person amount.
  ///
  /// In ar, this message translates to:
  /// **'بتتقسم بالتساوي على اللي معاهم أصناف: {amount} لكل واحد'**
  String expenseItzDeliveryHint(String amount);

  /// A180: delivery hint when the parts differ by the leftover piaster.
  ///
  /// In ar, this message translates to:
  /// **'بتتقسم بالتساوي على اللي معاهم أصناف: من {min} لـ {max} لكل واحد'**
  String expenseItzDeliveryHintRange(String min, String max);

  /// A180: delivery part in a person's breakdown line.
  ///
  /// In ar, this message translates to:
  /// **'توصيل {amount}'**
  String expensePartDelivery(String amount);

  /// A171: the discount is not below the items total (the server refused the bill).
  ///
  /// In ar, this message translates to:
  /// **'الخصم لازم يكون أقل من إجمالي الأصناف.'**
  String get expenseItzDiscountTooLarge;

  /// Redesign: title of the list of problems shown after Save.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{في حاجة لازم تتصلّح قبل الحفظ} =2{في حاجتين لازم تتصلّحوا قبل الحفظ} few{في {count} حاجات لازم تتصلّح قبل الحفظ} many{في {count} حاجة لازم تتصلّح قبل الحفظ} other{في {count} حاجة لازم تتصلّح قبل الحفظ}}'**
  String expenseItzSummaryTitle(int count);

  /// Redesign: hint under the list of problems.
  ///
  /// In ar, this message translates to:
  /// **'اضغط على أي حاجة عشان توصلها'**
  String get expenseItzSummaryHint;

  /// Redesign: problem row, the bill has no items.
  ///
  /// In ar, this message translates to:
  /// **'أضف صنف واحد على الأقل'**
  String get expenseItzIssueItemsEmpty;

  /// Redesign: problem row, an item without a name.
  ///
  /// In ar, this message translates to:
  /// **'اسم الصنف رقم {n}'**
  String expenseItzIssueItemName(String n);

  /// Redesign: problem row, an item price.
  ///
  /// In ar, this message translates to:
  /// **'سعر الصنف: {item}'**
  String expenseItzIssueItemPrice(String item);

  /// Redesign: problem row, an item quantity.
  ///
  /// In ar, this message translates to:
  /// **'كمية الصنف: {item}'**
  String expenseItzIssueItemQuantity(String item);

  /// Redesign: problem row, an item nobody shares.
  ///
  /// In ar, this message translates to:
  /// **'الصنف مش متقسم على حد: {item}'**
  String expenseItzIssueItemMembers(String item);

  /// Warning above the itemized bill while some items have no member.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{فيه صنف واحد لسه مش متقسم على حد} other{فيه {count} أصناف لسه مش متقسمة على حد}}'**
  String expenseItzUnassignedWarning(int count);

  /// Redesign: spoken label of a collapsed item row.
  ///
  /// In ar, this message translates to:
  /// **'افتح {item}'**
  String expenseItzItemExpandSpoken(String item);

  /// Redesign: spoken label of the collapse button of an open item.
  ///
  /// In ar, this message translates to:
  /// **'اقفل {item}'**
  String expenseItzItemCollapseSpoken(String item);

  /// Redesign: spoken hint of a collapsed item that has a problem.
  ///
  /// In ar, this message translates to:
  /// **'الصنف ناقص بيانات'**
  String get expenseItzItemNeedsFixing;

  /// Redesign: label above the members button of an item.
  ///
  /// In ar, this message translates to:
  /// **'مين شارك؟'**
  String get expenseItzWhoShared;

  /// Redesign: picker mode, everyone selected shares the item equally.
  ///
  /// In ar, this message translates to:
  /// **'بالتساوي'**
  String get expenseItzPickerModeEqual;

  /// Redesign: picker mode, each person gets a number of units.
  ///
  /// In ar, this message translates to:
  /// **'حسب الكمية'**
  String get expenseItzPickerModeQuantity;

  /// Redesign: units given so far in the picker.
  ///
  /// In ar, this message translates to:
  /// **'وزّعت {x} من {n}'**
  String expenseItzPickerDistributed(String x, String n);

  /// Redesign: quantity times the typed unit price, as typed.
  ///
  /// In ar, this message translates to:
  /// **'الكمية {qty} × {price}'**
  String expenseItzPickerQtyLine(String qty, String price);

  /// Redesign: set every unit count back to zero.
  ///
  /// In ar, this message translates to:
  /// **'مسح الكل'**
  String get expenseItzPickerClearAll;

  /// Redesign: footer of the picker, who got what.
  ///
  /// In ar, this message translates to:
  /// **'{names}'**
  String expenseItzPickerSelectedNames(String names);

  /// Redesign: hint at the top of the by-person mode.
  ///
  /// In ar, this message translates to:
  /// **'ضيف لكل شخص الأصناف اللي أكلها. لو صنف مشترك، استخدم «نسخ صنف موجود».'**
  String get expenseItzPersonByPersonHint;

  /// Redesign: by person, add an item for this person.
  ///
  /// In ar, this message translates to:
  /// **'إضافة صنف لـ {name}'**
  String expenseItzAddItemFor(String name);

  /// Redesign: by person, label of the existing-items chips.
  ///
  /// In ar, this message translates to:
  /// **'نسخ صنف موجود'**
  String get expenseItzCopyItem;

  /// Redesign: by person, spoken chip that puts an existing item on this person.
  ///
  /// In ar, this message translates to:
  /// **'ضيف «{item}» لـ {name}'**
  String expenseItzCopyItemSpoken(String item, String name);

  /// Redesign: by person, tooltip of the remove button of an item row.
  ///
  /// In ar, this message translates to:
  /// **'شيل «{item}» من {name}'**
  String expenseItzPersonRemoveItem(String item, String name);

  /// Redesign: by person, folded section of members with no item.
  ///
  /// In ar, this message translates to:
  /// **'أعضاء من غير أصناف ({n})'**
  String expenseItzMembersWithoutItems(String n);

  /// Redesign: by person, a card of a member who has no item.
  ///
  /// In ar, this message translates to:
  /// **'من غير أصناف'**
  String get expenseItzPersonNoItemsLine;

  /// Redesign: split method row, everyone.
  ///
  /// In ar, this message translates to:
  /// **'بالتساوي على كل الأعضاء'**
  String get expenseFormSplitSubtitleAll;

  /// Redesign: split method row, selected members.
  ///
  /// In ar, this message translates to:
  /// **'بالتساوي على ناس محددين'**
  String get expenseFormSplitSubtitleSelected;

  /// Redesign: split method row, exact amounts.
  ///
  /// In ar, this message translates to:
  /// **'كل واحد بمبلغ محدد'**
  String get expenseFormSplitSubtitleExact;

  /// Redesign: split method row, restaurant bill.
  ///
  /// In ar, this message translates to:
  /// **'كل صنف وليه ناسه'**
  String get expenseFormSplitSubtitleItemized;

  /// Redesign: change button of the payer row and the split method row.
  ///
  /// In ar, this message translates to:
  /// **'تغيير'**
  String get expenseFormChange;

  /// Split method row: shares (SA19).
  ///
  /// In ar, this message translates to:
  /// **'كل واحد بعدد حصص، وممكن بأيام الإقامة'**
  String get expenseFormSplitSubtitleShares;

  /// Shares editor: header of the list of people.
  ///
  /// In ar, this message translates to:
  /// **'الأشخاص'**
  String get sharesPeopleTitle;

  /// Shares editor: opens the member picker.
  ///
  /// In ar, this message translates to:
  /// **'عدّل الأشخاص'**
  String get sharesEditPeople;

  /// Shares editor: title of the member picker.
  ///
  /// In ar, this message translates to:
  /// **'مين بيشارك؟'**
  String get sharesPickerTitle;

  /// Shares editor: one-line explanation.
  ///
  /// In ar, this message translates to:
  /// **'اللي حصصه أكتر بيدفع أكتر.'**
  String get sharesHint;

  /// Shares editor: nobody selected.
  ///
  /// In ar, this message translates to:
  /// **'اختار شخص واحد على الأقل.'**
  String get sharesNeedPeople;

  /// Shares: one unit.
  ///
  /// In ar, this message translates to:
  /// **'حصة واحدة'**
  String get sharesUnitsOne;

  /// Shares: two units.
  ///
  /// In ar, this message translates to:
  /// **'حصتين'**
  String get sharesUnitsTwo;

  /// Shares: 3 to 10 units.
  ///
  /// In ar, this message translates to:
  /// **'{count} حصص'**
  String sharesUnitsFew(String count);

  /// Shares: 11 or more units.
  ///
  /// In ar, this message translates to:
  /// **'{count} حصة'**
  String sharesUnitsMany(String count);

  /// Stepper label (spoken) of a person's shares.
  ///
  /// In ar, this message translates to:
  /// **'الحصص'**
  String get sharesStepperLabel;

  /// Stepper button.
  ///
  /// In ar, this message translates to:
  /// **'قلّل الحصص'**
  String get sharesStepperMinus;

  /// Stepper button.
  ///
  /// In ar, this message translates to:
  /// **'زوّد الحصص'**
  String get sharesStepperPlus;

  /// Shares editor: switch title and details tag.
  ///
  /// In ar, this message translates to:
  /// **'فترة الفاتورة'**
  String get sharesPeriodTitle;

  /// Shares editor: switch subtitle.
  ///
  /// In ar, this message translates to:
  /// **'لو فيه حد قعد جزء من الفترة بس'**
  String get sharesPeriodSubtitle;

  /// Shares editor: opens the date range picker.
  ///
  /// In ar, this message translates to:
  /// **'حدّد الفترة'**
  String get sharesPeriodPick;

  /// Shares editor: opens the date range picker again.
  ///
  /// In ar, this message translates to:
  /// **'غيّر الفترة'**
  String get sharesPeriodChange;

  /// A date range as typed by the user or sent by the server.
  ///
  /// In ar, this message translates to:
  /// **'{from} – {to}'**
  String sharesRange(String from, String to);

  /// Details and history: the billing period.
  ///
  /// In ar, this message translates to:
  /// **'فترة الفاتورة: {range}'**
  String sharesPeriodLine(String range);

  /// Shares editor: label of a person's presence.
  ///
  /// In ar, this message translates to:
  /// **'أيام الإقامة'**
  String get sharesDaysPresent;

  /// Shares editor: the person is there for the whole billing period.
  ///
  /// In ar, this message translates to:
  /// **'الفترة كلها'**
  String get sharesFullPeriod;

  /// Shares editor: opens the range picker for a person.
  ///
  /// In ar, this message translates to:
  /// **'حدّد أيام الإقامة'**
  String get sharesPresencePick;

  /// Shares editor: clears a person's presence range.
  ///
  /// In ar, this message translates to:
  /// **'ارجع للفترة كلها'**
  String get sharesPresenceReset;

  /// Spoken label of the presence control.
  ///
  /// In ar, this message translates to:
  /// **'أيام إقامة {name}'**
  String sharesPresenceFor(String name);

  /// Details and editor: a person's presence range.
  ///
  /// In ar, this message translates to:
  /// **'أيام الإقامة: {range}'**
  String sharesDaysPresentLine(String range);

  /// Shares editor: the server refused the units.
  ///
  /// In ar, this message translates to:
  /// **'الحصص من 1 لـ 100.'**
  String get sharesErrUnits;

  /// Shares editor: the server refused the presence range.
  ///
  /// In ar, this message translates to:
  /// **'أيام الإقامة لازم تبقى جوه فترة الفاتورة.'**
  String get sharesErrPresence;

  /// Shares editor: the server refused the billing period.
  ///
  /// In ar, this message translates to:
  /// **'فترة الفاتورة مش مظبوطة. اختار أول وآخر يوم تاني.'**
  String get sharesErrPeriod;

  /// Screen-reader label of a person row with the server amount.
  ///
  /// In ar, this message translates to:
  /// **'{name}، {units}، نصيبه {amount}'**
  String sharesRowSpoken(String name, String units, String amount);

  /// Screen-reader label of a person row before the amount is known.
  ///
  /// In ar, this message translates to:
  /// **'{name}، {units}'**
  String sharesRowSpokenNoAmount(String name, String units);

  /// History: a person with units and presence.
  ///
  /// In ar, this message translates to:
  /// **'{name} · {units} · {range}'**
  String sharesHistoryRow(String name, String units, String range);

  /// History: a person with units.
  ///
  /// In ar, this message translates to:
  /// **'{name} · {units}'**
  String sharesHistoryRowNoRange(String name, String units);

  /// Member options: default shares for a shares split.
  ///
  /// In ar, this message translates to:
  /// **'الحصة الافتراضية'**
  String get membersActionDefaultShare;

  /// Member options: hint when none is set.
  ///
  /// In ar, this message translates to:
  /// **'بتتحط تلقائي لما التقسيم بالحصص'**
  String get membersActionDefaultShareHint;

  /// Member options: hint with the current default share.
  ///
  /// In ar, this message translates to:
  /// **'الحالية: {units}'**
  String membersDefaultShareCurrent(String units);

  /// Default share sheet: title.
  ///
  /// In ar, this message translates to:
  /// **'الحصة الافتراضية لـ {name}'**
  String memberDefaultShareTitle(String name);

  /// Default share sheet: explanation.
  ///
  /// In ar, this message translates to:
  /// **'بتتحط تلقائي لما تقسم بالحصص، وتقدر تغيّرها في كل مصروف.'**
  String get memberDefaultShareBody;

  /// Default share sheet: clears it.
  ///
  /// In ar, this message translates to:
  /// **'امسح الحصة الافتراضية'**
  String get memberDefaultShareClear;

  /// SA20: title of the pool card on the group home (the budget card says 'budget left').
  ///
  /// In ar, this message translates to:
  /// **'رصيد الصندوق'**
  String get poolBalanceLabel;

  /// SA20: edit-group section title for the trip budget.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية'**
  String get budgetSectionTitle;

  /// SA20: one-line explanation under the budget section title.
  ///
  /// In ar, this message translates to:
  /// **'حدّدوا ميزانية للرحلة وتابعوا الصرف. دي للمتابعة بس ومش بتغيّر حساب حد.'**
  String get budgetSectionHint;

  /// SA20: label of the budget amount field.
  ///
  /// In ar, this message translates to:
  /// **'مبلغ الميزانية'**
  String get budgetAmountLabel;

  /// SA20: inline error for an invalid budget amount.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مبلغ أكبر من صفر'**
  String get budgetAmountError;

  /// SA20: trip start date row.
  ///
  /// In ar, this message translates to:
  /// **'أول يوم في الرحلة (اختياري)'**
  String get budgetStartLabel;

  /// SA20: trip end date row.
  ///
  /// In ar, this message translates to:
  /// **'آخر يوم في الرحلة (اختياري)'**
  String get budgetEndLabel;

  /// SA20: a trip date that is not set.
  ///
  /// In ar, this message translates to:
  /// **'مش محدّد'**
  String get budgetDateNotSet;

  /// SA20: clears a trip date.
  ///
  /// In ar, this message translates to:
  /// **'مسح التاريخ'**
  String get budgetDateClear;

  /// Edit group: label of the field for extra budget to add on top of the current one.
  ///
  /// In ar, this message translates to:
  /// **'زوّد الميزانية'**
  String get budgetTopUpLabel;

  /// Edit group: button that adds the typed amount to the budget amount.
  ///
  /// In ar, this message translates to:
  /// **'إضافة'**
  String get budgetTopUpAction;

  /// Edit group: hint under the add-to-budget field.
  ///
  /// In ar, this message translates to:
  /// **'المبلغ بيتضاف على الميزانية اللي فوق. اضغط حفظ عشان يتثبّت.'**
  String get budgetTopUpHint;

  /// Edit group: inline error for the amount to add.
  ///
  /// In ar, this message translates to:
  /// **'اكتب مبلغ أكبر من صفر وميعدّيش الحد الأقصى للميزانية'**
  String get budgetTopUpError;

  /// SA20: removes the budget from the group.
  ///
  /// In ar, this message translates to:
  /// **'مسح الميزانية'**
  String get budgetClear;

  /// SA20: title of the budget card on the group home.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية المتبقية'**
  String get budgetCardTitle;

  /// SA20: spent versus budget line.
  ///
  /// In ar, this message translates to:
  /// **'اتصرف {spent} من {budget}'**
  String budgetSpentOf(String spent, String budget);

  /// SA20: progress text next to the bar (uncapped).
  ///
  /// In ar, this message translates to:
  /// **'{percent} من الميزانية'**
  String budgetProgress(String percent);

  /// SA20: said in words when the spending is above the budget.
  ///
  /// In ar, this message translates to:
  /// **'تخطّيتوا الميزانية بـ {amount}'**
  String budgetOverBy(String amount);

  /// SA20: screen-reader label of the budget card.
  ///
  /// In ar, this message translates to:
  /// **'تفاصيل الميزانية'**
  String get budgetOpenDetails;

  /// SA20: budget screen title.
  ///
  /// In ar, this message translates to:
  /// **'الميزانية'**
  String get budgetScreenTitle;

  /// SA20: average spending per elapsed day.
  ///
  /// In ar, this message translates to:
  /// **'متوسط الصرف في اليوم'**
  String get budgetDailyAverage;

  /// SA20: the number of days the daily average covers.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{على يوم واحد} =2{على يومين} few{على {count} أيام} many{على {count} يوم} other{على {count} يوم}}'**
  String budgetOverDays(int count);

  /// SA20: what is left per remaining day.
  ///
  /// In ar, this message translates to:
  /// **'تقدروا تصرفوا في اليوم'**
  String get budgetPerDayLeft;

  /// SA20: days left in the trip.
  ///
  /// In ar, this message translates to:
  /// **'{count, plural, =1{باقي يوم واحد} =2{باقي يومين} few{باقي {count} أيام} many{باقي {count} يوم} other{باقي {count} يوم}}'**
  String budgetDaysLeft(int count);

  /// SA20: the budget divided over the active members, an estimate.
  ///
  /// In ar, this message translates to:
  /// **'نصيب الفرد من الميزانية (تقريبًا)'**
  String get budgetCostPerHead;

  /// SA20: says the per-person figure is not anyone's real share.
  ///
  /// In ar, this message translates to:
  /// **'تقدير بس: نصيب كل واحد الفعلي على حسب تقسيم كل مصروف.'**
  String get budgetCostPerHeadHint;

  /// SA20: heading of the per-day spending list.
  ///
  /// In ar, this message translates to:
  /// **'الصرف في كل يوم'**
  String get budgetPerDayTitle;

  /// SA20: empty state of the per-day list.
  ///
  /// In ar, this message translates to:
  /// **'لسه مفيش مصاريف.'**
  String get budgetNoExpenses;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
