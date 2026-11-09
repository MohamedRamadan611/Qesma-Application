import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Now", injectable so "today" / "yesterday" headers are testable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
