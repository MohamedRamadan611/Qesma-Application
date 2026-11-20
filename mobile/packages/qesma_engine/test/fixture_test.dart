import 'dart:convert';
import 'dart:io';

import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

/// Port of the Java FixtureTest: runs every shared vector in /fixtures/engine against the Dart engine.
/// Only the keys present under "expected" are asserted (fixtures/README.md). The working directory under
/// `dart test` is the package root, so the repo-root fixtures are three levels up.
final Directory _dir = Directory('../../../fixtures/engine');

List<File> _fixtureFiles() =>
    _dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
      ..sort((a, b) => _name(a).compareTo(_name(b)));

String _name(File f) => f.uri.pathSegments.last;

void main() {
  test('all spec vectors are present (V1-V8 spec 10, V9-V16 STANDALONE_SPEC 18.6)', () {
    final names = _fixtureFiles().map(_name).toList();
    expect(names.length, greaterThanOrEqualTo(16));
    for (var v = 1; v <= 16; v++) {
      expect(names.any((n) => n.startsWith('V$v-')), isTrue, reason: 'V$v missing');
    }
  });

  for (final file in _fixtureFiles()) {
    test(_name(file), () => _run(jsonDecode(file.readAsStringSync()) as Map<String, dynamic>));
  }
}

void _run(Map<String, dynamic> fixture) {
  final input = fixture['input'] as Map<String, dynamic>;
  final expected = fixture['expected'] as Map<String, dynamic>;

  final members = [
    for (final m in _list(input['members'])) MemberRef(m['id'] as String, m['sortOrder'] as int),
  ];

  final ledger = <ExpenseLedgerEntry>[];
  final expenses = _list(input['expenses']);
  for (var i = 0; i < expenses.length; i++) {
    final e = expenses[i];
    final int total;
    final Map<String, int> owed;
    ItemizedResult? itemized;
    switch (e['type']) {
      case 'EQUAL':
        total = e['totalMinor'] as int;
        final participants = [
          for (final id in e['participantMemberIds'] as List<dynamic>) members.firstWhere((m) => m.id == id),
        ];
        owed = SplitCalculator.equal(total, participants);
      case 'EXACT':
        total = e['totalMinor'] as int;
        owed = SplitCalculator.exact(total, [
          for (final s in _list(e['shares'])) Share(s['memberId'] as String, s['amountMinor'] as int),
        ]);
      case 'ITEMIZED':
        final rejected =
            expected.containsKey('expenses') ? _list(expected['expenses'])[i] : const <String, dynamic>{};
        if (rejected.containsKey('error')) {
          // A rejected bill: the engine (input shape included) must refuse it with this code; it is not in the ledger.
          final code = EngineErrorCode.values.firstWhere((c) => c.wireName == rejected['error']);
          expect(() => ItemizedCalculator.calculate(_itemizedInput(e, members)),
              throwsA(isA<EngineException>().having((x) => x.code, 'code', code)),
              reason: 'expense $i');
          continue;
        }
        final result = ItemizedCalculator.calculate(_itemizedInput(e, members));
        itemized = result;
        total = result.totalMinor;
        owed = {for (final b in result.members) b.memberId: b.owedMinor};
      default:
        throw ArgumentError('unknown expense type ${e['type']}');
    }

    final payers = [for (final p in _list(e['payers'])) Payer(p['memberId'] as String, p['amountMinor'] as int)];
    PayerValidator.validate(total, payers);
    ledger.add(ExpenseLedgerEntry(payers, owed));

    if (expected.containsKey('expenses')) {
      final exp = _list(expected['expenses'])[i];
      if (exp.containsKey('owed')) {
        expect(owed, _intMap(exp['owed']), reason: 'expense $i owed');
      }
      if (exp.containsKey('totalMinor')) {
        expect(total, exp['totalMinor'], reason: 'expense $i total');
      }
      if (itemized != null) {
        _field(exp, 'subtotalMinor', itemized.subtotalMinor);
        _field(exp, 'discountMinor', itemized.discountMinor);
        if (exp.containsKey('discounts')) {
          expect({for (final b in itemized.members) b.memberId: b.discountMinor}, _intMap(exp['discounts']),
              reason: 'expense $i discounts');
        }
        _field(exp, 'serviceMinor', itemized.serviceMinor);
        _field(exp, 'taxMinor', itemized.taxMinor);
      }
    }
  }

  final settlements = [
    for (final s in _list(input['settlements'] ?? <dynamic>[]))
      SettlementEntry(s['fromMemberId'] as String, s['toMemberId'] as String, s['amountMinor'] as int),
  ];

  final nets = BalanceCalculator.nets(members, ledger, settlements);
  if (expected.containsKey('nets')) {
    final exp = _intMap(expected['nets']);
    expect(nets, exp, reason: 'nets');
    expect(nets.keys.toList(), exp.keys.toList(), reason: 'nets are in sortOrder');
  }
  if (expected.containsKey('transfers')) {
    expect(Simplifier.simplify(nets, members), [
      for (final t in _list(expected['transfers']))
        Transfer(t['fromMemberId'] as String, t['toMemberId'] as String, t['amountMinor'] as int),
    ], reason: 'transfers (ordered)');
  }
}

/// Maps a fixture bill to the engine input through the engine's own shape rules ([Item.of], [ChargeSpec.of]), so a
/// rejected shape (V16) fails exactly as it does behind the API (Java `FixtureTest.itemizedInput`). Legacy
/// `serviceBps` is still read; `service`/`tax`/`discount` take `bps` or `amountMinor`.
ItemizedInput _itemizedInput(Map<String, dynamic> e, List<MemberRef> members) {
  final items = [
    for (final it in _list(e['items']))
      Item.of(it['name'] as String, [for (final a in it['assigneeMemberIds'] as List<dynamic>) a as String],
          amountMinor: it['amountMinor'] as int?,
          unitAmountMinor: it['unitAmountMinor'] as int?,
          quantity: it['quantity'] as int?),
  ];
  ChargeSpec charge(Object? json) {
    final m = json! as Map<String, dynamic>;
    return ChargeSpec.of(m['bps'] as int?, m['amountMinor'] as int?);
  }

  final service = e['serviceBps'] != null
      ? ChargeSpec.percent(e['serviceBps'] as int)
      : (e['service'] == null ? null : charge(e['service']));
  final taxJson = e['tax'] as Map<String, dynamic>?;
  final tax = taxJson == null
      ? null
      : TaxSpec.of(charge(taxJson), taxJson['base'] == null ? null : TaxBase.fromWire(taxJson['base'] as String));
  return ItemizedInput.charges(members, items,
      discount: e['discount'] == null ? null : charge(e['discount']),
      service: service,
      tax: tax,
      adjustmentMinor: (e['adjustmentMinor'] as int?) ?? 0);
}

List<Map<String, dynamic>> _list(Object? json) => [for (final o in json! as List<dynamic>) o as Map<String, dynamic>];

Map<String, int> _intMap(Object? json) => (json! as Map<String, dynamic>).map((k, v) => MapEntry(k, v as int));

void _field(Map<String, dynamic> exp, String field, int actual) {
  if (exp.containsKey(field)) {
    expect(actual, exp[field], reason: field);
  }
}
