import 'package:qesma_api/qesma_api.dart';

/// Display helpers for an [ExpenseView]. They only select and label what the server sent:
/// no amount is computed here (the one sum, [paidTotalMinor], is the payers' own list).

/// One payer: the member and what they paid.
class PayerLine {
  const PayerLine(this.memberId, this.amountMinor);

  final String memberId;
  final int amountMinor;
}

List<PayerLine> payerLines(ExpenseView expense) => [for (final p in expense.payers) PayerLine(p.memberId, p.amountMinor)];

/// What the signed-in member owes for this expense: the `shares[]` entry of
/// [yourMemberId]. Null (so nothing is shown) when they have no entry (not a participant,
/// or an itemized assignee who owes 0, A34) or when the group has no linked member.
int? yourShareMinor(ExpenseView expense, String? yourMemberId) {
  if (yourMemberId == null) return null;
  for (final share in expense.shares) {
    if (share.memberId == yourMemberId) return share.owedMinor;
  }
  return null;
}

/// Number of people the expense is divided among (`shares` rows; itemized lists only
/// members who owe more than 0).
int participantCount(ExpenseView expense) => expense.shares.length;

/// The payers' amounts added up, for the "paid in total" line. The server guarantees it
/// equals `totalMinor` (PAYERS_TOTAL_MISMATCH otherwise); it is shown as the payers' own sum.
int paidTotalMinor(ExpenseView expense) => expense.payers.fold<int>(0, (sum, p) => sum + p.amountMinor);

/// The breakdown parts of one share worth printing: only fields the server sent and that
/// are not zero (a service-only bill has no tax part). Empty for EQUAL/EXACT.
class BreakdownParts {
  const BreakdownParts({this.itemsMinor, this.serviceMinor, this.taxMinor, this.adjustmentMinor});

  final int? itemsMinor;
  final int? serviceMinor;
  final int? taxMinor;
  final int? adjustmentMinor;

  bool get isEmpty => itemsMinor == null && serviceMinor == null && taxMinor == null && adjustmentMinor == null;
}

BreakdownParts breakdownOf(ShareView share) {
  int? nonZero(int? v) => (v == null || v == 0) ? null : v;
  return BreakdownParts(
    itemsMinor: share.itemsMinor,
    serviceMinor: nonZero(share.serviceMinor),
    taxMinor: nonZero(share.taxMinor),
    adjustmentMinor: nonZero(share.adjustmentMinor),
  );
}
