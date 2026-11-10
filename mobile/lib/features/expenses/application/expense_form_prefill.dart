import 'package:qesma_api/qesma_api.dart';

import '../../../core/money/money.dart';
import 'expense_form_state.dart';

/// Fills the edit form from a saved expense.
///
/// EQUAL is "All" only when the saved participants are exactly today's members; otherwise it
/// is "Selected" with exactly those participants, so a member who joined later is shown
/// unchecked and never added silently (spec 7.9). A restaurant bill opens with its items,
/// service and tax percentages (1200 bps shown as "12"), tax base and adjustment, and with the
/// saved total as the server's total for those unchanged inputs. Numbers are the saved server numbers.
ExpenseFormState formFromExpense(
  ExpenseView expense, {
  required List<String> memberIds,
  required String? fallbackPayerId,
}) {
  final shareIds = {for (final s in expense.shares) s.memberId};
  final everyone = shareIds.length == memberIds.length && memberIds.every(shareIds.contains);

  final payers = expense.payers.toList();
  final single = payers.length == 1;

  final itemized = expense.splitType == 'ITEMIZED';
  final exact = expense.splitType == 'EXACT';
  final charges = expense.charges;

  return ExpenseFormState(
    title: expense.title,
    amountText: Money.formatPlain(expense.totalMinor),
    date: expense.expenseDate,
    singlePayerId: single ? payers.first.memberId : fallbackPayerId,
    splitMode: itemized
        ? SplitMode.itemized
        : exact
            ? SplitMode.exact
            : everyone
                ? SplitMode.all
                : SplitMode.selected,
    selectedIds: shareIds,
    exactTexts: exact ? {for (final s in expense.shares) s.memberId: Money.formatPlain(s.owedMinor)} : const {},
    payerMode: single ? PayerMode.single : PayerMode.multiple,
    payerTexts: single ? const {} : {for (final p in payers) p.memberId: Money.formatPlain(p.amountMinor)},
    itemized: itemized ? _itemizedFrom(expense, charges) : const ItemizedDraft(),
    serverTotalMinor: itemized ? expense.totalMinor : null,
  );
}

ItemizedDraft _itemizedFrom(ExpenseView expense, Charges? charges) {
  final service = charges?.service;
  final tax = charges?.tax;
  final adjustment = charges?.adjustmentMinor ?? 0;
  final items = expense.items?.toList() ?? const <ItemView>[];
  return ItemizedDraft(
    items: [
      for (var i = 0; i < items.length; i++)
        ItemDraft(
          id: 'saved-$i',
          name: items[i].name,
          amountText: Money.formatPlain(items[i].amountMinor),
          assigneeIds: items[i].assigneeMemberIds.toSet(),
          touched: true,
        ),
    ],
    serviceOn: service != null,
    servicePercentText: service == null ? '' : Bps.format(service.bps),
    taxOn: tax != null,
    taxPercentText: tax == null ? '' : Bps.format(tax.bps),
    taxBase: TaxBase.fromWire(tax?.base_),
    adjustmentText: adjustment == 0 ? '' : Money.formatPlain(adjustment),
  );
}
