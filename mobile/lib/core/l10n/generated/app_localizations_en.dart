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
  String get stateOfflineBanner => 'You are offline';

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
  String get errorForbidden => 'Your role in this group does not allow that.';

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

  @override
  String get expensesEmptyTitle => 'No expenses yet';

  @override
  String get expensesEmptyBody =>
      'Add the first expense and split it with the group.';

  @override
  String get expensesAdd => 'Add expense';

  @override
  String get expensesNoMatchTitle => 'No matching expenses';

  @override
  String get expensesNoMatchBody => 'Try changing or clearing the filters.';

  @override
  String get expensesClearFilters => 'Clear filters';

  @override
  String get expensesLoadMoreFailed => 'Could not load more expenses.';

  @override
  String get expensesRefreshFailed =>
      'Could not refresh. Showing the last copy we have.';

  @override
  String get expenseFilterDate => 'Date';

  @override
  String get expenseFilterMember => 'Member';

  @override
  String get expenseFilterAll => 'All';

  @override
  String expenseFilterRange(String from, String to) {
    return '$from to $to';
  }

  @override
  String expenseFilterFrom(String from) {
    return 'From $from';
  }

  @override
  String expenseFilterUntil(String to) {
    return 'Until $to';
  }

  @override
  String expenseFilterRemove(String label) {
    return 'Remove filter: $label';
  }

  @override
  String get expenseFilterDateTitle => 'Filter by date';

  @override
  String get expenseFilterFromLabel => 'From date';

  @override
  String get expenseFilterToLabel => 'To date';

  @override
  String get expenseFilterPickDate => 'Pick a date';

  @override
  String get expenseFilterApply => 'Apply';

  @override
  String get expenseFilterClear => 'Clear';

  @override
  String get expenseFilterRangeInvalid =>
      'The start date must be before the end date.';

  @override
  String get expenseFilterMemberTitle => 'Filter by member';

  @override
  String get expenseFilterMemberHint =>
      'Shows the expenses this member paid or shared in.';

  @override
  String get expenseFilterAllMembers => 'All members';

  @override
  String expenseDayToday(String date) {
    return 'Today — $date';
  }

  @override
  String expenseDayYesterday(String date) {
    return 'Yesterday — $date';
  }

  @override
  String expensePaidBy(String payers) {
    return 'Paid by $payers';
  }

  @override
  String expensePayerAmount(String name, String amount) {
    return '$name ($amount)';
  }

  @override
  String get expenseListSeparator => ', ';

  @override
  String get expenseUnknownMember => 'A member';

  @override
  String get expenseSplitAmongOne => 'For one person';

  @override
  String expenseSplitAmong(String count) {
    return 'Split between $count people';
  }

  @override
  String expenseYourShare(String amount) {
    return 'Your share: $amount';
  }

  @override
  String expenseCardSpoken(
    String title,
    String total,
    String split,
    String payers,
    String participants,
  ) {
    return '$title, $total, $split, $payers, $participants';
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
    return '$title, $total, $split, $payers, $participants, $share';
  }

  @override
  String get expenseSplitEqual => 'Equal';

  @override
  String get expenseSplitExact => 'Exact amounts';

  @override
  String get expenseSplitItemized => 'Itemized bill';

  @override
  String get expenseDetailsTitle => 'Expense details';

  @override
  String get expenseDetailsTotal => 'Expense total';

  @override
  String expenseEditedBadge(String version) {
    return 'Edited (version $version)';
  }

  @override
  String get expensePayersTitle => 'Paid by';

  @override
  String get expensePayersCountOne => '1 payer';

  @override
  String expensePayersCount(String count) {
    return '$count payers';
  }

  @override
  String expensePaidTotal(String amount) {
    return 'Total paid: $amount';
  }

  @override
  String get expenseItemsTitle => 'Items and charges';

  @override
  String get expenseItemsCountOne => '1 item';

  @override
  String expenseItemsCount(String count) {
    return '$count items';
  }

  @override
  String get expenseSubtotal => 'Items subtotal';

  @override
  String get expenseServiceLabel => 'Service charge';

  @override
  String get expenseTaxLabel => 'Tax';

  @override
  String get expenseTaxBaseSubtotal => 'on the items subtotal';

  @override
  String get expenseTaxBaseSubtotalPlusService => 'on items + service';

  @override
  String get expenseAdjustmentLabel => 'Adjustment';

  @override
  String get expenseBillTotal => 'Bill total';

  @override
  String expensePercent(String rate) {
    return '$rate%';
  }

  @override
  String get expenseBreakdownTitle => 'Each person’s share';

  @override
  String get expenseBreakdownCountOne => '1 person';

  @override
  String expenseBreakdownCount(String count) {
    return '$count people';
  }

  @override
  String expensePartItems(String amount) {
    return 'items $amount';
  }

  @override
  String expensePartService(String amount) {
    return 'service $amount';
  }

  @override
  String expensePartTax(String amount) {
    return 'tax $amount';
  }

  @override
  String expensePartAdjustment(String amount) {
    return 'adjustment $amount';
  }

  @override
  String get expenseEdit => 'Edit expense';

  @override
  String get expenseEditItemized => 'Edit bill and items';

  @override
  String get expenseDelete => 'Delete expense';

  @override
  String get expenseHistory => 'Edit history';

  @override
  String get expenseDeleteConfirmTitle => 'Delete this expense?';

  @override
  String expenseDeleteConfirmBody(String title) {
    return '“$title” will be removed from the expenses and balances.';
  }

  @override
  String get expenseDeleted => 'Expense deleted.';

  @override
  String get expenseAlreadyDeleted => 'This expense was already deleted.';

  @override
  String get expenseGoneTitle => 'This expense is no longer available';

  @override
  String get expenseBackToList => 'Back to expenses';

  @override
  String expenseHistoryVersion(String version) {
    return 'Version $version';
  }

  @override
  String get expenseChangeCreate => 'Created';

  @override
  String get expenseChangeUpdate => 'Edited';

  @override
  String get expenseChangeDelete => 'Deleted';

  @override
  String expenseHistoryTotal(String amount) {
    return 'Total: $amount';
  }

  @override
  String get expenseConflictTitle => 'This expense was edited';

  @override
  String get expenseConflictBody =>
      'Someone edited this expense since you opened it. Load the latest version and check it before deleting.';

  @override
  String get expensesRefresh => 'Refresh the list';

  @override
  String get expenseHistoryEmpty =>
      'There is no edit history for this expense.';

  @override
  String expenseAssignedTo(String names) {
    return 'Assigned to: $names';
  }

  @override
  String get expenseSplitUnknown => 'Split';

  @override
  String get expenseSplitAmongTwo => 'Split between 2 people';

  @override
  String expenseSplitAmongMany(String count) {
    return 'Split between $count people';
  }

  @override
  String get expensePayersCountTwo => '2 payers';

  @override
  String expensePayersCountMany(String count) {
    return '$count payers';
  }

  @override
  String get expenseItemsCountTwo => '2 items';

  @override
  String expenseItemsCountMany(String count) {
    return '$count items';
  }

  @override
  String get expenseBreakdownCountTwo => '2 people';

  @override
  String expenseBreakdownCountMany(String count) {
    return '$count people';
  }

  @override
  String get expenseFormTitleLabel => 'Expense name';

  @override
  String get expenseFormTitleHint => 'For example: dinner, petrol, tickets';

  @override
  String get expenseFormTitleRequired => 'Enter a name for the expense.';

  @override
  String get expenseFormAmountLabel => 'Total amount';

  @override
  String get expenseFormAmountHint => 'For example 250 or 99.50';

  @override
  String get expenseFormAmountInvalid => 'Enter a valid amount above zero.';

  @override
  String get expenseFormCurrencyNote => 'Currency: Egyptian pound (EGP)';

  @override
  String get expenseFormDateLabel => 'Date';

  @override
  String get expenseFormPaidByTitle => 'Who paid?';

  @override
  String get expenseFormEditPayers => 'Edit payers';

  @override
  String get expenseFormPayersMismatch =>
      'What the payers paid does not match the total. Edit the payers.';

  @override
  String get expenseFormSplitTitle => 'How to split';

  @override
  String get expenseFormSplitAll => 'Everyone';

  @override
  String get expenseFormSplitSelected => 'Selected';

  @override
  String expenseFormMemberSpoken(String name, String amount) {
    return '$name, share $amount';
  }

  @override
  String expenseFormMemberUnchecked(String name) {
    return '$name, not included';
  }

  @override
  String get expenseFormShareLoading => 'Working out the shares…';

  @override
  String get expenseFormShareFailed => 'Could not work out the shares.';

  @override
  String get expenseFormShareNeedAmount => 'Enter the total to see the shares.';

  @override
  String get expenseFormExactHint =>
      'You can edit each member’s share, or spread it equally again.';

  @override
  String expenseFormExactAmountLabel(String name) {
    return '$name’s share';
  }

  @override
  String get expenseFormSpreadEqually => 'Spread equally';

  @override
  String expenseFormExactSummary(String sum, String total) {
    return 'Split total: $sum of $total';
  }

  @override
  String expenseFormExactRemaining(String amount) {
    return '$amount left to split';
  }

  @override
  String expenseFormExactOver(String amount) {
    return '$amount over the total';
  }

  @override
  String get expenseFormExactMatches => 'Matches the total';

  @override
  String get expenseFormSave => 'Save expense';

  @override
  String get expenseFormSaveChanges => 'Save changes';

  @override
  String get expenseFormLeaveTitle => 'Leave without saving?';

  @override
  String get expenseFormLeaveBody => 'What you entered will be lost.';

  @override
  String get expenseFormLeaveConfirm => 'Leave';

  @override
  String get expenseFormLeaveKeep => 'Keep editing';

  @override
  String get expenseFormConflictTitle => 'This expense was edited';

  @override
  String get expenseFormConflictBody =>
      'Someone edited this expense since you opened it. Load the latest version; what you entered stays as it is. Then save again.';

  @override
  String get expenseFormConflictNote =>
      'Someone edited this expense. Your changes are still here, and saving replaces their version.';

  @override
  String get expenseFormSaveRetry => 'Save again';

  @override
  String get expenseFormOutcomeUnknown =>
      'We are not sure the expense was saved. Saving again will not create a duplicate.';

  @override
  String get expensePayersSheetTitle => 'Who paid the bill?';

  @override
  String get expensePayersSheetSubtitle =>
      'Pick who paid and how much each person paid.';

  @override
  String get expensePayersTotalLabel => 'Bill total due';

  @override
  String get expensePayersNeedTotal => 'Enter the total amount first.';

  @override
  String expensePayersRemaining(String amount) {
    return 'Left to assign: $amount';
  }

  @override
  String expensePayersOver(String amount) {
    return '$amount more than the bill';
  }

  @override
  String get expensePayersMatched => 'The total matches the bill';

  @override
  String get expensePayersChecking => 'Checking the total with the server…';

  @override
  String get expensePayersServerMismatch =>
      'The server says the total does not match. Check the amounts.';

  @override
  String get expensePayersSplitEqually => 'Split equally among the payers';

  @override
  String get expensePayersClear => 'Clear amounts';

  @override
  String get expensePayersEntered => 'Total entered';

  @override
  String expensePayersConfirm(String amount) {
    return 'Confirm payers ($amount)';
  }

  @override
  String expensePayersAmountLabel(String name) {
    return 'Paid by $name';
  }

  @override
  String expensePayersRowSpoken(String name, String amount) {
    return '$name, paid $amount';
  }

  @override
  String expensePayersRowUnchecked(String name) {
    return '$name, did not pay';
  }

  @override
  String get expensePayersFailed =>
      'Could not work out the equal split. Try again.';

  @override
  String get expenseFormSaved => 'Expense saved.';

  @override
  String get expenseItemizedTotalNote =>
      'Worked out from the items, service and tax.';

  @override
  String get expenseItemizedItemsTitle => 'Bill items';

  @override
  String expenseItemizedItemHeading(String n) {
    return 'Item $n';
  }

  @override
  String get expenseItemizedNameLabel => 'Item name';

  @override
  String get expenseItemizedNameHint => 'For example: pizza';

  @override
  String get expenseItemizedNameRequired => 'Enter the item name.';

  @override
  String get expenseItemizedAmountLabel => 'Item price';

  @override
  String get expenseItemizedAmountInvalid => 'Enter a valid price above zero.';

  @override
  String get expenseItemizedAssigneesLabel => 'Who shared this item?';

  @override
  String get expenseItemizedNoAssignee => 'Choose at least one person.';

  @override
  String get expenseItemizedAdd => 'Add an item';

  @override
  String get expenseItemizedLimit => 'You reached the limit: 100 items.';

  @override
  String get expenseItemizedRemove => 'Remove item';

  @override
  String expenseItemizedRemoveSpoken(String n) {
    return 'Remove item $n';
  }

  @override
  String get expenseItemizedChargesTitle => 'Service and tax';

  @override
  String get expenseItemizedPercentLabel => 'Rate (%)';

  @override
  String get expenseItemizedPercentHint => 'For example 12';

  @override
  String get expenseItemizedPercentInvalid =>
      'Enter a rate from 0 to 100 with at most two decimals.';

  @override
  String get expenseItemizedTaxBaseTitle => 'Tax is applied to';

  @override
  String get expenseItemizedTaxBaseSubtotal => 'Items only';

  @override
  String get expenseItemizedTaxBaseWithService => 'Items + service';

  @override
  String get expenseItemizedAdjustmentTitle => 'Rounding / tip';

  @override
  String get expenseItemizedAdjustmentHint =>
      'To settle fractions or a tip. It can be negative.';

  @override
  String get expenseItemizedAdjustmentInvalid =>
      'Enter a valid amount (it can be negative).';

  @override
  String get expenseItemizedAdjustmentPlus => 'Add one piaster';

  @override
  String get expenseItemizedAdjustmentMinus => 'Subtract one piaster';

  @override
  String get expenseItemizedLoading => 'Working out the bill…';

  @override
  String get expenseItemizedFailed => 'Could not work out the bill.';

  @override
  String get expenseItemizedIncomplete =>
      'Complete the items and rates to see the numbers.';

  @override
  String get expenseItemizedPayersMatch => 'The payers match the bill';

  @override
  String get expenseItemizedPayersMismatch =>
      'The payers do not match the bill. Edit the payers.';

  @override
  String get expenseItemizedPayersChecking => 'Checking the payers…';

  @override
  String get expenseItemizedBarTotal => 'Calculated bill total';

  @override
  String get expensePayersNeedItems => 'Complete the bill items first.';

  @override
  String get balancesTotalSpent => 'Group total spent';

  @override
  String get balancesNeedOne => '1 transfer needed to settle up';

  @override
  String get balancesNeedTwo => '2 transfers needed to settle up';

  @override
  String balancesNeed(String count) {
    return '$count transfers needed to settle up';
  }

  @override
  String balancesNeedMany(String count) {
    return '$count transfers needed to settle up';
  }

  @override
  String get balancesAllSettledTitle => 'Everyone is settled up';

  @override
  String get balancesAllSettledBody => 'Nobody owes anyone anything right now.';

  @override
  String get balancesSuggestedTitle => 'Suggested transfers';

  @override
  String get balancesPays => 'Pays';

  @override
  String get balancesReceives => 'Receives';

  @override
  String balancesTransferSpoken(String from, String to, String amount) {
    return '$from pays $to $amount';
  }

  @override
  String get balancesRecordPayment => 'Record payment';

  @override
  String balancesRecordPaymentSpoken(String from, String to, String amount) {
    return 'Record payment from $from to $to, $amount';
  }

  @override
  String get balancesRecordAnother => 'Record another payment';

  @override
  String get balancesNetsTitle => 'Net balance per member';

  @override
  String balancesMemberSpoken(String name, String status) {
    return '$name, $status';
  }

  @override
  String get balancesHistoryTitle => 'Payment history';

  @override
  String get balancesHistoryEmpty => 'No payments recorded yet.';

  @override
  String balancesPaymentTitle(String from, String to) {
    return '$from paid $to';
  }

  @override
  String balancesPaymentSpoken(
    String from,
    String to,
    String amount,
    String date,
  ) {
    return '$from paid $to $amount, $date';
  }

  @override
  String balancesPaymentNoteSpoken(String base, String note) {
    return '$base, $note';
  }

  @override
  String get balancesLoadMore => 'Load more';

  @override
  String get balancesLoadMoreFailed => 'We could not load more payments.';

  @override
  String get balancesRefresh => 'Refresh balances';

  @override
  String get balancesRefreshFailed =>
      'We could not refresh the balances. This is the last copy we have.';

  @override
  String get paymentSubtitle => 'Settle up between group members';

  @override
  String get paymentFrom => 'From (payer)';

  @override
  String get paymentTo => 'To (receiver)';

  @override
  String get paymentPickMember => 'Choose a member';

  @override
  String get paymentAmountLabel => 'Amount paid (EGP)';

  @override
  String get paymentAmountError =>
      'Enter a valid amount above zero, with up to 2 decimals.';

  @override
  String paymentFullAmount(String amount) {
    return 'Full amount: $amount';
  }

  @override
  String get paymentDateLabel => 'Payment date';

  @override
  String get paymentDateError => 'Choose a date between 2000 and 2100.';

  @override
  String get paymentNoteLabel => 'Note (optional)';

  @override
  String get paymentNoteHint => 'e.g. cash on the trip';

  @override
  String get paymentNoteError => 'The note is longer than 200 characters.';

  @override
  String get paymentSameMember => 'Choose two different members.';

  @override
  String paymentConfirm(String amount) {
    return 'Confirm payment ($amount)';
  }

  @override
  String get paymentConfirmNoAmount => 'Confirm payment';

  @override
  String get paymentRecorded => 'Payment recorded.';

  @override
  String get paymentDiscardTitle => 'Discard this payment?';

  @override
  String get paymentDiscardBody => 'What you entered will not be saved.';

  @override
  String get paymentDiscardConfirm => 'Discard';

  @override
  String get profileTitle => 'Account';

  @override
  String get profileEdit => 'Edit profile';

  @override
  String get profileGroupsOne => '1 group';

  @override
  String get profileGroupsTwo => '2 groups';

  @override
  String profileGroups(String count) {
    return '$count groups';
  }

  @override
  String profileGroupsMany(String count) {
    return '$count groups';
  }

  @override
  String get profileSectionPrefs => 'Preferences';

  @override
  String get profileSectionAbout => 'About the app';

  @override
  String get profileLanguage => 'App language';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageSheetTitle => 'Choose a language';

  @override
  String get profileAccountSettings => 'Account settings';

  @override
  String get profileVersion => 'App version';

  @override
  String get profileSignOutTitle => 'Sign out?';

  @override
  String get profileSignOutBody =>
      'You will need to sign in with Google again to come back.';

  @override
  String get profileEditTitle => 'Edit profile';

  @override
  String get profileNameLabel => 'Display name';

  @override
  String get profileNameHint =>
      'Your friends see this name in groups and expenses.';

  @override
  String get profileNameRequired =>
      'Enter your name so your friends recognise you.';

  @override
  String get profileNameTooLong => 'The name is longer than 60 characters.';

  @override
  String get profileEmailLabel => 'Email';

  @override
  String get profileEmailLocked =>
      'Linked to your Google account and cannot be edited by hand.';

  @override
  String get profileSave => 'Save changes';

  @override
  String get profileSaved => 'Name saved.';

  @override
  String get profileDiscardTitle => 'Discard changes?';

  @override
  String get profileDiscardBody => 'The new name will not be saved.';

  @override
  String get profileDiscardConfirm => 'Discard';

  @override
  String get accountGoogleTitle => 'Connected Google account';

  @override
  String get accountConnected => 'Connected';

  @override
  String get profileAppearance => 'Appearance';

  @override
  String get appearanceSheetTitle => 'Choose appearance';

  @override
  String get appearanceSystem => 'Follow phone';

  @override
  String get appearanceLight => 'Light';

  @override
  String get appearanceDark => 'Dark';

  @override
  String get authUsernameContinue => 'Continue with username';

  @override
  String get authUsernameSignInTitle => 'Sign in with username';

  @override
  String get authUsernameSignInButton => 'Sign in';

  @override
  String get authRegisterTitle => 'Create an account';

  @override
  String get authRegisterButton => 'Create account';

  @override
  String get authGoRegister => 'No account yet? Create one';

  @override
  String get authGoSignIn => 'Already have an account? Sign in';

  @override
  String get fieldUsername => 'Username';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPasswordShow => 'Show password';

  @override
  String get fieldPasswordHide => 'Hide password';

  @override
  String get fieldDisplayNameOptional => 'Name (optional)';

  @override
  String get authPasswordRules =>
      'At least 8 characters, and not a common password.';

  @override
  String get authErrorUsernameInvalid =>
      'A username is 3 to 30 characters: letters, digits, dots and hyphens, with no spaces or @.';

  @override
  String get authErrorPasswordShort =>
      'The password must be at least 8 characters.';

  @override
  String get authErrorPasswordLong =>
      'The password is too long. The limit is 72 bytes (about 36 Arabic letters).';

  @override
  String get authErrorWrongCredentials =>
      'The username or password is not right. Try again.';

  @override
  String get authErrorUsernameTaken =>
      'This username is taken. Choose another one or sign in.';

  @override
  String get authErrorPasswordRejected =>
      'This password is not accepted. Choose a stronger, less common one.';

  @override
  String get profileChangePassword => 'Change password';

  @override
  String get passwordChangeTitle => 'Change password';

  @override
  String get passwordCurrentLabel => 'Current password';

  @override
  String get passwordNewLabel => 'New password';

  @override
  String get passwordChangeButton => 'Save password';

  @override
  String get passwordChanged =>
      'Password changed. Your other devices were signed out.';

  @override
  String get passwordCurrentWrong =>
      'The current password is wrong, or the new one is not accepted (too common).';

  @override
  String get accountSignedInWithPassword =>
      'Signed in with username and password';

  @override
  String get inviteAction => 'Invite members';

  @override
  String get inviteSheetTitle => 'Invite people to the group';

  @override
  String inviteSheetSubtitle(String group) {
    return 'Group “$group”';
  }

  @override
  String get inviteSheetIntro =>
      'Share the code or the link with your friends so they can see the balances and add their expenses.';

  @override
  String get inviteCodeLabel => 'Join code';

  @override
  String get inviteCopyCode => 'Copy code';

  @override
  String get inviteCodeCopied => 'Code copied';

  @override
  String get inviteCopyLink => 'Copy link';

  @override
  String get inviteLinkCopied => 'Link copied';

  @override
  String get inviteShareLink => 'Share link';

  @override
  String inviteShareText(String group, String link, String code) {
    return 'Join the group “$group” on Qesma:\n$link\nOr enter the code: $code';
  }

  @override
  String inviteExpiresIn(String duration) {
    return 'Expires in $duration';
  }

  @override
  String get inviteExpiresSoon => 'Expires in less than an hour';

  @override
  String get inviteExpiryChoiceLabel => 'How long the new invite lasts';

  @override
  String get inviteApprovalTitle => 'Needs admin approval';

  @override
  String get inviteApprovalBody =>
      'An admin reviews each new person before they get in';

  @override
  String get inviteApprovalTag => 'Admin approval';

  @override
  String get inviteCreateNew => 'Create a new invite';

  @override
  String get inviteCreate => 'Create invite';

  @override
  String get inviteCreated => 'Invite created';

  @override
  String get inviteRevoke => 'Cancel this invite';

  @override
  String get inviteRevokeConfirmTitle => 'Cancel this invite?';

  @override
  String get inviteRevokeConfirmBody =>
      'Nobody will be able to join with this code or link any more. People who already joined stay in the group.';

  @override
  String get inviteKeep => 'Keep it';

  @override
  String get inviteRevoked => 'Invite cancelled';

  @override
  String get inviteOtherActiveTitle => 'Other active invites';

  @override
  String get inviteNoActive =>
      'There is no active invite right now. Create one and send it to your friends.';

  @override
  String inviteUsesProgress(String used, String max) {
    return '$used of $max joined';
  }

  @override
  String inviteUsesCount(String used) {
    return 'Joined: $used';
  }

  @override
  String get inviteJoinTitle => 'Join a group';

  @override
  String inviteInvitedBy(String name) {
    return '$name invited you';
  }

  @override
  String get inviteWhoAreYou => 'Which of these members are you?';

  @override
  String get inviteWhoBody =>
      'If the organiser already added your name and recorded your expenses, pick it so your account is linked to them without duplicates.';

  @override
  String get inviteNewMember => 'I am a new member (not in the list)';

  @override
  String get inviteNewMemberBody =>
      'Your name is added as a new member of the group';

  @override
  String get inviteNameLabel => 'Your name in this group';

  @override
  String get inviteJoinButton => 'Join';

  @override
  String get inviteJoinNote =>
      'After you join you can record expenses and follow the balances with the other members.';

  @override
  String get inviteNeedsApprovalNote =>
      'An admin has to approve you before you get into this group.';

  @override
  String get inviteClaimedNotice =>
      'Someone else just took that name. Pick another one or join as a new member.';

  @override
  String get inviteExpiredTitle => 'This invite has expired';

  @override
  String get inviteExpiredBody =>
      'This invite is no longer valid. Ask a group admin for a new one.';

  @override
  String get inviteRevokedTitle => 'This invite was cancelled';

  @override
  String get inviteRevokedBody =>
      'A group admin cancelled this invite. Ask for a new one if you still want to join.';

  @override
  String get inviteNotFoundTitle => 'Invite not found';

  @override
  String get inviteNotFoundBody =>
      'Check the code and try again, or ask for a new invite.';

  @override
  String get inviteAlreadyMemberTitle => 'You are already in this group';

  @override
  String get inviteAlreadyMemberBody =>
      'You do not need an invite. Open the group from here.';

  @override
  String get inviteOpenGroup => 'Open the group';

  @override
  String get inviteWaitingTitle => 'Waiting for admin approval';

  @override
  String inviteWaitingBody(String group) {
    return 'Your request to join “$group” was sent. You get in as soon as an admin approves.';
  }

  @override
  String get inviteRefreshStatus => 'Check status';

  @override
  String get inviteStillWaiting => 'Still waiting for approval';

  @override
  String get inviteBackHome => 'Back to home';

  @override
  String get inviteEnterCodeButton => 'Have an invite code?';

  @override
  String get inviteEnterCodeTitle => 'Join with a code';

  @override
  String get inviteEnterCodeBody =>
      'Type the invite code you received, or paste the link.';

  @override
  String get inviteCodeFieldLabel => 'Invite code';

  @override
  String get inviteCodeInvalid =>
      'The code is 8 letters and digits. Check it and try again.';

  @override
  String get inviteContinue => 'Continue';

  @override
  String get inviteDayOne => '1 day';

  @override
  String get inviteDayTwo => '2 days';

  @override
  String inviteDaysFew(String count) {
    return '$count days';
  }

  @override
  String inviteDaysMany(String count) {
    return '$count days';
  }

  @override
  String get inviteHourOne => '1 hour';

  @override
  String get inviteHourTwo => '2 hours';

  @override
  String inviteHoursFew(String count) {
    return '$count hours';
  }

  @override
  String inviteHoursMany(String count) {
    return '$count hours';
  }

  @override
  String get membersBadgeConnected => 'Linked to an account';

  @override
  String get membersBadgeNameOnly => 'Name only';

  @override
  String get membersRoleOwner => 'Owner';

  @override
  String get membersRoleAdmin => 'Admin';

  @override
  String get membersLeftChip => 'Left';

  @override
  String get membersActionPromote => 'Make admin';

  @override
  String get membersActionPromoteHint =>
      'Can edit the group and manage members and invitations.';

  @override
  String get membersActionDemote => 'Remove admin';

  @override
  String get membersActionDemoteHint => 'Becomes a regular member.';

  @override
  String get membersActionUnlink => 'Unlink account';

  @override
  String get membersActionUnlinkHint =>
      'Becomes a name only; the expenses and history stay.';

  @override
  String get membersActionMarkLeft => 'Mark as left';

  @override
  String get membersActionMarkLeftHint =>
      'Stays in the list with the balance, and cannot be added to new expenses.';

  @override
  String get membersActionReactivate => 'Reactivate';

  @override
  String get membersActionReactivateHint => 'Becomes an active member again.';

  @override
  String get membersActionTransfer => 'Transfer ownership';

  @override
  String get membersActionTransferHint =>
      'They become the owner and you become an admin.';

  @override
  String memberUnlinkConfirmTitle(String name) {
    return 'Unlink the account of $name?';
  }

  @override
  String memberUnlinkConfirmBody(String name) {
    return '$name becomes a name only and loses access to the group. Their expenses and history stay, and you can invite them again.';
  }

  @override
  String get memberUnlinkConfirmAction => 'Unlink account';

  @override
  String memberMarkLeftConfirmTitle(String name) {
    return 'Mark $name as left?';
  }

  @override
  String memberMarkLeftConfirmBody(String name) {
    return '$name stays in the list with the balance, but cannot be added to new expenses.';
  }

  @override
  String get memberMarkLeftConfirmAction => 'Mark as left';

  @override
  String memberPromoteConfirmTitle(String name) {
    return 'Make $name an admin?';
  }

  @override
  String memberPromoteConfirmBody(String name) {
    return '$name will be able to edit the group and manage members and invitations.';
  }

  @override
  String get memberPromoteConfirmAction => 'Make admin';

  @override
  String memberDemoteConfirmTitle(String name) {
    return 'Remove admin from $name?';
  }

  @override
  String memberDemoteConfirmBody(String name) {
    return '$name becomes a regular member.';
  }

  @override
  String get memberDemoteConfirmAction => 'Remove admin';

  @override
  String memberReactivatedNotice(String name) {
    return '$name is active again.';
  }

  @override
  String get membersLeave => 'Leave group';

  @override
  String get groupLeaveConfirmTitle => 'Leave this group?';

  @override
  String get groupLeaveConfirmBody =>
      'Your balance stays in the group and you will no longer see it. You need a new invitation to come back.';

  @override
  String get groupLeaveConfirmAction => 'Leave group';

  @override
  String get groupLeftNotice => 'You left the group.';

  @override
  String get membersTransfer => 'Transfer ownership';

  @override
  String get memberTransferPickerTitle => 'Transfer ownership';

  @override
  String get memberTransferPickerSubtitle =>
      'Pick who becomes the owner. They must be linked to an account.';

  @override
  String get memberTransferPickerEmptyTitle => 'Nobody to transfer to';

  @override
  String get memberTransferPickerEmptyBody =>
      'Ownership goes to an active member linked to an account. Invite someone to the group first.';

  @override
  String memberTransferConfirmTitle(String name) {
    return 'Transfer ownership to $name?';
  }

  @override
  String memberTransferConfirmBody(String name) {
    return '$name becomes the owner and you become an admin. You cannot undo this yourself.';
  }

  @override
  String get memberTransferConfirmAction => 'Transfer ownership';

  @override
  String get memberTransferDoneNotice => 'Ownership was transferred.';

  @override
  String get errorOwnerMustTransferTitle => 'Transfer ownership first';

  @override
  String get errorOwnerMustTransferMessage =>
      'The owner cannot leave the group. Transfer ownership to another member, then leave.';

  @override
  String get errorMemberInactive =>
      'This member has left the group. The list was refreshed.';

  @override
  String inviteRequestsBanner(String count) {
    return 'Pending join requests: $count';
  }

  @override
  String get inviteRequestsTitle => 'Join requests';

  @override
  String get inviteRequestsEmptyTitle => 'No join requests';

  @override
  String get inviteRequestsEmptyBody =>
      'When someone uses an invitation that needs approval, the request shows up here.';

  @override
  String inviteRequestClaims(String name) {
    return 'Wants to be: $name';
  }

  @override
  String inviteRequestNewMember(String name) {
    return 'New member named $name';
  }

  @override
  String inviteRequestWhen(String when) {
    return 'Requested $when';
  }

  @override
  String get inviteRequestApprove => 'Approve';

  @override
  String get inviteRequestReject => 'Reject';

  @override
  String inviteRequestApproveLabel(String name) {
    return 'Approve the request of $name';
  }

  @override
  String inviteRequestRejectLabel(String name) {
    return 'Reject the request of $name';
  }

  @override
  String get inviteRequestClaimedNotice =>
      'That name was linked to another account. The list was refreshed.';

  @override
  String get inviteRequestDecidedNotice =>
      'Somebody already decided this request. The list was refreshed.';

  @override
  String get inviteRequestApprovedNotice => 'Request approved.';

  @override
  String get inviteRequestRejectedNotice => 'Request rejected.';

  @override
  String get inviteRequestUnknownName => 'Someone';

  @override
  String get settlementChipPending => 'Waiting for confirmation';

  @override
  String get settlementChipConfirmed => 'Confirmed';

  @override
  String get settlementChipDisputed => 'Disputed';

  @override
  String get settlementChipCancelled => 'Cancelled';

  @override
  String get settlementChipUnknown => 'Other status';

  @override
  String settlementChipSpoken(String status) {
    return 'Payment status: $status';
  }

  @override
  String get settlementByAdmin => 'Recorded by an admin';

  @override
  String get payNoMoveNote =>
      'The app does not move money — transfer from your bank or wallet app, then tap I paid.';

  @override
  String payHandlesTitle(String name) {
    return 'Payment details of $name';
  }

  @override
  String get payInstapayLabel => 'InstaPay address';

  @override
  String get payWalletLabel => 'Mobile wallet';

  @override
  String get payCopyOne => 'Copy';

  @override
  String payCopyOneSpoken(String what) {
    return 'Copy $what';
  }

  @override
  String get payCopyAll => 'Copy details';

  @override
  String get payCopied => 'Copied';

  @override
  String payNoHandles(String name) {
    return '$name has not added payment details yet. Agree on how to transfer, then tap I paid.';
  }

  @override
  String get payButton => 'I paid';

  @override
  String payButtonSpoken(String amount, String name) {
    return 'I paid $amount to $name';
  }

  @override
  String get payOnBehalf => 'Record on behalf';

  @override
  String get payReceived => 'I received it';

  @override
  String payTransferTitle(String name) {
    return 'Pay $name';
  }

  @override
  String get pendingBadge => 'A payment is waiting for confirmation';

  @override
  String pendingExplain(String pending, String amount) {
    return 'Balances count confirmed payments only. A payment of $pending is waiting for confirmation; $amount is still due until it is confirmed.';
  }

  @override
  String get disputeFlag => 'A payment is disputed';

  @override
  String get paymentTitleDeclare => 'I paid';

  @override
  String get paymentTitleReceived => 'I received it';

  @override
  String get paymentTitleOnBehalf => 'Record on behalf';

  @override
  String paymentHintPending(String name) {
    return 'It goes to $name to confirm. Balances do not change until they confirm.';
  }

  @override
  String get paymentHintConfirmed =>
      'It is recorded as confirmed and counted in the balances right away.';

  @override
  String paymentHintNoAccount(String name) {
    return '$name has no account in the app, so an admin records this payment.';
  }

  @override
  String get paymentHintNotAllowed =>
      'You can record your own payments only. An admin records for others.';

  @override
  String paymentSentPending(String name) {
    return 'Sent to $name to confirm.';
  }

  @override
  String get incomingBannerOne => 'A payment is waiting for you to confirm';

  @override
  String incomingBannerMany(String count) {
    return '$count payments are waiting for you to confirm';
  }

  @override
  String get incomingTitle => 'Payments waiting for you';

  @override
  String receiverCardTitle(String name, String amount) {
    return '$name says they paid you $amount';
  }

  @override
  String get receiverCardBody =>
      'Check your account and make sure the money arrived before you confirm.';

  @override
  String get receiverConfirm => 'Received';

  @override
  String receiverConfirmSpoken(String amount, String name) {
    return 'Confirm you received $amount from $name';
  }

  @override
  String get receiverDispute => 'Not received yet';

  @override
  String receiverDisputeSpoken(String amount, String name) {
    return 'Say you have not received $amount from $name';
  }

  @override
  String get disputeDialogTitle => 'Money has not arrived?';

  @override
  String disputeDialogBody(String name) {
    return 'We will tell $name you have not received it. The payment is not counted until it is confirmed or cancelled.';
  }

  @override
  String get disputeDialogConfirm => 'Yes, not received';

  @override
  String get cancelDialogTitle => 'Cancel this payment?';

  @override
  String get cancelDialogBody =>
      'It will be cancelled and not counted in the balances. It stays in the history as cancelled.';

  @override
  String get cancelDialogConfirm => 'Cancel payment';

  @override
  String get cancelDialogKeep => 'No, keep it';

  @override
  String get settlementConfirmedSnack =>
      'Payment confirmed and counted in the balances.';

  @override
  String get settlementDisputedSnack =>
      'Noted: you have not received the payment.';

  @override
  String get settlementCancelledSnack => 'Payment cancelled.';

  @override
  String get settlementStateChanged =>
      'This payment changed. Here is its current state.';

  @override
  String get settlementGone => 'This payment is no longer there.';

  @override
  String get settlementDetailTitle => 'Payment details';

  @override
  String get settlementDetailAmount => 'Payment amount';

  @override
  String get settlementPayerRole => 'Payer';

  @override
  String get settlementReceiverRole => 'Receiver';

  @override
  String get stmtPayerPaid => 'Says: I paid';

  @override
  String get stmtPayerCancelled => 'The payment was cancelled';

  @override
  String get stmtReceiverWaiting => 'Has not answered yet';

  @override
  String get stmtReceiverNotReceived => 'Says: not received';

  @override
  String get stmtReceiverConfirmed => 'Confirmed it arrived';

  @override
  String get stmtRecordedByAdmin => 'Recorded by an admin';

  @override
  String get detailBannerPending => 'Waiting for the receiver';

  @override
  String get detailBannerDisputed => 'This payment is disputed';

  @override
  String get detailBannerDisputedBody =>
      'Waiting for both sides to agree, or for an admin';

  @override
  String get detailBannerConfirmed => 'Confirmed and counted in the balances';

  @override
  String get detailBannerCancelled => 'Cancelled and not counted';

  @override
  String get detailNotCounted =>
      'This payment is not counted in the balances until it is confirmed.';

  @override
  String detailDeclaredAt(String when) {
    return 'Declared: $when';
  }

  @override
  String detailDisputedAt(String when) {
    return 'Dispute raised: $when';
  }

  @override
  String detailConfirmedAt(String when) {
    return 'Confirmed: $when';
  }

  @override
  String detailCancelledAt(String when) {
    return 'Cancelled: $when';
  }

  @override
  String detailDateOn(String date) {
    return 'Payment date: $date';
  }

  @override
  String get guidanceTitle => 'Resolve it in a friendly way';

  @override
  String get guidanceBody =>
      'Both sides and the admins can sort it out after checking the account statement and transfer messages. The app does not decide and does not move money.';

  @override
  String get detailConfirm => 'Confirm and receive the payment';
}
