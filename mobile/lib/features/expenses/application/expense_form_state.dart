import 'package:qesma_api/qesma_api.dart';

import '../../../core/money/money.dart';
import '../../../core/widgets/code_point_limit.dart';

/// Which people share the expense. `itemized` (the restaurant bill) is built in FL6; the
/// form only routes to it.
enum SplitMode { all, selected, exact, itemized }

/// One payer who covers the whole total, or several who each type what they paid.
enum PayerMode { single, multiple }

/// The title limit of the backend (code points).
const int kExpenseTitleMax = 100;

final Date kFirstExpenseDate = Date(2000, 1, 1);
final Date kLastExpenseDate = Date(2100, 12, 31);

/// Everything the user typed or chose on the add/edit form. Immutable; the controller
/// replaces it as a whole. Pure: no I/O and no money arithmetic beyond ADDING UP what the
/// user typed (the "remaining" indicators the spec allows). Splits, rounding and "equal" amounts
/// come from the backend preview, never from here.
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
  });

  final String title;

  /// The total exactly as typed ("500", "1,000.50", Arabic digits all fine).
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
      );

  // ---- title, total, date ----

  String get trimmedTitle => title.trim();

  bool get titleValid {
    final count = codePointCount(trimmedTitle);
    return count >= 1 && count <= kExpenseTitleMax;
  }

  /// The total in piasters, or null while the text is empty or not an amount (1..10^12).
  int? get totalMinor => Money.parse(amountText);

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
        SplitMode.itemized => false, // FL6
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
      !_sameMap(payerTexts, other.payerTexts);

  static bool _sameSet(Set<String> a, Set<String> b) => a.length == b.length && a.containsAll(b);

  static bool _sameMap(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}
