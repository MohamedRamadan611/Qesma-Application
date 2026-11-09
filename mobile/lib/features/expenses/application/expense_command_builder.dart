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
/// - ITEMIZED is built in FL6: null here.
/// - Payers: single = the payer with the total (a copy, not a division); several = the typed
///   amounts. A PREVIEW may go without payers, so it sends them only when they are valid.
ExpenseCommand? buildExpenseCommand(
  ExpenseFormState form, {
  required bool edit,
  required List<String> memberIds,
  bool preview = false,
}) {
  final total = form.totalMinor;
  if (total == null || !form.dateValid || memberIds.isEmpty) return null;
  if (form.splitMode == SplitMode.itemized) return null;

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
