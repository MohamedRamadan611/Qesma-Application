import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/api_providers.dart';
import 'package:qesma/core/api/etag_store.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/groups/data/groups_repository.dart';

/// FL3 against a REAL local backend (profile `local,fake-auth`): create, paging, ETag/If-Match,
/// a real VERSION_CONFLICT, members, deletes. Skipped unless `API_BASE_URL` is given (see
/// auth_flow_test.dart). Uses a unique fake user so it never touches the seed data.
const String _baseUrl = String.fromEnvironment('API_BASE_URL');

void main() {
  final skip = _baseUrl.isEmpty ? 'set API_BASE_URL to run against a local backend' : null;

  setUpAll(() => HttpOverrides.global = null);

  test('groups and members against the real backend', () async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final container = ProviderContainer(overrides: [
      tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
      autoRestoreProvider.overrideWithValue(false),
      authLogProvider.overrideWithValue(RecordingAuthLog()),
    ]);
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).signInWithIdToken('fake:fl3-$stamp:fl3-$stamp@example.com:Tester');
    expect(container.read(authControllerProvider), isA<AuthSignedIn>());
    final repo = container.read(groupsRepositoryProvider);

    // create 22 groups -> 2 pages of 20
    final ids = <String>[];
    for (var i = 0; i < 22; i++) {
      ids.add((await repo.create(name: 'g$i', type: 'TRIP')).id);
    }
    final p0 = await repo.list(page: 0);
    final p1 = await repo.list(page: 1);
    expect(p0.items.length, 20);
    expect(p1.items.length, 2);
    expect(p0.totalPages, 2);
    expect((await repo.listAll()).length, 22);

    final gid = ids.first;
    final g = await repo.get(gid);
    expect(g.members.length, 1);
    expect(g.members.first.isYou, isTrue);
    expect(g.yourNetMinor, 0);

    // If-Match edit, then a stale edit hits a real 409
    final updated = await repo.update(gid, name: 'renamed', type: 'HOUSING');
    expect(updated.name, 'renamed');
    expect(updated.version, greaterThan(g.version));
    final staleRepo = container.read(groupsRepositoryProvider);
    expect(staleRepo, same(repo));

    // second client with a stale version
    final other = GroupsRepository(container.read(qesmaApiProvider), ETagStore());
    await other.get(gid);
    await repo.update(gid, name: 'renamed2', type: 'HOUSING'); // bumps version
    Object? caught;
    try {
      await other.update(gid, name: 'stale', type: 'TRIP');
    } catch (e) {
      caught = e;
    }
    expect(caught, isA<ApiHttpFailure>());
    expect((caught! as ApiHttpFailure).status, anyOf(409, 412));
    // ignore: avoid_print
    print('stale update -> ${(caught as ApiHttpFailure).status} ${(caught).problem?.code}');

    // members
    final m = await repo.addMember(gid, 'Ali');
    await expectLater(repo.addMember(gid, 'Ali'), throwsA(isA<ApiHttpFailure>()));
    final r = await repo.renameMember(gid, m.id, 'Ali2');
    expect(r.displayName, 'Ali2');
    final me = (await repo.get(gid)).members.firstWhere((x) => x.isYou);
    Object? ownerErr;
    try {
      await repo.deleteMember(gid, me.id);
    } catch (e) {
      ownerErr = e;
    }
    expect(ownerErr, isA<ApiHttpFailure>());
    // ignore: avoid_print
    print('delete owner member -> ${(ownerErr! as ApiHttpFailure).status} ${(ownerErr as ApiHttpFailure).problem?.code}');
    await repo.deleteMember(gid, m.id);

    // delete all groups
    for (final id in ids) {
      await repo.delete(id);
    }
    expect((await repo.list()).items, isEmpty);
  }, skip: skip, timeout: const Timeout(Duration(minutes: 3)));
}
