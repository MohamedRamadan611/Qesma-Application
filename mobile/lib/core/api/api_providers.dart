import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'etag_store.dart';

/// One store for the versions of every resource read in this app run (SCREEN_MAP rule 7).
final etagStoreProvider = Provider<ETagStore>((ref) => ETagStore());
