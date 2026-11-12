import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/forbidden_events.dart';
import 'package:qesma/core/format/clock.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/groups/application/freshness.dart';
import 'package:qesma/features/groups/application/group_detail_controller.dart';
import 'package:qesma/features/groups/application/groups_list_controller.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../support/auth_ui.dart';
import '../../support/fake_groups_server.dart';
import '../../support/groups_rig.dart';

final UserDto _user = UserDto((b) => b
  ..hasPassword = false
  ..emailVerified = true
  ..id = 'u1'
  ..displayName = 'Test User');

/// A clock the test moves by hand.
class _Time {
  DateTime now = DateTime.utc(2026, 11, 12, 10);
  DateTime call() => now;
}

void main() {
  late FakeGroupsServer server;
  late FakeGroup dahab;
  late _Time time;
  late String location;

  setUp(() {
    server = FakeGroupsServer();
    dahab = server.seed(name: 'Dahab');
    time = _Time();
    location = '/';
  });

  ProviderContainer container({AuthState? auth}) {
    final c = groupsContainer(server, extra: [
      authControllerProvider.overrideWith(() => StubAuth(auth ?? AuthSignedIn(_user))),
      clockProvider.overrideWithValue(time.call),
      freshnessLocationProvider.overrideWithValue(() => location),
    ]);
    addTearDown(c.dispose);
    c.read(freshnessProvider); // the host creates it when the app starts: the gap counts from then
    return c;
  }

  Future<void> settle() => Future<void>.delayed(const Duration(milliseconds: 20));

  int count(String request) => server.requests.where((r) => r == request || r.startsWith('$request?')).length;

  group('coming back to the app', () {
    test('after the gap the groups list is read again', () async {
      final c = container();
      await c.read(groupsListControllerProvider.notifier).load();
      final before = count('GET /api/v1/groups');

      time.now = time.now.add(resumeRefreshMinGap + const Duration(seconds: 1));
      c.read(freshnessProvider).onResumed();
      await settle();

      expect(count('GET /api/v1/groups'), before + 1);
    });

    test('inside the gap nothing is read (a quick switch to another app and back costs nothing)', () async {
      final c = container();
      await c.read(groupsListControllerProvider.notifier).load();
      final before = count('GET /api/v1/groups');

      time.now = time.now.add(resumeRefreshMinGap - const Duration(seconds: 1));
      c.read(freshnessProvider).onResumed();
      await settle();

      expect(count('GET /api/v1/groups'), before);
    });

    test('two resumes in a row refresh once: the gap counts from the last refresh', () async {
      final c = container();
      await c.read(groupsListControllerProvider.notifier).load();
      final before = count('GET /api/v1/groups');

      time.now = time.now.add(const Duration(minutes: 5));
      c.read(freshnessProvider).onResumed();
      time.now = time.now.add(const Duration(seconds: 2));
      c.read(freshnessProvider).onResumed();
      await settle();

      expect(count('GET /api/v1/groups'), before + 1);
    });

    test('while signed out, restoring or expired nothing is read', () async {
      for (final AuthState state in const [AuthSignedOut(), AuthRestoring(), AuthSessionExpired()]) {
        final c = container(auth: state);
        await c.read(groupsListControllerProvider.notifier).load();
        final before = count('GET /api/v1/groups');
        time.now = time.now.add(const Duration(minutes: 5));
        c.read(freshnessProvider).onResumed();
        await settle();
        expect(count('GET /api/v1/groups'), before, reason: '$state');
      }
    });

    test('the group on screen is read again; a group that is not alive is never created for the purpose', () async {
      final c = container();
      await c.read(groupsListControllerProvider.notifier).load();
      c.listen(groupDetailControllerProvider(dahab.id), (_, _) {});
      await c.read(groupDetailControllerProvider(dahab.id).notifier).load();
      location = '/groups/${dahab.id}';
      final detailBefore = count('GET /api/v1/groups/${dahab.id}');

      time.now = time.now.add(const Duration(minutes: 5));
      c.read(freshnessProvider).onResumed();
      await settle();
      expect(count('GET /api/v1/groups/${dahab.id}'), detailBefore + 1);

      // another group: nothing alive for it, so nothing is requested
      location = '/groups/00000000-0000-0000-0000-000000000000';
      final other = count('GET /api/v1/groups/00000000-0000-0000-0000-000000000000');
      time.now = time.now.add(const Duration(minutes: 5));
      c.read(freshnessProvider).onResumed();
      await settle();
      expect(count('GET /api/v1/groups/00000000-0000-0000-0000-000000000000'), other);
    });

    test('no controller exists that nobody asked for', () async {
      final c = container();
      time.now = time.now.add(const Duration(minutes: 5));
      c.read(freshnessProvider).onResumed();
      await settle();
      expect(c.read(groupsListControllerProvider.exists), isFalse, reason: 'refreshing never creates a list controller');
      expect(server.requests.where((r) => r.contains('/groups')), isEmpty);
    });
  });

  group('a 403 for a group', () {
    test('reloads that group and the list so the role catches up', () async {
      final c = container();
      await c.read(groupsListControllerProvider.notifier).load();
      c.listen(groupDetailControllerProvider(dahab.id), (_, _) {});
      await c.read(groupDetailControllerProvider(dahab.id).notifier).load();
      expect(c.read(groupDetailControllerProvider(dahab.id)).group!.yourRole, 'OWNER');

      dahab.yourRole = 'MEMBER'; // an admin demoted this person meanwhile
      c.read(freshnessProvider).onForbidden(dahab.id);
      await settle();

      expect(c.read(groupDetailControllerProvider(dahab.id)).group!.yourRole, 'MEMBER');
    });

    test('the same happens through the event the interceptor reports', () async {
      final c = container();
      c.listen(groupDetailControllerProvider(dahab.id), (_, _) {});
      await c.read(groupDetailControllerProvider(dahab.id).notifier).load();
      final host = c.listen(forbiddenEventsProvider, (_, next) {
        if (next != null) c.read(freshnessProvider).onForbidden(next.gid);
      });
      addTearDown(host.close);
      final before = count('GET /api/v1/groups/${dahab.id}');

      c.read(forbiddenEventsProvider.notifier).report(dahab.id);
      await settle();

      expect(count('GET /api/v1/groups/${dahab.id}'), before + 1);
    });
  });

  group('the host', () {
    testWidgets('only a real trip to the background counts, and only once it is over', (tester) async {
      final c = container();
      await tester.runAsync(() => c.read(groupsListControllerProvider.notifier).load());
      final before = count('GET /api/v1/groups');
      await tester.pumpWidget(UncontrolledProviderScope(
        container: c,
        child: const Directionality(textDirection: TextDirection.ltr, child: FreshnessHost(child: SizedBox())),
      ));

      time.now = time.now.add(const Duration(minutes: 5));
      final binding = tester.binding;
      // the lifecycle events run inside runAsync so the request they start really goes through the fake server
      // inactive -> resumed (a permission prompt, the app switcher): no refresh
      await tester.runAsync(() async {
        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await settle();
      });
      expect(count('GET /api/v1/groups'), before);

      // paused -> resumed: refresh
      await tester.runAsync(() async {
        for (final s in [
          AppLifecycleState.inactive,
          AppLifecycleState.hidden,
          AppLifecycleState.paused,
          AppLifecycleState.hidden,
          AppLifecycleState.inactive,
          AppLifecycleState.resumed,
        ]) {
          binding.handleAppLifecycleStateChanged(s);
        }
        await settle();
      });
      expect(count('GET /api/v1/groups'), before + 1);
    });
  });
}
