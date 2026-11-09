import 'package:qesma_api/qesma_api.dart';

import '../../../core/money/money.dart';
import 'expense_form_state.dart';

/// Fills the edit form from a saved expense, or null for an itemized bill (built in FL6).
///
/// EQUAL is "All" only when the saved participants are exactly today's members; otherwise it
/// is "Selected" with exactly those participants, so a member who joined later is shown
/// unchecked and never added silently (spec 7.9). Numbers are the saved server numbers.
ExpenseFormState? formFromExpense(
  ExpenseView expense, {
  required List<String> memberIds,
  required String? fallbackPayerId,
}) {
  if (expense.splitType == 'ITEMIZED') return null;

  final shareIds = {for (final s in expense.shares) s.memberId};
  final everyone = shareIds.length == memberIds.length && memberIds.every(shareIds.contains);

  final payers = expense.payers.toList();
  final single = payers.length == 1;

  final exact = expense.splitType == 'EXACT';
  return ExpenseFormState(
    title: expense.title,
    amountText: Money.formatPlain(expense.totalMinor),
    date: expense.expenseDate,
    singlePayerId: single ? payers.first.memberId : fallbackPayerId,
    splitMode: exact
        ? SplitMode.exact
        : everyone
            ? SplitMode.all
            : SplitMode.selected,
    selectedIds: shareIds,
    exactTexts: exact ? {for (final s in expense.shares) s.memberId: Money.formatPlain(s.owedMinor)} : const {},
    payerMode: single ? PayerMode.single : PayerMode.multiple,
    payerTexts: single ? const {} : {for (final p in payers) p.memberId: Money.formatPlain(p.amountMinor)},
  );
}
