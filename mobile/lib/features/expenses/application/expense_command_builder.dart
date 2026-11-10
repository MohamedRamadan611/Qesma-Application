import 'package:qesma_api/qesma_api.dart';

import '../../../core/api/idempotent_action.dart';
import 'expense_form_state.dart';

/// The title sent to a PREVIEW while the user has not typed one yet. The backend validates the
/// title even for a preview; this value is never saved and never shown.
const String kPreviewTitle = 'x';

/// Turns the form into the body the backend takes (create, edit or preview). Pure. The only
/// place in the app that constructs an [ExpenseCommand] (a guard test enforces it).
///
/// Returns null while the form cannot make a valid request. Rules (spec 7.2-7.5, 7.9, A28):
/// - EQUAL "all": a CREATE omits `participantMemberIds` (the server resolves the current
///   members); an EDIT sends the explicit list of all current members (A39).
/// - EQUAL "selected": the explicit selected ids.
/// - EXACT: `shares` for the selected members with the typed amounts.
/// - ITEMIZED: [buildItemizedCommand] (items, service, tax, adjustment; no total).
/// - Payers: single = the payer with the total (a copy, not a division); several = the typed
///   amounts. A PREVIEW may go without payers, so it sends them only when they are valid.
ExpenseCommand? buildExpenseCommand(
  ExpenseFormState form, {
  required bool edit,
  required List<String> memberIds,
  bool preview = false,
}) {
  if (form.splitMode == SplitMode.itemized) return buildItemizedCommand(form, memberIds: memberIds);

  final total = form.totalMinor;
  if (total == null || !form.dateValid || memberIds.isEmpty) return null;

  var title = form.trimmedTitle;
  if (title.isEmpty && preview) {
    title = kPreviewTitle;
  } else if (!form.titleValid) {
    return null;
  }

  if (!form.splitValid(memberIds)) return null;

  final payers = form.payerMinors();
  if (!preview && !form.payersValid) return null;
  final sendPayers = !preview || form.payersValid;

  final participants = form.participantIds(memberIds);
  if (participants.isEmpty) return null;

  return ExpenseCommand((b) {
    b
      ..title = title
      ..expenseDate = form.date
      ..totalMinor = total;
    if (form.splitMode == SplitMode.exact) {
      b.splitType = 'EXACT';
      b.shares.addAll([
        for (final id in participants)
          ShareInput((s) => s
            ..memberId = id
            ..amountMinor = form.exactMinorOf(id) ?? 0),
      ]);
    } else {
      b.splitType = 'EQUAL';
      final explicit = form.splitMode == SplitMode.selected || edit;
      if (explicit) b.participantMemberIds.addAll(participants);
    }
    if (sendPayers) {
      b.payers.addAll([
        for (final entry in payers.entries)
          PayerInput((p) => p
            ..memberId = entry.key
            ..amountMinor = entry.value),
      ]);
    }
  });
}

/// An EQUAL command among exactly [participantIds] for [totalMinor], for the two things the
/// form asks the server to calculate: the Exact prefill and "split equally among the payers".
/// Payers are omitted (a preview may go without them).
ExpenseCommand buildEqualPreview({
  required String title,
  required Date date,
  required int totalMinor,
  required List<String> participantIds,
}) =>
    ExpenseCommand((b) => b
      ..title = title.trim().isEmpty ? kPreviewTitle : title.trim()
      ..expenseDate = date
      ..splitType = 'EQUAL'
      ..totalMinor = totalMinor
      ..participantMemberIds.addAll(participantIds));

/// The command as JSON-encodable data (what is sent over the wire).
Object? commandJson(ExpenseCommand command) => standardSerializers.serializeWith(ExpenseCommand.serializer, command);

/// Canonical text of a command: keys and the order of members/payers/shares do not matter, so
/// two commands that mean the same thing compare equal. Used as the preview key, as the
/// idempotency body and to recognise "my earlier save did apply".
String commandKey(ExpenseCommand command) {
  final json = (commandJson(command) as Map).cast<String, dynamic>();
  List<dynamic>? sorted(String key) {
    final list = json[key];
    if (list is! List) return null;
    final copy = list.map((e) => e is Map ? canonicalJson(e) : '$e').toList()..sort();
    return copy;
  }

  return canonicalJson({
    ...json,
    if (json['payers'] != null) 'payers': sorted('payers'),
    if (json['participantMemberIds'] != null) 'participantMemberIds': sorted('participantMemberIds'),
    if (json['shares'] != null) 'shares': sorted('shares'),
  });
}

/// For the paid-by sheet: an EQUAL command among [memberIds] with the payers being edited. The
/// only thing read from the answer is `payersTotalMatches` (the server decides whether the payers
/// cover the total); the split in it is irrelevant here.
ExpenseCommand buildPayersCheck({
  required String title,
  required Date date,
  required int totalMinor,
  required List<String> memberIds,
  required Map<String, int> payers,
}) =>
    ExpenseCommand((b) {
      b
        ..title = title.trim().isEmpty ? kPreviewTitle : title.trim()
        ..expenseDate = date
        ..splitType = 'EQUAL'
        ..totalMinor = totalMinor
        ..participantMemberIds.addAll(memberIds);
      b.payers.addAll([
        for (final entry in payers.entries)
          PayerInput((p) => p
            ..memberId = entry.key
            ..amountMinor = entry.value),
      ]);
    });

/// The restaurant bill as a request (spec 7.4, 8.4, A31). Null while the bill cannot make a valid
/// request.
///
/// - `items`: name (trimmed), amount, assignees (current members, in member order).
/// - `service {bps}` ONLY when the service switch is on; `tax {bps, base}` ONLY when the tax switch is
///   on (base always explicit). Off means the field is absent, never 0 bps; a 0% charge that is
///   switched on is sent as `bps: 0`.
/// - `adjustmentMinor` only when it is not zero. `totalMinor` is never sent: the server computes it.
/// - Payers: single = the payer with the server's total (a copy); several = the typed amounts.
///
/// [preview] builds the question for the preview endpoint: a placeholder title (the server validates
/// it, the answer does not depend on it) and payers only when [withPayers] is set and they are valid.
ExpenseCommand? buildItemizedCommand(
  ExpenseFormState form, {
  required List<String> memberIds,
  bool preview = false,
  bool withPayers = true,
}) {
  final draft = form.itemized;
  if (!form.dateValid || memberIds.isEmpty || !draft.valid(memberIds)) return null;

  var title = form.trimmedTitle;
  if (preview) {
    title = kPreviewTitle;
  } else if (!form.titleValid) {
    return null;
  }

  final canSendPayers = form.payersValid && form.totalMinor != null;
  if (!preview && !canSendPayers) return null;
  final payers = withPayers && canSendPayers ? form.payerMinors() : const <String, int>{};

  return ExpenseCommand((b) {
    b
      ..title = title
      ..expenseDate = form.date
      ..splitType = 'ITEMIZED';
    b.items.addAll([
      for (final item in draft.items)
        ItemInput((i) {
          final assignees = item.assigneesAmong(memberIds);
          i
            ..name = item.trimmedName
            ..amountMinor = item.amountMinor!
            ..assigneeMemberIds.addAll([for (final id in memberIds) if (assignees.contains(id)) id]);
        }),
    ]);
    final service = draft.serviceBps;
    if (service != null) b.service = ServiceInput((s) => s..bps = service).toBuilder();
    final tax = draft.taxBps;
    if (tax != null) {
      b.tax = TaxInput((t) => t
        ..bps = tax
        ..base_ = draft.taxBase.wire).toBuilder();
    }
    final adjustment = draft.adjustmentMinor ?? 0;
    if (adjustment != 0) b.adjustmentMinor = adjustment;
    if (payers.isNotEmpty) {
      b.payers.addAll([
        for (final entry in payers.entries)
          PayerInput((p) => p
            ..memberId = entry.key
            ..amountMinor = entry.value),
      ]);
    }
  });
}

/// The question for the numbers shown in the editor (no payers), or with them for the
/// "do the payers match" banner.
ExpenseCommand? buildItemizedPreview(ExpenseFormState form, {required List<String> memberIds, bool withPayers = false}) =>
    buildItemizedCommand(form, memberIds: memberIds, preview: true, withPayers: withPayers);
