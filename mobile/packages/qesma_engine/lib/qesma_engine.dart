/// Pure Dart money engine for Qesma: a 1:1 port of the Java engine (the reference), kept equal by the shared
/// `fixtures/engine` vectors (ADR-011). No Flutter, no I/O, no floating point. All amounts are `int` minor
/// units (piasters) and rates are integer basis points. Supported targets: Dart VM / AOT (Android, desktop);
/// web is not supported (64-bit `int` is required).
library;

export 'src/balance_calculator.dart';
export 'src/bps.dart';
export 'src/engine_exception.dart';
export 'src/insights/my_share.dart';
export 'src/insights/trip_recap.dart';
export 'src/itemized_calculator.dart';
export 'src/limits.dart';
export 'src/lrm.dart';
export 'src/payer_validator.dart';
export 'src/simplifier.dart';
export 'src/split_calculator.dart';
export 'src/values.dart';
