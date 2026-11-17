import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/local/backend/local_backend_overrides.dart';
import 'package:qesma/local/db/local_database.dart';
import 'package:qesma/local/service/local_context.dart';
import 'package:qesma/local/service/profile_service.dart';

/// A provider container in local mode: the app's repositories over `LocalBackend` on a fresh in-memory database
/// with the local profile already created (what SA4 onboarding will do). No token, no sign-in.
Future<ProviderContainer> localContainer({String profileName = 'Tester'}) async {
  final db = LocalDatabase.inMemory();
  await ProfileService(LocalContext(db)).ensureProfile(profileName);
  final container = ProviderContainer(overrides: [
    ...localBackendOverrides(db),
    tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
    autoRestoreProvider.overrideWithValue(false),
    authLogProvider.overrideWithValue(RecordingAuthLog()),
  ]);
  addTearDown(() async {
    container.dispose();
    await db.close();
  });
  return container;
}
