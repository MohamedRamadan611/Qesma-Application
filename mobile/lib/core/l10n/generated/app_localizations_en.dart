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
  String get balancesDeletePayment => 'Delete payment';

  @override
  String balancesDeletePaymentSpoken(String from, String to, String amount) {
    return 'Delete the payment from $from to $to, $amount';
  }

  @override
  String get balancesDeleteTitle => 'Delete this payment?';

  @override
  String get balancesDeleteBody =>
      'Balances will be recalculated without this payment. It cannot be restored.';

  @override
  String get balancesDeleted => 'Payment deleted.';

  @override
  String get balancesDeleteGone => 'This payment was already removed.';

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
}
