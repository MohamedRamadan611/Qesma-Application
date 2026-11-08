import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for ExpenseControllerApi
void main() {
  final instance = QesmaApi().getExpenseControllerApi();

  group(ExpenseControllerApi, () {
    // Create an expense (EQUAL, EXACT or ITEMIZED)
    //
    // Idempotency-Key (UUID) is required. For ITEMIZED, totalMinor is optional: the server computes it and the payers must add up to it (PAYERS_TOTAL_MISMATCH otherwise).
    //
    //Future<ExpenseView> createExpense(String gid, String idempotencyKey, ExpenseCommand expenseCommand) async
    test('test createExpense', () async {
      // TODO
    });

    // Delete an expense (soft delete, keeps the history)
    //
    // If-Match with the current version is required. Answers 204 with the new ETag.
    //
    //Future deleteExpense(String gid, String eid, String ifMatch) async
    test('test deleteExpense', () async {
      // TODO
    });

    //Future<ExpenseView> getExpense(String gid, String eid) async
    test('test getExpense', () async {
      // TODO
    });

    // History of an expense, oldest first
    //
    // Each entry carries the full expense as it was after that change. Still available after the expense was deleted.
    //
    //Future<BuiltList<ExpenseRevisionView>> listExpenseRevisions(String gid, String eid) async
    test('test listExpenseRevisions', () async {
      // TODO
    });

    //Future<PageResponseExpenseView> listExpenses(String gid, { int page, int size, Date fromDate, Date toDate, String memberId }) async
    test('test listExpenses', () async {
      // TODO
    });

    // Preview an expense split without saving it
    //
    // Same body as create. Returns the computed total, charges and per-member breakdown, and payersTotalMatches. Persists nothing. Itemized-only totals are null for EQUAL/EXACT.
    //
    //Future<ExpensePreview> previewExpense(String gid, ExpenseCommand expenseCommand) async
    test('test previewExpense', () async {
      // TODO
    });

    // Edit an expense (replaces payers, shares and items)
    //
    // If-Match with the current version is required. Send the explicit participant list: members who joined later are never added silently. Writes a revision.
    //
    //Future<ExpenseView> updateExpense(String gid, String eid, String ifMatch, ExpenseCommand expenseCommand) async
    test('test updateExpense', () async {
      // TODO
    });

  });
}
