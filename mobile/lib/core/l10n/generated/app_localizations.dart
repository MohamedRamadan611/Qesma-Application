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

  /// Tooltip of the delete button on a history row.
  ///
  /// In ar, this message translates to:
  /// **'امسح السداد'**
  String get balancesDeletePayment;

  /// Screen-reader label of the delete button.
  ///
  /// In ar, this message translates to:
  /// **'امسح سداد {from} لـ {to}، {amount}'**
  String balancesDeletePaymentSpoken(String from, String to, String amount);

  /// Delete payment confirmation title.
  ///
  /// In ar, this message translates to:
  /// **'تمسح السداد ده؟'**
  String get balancesDeleteTitle;

  /// Delete payment confirmation body (there is no undo).
  ///
  /// In ar, this message translates to:
  /// **'الأرصدة هتتحسب من جديد من غير السداد ده، ومش هينفع نرجّعه بعد كده.'**
  String get balancesDeleteBody;

  /// Snackbar after a payment was deleted.
  ///
  /// In ar, this message translates to:
  /// **'اتمسح السداد.'**
  String get balancesDeleted;

  /// Snackbar when the payment to delete no longer exists.
  ///
  /// In ar, this message translates to:
  /// **'السداد ده كان اتمسح قبل كده.'**
  String get balancesDeleteGone;

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
  /// **'الاسم المعروض'**
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
