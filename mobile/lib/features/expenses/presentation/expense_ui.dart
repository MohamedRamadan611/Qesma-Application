import 'package:flutter/material.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_view_model.dart';

/// Member id -> display name, from the group's member list. An id that is not in the list
/// (cannot happen while members with expenses cannot be deleted, A30) reads as "a member".
String Function(String memberId) memberNameResolver(GroupDto? group, AppLocalizations l10n) {
  final names = <String, String>{
    for (final m in group?.members ?? const <MemberDto>[]) m.id: m.displayName,
  };
  return (id) => names[id] ?? l10n.expenseUnknownMember;
}

/// `2026-10-18`, Western digits, kept left-to-right inside Arabic text.
String dateText(Date date) => ltrIsolate(date.toString());

/// Date header of the list: "Today — 2026-10-18", "Yesterday — ..." or just the date.
String dayHeaderText(AppLocalizations l10n, Date date, DateTime now) {
  final text = dateText(date);
  final today = now.toDate();
  final yesterday = DateTime(now.year, now.month, now.day - 1).toDate();
  if (date == today) return l10n.expenseDayToday(text);
  if (date == yesterday) return l10n.expenseDayYesterday(text);
  return text;
}

/// The list header as it is said ("Today — Sunday, 18 October 2026").
String dayHeaderSpoken(BuildContext context, Date date, DateTime now) {
  final l10n = AppLocalizations.of(context);
  final said = spokenDate(context, date);
  final today = now.toDate();
  final yesterday = DateTime(now.year, now.month, now.day - 1).toDate();
  if (date == today) return l10n.expenseDayToday(said);
  if (date == yesterday) return l10n.expenseDayYesterday(said);
  return said;
}

/// An amount without the currency, as in the design's payer line: "(300.00)".
String plainAmount(int minor) => ltrIsolate(Money.formatNumber(minor));

/// "Paid by Mohamed" or, with several payers, "Paid by Mohamed (300.00), Asem (261.79)".
String payersText(AppLocalizations l10n, ExpenseView expense, String Function(String) nameOf) {
  final lines = payerLines(expense);
  if (lines.length == 1) return l10n.expensePaidBy(nameOf(lines.first.memberId));
  final parts = [for (final p in lines) fsIsolate(l10n.expensePayerAmount(nameOf(p.memberId), plainAmount(p.amountMinor)))];
  return l10n.expensePaidBy(parts.join(l10n.expenseListSeparator));
}

/// Picks the right wording for a count: Arabic has a singular, a dual, 3-10 and 11+ (2 is
/// "فردين", 11 is "11 فردًا"); English uses [one] for 1 and the plural otherwise.
String countPhrase(
  int count, {
  required String one,
  required String two,
  required String Function(String count) few,
  required String Function(String count) many,
}) {
  if (count == 1) return one;
  if (count == 2) return two;
  return count <= 10 ? few('$count') : many('$count');
}

/// "Split between 3 people".
String participantsText(AppLocalizations l10n, int count) => countPhrase(
      count,
      one: l10n.expenseSplitAmongOne,
      two: l10n.expenseSplitAmongTwo,
      few: l10n.expenseSplitAmong,
      many: l10n.expenseSplitAmongMany,
    );

/// The payers for a screen reader: names with amounts in words ("300 جنيه"), no digits-only
/// numbers and no bidi control characters (they are for the eye, not for a voice).
String payersSpoken(AppLocalizations l10n, ExpenseView expense, String Function(String) nameOf) {
  final lines = payerLines(expense);
  if (lines.length == 1) return l10n.expensePaidBy(nameOf(lines.first.memberId));
  final parts = [for (final p in lines) l10n.expensePayerAmount(nameOf(p.memberId), moneySpoken(l10n, p.amountMinor))];
  return l10n.expensePaidBy(parts.join(l10n.expenseListSeparator));
}

/// A date as a person would say it ("Sunday, 18 October 2026"), from the platform's own
/// localisation, for screen readers; the screen shows the ISO form.
String spokenDate(BuildContext context, Date date) => MaterialLocalizations.of(context).formatFullDate(date.toDateTime());

// ---- shares (SA19): text only, every number and date is the server's or the user's ----

/// "حصة واحدة" / "حصتين" / "3 حصص" / "11 حصة" (Arabic has its own forms; English is "1 share" / "n shares").
String unitsText(AppLocalizations l10n, int units) => countPhrase(
      units,
      one: l10n.sharesUnitsOne,
      two: l10n.sharesUnitsTwo,
      few: (count) => l10n.sharesUnitsFew(ltrIsolate(count)),
      many: (count) => l10n.sharesUnitsMany(ltrIsolate(count)),
    );

/// The same, for a screen reader: no direction marks.
String unitsSpoken(AppLocalizations l10n, int units) => countPhrase(
      units,
      one: l10n.sharesUnitsOne,
      two: l10n.sharesUnitsTwo,
      few: l10n.sharesUnitsFew,
      many: l10n.sharesUnitsMany,
    );

/// "2026-11-12 – 2026-11-30", the dates exactly as stored (no day count).
String dateRangeText(AppLocalizations l10n, Date from, Date to) => l10n.sharesRange(dateText(from), dateText(to));

/// The range as it is said ("Thursday, 12 November 2026 – ...").
String dateRangeSpoken(BuildContext context, Date from, Date to) =>
    AppLocalizations.of(context).sharesRange(spokenDate(context, from), spokenDate(context, to));

/// "Days present: 2026-11-12 – 2026-11-30" for a share that has a presence range in the server's answer, or null.
String? presenceLineOf(AppLocalizations l10n, ShareView share) {
  final from = share.presentFrom, to = share.presentTo;
  return from == null || to == null ? null : l10n.sharesDaysPresentLine(dateRangeText(l10n, from, to));
}

/// "Billing period: ..." of an expense or preview that has one, or null.
String? periodLineOf(AppLocalizations l10n, Date? from, Date? to) =>
    from == null || to == null ? null : l10n.sharesPeriodLine(dateRangeText(l10n, from, to));

/// One compact history line for a share of a SHARES snapshot: "name · units · range".
String shareHistoryLine(AppLocalizations l10n, ShareView share, String name) {
  final from = share.presentFrom, to = share.presentTo;
  final units = unitsText(l10n, share.shareUnits ?? 1);
  return from == null || to == null
      ? l10n.sharesHistoryRowNoRange(fsIsolate(name), units)
      : l10n.sharesHistoryRow(fsIsolate(name), units, dateRangeText(l10n, from, to));
}
