import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/etag_store.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/expenses/application/expense_view_model.dart';
import 'package:qesma/features/expenses/data/expenses_repository.dart';
import 'package:qesma_api/qesma_api.dart';

/// FL4 against a REAL local backend (profile `local,fake-auth`): list paging, the date and
/// member filters, details with ETag, history, delete with If-Match, a real 409 and 404.
/// Skipped unless `API_BASE_URL` is given (see auth_flow_test.dart). The expenses are created
/// through the generated client in the test's own setup (the app has no add screen until FL5).
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  test('expenses against the real backend', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).signInWithIdToken('fake:fl4-$stamp:fl4-$stamp@example.com:Tester');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());

    // ---- setup through the generated client (not app code) ----
    final api = container.read(qesmaApiProvider);
    final group = (await api.getGroupControllerApi().createGroup(
          createGroupRequest: CreateGroupRequest((b) => b
            ..name = 'FL4 live'
            ..type = 'TRIP'
            ..currencyCode = 'EGP'),
        ))
        .data!;
    final gid = group.id;
    final you = group.yourMemberId;
    final asem = (await api.getMemberControllerApi().addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Asem'))).data!.id;
    final mohsen = (await api.getMemberControllerApi().addMember(gid: gid, createMemberRequest: CreateMemberRequest((b) => b.displayName = 'Mohsen'))).data!.id;

    final random = Random();
    String uuid() {
      String hex(int n) => List.generate(n, (_) => random.nextInt(16).toRadixString(16)).join();
      return '${hex(8)}-${hex(4)}-4${hex(3)}-a${hex(3)}-${hex(12)}';
    }

    Future<ExpenseView> create(ExpenseCommand command) async => (await api.getExpenseControllerApi().createExpense(
          gid: gid,
          idempotencyKey: uuid(),
          expenseCommand: command,
        ))
        .data!;

    // 22 EQUAL expenses on different days (two pages of 20) ...
    for (var i = 0; i < 22; i++) {
      await create(ExpenseCommand((b) => b
        ..title = 'Equal $i'
        ..expenseDate = Date(2026, 10, 1 + (i % 28))
        ..splitType = 'EQUAL'
        ..totalMinor = 10000 + i
        ..payers.add(PayerInput((p) => p
          ..memberId = you
          ..amountMinor = 10000 + i))));
    }
    // ... and the V5 itemized bill paid by Asem alone (so "payer" and "participant" differ).
    final itemized = await create(ExpenseCommand((b) => b
      ..title = 'Sea Food'
      ..expenseDate = Date(2026, 10, 18)
      ..splitType = 'ITEMIZED'
      ..items.addAll([
        ItemInput((i) => i
          ..name = 'Pizza'
          ..amountMinor = 20000
          ..assigneeMemberIds.addAll([you, asem])),
        ItemInput((i) => i
          ..name = 'Pasta'
          ..amountMinor = 15000
          ..assigneeMemberIds.add(mohsen)),
        ItemInput((i) => i
          ..name = 'Drinks'
          ..amountMinor = 9000
          ..assigneeMemberIds.addAll([you, asem, mohsen])),
      ])
      ..service = ServiceInput((s) => s..bps = 1200).toBuilder()
      ..tax = TaxInput((t) => t
        ..bps = 1400
        ..base_ = 'SUBTOTAL_PLUS_SERVICE').toBuilder()
      ..payers.add(PayerInput((p) => p
        ..memberId = asem
        ..amountMinor = 56179))));
    expect(itemized.totalMinor, 56179);

    // ---- the app's repository ----
    final repo = container.read(expensesRepositoryProvider);

    final page0 = await repo.list(gid, page: 0);
    final page1 = await repo.list(gid, page: 1);
    expect(page0.items.length, 20);
    expect(page1.items.length, 3);
    expect(page0.totalPages, 2);
    expect(page0.items.map((e) => e.expenseDate).toList(), isNot(contains(null)));
    // Newest first: dates never increase down the list.
    final dates = [...page0.items, ...page1.items].map((e) => e.expenseDate.toString()).toList();
    expect(dates, [...dates]..sort((a, b) => b.compareTo(a)));

    // Date range: only 2026-10-18 (equal #17 and the itemized bill).
    final day = await repo.list(gid, fromDate: Date(2026, 10, 18), toDate: Date(2026, 10, 18));
    expect(day.items.map((e) => e.expenseDate.toString()).toSet(), {'2026-10-18'});
    expect(day.items.any((e) => e.id == itemized.id), isTrue);

    // Member filter: payer OR participant. Asem pays only the itemized bill and shares in it;
    // Mohsen only shares in it. Neither is in the EQUAL expenses? (they are: EQUAL means all members)
    final asemList = await repo.list(gid, memberId: asem);
    expect(asemList.items.any((e) => e.id == itemized.id), isTrue);
    final unknown = await repo.list(gid, memberId: '00000000-0000-0000-0000-000000000000').then<Object>((p) => p, onError: (Object e) => e);
    // ignore: avoid_print
    print('unknown member filter -> ${unknown is ExpensesPage ? '${unknown.items.length} items' : unknown}');

    // Details: the captured V5 numbers, your share present, and the version for If-Match.
    final detail = await repo.get(gid, itemized.id);
    expect(detail.shares.map((s) => s.owedMinor).toList()..sort(), [16598, 16599, 22982]..sort());
    expect(yourShareMinor(detail, you), isNotNull);
    expect(detail.charges!.service!.amountMinor, 5280);
    expect(detail.charges!.tax!.amountMinor, 6899);
    expect(repo.versionOf(itemized.id), 1);

    // History: one CREATE.
    final history = await repo.revisions(gid, itemized.id);
    expect(history.map((r) => (r.version, r.changeType)).toList(), [(1, 'CREATE')]);

    // A stale delete: someone else bumps the version first (edit through the generated client).
    await api.getExpenseControllerApi().updateExpense(
          gid: gid,
          eid: itemized.id,
          ifMatch: ETagStore.ifMatch(1),
          expenseCommand: ExpenseCommand((b) => b
            ..title = 'Sea Food (edited)'
            ..expenseDate = Date(2026, 10, 18)
            ..splitType = 'EQUAL'
            ..totalMinor = 56179
            ..participantMemberIds.addAll([you, asem, mohsen])
            ..payers.add(PayerInput((p) => p
              ..memberId = asem
              ..amountMinor = 56179))),
        );
    Object? stale;
    try {
      await repo.delete(gid, itemized.id);
    } catch (e) {
      stale = e;
    }
    expect(stale, isA<ApiHttpFailure>());
    expect((stale! as ApiHttpFailure).status, 409);
    expect((stale as ApiHttpFailure).problem?.code, ApiErrorCode.versionConflict);

    // Reload (new version 2), then delete works; the server answers 204.
    final fresh = await repo.get(gid, itemized.id);
    expect(fresh.version, 2);
    expect(repo.versionOf(itemized.id), 2);
    await repo.delete(gid, itemized.id);

    // Deleted: gone from detail and list, a second delete is a plain 404, history survives.
    Object? gone;
    try {
      await repo.get(gid, itemized.id);
    } catch (e) {
      gone = e;
    }
    expect((gone! as ApiHttpFailure).problem?.code, ApiErrorCode.notFound);
    expect((await repo.list(gid, page: 1)).items.any((e) => e.id == itemized.id), isFalse);
    // The first read after the delete forgot the version; the app only deletes after a read, so
    // a second delete is exercised through the generated client to see the server's answer.
    Object? again;
    try {
      await api.getExpenseControllerApi().deleteExpense(gid: gid, eid: itemized.id, ifMatch: ETagStore.ifMatch(3));
    } catch (e) {
      again = mapApiError(e);
    }
    expect((again! as ApiHttpFailure).status, 404);
    final after = await repo.revisions(gid, itemized.id);
    expect(after.map((r) => r.changeType).toList(), ['CREATE', 'UPDATE', 'DELETE']);
    expect(after.last.version, 3);

    // ---- cleanup is not possible (the group has expenses, A30); the fake user is unique per run ----
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
