import 'package:qesma_api/qesma_api.dart';

import '../../../core/money/money.dart';
import 'expense_draft.dart';
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
    category: expense.category,
    categoryTouched: true,
    paidFromPool: expense.paidFromPool,
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
  final discount = charges?.discount;
  final service = charges?.service;
  final tax = charges?.tax;
  final adjustment = charges?.adjustmentMinor ?? 0;
  final delivery = charges?.deliveryMinor ?? 0;
  final items = expense.items?.toList() ?? const <ItemView>[];
  // A charge saved with a rate opens as a percentage; one saved as an amount opens as an amount (A171, A173).
  ChargeMode modeOf(bool on, int? bps) => on && bps == null ? ChargeMode.amount : ChargeMode.percent;
  return ItemizedDraft(
    items: [
      for (var i = 0; i < items.length; i++)
        ItemDraft(
          id: 'saved-$i',
          name: items[i].name,
          amountText: Money.formatPlain(items[i].unitAmountMinor),
          quantity: items[i].quantity,
          assigneeIds: items[i].assigneeMemberIds.toSet(),
          touched: true,
        ),
    ],
    discountOn: discount != null,
    discountMode: modeOf(discount != null, discount?.bps),
    discountPercentText: discount?.bps == null ? '' : Bps.format(discount!.bps!),
    discountAmountText: discount != null && discount.bps == null ? Money.formatPlain(discount.amountMinor) : '',
    serviceOn: service != null,
    serviceMode: modeOf(service != null, service?.bps),
    servicePercentText: service?.bps == null ? '' : Bps.format(service!.bps!),
    serviceAmountText: service != null && service.bps == null ? Money.formatPlain(service.amountMinor) : '',
    taxOn: tax != null,
    taxMode: modeOf(tax != null, tax?.bps),
    taxPercentText: tax?.bps == null ? '' : Bps.format(tax!.bps!),
    taxAmountText: tax != null && tax.bps == null ? Money.formatPlain(tax.amountMinor) : '',
    taxBase: TaxBase.fromWire(tax?.base_),
    deliveryOn: delivery > 0,
    deliveryAmountText: delivery > 0 ? Money.formatPlain(delivery) : '',
    adjustmentText: adjustment == 0 ? '' : Money.formatPlain(adjustment),
    adjustmentManual: adjustment != 0,
  );
}

/// Fills the add form from a receipt scan (SA12): itemized mode with the proposed items and charges, nobody assigned,
/// one payer (you), on [date]. The user assigns members and confirms every number; nothing is saved here. SA17: the
/// shop name becomes the title and the category guess the category (both are suggestions, and the form was empty).
ExpenseFormState formFromScan(ScanDraft draft, {required Date date, required String? payerId}) => ExpenseFormState(
      title: draft.merchantName ?? '',
      amountText: '',
      date: date,
      category: draft.category ?? 'OTHER',
      singlePayerId: payerId,
      splitMode: SplitMode.itemized,
      itemized: draft.itemized,
      printedTotalMinor: draft.printedTotalMinor,
      scanNotes: {
        ...draft.notes,
        if (draft.merchantName != null || draft.category != null) ScanNote.titleCategorySuggested,
      },
    );

/// Fills the add form from a draft (SA11): EXACT among the draft's members with its amounts, one payer, its
/// category, on [date]. Amounts are shown as plain numbers, exactly as if typed.
ExpenseFormState formFromDraft(ExpenseDraft draft, {required Date date}) => ExpenseFormState(
      title: draft.title,
      amountText: Money.formatPlain(draft.totalMinor),
      date: date,
      category: draft.category,
      singlePayerId: draft.payerId,
      splitMode: SplitMode.exact,
      selectedIds: draft.exactShares.keys.toSet(),
      exactTexts: {for (final e in draft.exactShares.entries) e.key: Money.formatPlain(e.value)},
    );
