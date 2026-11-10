import 'package:qesma_api/qesma_api.dart';

import '../../../core/money/money.dart';
import '../../../core/widgets/code_point_limit.dart';

/// Which people share the expense and how: everyone or some members equally, typed exact
/// amounts, or a restaurant bill with items, service, tax and an adjustment (itemized).
enum SplitMode { all, selected, exact, itemized }

/// One payer who covers the whole total, or several who each type what they paid.
enum PayerMode { single, multiple }

/// The title limit of the backend (code points).
const int kExpenseTitleMax = 100;

/// Limits of an itemized bill (backend, A31).
const int kMaxItems = 100;
const int kItemNameMax = 100;

/// Rates offered when the service / tax switch is turned on (editable; never applied silently).
const String kDefaultServicePercent = '12';
const String kDefaultTaxPercent = '14';

final Date kFirstExpenseDate = Date(2000, 1, 1);
final Date kLastExpenseDate = Date(2100, 12, 31);

/// What the tax percentage is applied to (spec A1). The wire values are the API's.
enum TaxBase {
  subtotal('SUBTOTAL'),
  subtotalPlusService('SUBTOTAL_PLUS_SERVICE');

  const TaxBase(this.wire);

  final String wire;

  static TaxBase fromWire(String? value) => value == 'SUBTOTAL' ? TaxBase.subtotal : TaxBase.subtotalPlusService;
}

/// One line of a restaurant bill as the user typed it.
class ItemDraft {
  const ItemDraft({required this.id, this.name = '', this.amountText = '', this.assigneeIds = const {}, this.touched = false});

  /// Local key for the list (never sent).
  final String id;
  final String name;
  final String amountText;
  final Set<String> assigneeIds;

  /// The user has typed or chosen something in this item (errors are shown only for touched items).
  final bool touched;

  ItemDraft copyWith({String? name, String? amountText, Set<String>? assigneeIds, bool? touched}) => ItemDraft(
        id: id,
        name: name ?? this.name,
        amountText: amountText ?? this.amountText,
        assigneeIds: assigneeIds ?? this.assigneeIds,
        touched: touched ?? this.touched,
      );

  String get trimmedName => name.trim();

  bool get nameValid {
    final count = codePointCount(trimmedName);
    return count >= 1 && count <= kItemNameMax;
  }

  /// The amount in piasters (> 0), or null while empty or unreadable.
  int? get amountMinor => Money.parse(amountText);

  /// Assignees who are current members (a removed member's chip is ignored).
  Set<String> assigneesAmong(List<String> memberIds) => {for (final id in memberIds) if (assigneeIds.contains(id)) id};

  bool validFor(List<String> memberIds) => nameValid && amountMinor != null && assigneesAmong(memberIds).isNotEmpty;

  bool sameAs(ItemDraft other) =>
      id == other.id &&
      name == other.name &&
      amountText == other.amountText &&
      assigneeIds.length == other.assigneeIds.length &&
      assigneeIds.containsAll(other.assigneeIds);
}

/// The restaurant bill being edited: items, service and tax (each independently on or off, with
/// the percentage as typed), the tax base and a signed adjustment. Pure text and flags: the
/// amounts they produce come from the backend preview, never from here.
class ItemizedDraft {
  const ItemizedDraft({
    this.items = const [],
    this.serviceOn = false,
    this.servicePercentText = '',
    this.taxOn = false,
    this.taxPercentText = '',
    this.taxBase = TaxBase.subtotalPlusService,
    this.adjustmentText = '',
  });

  final List<ItemDraft> items;
  final bool serviceOn;
  final String servicePercentText;
  final bool taxOn;
  final String taxPercentText;
  final TaxBase taxBase;

  /// Signed, as typed; empty means no adjustment.
  final String adjustmentText;

  ItemizedDraft copyWith({
    List<ItemDraft>? items,
    bool? serviceOn,
    String? servicePercentText,
    bool? taxOn,
    String? taxPercentText,
    TaxBase? taxBase,
    String? adjustmentText,
  }) =>
      ItemizedDraft(
        items: items ?? this.items,
        serviceOn: serviceOn ?? this.serviceOn,
        servicePercentText: servicePercentText ?? this.servicePercentText,
        taxOn: taxOn ?? this.taxOn,
        taxPercentText: taxPercentText ?? this.taxPercentText,
        taxBase: taxBase ?? this.taxBase,
        adjustmentText: adjustmentText ?? this.adjustmentText,
      );

  /// Service rate in basis points when it is on and readable (string parsing, no floating point).
  int? get serviceBps => serviceOn ? Bps.parse(servicePercentText) : null;
  int? get taxBps => taxOn ? Bps.parse(taxPercentText) : null;

  bool get serviceValid => !serviceOn || serviceBps != null;
  bool get taxValid => !taxOn || taxBps != null;

  /// The adjustment in piasters: 0 when empty, null when unreadable.
  int? get adjustmentMinor => adjustmentText.trim().isEmpty ? 0 : Money.parse(adjustmentText, allowNegative: true, allowZero: true);

  bool get adjustmentValid => adjustmentMinor != null;

  bool itemsValid(List<String> memberIds) =>
      items.isNotEmpty && items.length <= kMaxItems && items.every((item) => item.validFor(memberIds));

  bool valid(List<String> memberIds) => itemsValid(memberIds) && serviceValid && taxValid && adjustmentValid;

  bool sameAs(ItemizedDraft other) {
    if (serviceOn != other.serviceOn ||
        servicePercentText != other.servicePercentText ||
        taxOn != other.taxOn ||
        taxPercentText != other.taxPercentText ||
        taxBase != other.taxBase ||
        adjustmentText != other.adjustmentText ||
        items.length != other.items.length) {
      return false;
    }
    for (var i = 0; i < items.length; i++) {
      if (!items[i].sameAs(other.items[i])) return false;
    }
    return true;
  }
}

/// Everything the user typed or chose on the add/edit form. Immutable; the controller
/// replaces it as a whole. Pure: no I/O and no money arithmetic beyond ADDING UP what the
/// user typed (the "remaining" indicators the spec allows). Splits, rounding, service, tax and
/// totals come from the backend preview, never from here.
class ExpenseFormState {
  const ExpenseFormState({
    required this.title,
    required this.amountText,
    required this.date,
    required this.singlePayerId,
    this.splitMode = SplitMode.all,
    this.selectedIds = const {},
    this.exactTexts = const {},
    this.payerMode = PayerMode.single,
    this.payerTexts = const {},
    this.itemized = const ItemizedDraft(),
    this.serverTotalMinor,
  });

  final String title;

  /// The total exactly as typed ("500", "1,000.50", Arabic digits all fine). Not used for a restaurant bill.
  final String amountText;
  final Date date;
  final SplitMode splitMode;

  /// Members who share the expense in Selected and Exact mode (All means every member).
  final Set<String> selectedIds;

  /// What the user typed per member in Exact mode (keys are members of [selectedIds]).
  final Map<String, String> exactTexts;
  final PayerMode payerMode;

  /// The payer in single mode (null only before the group has loaded).
  final String? singlePayerId;

  /// What each payer typed in multiple mode (a key is a selected payer).
  final Map<String, String> payerTexts;

  /// The restaurant bill (used in [SplitMode.itemized]).
  final ItemizedDraft itemized;

  /// The total the SERVER reported for the current itemized inputs (a copy of the preview's
  /// `totalMinor`). Null while the inputs changed and no answer for them has arrived yet.
  final int? serverTotalMinor;

  ExpenseFormState copyWith({
    String? title,
    String? amountText,
    Date? date,
    SplitMode? splitMode,
    Set<String>? selectedIds,
    Map<String, String>? exactTexts,
    PayerMode? payerMode,
    String? singlePayerId,
    Map<String, String>? payerTexts,
    ItemizedDraft? itemized,
    int? serverTotalMinor,
    bool clearServerTotal = false,
  }) =>
      ExpenseFormState(
        title: title ?? this.title,
        amountText: amountText ?? this.amountText,
        date: date ?? this.date,
        splitMode: splitMode ?? this.splitMode,
        selectedIds: selectedIds ?? this.selectedIds,
        exactTexts: exactTexts ?? this.exactTexts,
        payerMode: payerMode ?? this.payerMode,
        singlePayerId: singlePayerId ?? this.singlePayerId,
        payerTexts: payerTexts ?? this.payerTexts,
        itemized: itemized ?? this.itemized,
        serverTotalMinor: clearServerTotal ? null : (serverTotalMinor ?? this.serverTotalMinor),
      );

  // ---- title, total, date ----

  String get trimmedTitle => title.trim();

  bool get titleValid {
    final count = codePointCount(trimmedTitle);
    return count >= 1 && count <= kExpenseTitleMax;
  }

  /// The total in piasters: what the user typed (1..10^12) for an ordinary expense, or the
  /// server's total for a restaurant bill. Null while it is not known.
  int? get totalMinor => splitMode == SplitMode.itemized ? serverTotalMinor : Money.parse(amountText);

  bool get amountTyped => amountText.trim().isNotEmpty;

  bool get dateValid => date.compareTo(kFirstExpenseDate) >= 0 && date.compareTo(kLastExpenseDate) <= 0;

  // ---- split ----

  /// Who shares the expense, in the group's member order.
  List<String> participantIds(List<String> memberIds) =>
      splitMode == SplitMode.all ? memberIds : [for (final id in memberIds) if (selectedIds.contains(id)) id];

  /// Amount typed for [memberId] in Exact mode (0 allowed), or null when empty/invalid.
  int? exactMinorOf(String memberId) {
    final text = exactTexts[memberId];
    return text == null ? null : Money.parse(text, allowZero: true);
  }

  /// The typed Exact amounts added up (an unreadable box counts as nothing).
  int exactSum(List<String> memberIds) => participantIds(memberIds).fold<int>(0, (sum, id) => sum + (exactMinorOf(id) ?? 0));

  /// Total minus what was typed; positive = still to distribute. Null until the total is valid.
  int? exactRemaining(List<String> memberIds) {
    final total = totalMinor;
    return total == null ? null : total - exactSum(memberIds);
  }

  /// Every selected member has a readable amount, at least one is above zero and the sum is the total.
  bool exactValid(List<String> memberIds) {
    final ids = participantIds(memberIds);
    if (ids.isEmpty) return false;
    var anyPositive = false;
    for (final id in ids) {
      final minor = exactMinorOf(id);
      if (minor == null) return false;
      if (minor > 0) anyPositive = true;
    }
    return anyPositive && exactRemaining(memberIds) == 0;
  }

  bool splitValid(List<String> memberIds) => switch (splitMode) {
        SplitMode.all => memberIds.isNotEmpty,
        SplitMode.selected => participantIds(memberIds).isNotEmpty,
        SplitMode.exact => exactValid(memberIds),
        SplitMode.itemized => itemized.valid(memberIds),
      };

  // ---- payers ----

  /// Who paid and how much, as the user set it: single mode = the payer pays the total.
  Map<String, int> payerMinors() {
    if (payerMode == PayerMode.single) {
      final id = singlePayerId;
      final total = totalMinor;
      return id == null || total == null ? const {} : {id: total};
    }
    return {
      for (final entry in payerTexts.entries)
        if (Money.parse(entry.value) case final int minor) entry.key: minor,
    };
  }

  /// The typed payer amounts added up (multiple mode); in single mode it is the total.
  int payerSum() => payerMinors().values.fold<int>(0, (sum, v) => sum + v);

  /// Total minus the payers' amounts; positive = still unpaid. Null until the total is valid.
  int? payerRemaining() {
    final total = totalMinor;
    return total == null ? null : total - payerSum();
  }

  bool get payersValid {
    if (payerMode == PayerMode.single) return singlePayerId != null;
    if (payerTexts.isEmpty) return false;
    for (final text in payerTexts.values) {
      if (Money.parse(text) == null) return false;
    }
    return payerRemaining() == 0;
  }

  // ---- whole form ----

  bool canSave(List<String> memberIds) =>
      titleValid && totalMinor != null && dateValid && payersValid && splitValid(memberIds);

  /// The form differs from a freshly opened one (used to ask before discarding).
  bool differsFrom(ExpenseFormState other) =>
      title != other.title ||
      amountText != other.amountText ||
      date != other.date ||
      splitMode != other.splitMode ||
      !_sameSet(selectedIds, other.selectedIds) ||
      !_sameMap(exactTexts, other.exactTexts) ||
      payerMode != other.payerMode ||
      singlePayerId != other.singlePayerId ||
      !_sameMap(payerTexts, other.payerTexts) ||
      !itemized.sameAs(other.itemized);

  static bool _sameSet(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  static bool _sameMap(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
