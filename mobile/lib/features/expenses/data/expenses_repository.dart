import 'package:dio/dio.dart' show CancelToken;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/api/api_providers.dart';
import '../../../core/api/etag_store.dart';
import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/api_failure.dart';

/// One page of the expenses list.
typedef ExpensesPage = ({List<ExpenseView> items, int page, int totalPages});

/// The only code that talks to the generated expenses API. Everything it throws is an
/// [ApiFailure]; widgets and notifiers never see Dio.
class ExpensesRepository {
  ExpensesRepository(this._api, this._etags);

  final QesmaApi _api;
  final ETagStore _etags;

  static const int pageSize = 20;

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw mapApiError(error);
    }
  }

  /// Newest first (the server sorts by `expenseDate desc, createdAt desc`).
  Future<ExpensesPage> list(String gid, {int page = 0, Date? fromDate, Date? toDate, String? memberId}) => _run(() async {
        final response = await _api.getExpenseControllerApi().listExpenses(
              gid: gid,
              page: page,
              size: pageSize,
              fromDate: fromDate,
              toDate: toDate,
              memberId: memberId,
            );
        final body = response.data;
        if (body == null) throw const ApiUnexpected();
        return (items: body.items.toList(), page: body.page, totalPages: body.totalPages);
      });

  /// Reads one expense and remembers its version for the next `If-Match` (delete now,
  /// edit in FL5/FL6). List items carry no ETag, so only this read enables a delete.
  Future<ExpenseView> get(String gid, String eid) => _run(() async {
        final response = await _api.getExpenseControllerApi().getExpense(gid: gid, eid: eid);
        final expense = response.data;
        if (expense == null) throw const ApiUnexpected();
        // Always the version of THIS read: a missing header must not leave an older one behind.
        final fromHeader = ETagStore.parseVersion(response.headers.value('etag'));
        _etags.remember(eid, ETagStore.ifMatch(fromHeader ?? expense.version));
        return expense;
      });

  /// Soft delete with `If-Match`. The expense must have been read first (no blind deletes).
  Future<void> delete(String gid, String eid) => _run(() async {
        final ifMatch = _etags.ifMatchFor(eid);
        if (ifMatch == null) throw const ApiUnexpected();
        await _api.getExpenseControllerApi().deleteExpense(gid: gid, eid: eid, ifMatch: ifMatch);
        _etags.forget(eid);
      });

  /// Oldest first, as the server sends them. Works for a deleted expense too.
  Future<List<ExpenseRevisionView>> revisions(String gid, String eid) => _run(() async {
        final response = await _api.getExpenseControllerApi().listExpenseRevisions(gid: gid, eid: eid);
        final body = response.data;
        if (body == null) throw const ApiUnexpected();
        return body.toList();
      });

  /// Asks the server for the split of the command (nothing is saved). Returns the call together with a
  /// handle that cancels it, so a newer request can supersede it without the caller touching Dio.
  ({Future<ExpensePreview> result, void Function() cancel}) preview(String gid, ExpenseCommand command) {
    final token = CancelToken();
    final result = _run(() async {
      final response = await _api.getExpenseControllerApi().previewExpense(gid: gid, expenseCommand: command, cancelToken: token);
      final body = response.data;
      if (body == null) throw const ApiUnexpected();
      return body;
    });
    return (result: result, cancel: () => token.cancel());
  }

  /// Creates an expense with an Idempotency-Key. "replayed" is true when the server answered a repeat of
  /// an earlier request with the stored result (the same expense, no duplicate).
  Future<({ExpenseView expense, bool replayed})> create(String gid, ExpenseCommand command, String idempotencyKey) => _run(() async {
        final response = await _api.getExpenseControllerApi().createExpense(gid: gid, idempotencyKey: idempotencyKey, expenseCommand: command);
        final expense = response.data;
        if (expense == null) throw const ApiUnexpected();
        final fromHeader = ETagStore.parseVersion(response.headers.value('etag'));
        _etags.remember(expense.id, ETagStore.ifMatch(fromHeader ?? expense.version));
        return (expense: expense, replayed: response.headers.value('idempotency-replayed') == 'true');
      });

  /// Replaces an expense (PUT with If-Match, no key). The expense must have been read first.
  Future<ExpenseView> update(String gid, String eid, ExpenseCommand command) => _run(() async {
        final ifMatch = _etags.ifMatchFor(eid);
        if (ifMatch == null) throw const ApiUnexpected();
        final response = await _api.getExpenseControllerApi().updateExpense(gid: gid, eid: eid, ifMatch: ifMatch, expenseCommand: command);
        final expense = response.data;
        if (expense == null) throw const ApiUnexpected();
        final fromHeader = ETagStore.parseVersion(response.headers.value('etag'));
        _etags.remember(eid, ETagStore.ifMatch(fromHeader ?? expense.version));
        return expense;
      });

  /// The version last read for [eid], for the edit flows (FL5/FL6).
  int? versionOf(String eid) => _etags.versionOf(eid);
}

final expensesRepositoryProvider = Provider<ExpensesRepository>(
  (ref) => ExpensesRepository(ref.watch(qesmaApiProvider), ref.watch(etagStoreProvider)),
);
