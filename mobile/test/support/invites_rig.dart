import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/format/clock.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/invites/application/invite_sheet_controller.dart';
import 'package:qesma/features/invites/application/join_controller.dart';
import 'package:qesma/features/invites/application/pending_invite.dart';
import 'package:qesma_api/qesma_api.dart';

import 'auth_ui.dart';
import 'fake_invites_server.dart';
import 'groups_rig.dart';

final UserDto testUser = UserDto((b) => b
  ..hasPassword = false
  ..emailVerified = true
  ..id = 'u1'
  ..displayName = 'Test User'
  ..email = 'test@example.com');

/// Everything a test may want to look at after the fact.
class InvitesHarness {
  InvitesHarness(this.server, {AuthState? auth, bool autoLoad = false, List<Override> extra = const [], String? storedPending}) {
    pending = InMemoryPendingInviteStorage(storedPending);
    container = groupsContainer(
      server,
      autoLoad: autoLoad,
      extra: [
        authControllerProvider.overrideWith(() => StubAuth(auth ?? AuthSignedIn(testUser))),
        clockProvider.overrideWithValue(() => FakeInvitesServer.serverNow),
        inviteSharerProvider.overrideWithValue(sharer),
        clipboardWriterProvider.overrideWithValue((text) async => copied.add(text)),
        pendingInviteStorageProvider.overrideWithValue(pending),
        joinAutoLoadProvider.overrideWithValue(autoLoad),
        inviteSheetAutoLoadProvider.overrideWithValue(autoLoad),
        ...extra,
      ],
    );
  }

  final FakeInvitesServer server;
  final RecordingSharer sharer = RecordingSharer();
  final List<String> copied = [];
  late final InMemoryPendingInviteStorage pending;
  late final ProviderContainer container;

  void dispose() => container.dispose();
}

/// The real app (router, guard, controllers, generated client) on the fake invites server.
Future<InvitesHarness> pumpInvitesApp(
  WidgetTester tester,
  FakeInvitesServer server, {
  AuthState? auth,
  String? route,
  Locale locale = const Locale('ar'),
  double textScale = 1.0,
  double height = 2400,
  String? storedPending,
  List<Override> extra = const [],
}) async {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = Size(360, height);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  final harness = InvitesHarness(server, auth: auth, autoLoad: true, extra: extra, storedPending: storedPending);
  addTearDown(harness.dispose);
  harness.container.read(localeProvider.notifier).set(locale);
  await tester.pumpWidget(UncontrolledProviderScope(container: harness.container, child: const QesmaApp()));
  await tester.pumpAndSettle();
  if (route != null) {
    harness.container.read(routerProvider).go(route);
    await tester.pumpAndSettle();
  }
  return harness;
}

/// A server with one group the signed-in person owns (g1) and an invite preview for [code].
FakeInvitesServer inviteServer({String code = 'ABCD2345', FakePreview? preview}) {
  final server = FakeInvitesServer();
  server.seed(name: 'رحلة دهب');
  server.previews[code] = preview ?? FakePreview();
  return server;
}
