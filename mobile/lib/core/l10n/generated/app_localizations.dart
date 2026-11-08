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
  /// **'مفيش اتصال بالإنترنت'**
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
  /// **'المجموعة فيها مصاريف أو تسويات، فمينفعش تتمسح.'**
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
  /// **'هيتمسح «{name}» نهائيًا ومش هينفع ترجّعه.'**
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

  /// Placeholder for tabs that later milestones build.
  ///
  /// In ar, this message translates to:
  /// **'الشاشة دي لسه تحت الإنشاء.'**
  String get groupNotBuiltYet;

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
