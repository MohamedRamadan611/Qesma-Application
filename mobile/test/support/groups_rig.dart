import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/groups/application/group_detail_controller.dart';
import 'package:qesma/features/groups/application/groups_list_controller.dart';

import 'auth_rig.dart';
import 'fake_groups_server.dart';

/// The real groups stack (repository, controllers, generated client, Dio) on a fake server.
/// Controllers do not auto-load, so a test drives them step by step.
ProviderContainer groupsContainer(FakeGroupsServer server, {bool autoLoad = false, List<Override> extra = const []}) {
  final container = ProviderContainer(
    overrides: [
      httpAdapterProvider.overrideWithValue(server),
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      googleIdTokenSourceProvider.overrideWithValue(FakeGoogleSource()),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
      autoRestoreProvider.overrideWithValue(false),
      groupsAutoLoadProvider.overrideWithValue(autoLoad),
      groupDetailAutoLoadProvider.overrideWithValue(autoLoad),
      ...extra,
    ],
  );
  return container;
}
