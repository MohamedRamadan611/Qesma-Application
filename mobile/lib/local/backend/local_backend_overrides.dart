import 'package:flutter_riverpod/misc.dart' show Override;

import '../../core/app_mode.dart';
import '../../core/auth/auth_providers.dart';
import '../../core/auth/local_auth_controller.dart';
import '../../core/auth/token_store.dart';
import '../../features/auth/application/auth_controller.dart';
import '../db/local_database.dart';
import '../db/local_database_provider.dart';
import 'local_backend.dart';

/// The provider overrides that run the app (or a test) in local mode over [db]: the repositories keep talking HTTP,
/// and [LocalBackend] answers in-process.
List<Override> localBackendOverrides(LocalDatabase db, {int Function()? clock}) => [
      localDatabaseProvider.overrideWithValue(db),
      httpAdapterProvider.overrideWithValue(LocalBackend(db, clock: clock)),
    ];

/// Everything `QESMA_MODE=local` needs (SA4): the mode itself, the local backend, the profile-only "session"
/// ([LocalAuthController]) and a token store that stores nothing. `main.dart` and the local app tests use it.
List<Override> localModeOverrides(LocalDatabase db, {int Function()? clock}) => [
      appModeProvider.overrideWithValue(AppMode.local),
      ...localBackendOverrides(db, clock: clock),
      authControllerProvider.overrideWith(LocalAuthController.new),
      tokenStoreProvider.overrideWithValue(const NoTokenStore()),
    ];
