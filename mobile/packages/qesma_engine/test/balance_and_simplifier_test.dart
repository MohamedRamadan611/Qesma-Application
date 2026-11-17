import 'dart:math';

import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

import 'support/engine_matchers.dart';

/// Ports of BalanceAndSimplifierTest (spec 7.6-7.8) and BalanceTotalsTest (the per-member-totals form).
void main() {
  group('BalanceCalculator.nets and Simplifier', () {
    const members = [MemberRef('A', 1), MemberRef('B', 2), MemberRef('C', 3)];

    ExpenseLedgerEntry expense(String payer, int total, Map<String, int> owed) =>
        ExpenseLedgerEntry([Payer(payer, total)], owed);

    test('nets sum to zero and include all members in sortOrder', () {
      final nets = BalanceCalculator.nets(members, [
        expense('A', 300, {'B': 100, 'C': 200})
      ], const []);
      expect(nets, {'A': 300, 'B': -100, 'C': -200});
      expect(nets.keys, ['A', 'B', 'C']);
    });

    test('a settlement exceeding the debt flips the balance', () {
      final nets = BalanceCalculator.nets(members, [
        expense('A', 100, {'B': 100})
      ], const [
        SettlementEntry('B', 'A', 150)
      ]);
      expect(nets['B'], 50);
      expect(nets['A'], -50);
    });

    test('rejects an expense where payers and owed differ', () {
      expect(
          () => BalanceCalculator.nets(members, [
                expense('A', 100, {'B': 99})
              ], const []),
          throwsEngine(EngineErrorCode.payersTotalMismatch));
    });

    test('rejects unknown members and bad settlements', () {
      expect(
          () => BalanceCalculator.nets(members, [
                expense('Z', 100, {'B': 100})
              ], const []),
          throwsEngine(EngineErrorCode.memberNotInGroup));
      expect(() => BalanceCalculator.nets(members, const [], const [SettlementEntry('A', 'Z', 5)]),
          throwsEngine(EngineErrorCode.memberNotInGroup));
      expect(() => BalanceCalculator.nets(members, const [], const [SettlementEntry('A', 'A', 5)]),
          throwsEngine(EngineErrorCode.validationError));
      expect(() => BalanceCalculator.nets(members, const [], const [SettlementEntry('A', 'B', 0)]),
          throwsEngine(EngineErrorCode.validationError));
      expect(() => BalanceCalculator.nets(const [MemberRef('A', 1), MemberRef('A', 2)], const [], const []),
          throwsEngine(EngineErrorCode.validationError));
    });

    test('simplifier tie-breaks on the lowest sortOrder', () {
      expect(Simplifier.simplify({'A': 100, 'B': -50, 'C': -50}, members),
          const [Transfer('B', 'A', 50), Transfer('C', 'A', 50)]);
    });

    test('simplifier tie-breaks tied creditors on the lowest sortOrder too', () {
      expect(Simplifier.simplify({'A': 50, 'B': 50, 'C': -100}, members),
          const [Transfer('C', 'A', 50), Transfer('C', 'B', 50)]);
    });

    test('simplifier picks the largest creditor, then the most negative debtor', () {
      const four = [MemberRef('X', 1), MemberRef('Y', 2), MemberRef('Z', 3), MemberRef('W', 4)];
      expect(Simplifier.simplify({'X': 17500, 'Y': 7500, 'Z': -12500, 'W': -12500}, four), const [
        Transfer('Z', 'X', 12500),
        Transfer('W', 'Y', 7500),
        Transfer('W', 'X', 5000),
      ]);
    });

    test('simplifier tie-break follows sortOrder, not map or roster order', () {
      const shuffled = [MemberRef('C', 3), MemberRef('B', 2), MemberRef('A', 1)];
      expect(Simplifier.simplify({'C': -50, 'B': -50, 'A': 100}, shuffled),
          const [Transfer('B', 'A', 50), Transfer('C', 'A', 50)]);
    });

    test('all-zero nets need no transfers', () {
      expect(Simplifier.simplify({'A': 0, 'B': 0}, members), isEmpty);
    });

    test('simplifier rejects nets that do not sum to zero or unknown members', () {
      expect(() => Simplifier.simplify({'A': 10, 'B': -9}, members), throwsEngine(EngineErrorCode.validationError));
      expect(() => Simplifier.simplify({'A': 10, 'Z': -10}, members), throwsEngine(EngineErrorCode.memberNotInGroup));
    });
  });

  group('BalanceCalculator.netsFromTotals and memberNet', () {
    const r = [MemberRef('M', 1), MemberRef('A', 2), MemberRef('S', 3)];

    test('V1 from totals gives the spec nets', () {
      final nets = BalanceCalculator.netsFromTotals(r, const [
        MemberTotals('M', 10000, 0, 0, 0),
        MemberTotals('A', 0, 8000, 0, 0),
        MemberTotals('S', 3000, 5000, 0, 0),
      ]);
      expect(nets, {'M': 10000, 'A': -8000, 'S': -2000});
      expect(nets.keys, ['M', 'A', 'S']);
    });

    test('V2: a settlement moves the nets by the sent and received amounts', () {
      final nets = BalanceCalculator.netsFromTotals(r, const [
        MemberTotals('M', 10000, 0, 0, 8000),
        MemberTotals('A', 0, 8000, 8000, 0),
        MemberTotals('S', 3000, 5000, 0, 0),
      ]);
      expect(nets, {'M': 2000, 'A': 0, 'S': -2000});
    });

    test('members without totals are zero and listed in sortOrder', () {
      final nets = BalanceCalculator.netsFromTotals(r, const []);
      expect(nets.keys, ['M', 'A', 'S']);
      expect(nets.values.toSet(), {0});
    });

    test('an unknown member or a broken ledger is rejected', () {
      expect(
          () => BalanceCalculator.netsFromTotals(
              r, const [MemberTotals('X', 5, 0, 0, 0), MemberTotals('M', 0, 5, 0, 0)]),
          throwsEngine(EngineErrorCode.memberNotInGroup));
      expect(
          () => BalanceCalculator.netsFromTotals(r, const [MemberTotals('M', 100, 0, 0, 0)]),
          throwsA(isA<EngineException>().having((e) => e.message, 'message', contains('sum to zero'))));
    });

    test('overflow is a typed error, not a wrap-around', () {
      expect(
          () => BalanceCalculator.netsFromTotals(
              r, const [MemberTotals('M', longMax, 0, 0, 0), MemberTotals('A', longMax, 0, 0, 0)]),
          throwsAnyEngine);
    });

    test('the totals form equals the row form on random ledgers with settlements', () {
      final rnd = Random(7);
      final roster8 = roster(8);
      for (var round = 0; round < 300; round++) {
        final expenses = <ExpenseLedgerEntry>[];
        final totals = <String, List<int>>{}; // paid, owed, sent, received
        List<int> t(String m) => totals.putIfAbsent(m, () => [0, 0, 0, 0]);
        for (var e = 0, n = rnd.nextInt(12); e < n; e++) {
          final amount = 1 + rnd.nextInt(100000);
          final payer = 'm${rnd.nextInt(8)}';
          final owed = <String, int>{};
          var left = amount;
          for (var k = 0; k < 3; k++) {
            final part = k == 2 ? left : rnd.nextInt(left + 1);
            final m = 'm${rnd.nextInt(8)}';
            owed[m] = (owed[m] ?? 0) + part;
            left -= part;
          }
          expenses.add(ExpenseLedgerEntry([Payer(payer, amount)], owed));
          t(payer)[0] += amount;
          owed.forEach((m, v) => t(m)[1] += v);
        }
        final settlements = <SettlementEntry>[];
        for (var s = 0, n = rnd.nextInt(6); s < n; s++) {
          final from = rnd.nextInt(8);
          final to = (from + 1 + rnd.nextInt(7)) % 8;
          final amount = 1 + rnd.nextInt(50000);
          settlements.add(SettlementEntry('m$from', 'm$to', amount));
          t('m$from')[2] += amount;
          t('m$to')[3] += amount;
        }
        final list = [for (final e in totals.entries) MemberTotals(e.key, e.value[0], e.value[1], e.value[2], e.value[3])];

        final fromRows = BalanceCalculator.nets(roster8, expenses, settlements);
        final fromTotals = BalanceCalculator.netsFromTotals(roster8, list);

        expect(fromTotals, fromRows, reason: 'round $round');
        expect(sumOf(fromTotals.values), 0);
        final after = Map<String, int>.of(fromTotals);
        for (final tr in Simplifier.simplify(fromTotals, roster8)) {
          after[tr.fromMemberId] = after[tr.fromMemberId]! + tr.amountMinor;
          after[tr.toMemberId] = after[tr.toMemberId]! - tr.amountMinor;
        }
        expect(after.values.every((v) => v == 0), isTrue, reason: 'round $round');
      }
    });

    test('memberNet is the same rule for one member', () {
      expect(BalanceCalculator.memberNet(const MemberTotals('M', 10000, 0, 0, 8000)), 2000);
      expect(BalanceCalculator.memberNet(const MemberTotals('A', 0, 8000, 8000, 0)), 0);
      expect(BalanceCalculator.memberNet(const MemberTotals('S', 3000, 5000, 0, 0)), -2000);
      final rnd = Random(11);
      for (var round = 0; round < 200; round++) {
        final paid = rnd.nextInt(1000000);
        final owed = rnd.nextInt(1000000);
        final sent = rnd.nextInt(1000000);
        final received = rnd.nextInt(1000000);
        expect(BalanceCalculator.memberNet(MemberTotals('m', paid, owed, sent, received)),
            paid - owed + sent - received);
      }
      expect(() => BalanceCalculator.memberNet(const MemberTotals('m', longMax, -1, 0, 0)), throwsAnyEngine);
    });

    test('the amount cap is ten billion pounds', () {
      expect(Limits.maxAmountMinor, 1000000000000);
      expect(Limits.withinAmountLimit(Limits.maxAmountMinor), isTrue);
      expect(Limits.withinAmountLimit(Limits.maxAmountMinor + 1), isFalse);
    });
  });
}
