import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'cairo_day.dart';

/// "Now", injectable so "today" / "yesterday" headers are testable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Today's calendar date in Africa/Cairo (`YYYY-MM-DD`), read from [clockProvider]. Engines take it as a parameter
/// and never read a clock themselves (trip budget, A191).
final cairoTodayProvider = Provider<String>((ref) => cairoDay(ref.watch(clockProvider)()));
