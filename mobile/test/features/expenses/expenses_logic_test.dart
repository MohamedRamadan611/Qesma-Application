import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderListenable;
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/features/expenses/application/expense_detail_controller.dart';
import 'package:qesma/features/expenses/application/expense_filters.dart';
import 'package:qesma/features/expenses/application/expense_grouping.dart';
import 'package:qesma/features/expenses/application/expense_view_model.dart';
import 'package:qesma/features/expenses/application/expenses_list_controller.dart';
import 'package:qesma/features/expenses/data/expenses_repository.dart';
import 'package:qesma/features/expenses/presentation/expense_ui.dart';
import 'package:qesma/features/groups/application/group_detail_controller.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/expenses_rig.dart';
import '../../support/fake_expenses_server.dart';
import '../../support/test_app.dart';

const String _you = '77e31a5d-f072-4568-9115-0259fb131e9a';
const String _asem = '98138ea2-62ee-4b5d-92d0-0ecccb012cfa';
const String _mohsen = '014bf05a-7ba1-432e-9c17-35881f72d003';

GroupDto _group() => standardSerializers.deserializeWith(GroupDto.serializer, fixtureMap('group'))!;

/// Keeps an auto-dispose provider alive for the length of the test.
void _keep(ProviderContainer c, ProviderListenable<Object?> p) {
  c.listen(p, (_, _) {});
}

Future<void> _until(bool Function() done) async {
  for (var i = 0; i < 200 && !done(); i++) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
}

void main() {
  _countTests();
  group('mapping from real backend responses (captured from the running backend)', () {
    test('EQUAL (edited): no items, no charges, no breakdown parts; your share is your row', () {
      final e = expenseFixture('expense_equal_v2');
      expect(e.splitType, 'EQUAL');
      expect(e.version, 2);
      expect(e.items, isNull);
      expect(e.charges, isNull);
      expect(e.shares.map((s) => s.owedMinor), [17334, 17333, 17333]);
      expect(e.shares.every((s) => breakdownOf(s).isEmpty), isTrue);
      expect(yourShareMinor(e, _you), 17334);
      expect(participantCount(e), 3);
    });

    test('EXACT: server amounts as sent, two payers', () {
      final e = expenseFixture('expense_exact');
      expect(payerLines(e).map((p) => (p.memberId, p.amountMinor)), [(_you, 10000), (_asem, 20000)]);
      expect(paidTotalMinor(e), 30000);
      expect(e.shares.map((s) => s.owedMinor), [10000, 15000, 5000]);
      expect(yourShareMinor(e, _asem), 15000);
      expect(e.shares.every((s) => breakdownOf(s).isEmpty), isTrue);
    });

    test('V5 itemized, service 12% + tax 14% on subtotal plus service: every number is the server number', () {
      final e = expenseFixture('expense_itemized_v5');
      final c = e.charges!;
      expect((c.subtotalMinor, c.service!.bps, c.service!.amountMinor, c.tax!.bps, c.tax!.amountMinor, c.tax!.base_, c.adjustmentMinor),
          (44000, 1200, 5280, 1400, 6899, 'SUBTOTAL_PLUS_SERVICE', 0));
      expect(e.totalMinor, 56179);
      expect(e.shares.map((s) => s.owedMinor), [16599, 16598, 22982]);
      final parts = e.shares.map(breakdownOf).toList();
      expect(parts.map((p) => p.itemsMinor), [13000, 13000, 18000]);
      expect(parts.map((p) => p.serviceMinor), [1560, 1560, 2160]);
      expect(parts.map((p) => p.taxMinor), [2039, 2038, 2822]);
      expect(parts.map((p) => p.adjustmentMinor), [null, null, null], reason: 'a zero adjustment is not drawn');
      expect(e.items!.map((i) => (i.name, i.amountMinor)), [('Pizza', 20000), ('Pasta', 15000), ('Drinks', 9000)]);
      expect(e.items!.first.assigneeMemberIds.toList(), [_you, _asem]);
    });

    test('V6 service only: no tax anywhere', () {
      final e = expenseFixture('expense_itemized_v6_service_only');
      expect(e.charges!.tax, isNull);
      expect(e.charges!.service!.amountMinor, 5280);
      expect(e.shares.map(breakdownOf).every((p) => p.taxMinor == null && p.serviceMinor != null), isTrue);
      expect(e.totalMinor, 49280);
    });

    test('V7 tax only: no service anywhere, tax on the subtotal', () {
      final e = expenseFixture('expense_itemized_v7_tax_only');
      expect(e.charges!.service, isNull);
      expect(e.charges!.tax!.base_, 'SUBTOTAL');
      expect(e.charges!.tax!.amountMinor, 6160);
      expect(e.shares.map(breakdownOf).every((p) => p.serviceMinor == null && p.taxMinor != null), isTrue);
      expect(e.shares.map((s) => s.owedMinor), [14820, 14820, 20520]);
    });

    test('V8 neither: items only', () {
      final e = expenseFixture('expense_itemized_v8_neither');
      expect(e.charges!.service, isNull);
      expect(e.charges!.tax, isNull);
      expect(e.shares.map(breakdownOf).every((p) => p.itemsMinor != null && p.serviceMinor == null && p.taxMinor == null), isTrue);
      expect(e.totalMinor, 44000);
    });

    test('"your share": present, absent (not a participant, A34), and null when the group has no linked member', () {
      final e = expenseFixture('expense_itemized_v5');
      expect(yourShareMinor(e, _mohsen), 22982);
      expect(yourShareMinor(e, 'someone-else'), isNull);
      expect(yourShareMinor(e, null), isNull);

      // An itemized assignee who owes 0 has no shares entry at all.
      final json = copyJson(fixtureMap('expense_itemized_v5'));
      (json['shares'] as List).removeWhere((s) => s['memberId'] == _you);
      final without = expenseFrom(json);
      expect(yourShareMinor(without, _you), isNull);
      expect(participantCount(without), 2);
    });

    test('display helpers select; they never recompute: inconsistent server numbers come out unchanged', () {
      final json = copyJson(fixtureMap('expense_itemized_v5'));
      json['totalMinor'] = 999;
      (json['shares'] as List)[0]['owedMinor'] = 1;
      (json['shares'] as List)[0]['serviceMinor'] = 7;
      (json['charges'] as Map)['subtotalMinor'] = 5;
      final e = expenseFrom(json);
      expect(e.totalMinor, 999);
      expect(yourShareMinor(e, _you), 1);
      expect(breakdownOf(e.shares.first).serviceMinor, 7);
      expect(e.charges!.subtotalMinor, 5);
      // The only sum is the payers' own list, and it is not forced to match the total.
      expect(paidTotalMinor(e), 56179);
    });

    test('the page response parses (nullable fields sent as null are fine)', () {
      final page = standardSerializers.deserializeWith(PageResponseExpenseView.serializer, fixtureMap('list_page0'))!;
      expect(page.items.length, 6);
      expect(page.totalPages, 1);
    });
  });

  group('payer text and date headers', () {
    final group = _group();

    for (final locale in const [Locale('ar'), Locale('en')]) {
      final l10n = lookupAppLocalizations(locale);
      final nameOf = memberNameResolver(group, l10n);

      test('${locale.languageCode}: one payer, several payers with amounts, unknown member', () {
        expect(payersText(l10n, expenseFixture('expense_equal_v2'), nameOf), l10n.expensePaidBy('Mohamed'));
        final multi = payersText(l10n, expenseFixture('expense_itemized_v5'), nameOf);
        expect(multi, l10n.expensePaidBy('${fsIsolated("Mohamed (${isolated('300.00')})")}${l10n.expenseListSeparator}${fsIsolated("Asem (${isolated('261.79')})")}'));
        expect(memberNameResolver(group, l10n)('nobody'), l10n.expenseUnknownMember);
        expect(memberNameResolver(null, l10n)(_you), l10n.expenseUnknownMember);
      });

      test('${locale.languageCode}: today, yesterday and other days', () {
        final now = DateTime(2026, 10, 18, 9, 30);
        expect(dayHeaderText(l10n, Date(2026, 10, 18), now), l10n.expenseDayToday(isolated('2026-10-18')));
        expect(dayHeaderText(l10n, Date(2026, 10, 17), now), l10n.expenseDayYesterday(isolated('2026-10-17')));
        expect(dayHeaderText(l10n, Date(2026, 10, 1), now), isolated('2026-10-01'));
        // Month and year boundaries.
        expect(dayHeaderText(l10n, Date(2026, 9, 30), DateTime(2026, 10, 1)), l10n.expenseDayYesterday(isolated('2026-09-30')));
        expect(dayHeaderText(l10n, Date(2025, 12, 31), DateTime(2026, 1, 1)), l10n.expenseDayYesterday(isolated('2025-12-31')));
      });
    }
  });

  group('grouping by expenseDate', () {
    ExpenseView e(String id, String date) => expenseFrom(cloneExpense(fixtureMap('expense_equal_v2'), id: id, title: id, date: date));

    test('neighbours with the same date share one header; order is kept', () {
      final days = groupByDate([e('a', '2026-10-18'), e('b', '2026-10-18'), e('c', '2026-10-17'), e('d', '2026-10-01')]);
      expect(days.map((d) => d.date.toString()), ['2026-10-18', '2026-10-17', '2026-10-01']);
      expect(days.map((d) => d.items.map((x) => x.id).toList()), [
        ['a', 'b'],
        ['c'],
        ['d'],
      ]);
    });

    test('a day that continues on the next page keeps ONE header (grouping runs over everything loaded)', () {
      final page1 = [e('a', '2026-10-18'), e('b', '2026-10-17')];
      final page2 = [e('c', '2026-10-17'), e('d', '2026-10-16')];
      final days = groupByDate([...page1, ...page2]);
      expect(days.map((d) => d.date.toString()), ['2026-10-18', '2026-10-17', '2026-10-16']);
      expect(days[1].items.map((x) => x.id), ['b', 'c']);
    });

    test('the real captured list groups into two days', () {
      final page = standardSerializers.deserializeWith(PageResponseExpenseView.serializer, fixtureMap('list_page0'))!;
      final days = groupByDate(page.items.toList());
      expect(days.map((d) => (d.date.toString(), d.items.length)), [('2026-10-18', 5), ('2026-10-17', 1)]);
    });

    test('an empty list has no days', () => expect(groupByDate(const []), isEmpty));
  });

  group('filters', () {
    test('range validity, activity and equality', () {
      expect(ExpenseFilters.none.isActive, isFalse);
      expect(ExpenseFilters(from: Date(2026, 10, 1), to: Date(2026, 10, 1)).rangeValid, isTrue, reason: 'one day is a valid range');
      expect(ExpenseFilters(from: Date(2026, 10, 2), to: Date(2026, 10, 1)).rangeValid, isFalse);
      expect(ExpenseFilters(from: Date(2026, 10, 2)).rangeValid, isTrue);
      expect(ExpenseFilters(memberId: 'm').isActive, isTrue);
      expect(ExpenseFilters(from: Date(2026, 10, 2)), ExpenseFilters(from: Date(2026, 10, 2)));
      expect(const ExpenseFilters(memberId: 'a') == const ExpenseFilters(memberId: 'b'), isFalse);
    });
  });

  group('list controller', () {
    late FakeExpensesServer server;
    late ProviderContainer container;

    ExpensesListController list() => container.read(expensesListControllerProvider(server.gid).notifier);
    ExpensesListState state() => container.read(expensesListControllerProvider(server.gid));

    setUp(() {
      server = FakeExpensesServer();
      container = expensesContainer(server);
      addTearDown(container.dispose);
      _keep(container, expensesListControllerProvider(server.gid));
    });

    List<String> listRequests() => server.requests.where((r) => r.startsWith('GET') && r.contains('/expenses?')).toList();

    test('the first load asks for page 0, size 20 and shows everything newest first', () async {
      seedAllFixtures(server);
      expect(state().status, ExpensesStatus.loading);
      await list().load();
      expect(listRequests().single, endsWith('/expenses?page=0&size=20'));
      expect(state().status, ExpensesStatus.ready);
      expect(state().items.map((e) => e.expenseDate.toString()).toList(), [
        '2026-10-18',
        '2026-10-18',
        '2026-10-18',
        '2026-10-18',
        '2026-10-18',
        '2026-10-17',
      ]);
      expect(state().hasMore, isFalse);
    });

    void seedMany(int n) {
      for (var i = 0; i < n; i++) {
        server.expenses.add(cloneExpense(fixtureMap('expense_exact'), id: 'e$i', title: 'Expense $i', date: '2026-10-${(28 - i ~/ 3).toString().padLeft(2, '0')}'));
      }
    }

    test('infinite scroll: one request per next page, stops at the last page, never loads while loading', () async {
      seedMany(25);
      await list().load();
      expect(state().items, hasLength(20));
      expect(state().hasMore, isTrue);

      // Two scroll events at once must send ONE request.
      final a = list().loadMore();
      final b = list().loadMore();
      await Future.wait([a, b]);
      expect(listRequests().where((r) => r.contains('page=1')), hasLength(1));
      expect(state().items, hasLength(25));
      expect(state().hasMore, isFalse);

      await list().loadMore();
      expect(listRequests().where((r) => r.contains('page=2')), isEmpty, reason: 'nothing after the last page');
    });

    test('refresh replaces the list without duplicates; a failed refresh keeps the old list', () async {
      seedMany(5);
      await list().load();
      server.expenses.add(cloneExpense(fixtureMap('expense_exact'), id: 'new', title: 'New', date: '2026-10-29'));
      expect(await list().refresh(), isNull);
      expect(state().items.length, 6);
      expect(state().items.map((e) => e.id).toSet().length, 6);
      expect(state().items.first.id, 'new');

      server.offline = true;
      final failure = await list().refresh();
      expect(failure, isA<ApiNoConnection>());
      expect(state().status, ExpensesStatus.ready);
      expect(state().items.length, 6, reason: 'the old list stays');
      expect(state().refreshing, isFalse);
    });

    test('a first-load failure shows the failed state; a retry recovers', () async {
      seedMany(2);
      server.offline = true;
      await list().load();
      expect(state().status, ExpensesStatus.failed);
      expect(state().failure, isA<ApiNoConnection>());
      server.offline = false;
      await list().load();
      expect(state().status, ExpensesStatus.ready);
      expect(state().items, hasLength(2));
    });

    test('date filter sends fromDate and toDate (yyyy-MM-dd) and starts again at page 0', () async {
      seedMany(25);
      await list().load();
      await list().loadMore();
      expect(state().page, 1);

      final ok = await list().applyFilters(ExpenseFilters(from: Date(2026, 10, 27), to: Date(2026, 10, 28)));
      expect(ok, isTrue);
      expect(listRequests().last, endsWith('/expenses?page=0&size=20&fromDate=2026-10-27&toDate=2026-10-28'));
      expect(state().page, 0);
      expect(state().items.every((e) => e.expenseDate.toString().compareTo('2026-10-27') >= 0), isTrue);
      expect(state().filters.hasDateRange, isTrue);
    });

    test('member filter sends memberId (payer or participant is the server\'s rule)', () async {
      seedAllFixtures(server);
      await list().load();
      await list().applyFilters(const ExpenseFilters(memberId: _asem));
      expect(listRequests().last, contains('memberId=$_asem'));
      expect(state().items, hasLength(6), reason: 'Asem is a payer or a participant of every captured expense');
    });

    test('from and to may be given alone; both filters combine', () async {
      seedAllFixtures(server);
      await list().load();
      await list().applyFilters(ExpenseFilters(to: Date(2026, 10, 17)));
      expect(listRequests().last, allOf(contains('toDate=2026-10-17'), isNot(contains('fromDate'))));
      expect(state().items.map((e) => e.title), ['Tickets']);

      await list().applyFilters(ExpenseFilters(from: Date(2026, 10, 18), memberId: _mohsen));
      expect(listRequests().last, allOf(contains('fromDate=2026-10-18'), contains('memberId=$_mohsen')));
      expect(state().items, hasLength(5));
    });

    test('a backwards range is refused before any request is sent', () async {
      seedAllFixtures(server);
      await list().load();
      final before = server.requests.length;
      final ok = await list().applyFilters(ExpenseFilters(from: Date(2026, 10, 20), to: Date(2026, 10, 18)));
      expect(ok, isFalse);
      expect(server.requests.length, before);
      expect(state().filters, ExpenseFilters.none);
      expect(state().items, hasLength(6));
    });

    test('filtered-empty is not the same as empty: filters stay on, items are empty; clearing reloads everything', () async {
      seedAllFixtures(server);
      await list().load();
      await list().applyFilters(ExpenseFilters(from: Date(2027, 1, 1)));
      expect(state().status, ExpensesStatus.ready);
      expect(state().items, isEmpty);
      expect(state().filters.isActive, isTrue);

      await list().clearFilters();
      expect(state().filters.isActive, isFalse);
      expect(state().items, hasLength(6));
      expect(listRequests().last, endsWith('/expenses?page=0&size=20'));
    });

    test('a failed refresh during a page load does not leave the page spinner on (review finding 3)', () async {
      seedMany(25);
      await list().load();
      server.holdNextList = Completer<void>(); // the next page's reply is slow
      final gate = server.holdNextList!;
      final more = list().loadMore();
      await Future<void>.delayed(Duration.zero);
      expect(state().loadingMore, isTrue);

      server.expensesOffline = true;
      final failure = await list().refresh(); // fails while the page request is still out
      expect(failure, isA<ApiNoConnection>());
      expect(state().loadingMore, isFalse, reason: 'the refresh supersedes the page request, so its flag must go');
      expect(state().refreshing, isFalse);

      server.expensesOffline = false;
      gate.complete(); // the old page reply arrives late and is dropped
      await more;
      expect(state().items, hasLength(20));
      expect(state().loadingMore, isFalse);

      // And paging works again afterwards.
      expect(await list().loadMore(), isNull);
      expect(state().items, hasLength(25));
    });

    test('after a failed page only an explicit retry loads again, scrolling does not', () async {
      seedMany(25);
      await list().load();
      server.expensesOffline = true;
      expect(await list().loadMore(), isA<ApiNoConnection>());
      expect(state().loadMoreFailed, isTrue);
      expect(state().loadingMore, isFalse);

      server.expensesOffline = false;
      final before = listRequests().length;
      expect(await list().loadMore(), isNull, reason: 'a scroll event alone does not retry');
      expect(listRequests().length, before);

      expect(await list().loadMore(retry: true), isNull);
      expect(state().loadMoreFailed, isFalse);
      expect(state().items, hasLength(25));
    });

    test('a slow reply for old filters never overwrites the list for the new ones', () async {
      seedAllFixtures(server);
      final first = list().load(); // unfiltered, sent first
      final second = list().applyFilters(ExpenseFilters(to: Date(2026, 10, 17)));
      await Future.wait([first, second]);
      expect(state().filters.to, Date(2026, 10, 17));
      expect(state().items.map((e) => e.title), ['Tickets']);
    });
  });

  group('details, delete and history', () {
    late FakeExpensesServer server;
    late ProviderContainer container;
    const v5 = '7e3b3a23-d844-4889-99ae-5cba254d1173';
    late String equalId;

    ExpenseKey key(String eid) => (gid: server.gid, eid: eid);
    ExpenseDetailController detail(String eid) => container.read(expenseDetailControllerProvider(key(eid)).notifier);
    ExpenseDetailState detailState(String eid) => container.read(expenseDetailControllerProvider(key(eid)));

    setUp(() {
      server = FakeExpensesServer();
      seedAllFixtures(server);
      equalId = fixtureMap('expense_equal_v2')['id'] as String;
      container = expensesContainer(server);
      addTearDown(container.dispose);
    });

    Future<void> open(String eid) async {
      _keep(container, expenseDetailControllerProvider(key(eid)));
      expect(await detail(eid).load(), isNull);
    }

    test('opening reads the expense and keeps its version for If-Match', () async {
      await open(v5);
      expect(detailState(v5).expense!.title, 'Sea Food');
      expect(detailState(v5).loading, isFalse);
      expect(container.read(expensesRepositoryProvider).versionOf(v5), 1);
      await open(equalId);
      expect(container.read(expensesRepositoryProvider).versionOf(equalId), 2);
    });

    test('delete sends If-Match "<version>" taken from the details read and removes the expense', () async {
      await open(equalId);
      final (outcome, failure) = await detail(equalId).delete();
      expect((outcome, failure), (DeleteOutcome.deleted, null));
      expect(server.requests.any((r) => r.startsWith('DELETE') && r.endsWith('if-match="2"')), isTrue);
      expect(server.expenses.any((e) => e['id'] == equalId), isFalse);
      expect(detailState(equalId).deleted, isTrue);
      expect(detailState(equalId).busy, isFalse);
    });

    test('after a delete the list and the group totals are refreshed if those screens are alive', () async {
      _keep(container, expensesListControllerProvider(server.gid));
      _keep(container, groupDetailControllerProvider(server.gid));
      await container.read(expensesListControllerProvider(server.gid).notifier).load();
      await container.read(groupDetailControllerProvider(server.gid).notifier).load();
      expect(container.read(expensesListControllerProvider(server.gid)).items, hasLength(6));
      final groupReadsBefore = server.requests.where((r) => r == 'GET /api/v1/groups/${server.gid}').length;

      await open(v5);
      await detail(v5).delete();
      await _until(() => container.read(expensesListControllerProvider(server.gid)).items.length == 5);
      expect(container.read(expensesListControllerProvider(server.gid)).items.any((e) => e.id == v5), isFalse);
      await _until(() => server.requests.where((r) => r == 'GET /api/v1/groups/${server.gid}').length > groupReadsBefore);
      expect(server.requests.where((r) => r == 'GET /api/v1/groups/${server.gid}').length, greaterThan(groupReadsBefore));
    });

    test('leaving the page while the delete is in flight still refreshes the list when the reply comes (review finding 16)', () async {
      _keep(container, expensesListControllerProvider(server.gid));
      await container.read(expensesListControllerProvider(server.gid).notifier).load();
      expect(container.read(expensesListControllerProvider(server.gid)).items, hasLength(6));

      final sub = container.listen(expenseDetailControllerProvider(key(v5)), (_, _) {});
      expect(await detail(v5).load(), isNull);
      server.holdNextDelete = Completer<void>();
      final gate = server.holdNextDelete!;
      final deleting = detail(v5).delete();
      await Future<void>.delayed(Duration.zero);
      sub.close(); // the user leaves the details page
      await Future<void>.delayed(const Duration(milliseconds: 20));

      gate.complete();
      final (outcome, _) = await deleting;
      expect(outcome, DeleteOutcome.deleted);
      await _until(() => container.read(expensesListControllerProvider(server.gid)).items.length == 5);
      expect(container.read(expensesListControllerProvider(server.gid)).items.any((e) => e.id == v5), isFalse);
    });

    test('a reply without an ETag header still records THIS read\'s version, never an older one (review finding 17)', () async {
      await open(v5);
      expect(container.read(expensesRepositoryProvider).versionOf(v5), 1);
      server.bumpVersion(v5);
      server.omitEtag = true;
      expect(await detail(v5).load(), isNull);
      expect(container.read(expensesRepositoryProvider).versionOf(v5), 2);
      expect((await detail(v5).delete()).$1, DeleteOutcome.deleted);
      expect(server.requests.where((r) => r.startsWith('DELETE')).last, endsWith('if-match="2"'));
    });

    test('nothing is refreshed (and nothing is created) when the list screen is not alive', () async {
      await open(v5);
      final before = server.requests.length;
      await detail(v5).delete();
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(server.requests.skip(before).where((r) => r.contains('/expenses?')), isEmpty);
    });

    test('409 VERSION_CONFLICT: nothing is deleted, the failure says so, and reloading then deleting works', () async {
      await open(v5);
      server.bumpVersion(v5); // someone else edited it
      final (outcome, failure) = await detail(v5).delete();
      expect(outcome, DeleteOutcome.failed);
      expect((failure! as ApiHttpFailure).problem!.code, ApiErrorCode.versionConflict);
      expect(server.expenses.any((e) => e['id'] == v5), isTrue);
      expect(detailState(v5).busy, isFalse);
      expect(detailState(v5).deleted, isFalse);

      expect(await detail(v5).load(), isNull);
      expect(detailState(v5).expense!.version, 2);
      final (second, _) = await detail(v5).delete();
      expect(second, DeleteOutcome.deleted);
      expect(server.requests.where((r) => r.startsWith('DELETE')).last, endsWith('if-match="2"'));
    });

    test('404 on delete (already deleted elsewhere): same end state, reported as already gone', () async {
      await open(v5);
      server.expenses.removeWhere((e) => e['id'] == v5);
      final (outcome, failure) = await detail(v5).delete();
      expect((outcome, failure), (DeleteOutcome.alreadyGone, null));
      expect(detailState(v5).deleted, isTrue);
    });

    test('a lost reply: the retry meets 404 and counts as deleted, not as an error', () async {
      await open(v5);
      server.loseNextDeleteResponse = true;
      final (first, failure) = await detail(v5).delete();
      expect(first, DeleteOutcome.failed);
      expect(failure, isA<ApiTimeout>());
      expect(detailState(v5).busy, isFalse, reason: 'the user can try again');
      expect(server.expenses.any((e) => e['id'] == v5), isFalse, reason: 'the server did delete it');

      final (second, again) = await detail(v5).delete();
      expect((second, again), (DeleteOutcome.alreadyGone, null));
    });

    test('offline delete fails cleanly and works once the network is back', () async {
      await open(v5);
      server.offline = true;
      final (outcome, failure) = await detail(v5).delete();
      expect(outcome, DeleteOutcome.failed);
      expect(failure, isA<ApiNoConnection>());
      expect(detailState(v5).busy, isFalse);
      server.offline = false;
      expect((await detail(v5).delete()).$1, DeleteOutcome.deleted);
    });

    test('only one delete runs at a time', () async {
      await open(v5);
      final a = detail(v5).delete();
      final b = detail(v5).delete();
      final results = await Future.wait([a, b]);
      expect(server.requests.where((r) => r.startsWith('DELETE')), hasLength(1));
      expect(results.map((r) => r.$1), containsAll([DeleteOutcome.deleted, DeleteOutcome.failed]));
    });

    test('a delete is never sent for an expense that was not read first (no blind If-Match)', () async {
      final repo = container.read(expensesRepositoryProvider);
      await expectLater(repo.delete(server.gid, v5), throwsA(isA<ApiUnexpected>()));
      expect(server.requests.where((r) => r.startsWith('DELETE')), isEmpty);
    });

    test('opening an expense that is gone: state says gone (the screen shows "no longer available")', () async {
      _keep(container, expenseDetailControllerProvider(key('missing')));
      final failure = await detail('missing').load();
      expect(failure, isA<ApiHttpFailure>());
      expect(detailState('missing').gone, isTrue);
      expect(detailState('missing').expense, isNull);
    });

    test('a failed reload keeps the previous copy', () async {
      await open(v5);
      server.offline = true;
      expect(await detail(v5).load(), isA<ApiNoConnection>());
      expect(detailState(v5).expense!.title, 'Sea Food');
      expect(detailState(v5).failure, isNotNull);
    });

    test('history: oldest first as the server sends it, with the snapshot of each version', () async {
      _keep(container, expenseRevisionsProvider(key(equalId)));
      final revisions = await container.read(expenseRevisionsProvider(key(equalId)).future);
      expect(revisions.map((r) => (r.version, r.changeType, r.snapshot.totalMinor)), [(1, 'CREATE', 50000), (2, 'UPDATE', 52000)]);
      expect(revisions.last.snapshot.title, 'Petrol (edited)');
    });

    test('history keeps working after the expense was deleted (A40)', () async {
      await open(equalId);
      await detail(equalId).delete();
      _keep(container, expenseRevisionsProvider(key(equalId)));
      final revisions = await container.read(expenseRevisionsProvider(key(equalId)).future);
      expect(revisions.last.changeType, 'DELETE');
    });

    test('history failure surfaces as an error the sheet can retry', () async {
      server.failNextRevisions = true;
      _keep(container, expenseRevisionsProvider(key(equalId)));
      await expectLater(container.read(expenseRevisionsProvider(key(equalId)).future), throwsA(isA<ApiHttpFailure>()));
      container.invalidate(expenseRevisionsProvider(key(equalId)));
      expect(await container.read(expenseRevisionsProvider(key(equalId)).future), hasLength(2));
    });
  });
}

void _countTests() {
  group('Arabic count forms (review finding 14)', () {
    final ar = lookupAppLocalizations(const Locale('ar'));
    final en = lookupAppLocalizations(const Locale('en'));

    test('participants: one, two, 3-10 and 11 or more', () {
      expect(participantsText(ar, 1), 'على فرد واحد');
      expect(participantsText(ar, 2), 'مقسومة على فردين');
      expect(participantsText(ar, 3), 'مقسومة على 3 أفراد');
      expect(participantsText(ar, 10), 'مقسومة على 10 أفراد');
      expect(participantsText(ar, 11), 'مقسومة على 11 فردًا');
      expect(participantsText(en, 2), 'Split between 2 people');
      expect(participantsText(en, 11), 'Split between 11 people');
    });
  });
}
