import 'dart:convert';
import 'dart:io';

import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

/// Runs `fixtures/ride/*.json` (SA11, STANDALONE_SPEC 11, A139-A141). These vectors are Dart-only: the Java engine
/// is frozen for the standalone release.
final Directory _dir = Directory('../../../fixtures/ride');

List<File> _files() => _dir.listSync().whereType<File>().where((f) => f.path.endsWith('.json')).toList()
  ..sort((a, b) => a.path.compareTo(b.path));

MemberRef _member(Object? raw) {
  final m = raw! as Map<String, dynamic>;
  return MemberRef(m['id'] as String, m['sortOrder'] as int);
}

Map<String, int> _shares(List<Share> shares) => {for (final s in shares) s.memberId: s.amountMinor};

Map<String, dynamic> _runFuel(Map<String, dynamic> input) {
  final r = FuelSplit.compute(
    distanceTenthsKm: input['distanceTenthsKm'] as int,
    consumptionTenths: input['consumptionTenths'] as int,
    pricePerLitreMinor: input['pricePerLitreMinor'] as int,
    tollsMinor: (input['tollsMinor'] as List<dynamic>).cast<int>(),
    driver: _member(input['driver']),
    driverIncluded: input['driverIncluded'] as bool,
    passengers: [for (final p in input['passengers'] as List<dynamic>) _member(p)],
  );
  return {
    'fuelMinor': r.fuelMinor,
    'tollsMinor': r.tollsMinor,
    'totalMinor': r.totalMinor,
    'payerMemberId': r.payerMemberId,
    'shares': _shares(r.shares),
  };
}

Map<String, dynamic> _runRide(Map<String, dynamic> input) {
  final r = MultiStopSplit.compute(
    fareMinor: input['fareMinor'] as int,
    legDistancesTenthsKm: (input['legDistancesTenthsKm'] as List<dynamic>).cast<int>(),
    riders: [
      for (final raw in input['riders'] as List<dynamic>)
        RideRider(
          memberId: (raw as Map<String, dynamic>)['memberId'] as String,
          sortOrder: raw['sortOrder'] as int,
          boardStop: raw['boardStop'] as int,
          leaveStop: raw['leaveStop'] as int,
        ),
    ],
  );
  return {'legFaresMinor': r.legFaresMinor, 'shares': _shares(r.shares)};
}

void main() {
  test('ride fixtures are present (fuel and multi-stop)', () {
    final names = _files().map((f) => f.uri.pathSegments.last).toList();
    expect(names.where((n) => n.startsWith('fuel-')).length, greaterThanOrEqualTo(5));
    expect(names.where((n) => n.startsWith('ride-')).length, greaterThanOrEqualTo(5));
  });

  for (final file in _files()) {
    test(file.uri.pathSegments.last, () {
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final input = json['input'] as Map<String, dynamic>;
      final expected = json['expected'] as Map<String, dynamic>;
      final run = switch (json['kind']) {
        'fuel' => () => _runFuel(input),
        'multiStop' => () => _runRide(input),
        final other => throw StateError('unknown kind $other'),
      };
      if (expected.containsKey('error')) {
        expect(
          run,
          throwsA(isA<EngineException>().having((e) => e.code.wireName, 'code', expected['error'])),
        );
      } else {
        expect(run(), equals(expected));
      }
    });
  }
}
