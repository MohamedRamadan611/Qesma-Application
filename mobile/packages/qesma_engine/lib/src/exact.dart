import 'engine_exception.dart';

/// Overflow-checked 64-bit arithmetic (port of the Java `Exact`), reporting overflow as a typed
/// [EngineException]. Dart `int` is a two's-complement 64-bit integer on the VM and in AOT builds
/// (Android, desktop) and wraps silently on overflow, so every money sum goes through here.
/// Web is not a supported target (ADR-011): there `int` is a JS number and these checks do not hold.
abstract final class Exact {
  /// Java `Long.MAX_VALUE`.
  static const int maxInt64 = 0x7FFFFFFFFFFFFFFF;

  /// Java `Long.MIN_VALUE`.
  static const int minInt64 = -9223372036854775808;

  static int add(int a, int b) {
    final r = a + b;
    // Overflow iff both operands have the same sign and the result's sign differs (Hacker's Delight 2-13).
    if (((a ^ r) & (b ^ r)) < 0) {
      throw EngineException.invalid('Amount too large');
    }
    return r;
  }

  /// Java `Math.multiplyExact`: overflow is a typed VALIDATION_ERROR (A13), never a silent wrap-around.
  static int multiply(int a, int b) {
    if (a == 0 || b == 0) return 0;
    if ((a == -1 && b == minInt64) || (b == -1 && a == minInt64)) {
      throw EngineException.invalid('Amount too large');
    }
    final r = a * b;
    if (r ~/ b != a) {
      throw EngineException.invalid('Amount too large');
    }
    return r;
  }

  static int negate(int a) {
    if (a == minInt64) {
      throw EngineException.invalid('Amount too large');
    }
    return -a;
  }
}
