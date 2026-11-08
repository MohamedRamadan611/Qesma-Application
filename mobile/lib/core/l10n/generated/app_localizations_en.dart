// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Qesma';

  @override
  String get bootstrapReady =>
      'The app is ready. Screens arrive in the next milestones.';

  @override
  String get commonRetry => 'Try again';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonOk => 'OK';

  @override
  String get commonClose => 'Close';

  @override
  String get commonBack => 'Back';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get fieldClear => 'Clear text';

  @override
  String fieldCounter(String count, String max) {
    return '$count/$max';
  }

  @override
  String get balanceOwed => 'Owed';

  @override
  String get balanceOwes => 'Owes';

  @override
  String get balanceSettled => 'Settled';

  @override
  String balanceOwedSpoken(String amount) {
    return 'Owed $amount';
  }

  @override
  String balanceOwesSpoken(String amount) {
    return 'Owes $amount';
  }

  @override
  String get balanceSettledSpoken => 'Settled, nothing due';

  @override
  String get moneyCurrency => 'EGP';

  @override
  String moneySpokenPounds(String pounds) {
    return '$pounds pounds';
  }

  @override
  String moneySpokenPoundsPiasters(String pounds, String piasters) {
    return '$pounds pounds and $piasters piasters';
  }

  @override
  String moneySpokenPiasters(String piasters) {
    return '$piasters piasters';
  }

  @override
  String moneySpokenNegative(String amount) {
    return 'minus $amount';
  }

  @override
  String get stateErrorTitle => 'Something went wrong';

  @override
  String get stateErrorMessage =>
      'We tried to do that but hit a problem. Please try again in a moment.';

  @override
  String stateErrorRequestId(String id) {
    return 'Error code: $id';
  }

  @override
  String get stateNoInternetTitle => 'No internet connection';

  @override
  String get stateNoInternetMessage =>
      'The app needs the internet to save and record expenses. Check your Wi-Fi or mobile data.';

  @override
  String get stateNoInternetReassure =>
      'Everything you recorded before is saved and will show up when you are back online.';

  @override
  String get stateOfflineBanner => 'No internet connection';

  @override
  String get errorTimeout =>
      'That took too long. Check your connection and try again.';

  @override
  String get errorNoConnection =>
      'No internet connection. Check it and try again.';

  @override
  String get errorUnexpected =>
      'Something unexpected happened. Please try again in a moment.';

  @override
  String get errorInternal =>
      'Something went wrong on our side. Please try again in a moment.';

  @override
  String get errorValidation =>
      'Some details are not right. Check the fields and try again.';

  @override
  String get errorPayersTotalMismatch =>
      'What the payers paid must add up to the expense total.';

  @override
  String get errorSplitTotalMismatch =>
      'The shares must add up to the expense total.';

  @override
  String get errorMemberNotInGroup =>
      'The member list has changed. We will refresh it and you can carry on.';

  @override
  String errorDuplicateMemberName(String name) {
    return 'The name \"$name\" already exists in this group. Try adding a surname to tell them apart.';
  }

  @override
  String get errorMemberHasTransactionsTitle => 'Can\'t delete this member';

  @override
  String get errorMemberHasTransactionsMessage =>
      'This member is part of expenses or settlements, so they can\'t be deleted.';

  @override
  String get errorGroupNotEmptyTitle => 'Can\'t delete this group';

  @override
  String get errorGroupNotEmptyMessage =>
      'This group has expenses or settlements, so it can\'t be deleted.';

  @override
  String get errorOwnerMemberProtectedTitle => 'This is your own member';

  @override
  String get errorOwnerMemberProtectedMessage =>
      'You can\'t remove yourself from the group, but you can rename yourself.';

  @override
  String get errorVersionConflictTitle => 'Changed somewhere else';

  @override
  String get errorVersionConflictMessage =>
      'Someone changed this since you opened it. We will load the latest version and you can redo your edit.';

  @override
  String get errorNotFound =>
      'This is no longer available. It may have been deleted.';

  @override
  String get errorUnauthorized => 'Please sign in again.';

  @override
  String get errorRateLimited =>
      'Too many attempts in a short time. Wait a minute and try again.';

  @override
  String get errorAuthProviderUnavailable =>
      'We can\'t reach Google right now. Please try again in a moment.';

  @override
  String get brandWordmark => 'Qesma';

  @override
  String get brandTagline =>
      'Trips, outings and shared flats: clear, smooth and awkward-free';

  @override
  String get welcomeTitle =>
      'Split group expenses for trips, outings and shared homes without the mess';

  @override
  String get welcomeValue1Title => 'Accurate to the piaster';

  @override
  String get welcomeValue1Body =>
      'Everyone gets their exact net share, nothing lost';

  @override
  String get welcomeValue2Title => 'Restaurant bills, split fairly';

  @override
  String get welcomeValue2Body =>
      'Service and tax are shared automatically between those who ate';

  @override
  String get welcomeValue3Title => 'The easiest way to settle up';

  @override
  String get welcomeValue3Body =>
      'We work out a short, practical list of transfers between friends';

  @override
  String get welcomeStart => 'Get started';

  @override
  String get legalConsentPrefix => 'By signing in you agree to the';

  @override
  String get legalTerms => 'Terms of Use';

  @override
  String get legalAnd => 'and';

  @override
  String get legalPrivacy => 'Privacy Policy';

  @override
  String get legalOpenFailed =>
      'We can\'t open the link right now. Please try again in a moment.';

  @override
  String get signInWithGoogle => 'Continue with Google';

  @override
  String get signInFailed => 'We couldn\'t sign you in. Please try again.';

  @override
  String get signInNotConfigured =>
      'Google sign-in is not configured on this device (GOOGLE_SERVER_CLIENT_ID).';

  @override
  String get devFakeSignIn => 'Debug sign-in (development only)';

  @override
  String get sessionExpiredTitle => 'Your session has ended';

  @override
  String get sessionExpiredBody =>
      'Sign in again to continue safely and keep your accounts and shared expenses protected.';

  @override
  String get sessionExpiredReassure =>
      'Your data and groups are fully saved and untouched';

  @override
  String get sessionExpiredLeave => 'Back to the start';

  @override
  String homeSignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get homeSignOut => 'Sign out';

  @override
  String get groupsTitle => 'Groups';

  @override
  String get groupsNew => 'New group';

  @override
  String get groupsMore => 'More';

  @override
  String get groupsEmptyTitle => 'No groups yet';

  @override
  String get groupsEmptyBody =>
      'Start a group and add your friends. We will do the maths.';

  @override
  String get groupsNetTotal => 'Your net across all groups';

  @override
  String get groupsRefreshFailed =>
      'We couldn\'t refresh the list. Please try again.';

  @override
  String get groupsLoadMoreFailed =>
      'We couldn\'t load the rest of your groups. Pull down to try again.';

  @override
  String get groupTypeTrip => 'Trip';

  @override
  String get groupTypeHousing => 'Housing';

  @override
  String get groupTypeOuting => 'Outing';

  @override
  String get groupTypeOther => 'Other';

  @override
  String groupLastActivity(String date) {
    return 'Last activity: $date';
  }

  @override
  String get groupNoActivity => 'No expenses yet';

  @override
  String get groupTotalSpent => 'Total spent';

  @override
  String groupMemberCount(String count) {
    return '$count members';
  }

  @override
  String get groupMemberOne => '1 member';

  @override
  String groupCardSpoken(
    String name,
    String type,
    String members,
    String total,
    String balance,
  ) {
    return '$name, $type, $members, total spent $total, $balance';
  }

  @override
  String get groupOpenFailedGone => 'This group is no longer available.';

  @override
  String get groupBackToList => 'Back to groups';

  @override
  String get groupCreateTitle => 'Create a new group';

  @override
  String get groupCreateSubtitle =>
      'A trip, a shared flat or an outing. Start with a name and a type.';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupNameHint => 'e.g. Dahab trip';

  @override
  String get groupTypeLabel => 'Group type';

  @override
  String get groupCurrencyLabel => 'Currency';

  @override
  String get groupCurrencyValue => 'Egyptian pound (EGP)';

  @override
  String get groupCurrencyNote =>
      'The currency can\'t be changed after the group is created';

  @override
  String get groupCreateButton => 'Create group';

  @override
  String get groupCreateOutcomeUnknown =>
      'We\'re not sure the group was created. We will check first before trying again, so it isn\'t duplicated.';

  @override
  String get groupEditTitle => 'Edit group';

  @override
  String groupCreatedOn(String date) {
    return 'Created: $date';
  }

  @override
  String get groupSaveChanges => 'Save changes';

  @override
  String get groupDelete => 'Delete group';

  @override
  String get groupDeleteConfirmTitle => 'Delete this group?';

  @override
  String groupDeleteConfirmBody(String name) {
    return '\"$name\" will be deleted permanently. This can\'t be undone.';
  }

  @override
  String groupBlockedTotal(String amount) {
    return 'Total recorded: $amount';
  }

  @override
  String get groupBlockedHint =>
      'Settle the accounts first, then contact support if you still need it removed.';

  @override
  String get groupConflictReload => 'Load latest version';

  @override
  String get groupConflictKeep => 'Keep my edit';

  @override
  String get groupTabExpenses => 'Expenses';

  @override
  String get groupTabBalances => 'Balances';

  @override
  String get groupTabMembers => 'Members';

  @override
  String get groupNotBuiltYet => 'This screen is not built yet.';

  @override
  String groupHeaderSubtitle(String members, String total) {
    return '$members • $total';
  }

  @override
  String get membersAdd => 'Add member';

  @override
  String get membersYouTag => '(you)';

  @override
  String membersOptions(String name) {
    return 'Options for $name';
  }

  @override
  String get membersRename => 'Rename';

  @override
  String get membersDelete => 'Delete member';

  @override
  String get memberAddTitle => 'Add a new member';

  @override
  String get memberAddSubtitle =>
      'Add your friend by name so expenses can be split with them easily.';

  @override
  String get memberNameLabel => 'Member name in this group';

  @override
  String get memberSave => 'Save member';

  @override
  String get memberRenameTitle => 'Rename member';

  @override
  String get memberDeleteConfirmTitle => 'Delete this member?';

  @override
  String memberDeleteConfirmBody(String name) {
    return '\"$name\" will be removed from the group.';
  }
}
