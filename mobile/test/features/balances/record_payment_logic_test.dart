import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/features/balances/application/balances_controller.dart';
import 'package:qesma/features/balances/application/record_payment_controller.dart';
import 'package:qesma/features/balances/application/record_payment_state.dart';
import 'package:qesma/features/balances/application/settlements_controller.dart';
import 'package:qesma/features/expenses/application/expense_refresh.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/expense_form_rig.dart';
import '../../support/fake_balances_server.dart';

final RegExp _uuid = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$');

PaymentForm _form({String? from = 'a', String? to = 'b', String amount = '80', Date? date, String note = ''}) =>
    PaymentForm(fromId: from, toId: to, amountText: amount, date: date ?? Date(2026, 10, 18), note: note);

/// The controllers do not load by themselves, so a test drives them step by step.
final List<Override> _manual = [balancesAutoLoadProvider.overrideWithValue(false), settlementsAutoLoadProvider.overrideWithValue(false)];

void main() {
  group('payment form: validation and the request (pure)', () {
    test('amount: 1..10^12 piasters, two decimals, Arabic digits', () {
      const cases = <String, int?>{
        '': null,
        '0': null,
        '0.00': null,
        'abc': null,
        '-5': null,
        '80': 8000,
        '80.5': 8050,
        '0.01': 1,
        '١٢٫٥': 1250,
        '1,000.50': 100050,
        '1.234': null,
        '10000000000': 1000000000000,
        '10000000000.01': null,
        '10000000001': null,
      };
      cases.forEach((text, minor) {
        expect(_form(amount: text).amountMinor, minor, reason: '"$text"');
        expect(_form(amount: text).canSend, minor != null, reason: '"$text"');
      });
    });

    test('date must be within 2000-01-01..2100-12-31', () {
      expect(_form(date: Date(1999, 12, 31)).firstError, PaymentFieldError.date);
      expect(_form(date: Date(2000, 1, 1)).canSend, isTrue);
      expect(_form(date: Date(2100, 12, 31)).canSend, isTrue);
      expect(_form(date: Date(2101, 1, 1)).firstError, PaymentFieldError.date);
    });

    test('note: at most 200 code points after trimming; blank means none', () {
      expect(_form(note: 'x' * 200).canSend, isTrue);
      expect(_form(note: 'x' * 201).firstError, PaymentFieldError.note);
      expect(_form(note: '${' ' * 5}${'x' * 200}${' ' * 5}').canSend, isTrue, reason: 'trimmed first');
      expect(_form(note: '😀' * 200).canSend, isTrue, reason: 'code points, not UTF-16 units');
      expect(buildSettlementCommand(_form(note: '   '))!.note, isNull);
      expect(buildSettlementCommand(_form(note: '  cash  '))!.note, 'cash');
    });

    test('from and to: both set and different', () {
      expect(_form(from: null).firstError, PaymentFieldError.missingMember);
      expect(_form(to: null).firstError, PaymentFieldError.missingMember);
      expect(_form(from: 'a', to: 'a').firstError, PaymentFieldError.sameMember);
      expect(buildSettlementCommand(_form(from: 'a', to: 'a')), isNull);
    });

    test('the command carries integers and the date as typed', () {
      final command = buildSettlementCommand(_form(amount: '80.5', note: 'cash'))!;
      expect(settlementBodyJson(command), {'fromMemberId': 'a', 'toMemberId': 'b', 'amountMinor': 8050, 'settledOn': '2026-10-18', 'note': 'cash'});
      expect(settlementBodyJson(buildSettlementCommand(_form())!).containsKey('note'), isFalse);
    });
  });

  group('record payment controller (real stack on the fake server)', () {
    late FakeBalancesServer server;
    late ProviderContainer container;

    PaymentKey key([PaymentSeed? seed]) => (gid: server.gid, seed: seed ?? const PaymentSeed());
    RecordPaymentController controller([PaymentSeed? seed]) {
      keepAlive(container, recordPaymentControllerProvider(key(seed)));
      return container.read(recordPaymentControllerProvider(key(seed)).notifier);
    }

    RecordPaymentView view([PaymentSeed? seed]) => container.read(recordPaymentControllerProvider(key(seed)));

    setUp(() async {
      server = FakeBalancesServer();
      container = await formContainer(server, extra: _manual);
      addTearDown(container.dispose);
    });

    PaymentSeed transfer() => PaymentSeed(fromId: server.member('Asem'), toId: server.you, amountMinor: 8000);

    test('a transfer prefills from, to and the server\'s amount; a manual entry starts as you -> someone else', () {
      final c = controller(transfer());
      expect(view(transfer()).form.fromId, server.member('Asem'));
      expect(view(transfer()).form.toId, server.you);
      expect(view(transfer()).form.amountText, '80');
      expect(c.dirty, isFalse);

      controller();
      final manual = view().form;
      expect(manual.fromId, server.you);
      expect(manual.toId, isNot(server.you));
      expect(manual.amountText, '');
      expect(manual.suggestedMinor, isNull);
    });

    test('"full amount" puts the transfer\'s amount back; picking the other side\'s member swaps them', () {
      final c = controller(transfer());
      c.setAmount('12');
      expect(c.dirty, isTrue);
      c.useFullAmount();
      expect(view(transfer()).form.amountText, '80');
      c.setFrom(server.you);
      expect(view(transfer()).form.fromId, server.you);
      expect(view(transfer()).form.toId, server.member('Asem'), reason: 'never the same member on both sides');
    });

    test('sends once with an Idempotency-Key and the exact body; double tap is one request', () async {
      server.balancesAfterCreate = balancesMap('balances_v2');
      final c = controller(transfer());
      final first = c.send();
      final second = c.send();
      expect(await second, PaymentOutcome.invalid, reason: 'a send is already in flight');
      expect(await first, PaymentOutcome.recorded);
      expect(server.settlementCreates, hasLength(1));
      final sent = server.settlementCreates.single;
      expect(sent.key, matches(_uuid));
      expect(sent.body, {'fromMemberId': server.member('Asem'), 'toMemberId': server.you, 'amountMinor': 8000, 'settledOn': '2026-10-18'});
    });

    test('the same key is reused on a retry of the same body, and a changed body gets a new key', () async {
      final c = controller(transfer());
      server.balancesOffline = true;
      expect(await c.send(), PaymentOutcome.failed);
      expect(view(transfer()).failure, isNotNull);
      expect(view(transfer()).sending, isFalse);
      server.balancesOffline = false;
      expect(await c.send(), PaymentOutcome.recorded);
      expect(server.settlementAttemptKeys, hasLength(2));
      expect(server.settlementAttemptKeys[1], server.settlementAttemptKeys[0], reason: 'a retry of the same payment');

      // Edit after a failed attempt: a different body is a different action.
      final d = controller();
      d.setAmount('5');
      server.balancesOffline = true;
      await d.send();
      d.setAmount('6');
      server.balancesOffline = false;
      await d.send();
      final keys = server.settlementAttemptKeys.skip(2).toList();
      expect(keys, hasLength(2));
      expect(keys[1], isNot(keys[0]), reason: 'the amount changed');
    });

    test('a 500 keeps the key (repeating may work); a definitive refusal forgets it', () async {
      final c = controller(transfer());
      server.failNextSettlementCreate = true;
      expect(await c.send(), PaymentOutcome.failed);
      expect(await c.send(), PaymentOutcome.recorded);
      expect(server.settlementAttemptKeys[1], server.settlementAttemptKeys[0]);

      final d = controller();
      d.setAmount('7');
      server.forceNextSettlementCode = 'VALIDATION_ERROR';
      expect(await d.send(), PaymentOutcome.failed);
      expect((view().failure! as dynamic).problem?.code, ApiErrorCode.validationError);
      expect(await d.send(), PaymentOutcome.recorded);
      final keys = server.settlementAttemptKeys.skip(2).toList();
      expect(keys[1], isNot(keys[0]), reason: 'the refusal ended that attempt');
    });

    test('a lost reply is answered by the stored response on retry: one payment, not two', () async {
      final c = controller(transfer());
      server.loseNextSettlementResponse = true;
      expect(await c.send(), PaymentOutcome.failed);
      expect(server.settlements, hasLength(1), reason: 'the server stored it');
      expect(await c.send(), PaymentOutcome.recorded);
      expect(server.settlements, hasLength(1), reason: 'same key, same body: replayed, not duplicated');
    });

    test('MEMBER_NOT_IN_GROUP reloads the group\'s members', () async {
      final c = controller(transfer());
      final before = server.count('GET', '/groups/${server.gid}');
      server.forceNextSettlementCode = 'MEMBER_NOT_IN_GROUP';
      expect(await c.send(), PaymentOutcome.failed);
      await waitUntil(() => server.count('GET', '/groups/${server.gid}') > before);
      expect(server.requests.where((r) => r == 'GET /api/v1/groups/${server.gid}').length, greaterThan(before));
    });

    test('an invalid form sends nothing', () async {
      final c = controller();
      expect(await c.send(), PaymentOutcome.invalid, reason: 'no amount');
      expect(server.settlementCreates, isEmpty);
    });
  });

  group('refresh: balances are never cached across edits', () {
    late FakeBalancesServer server;
    late ProviderContainer container;

    setUp(() async {
      server = FakeBalancesServer();
      container = await formContainer(server, extra: _manual);
      addTearDown(container.dispose);
    });

    int balancesReads() => server.requests.where((r) => r.startsWith('GET /api/v1/groups/${server.gid}/balances')).length;
    int listReads() => server.requests.where((r) => r.startsWith('GET /api/v1/groups/${server.gid}/settlements')).length;

    test('recording a payment refetches balances, history and the group header', () async {
      keepAlive(container, balancesControllerProvider(server.gid));
      keepAlive(container, settlementsControllerProvider(server.gid));
      await container.read(balancesControllerProvider(server.gid).notifier).load();
      await container.read(settlementsControllerProvider(server.gid).notifier).load();
      expect(balancesReads(), 1);
      final groupReads = server.count('GET', '/groups/${server.gid}') - balancesReads() - listReads();

      server.balancesAfterCreate = balancesMap('balances_v2');
      final key = (gid: server.gid, seed: PaymentSeed(fromId: server.member('Asem'), toId: server.you, amountMinor: 8000));
      keepAlive(container, recordPaymentControllerProvider(key));
      expect(await container.read(recordPaymentControllerProvider(key).notifier).send(), PaymentOutcome.recorded);
      List<int> nets() => container.read(balancesControllerProvider(server.gid)).balances!.nets.map((n) => n.netMinor).toList();
      await waitUntil(() => nets().first == 2000 && container.read(settlementsControllerProvider(server.gid)).items.length == 1);
      expect(balancesReads(), 2);
      expect(listReads(), 2);
      final groupReadsNow = server.requests.where((r) => r == 'GET /api/v1/groups/${server.gid}').length;
      expect(groupReadsNow, greaterThan(groupReads), reason: 'the header (total, your balance) is read again');
      final shown = nets();
      expect(shown, [2000, 0, -2000], reason: 'the server\'s V2 numbers, as sent');
      expect(container.read(settlementsControllerProvider(server.gid)).items, hasLength(1));
    });

    test('any expense change refreshes the balances and history that are alive, and creates none that are not', () async {
      final refresh = Provider<void Function()>((ref) => () => refreshExpenseViews(ref, server.gid));
      refresh.hashCode; // (keeps the analyzer honest about the unused-variable lint)
      container.read(refresh)();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(balancesReads(), 0, reason: 'nothing alive, nothing created');

      keepAlive(container, balancesControllerProvider(server.gid));
      keepAlive(container, settlementsControllerProvider(server.gid));
      await container.read(balancesControllerProvider(server.gid).notifier).load();
      await container.read(settlementsControllerProvider(server.gid).notifier).load();
      container.read(refresh)();
      await waitUntil(() => balancesReads() >= 2 && listReads() >= 2);
      expect(balancesReads(), 2);
      expect(listReads(), 2);
    });

    test('a failed refresh keeps what was shown', () async {
      keepAlive(container, balancesControllerProvider(server.gid));
      await container.read(balancesControllerProvider(server.gid).notifier).load();
      server.failNextBalances = true;
      final failure = await container.read(balancesControllerProvider(server.gid).notifier).refresh();
      expect(failure, isNotNull);
      final state = container.read(balancesControllerProvider(server.gid));
      expect(state.status, BalancesStatus.ready);
      expect(state.balances!.nets.map((n) => n.netMinor).toList(), [10000, -8000, -2000]);
    });

    test('history is paged, newest first, 20 per page, without duplicates', () async {
      for (var i = 0; i < 45; i++) {
        server.settlements.add({
          'id': 'p$i',
          'groupId': server.gid,
          'fromMemberId': server.you,
          'toMemberId': server.member('Asem'),
          'amountMinor': 100 + i,
          'settledOn': '2026-09-${(1 + i % 28).toString().padLeft(2, '0')}',
          'createdAt': '2026-11-10T10:00:00Z',
            'declaredAt': '2026-11-10T10:00:00Z', 'status': 'CONFIRMED', 'recordedByAdmin': true,
        });
      }
      keepAlive(container, settlementsControllerProvider(server.gid));
      final c = container.read(settlementsControllerProvider(server.gid).notifier);
      await c.load();
      var state = container.read(settlementsControllerProvider(server.gid));
      expect(state.items, hasLength(20));
      expect(state.total, 45);
      expect(state.hasMore, isTrue);
      await c.loadMore();
      await c.loadMore();
      state = container.read(settlementsControllerProvider(server.gid));
      expect(state.items, hasLength(45));
      expect(state.hasMore, isFalse);
      expect(state.items.map((s) => s.id).toSet(), hasLength(45));
      final dates = state.items.map((s) => s.settledOn.toString()).toList();
      expect(dates, [...dates]..sort((a, b) => b.compareTo(a)), reason: 'newest settledOn first');
    });
  });
}
