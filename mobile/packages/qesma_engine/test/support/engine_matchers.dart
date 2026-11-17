import 'package:qesma_engine/qesma_engine.dart';
import 'package:test/test.dart';

/// Java `Long.MAX_VALUE` / `Long.MIN_VALUE` (Dart `int` is 64-bit on the VM).
const int longMax = 0x7FFFFFFFFFFFFFFF;
const int longMin = -9223372036854775808;

/// Matches a call that throws an [EngineException] with [code].
Matcher throwsEngine(EngineErrorCode code) =>
    throwsA(isA<EngineException>().having((e) => e.code, 'code', code));

/// Matches a call that throws any [EngineException].
final Matcher throwsAnyEngine = throwsA(isA<EngineException>());

/// Roster m0..m(n-1) with sortOrder 1..n.
List<MemberRef> roster(int n) => [for (var i = 0; i < n; i++) MemberRef('m$i', i + 1)];

int sumOf(Iterable<int> values) => values.fold(0, (a, b) => a + b);
