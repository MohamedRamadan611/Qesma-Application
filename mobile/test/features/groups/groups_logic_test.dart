import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/errors/api_failure.dart';
import 'package:qesma/core/errors/api_problem.dart';
import 'package:qesma/features/groups/application/create_group_controller.dart';
import 'package:qesma/features/groups/application/group_detail_controller.dart';
import 'package:qesma/features/groups/application/groups_list_controller.dart';
import 'package:qesma/features/groups/data/groups_repository.dart';

import '../../support/fake_groups_server.dart';
import '../../support/groups_rig.dart';

ApiErrorCode? _code(Object? e) => e is ApiHttpFailure ? e.problem?.code : null;

Future<ApiFailure> _failure(Future<Object?> call) async {
  try {
    await call;
  } on ApiFailure catch (e) {
    return e;
  }
  fail('expected an ApiFailure');
}

void main() {
  late FakeGroupsServer server;
  late ProviderContainer c;

  setUp(() {
    server = FakeGroupsServer();
    c = groupsContainer(server);
  });
  tearDown(() => c.dispose());

  GroupsRepository repo() => c.read(groupsRepositoryProvider);

  group('repository', () {
    test('lists page by page with page and size 20', () async {
      for (var i = 0; i < 25; i++) {
        server.seed();
      }
      final first = await repo().list();
      expect(first.items, hasLength(20));
      expect(first.totalPages, 2);
      final second = await repo().list(page: 1);
      expect(second.items, hasLength(5));
      expect(server.requests, ['GET /api/v1/groups?page=0&size=20', 'GET /api/v1/groups?page=1&size=20']);
    });

    test('an edit sends If-Match with the version read from the ETag', () async {
      final g = server.seed(name: 'Dahab');
      await repo().get(g.id);
      final updated = await repo().update(g.id, name: 'Dahab 2', type: 'TRIP');
      expect(updated.name, 'Dahab 2');
      expect(server.requests.last, contains('if-match="1"'));
      // The new ETag is remembered for the next edit.
      await repo().update(g.id, name: 'Dahab 3', type: 'TRIP');
      expect(server.requests.last, contains('if-match="2"'));
    });

    test('a stale version is refused with VERSION_CONFLICT and changes nothing', () async {
      final g = server.seed(name: 'Dahab');
      await repo().get(g.id);
      g.version = 5; // somebody else edited
      final failure = await _failure(repo().update(g.id, name: 'Mine', type: 'TRIP'));
      expect(_code(failure), ApiErrorCode.versionConflict);
      expect(g.name, 'Dahab');
    });

    test('no blind edit: without a previous read nothing is sent', () async {
      final g = server.seed();
      final failure = await _failure(repo().update(g.id, name: 'x', type: 'TRIP'));
      expect(failure, isA<ApiUnexpected>());
      expect(server.requests, isEmpty);
    });

    test('blocked deletes and the owner member rule come back as their codes', () async {
      final g = server.seed(hasExpenses: true);
      expect(_code(await _failure(repo().delete(g.id))), ApiErrorCode.groupNotEmpty);
      final other = await repo().addMember(g.id, 'Asem');
      g.members.last.hasTransactions = true;
      expect(_code(await _failure(repo().deleteMember(g.id, other.id))), ApiErrorCode.memberHasTransactions);
      expect(_code(await _failure(repo().deleteMember(g.id, '${g.id}-m1'))), ApiErrorCode.ownerMemberProtected);
    });

    test('duplicate member names are refused; rename works; 404 and offline map cleanly', () async {
      final g = server.seed();
      await repo().addMember(g.id, 'Asem');
      expect(_code(await _failure(repo().addMember(g.id, 'Asem'))), ApiErrorCode.duplicateMemberName);
      final renamed = await repo().renameMember(g.id, '${g.id}-m2', 'Asem K');
      expect(renamed.displayName, 'Asem K');
      expect(_code(await _failure(repo().get('nope'))), ApiErrorCode.notFound);
      server.offline = true;
      expect(await _failure(repo().list()), isA<ApiNoConnection>());
    });
  });

  group('groups list controller', () {
    test('loads the first page, then more on demand, and stops at the end', () async {
      for (var i = 0; i < 45; i++) {
        server.seed();
      }
      final controller = c.read(groupsListControllerProvider.notifier);
      await controller.load();
      expect(c.read(groupsListControllerProvider).items, hasLength(20));
      expect(c.read(groupsListControllerProvider).hasMore, isTrue);

      await controller.loadMore();
      await controller.loadMore();
      expect(c.read(groupsListControllerProvider).items, hasLength(45));
      expect(c.read(groupsListControllerProvider).hasMore, isFalse);

      final before = server.requests.length;
      await controller.loadMore(); // nothing left
      expect(server.requests.length, before);
    });

    test('two loadMore calls at once fetch the next page only once', () async {
      for (var i = 0; i < 30; i++) {
        server.seed();
      }
      final controller = c.read(groupsListControllerProvider.notifier);
      await controller.load();
      await Future.wait([controller.loadMore(), controller.loadMore()]);
      expect(server.requests.where((r) => r.contains('page=1')), hasLength(1));
      expect(c.read(groupsListControllerProvider).items, hasLength(30));
    });

    test('refresh replaces the list without duplicates; a failed refresh keeps the old list', () async {
      for (var i = 0; i < 25; i++) {
        server.seed();
      }
      final controller = c.read(groupsListControllerProvider.notifier);
      await controller.load();
      await controller.loadMore();
      server.seed(name: 'New');
      expect(await controller.refresh(), isNull);
      final ids = c.read(groupsListControllerProvider).items.map((g) => g.id).toList();
      expect(ids.toSet(), hasLength(ids.length));

      server.offline = true;
      expect(await controller.refresh(), isA<ApiNoConnection>());
      expect(c.read(groupsListControllerProvider).items, hasLength(ids.length));
      expect(c.read(groupsListControllerProvider).status, GroupsStatus.ready);
    });

    test('first load failure is an error state that can retry', () async {
      server.offline = true;
      final controller = c.read(groupsListControllerProvider.notifier);
      await controller.load();
      expect(c.read(groupsListControllerProvider).status, GroupsStatus.failed);
      server.offline = false;
      server.seed();
      await controller.load();
      expect(c.read(groupsListControllerProvider).status, GroupsStatus.ready);
    });

    test('the net header: integer sum of server values, only when everything is loaded and one currency', () async {
      server
        ..seed(net: 6500)
        ..seed(net: -3200)
        ..seed(net: 0);
      final controller = c.read(groupsListControllerProvider.notifier);
      await controller.load();
      expect(c.read(groupsListControllerProvider).netTotalMinor, 3300);

      server.seed(currency: 'USD', net: 100);
      await controller.load();
      expect(c.read(groupsListControllerProvider).netTotalMinor, isNull, reason: 'mixed currencies');
    });

    test('no net header while more pages are unloaded (a partial sum would be wrong)', () async {
      for (var i = 0; i < 30; i++) {
        server.seed(net: 100);
      }
      final controller = c.read(groupsListControllerProvider.notifier);
      await controller.load();
      expect(c.read(groupsListControllerProvider).netTotalMinor, isNull);
      await controller.loadMore();
      expect(c.read(groupsListControllerProvider).netTotalMinor, 3000);
    });
  });

  group('create group never duplicates', () {
    CreateGroupController create() {
      c.listen(createGroupControllerProvider, (_, _) {}); // a screen would be listening
      return c.read(createGroupControllerProvider.notifier);
    }

    int posts() => server.requests.where((r) => r.startsWith('POST /api/v1/groups')).length;

    test('success returns the new id and the list is refreshed', () async {
      server.seed();
      await c.read(groupsListControllerProvider.notifier).load();
      final id = await create().submit(name: 'Dahab', type: 'TRIP');
      expect(id, isNotNull);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(c.read(groupsListControllerProvider).items.any((g) => g.name == 'Dahab'), isTrue);
    });

    test('a lost response: the group is found in the list, no second POST, no duplicate', () async {
      server.nextCreateFault = CreateFault.loseResponseAfterStoring;
      final id = await create().submit(name: 'Dahab', type: 'TRIP');
      expect(id, isNotNull);
      expect(posts(), 1);
      expect(server.groups.values.where((g) => g.name == 'Dahab'), hasLength(1));
    });

    test('a lost response while offline: unknown outcome; once back online it finds the group instead of re-posting', () async {
      server
        ..nextCreateFault = CreateFault.loseResponseAfterStoring
        ..goOfflineAfterFault = true;
      expect(await create().submit(name: 'Dahab', type: 'TRIP'), isNull);
      expect(c.read(createGroupControllerProvider).outcomeUnknown, isTrue);

      server.offline = false;
      final id = await create().submit(name: 'Dahab', type: 'TRIP');
      expect(id, isNotNull);
      expect(posts(), 1, reason: 'the retry must check first and not POST again');
      expect(server.groups.values.where((g) => g.name == 'Dahab'), hasLength(1));
    });

    test('a 500 that stored nothing: reachable server and no such group, so a retry is allowed and creates exactly one', () async {
      server.nextCreateFault = CreateFault.serverErrorNothingStored;
      expect(await create().submit(name: 'Dahab', type: 'TRIP'), isNull);
      expect(c.read(createGroupControllerProvider).outcomeUnknown, isFalse);
      expect(server.groups, isEmpty);

      expect(await create().submit(name: 'Dahab', type: 'TRIP'), isNotNull);
      expect(server.groups.values.where((g) => g.name == 'Dahab'), hasLength(1));
    });

    test('a validation error is a plain failure, not an unknown outcome', () async {
      server.nextCreateFault = CreateFault.validation;
      expect(await create().submit(name: 'x', type: 'TRIP'), isNull);
      final state = c.read(createGroupControllerProvider);
      expect(_code(state.failure), ApiErrorCode.validationError);
      expect(state.outcomeUnknown, isFalse);
    });

    test('a second tap while submitting is ignored', () async {
      final first = create().submit(name: 'Dahab', type: 'TRIP');
      final second = create().submit(name: 'Dahab', type: 'TRIP');
      await Future.wait([first, second]);
      expect(server.groups.values.where((g) => g.name == 'Dahab'), hasLength(1));
    });

    test('an existing group with the same name is not mistaken for the new one', () async {
      server.seed(name: 'Dahab', type: 'TRIP');
      server.nextCreateFault = CreateFault.serverErrorNothingStored;
      expect(await create().submit(name: 'Dahab', type: 'TRIP'), isNull);
      expect(server.groups.values.where((g) => g.name == 'Dahab'), hasLength(1), reason: 'the pre-existing one only');
      expect(await create().submit(name: 'Dahab', type: 'TRIP'), isNotNull);
      expect(server.groups.values.where((g) => g.name == 'Dahab'), hasLength(2), reason: 'a real second group is allowed');
    });
  });

  group('group detail controller', () {
    GroupDetailController detail(String gid) {
      c.listen(groupDetailControllerProvider(gid), (_, _) {}); // a screen would be listening
      return c.read(groupDetailControllerProvider(gid).notifier);
    }

    GroupDetailState state(String gid) => c.read(groupDetailControllerProvider(gid));

    test('loads the group; a missing group is "gone"', () async {
      final g = server.seed(name: 'Dahab');
      await detail(g.id).load();
      expect(state(g.id).group?.name, 'Dahab');
      await detail('nope').load();
      expect(state('nope').gone, isTrue);
    });

    test('save updates the group and its version', () async {
      final g = server.seed(name: 'Dahab');
      await detail(g.id).load();
      expect(await detail(g.id).save(name: 'Dahab 2', type: 'OUTING'), isNull);
      expect(state(g.id).group?.name, 'Dahab 2');
      expect(state(g.id).group?.version, 2);
      expect(state(g.id).busy, isFalse);
    });

    test('conflict flow: stale save fails, reload gets the new version, the re-applied save works', () async {
      final g = server.seed(name: 'Dahab');
      await detail(g.id).load();
      g
        ..name = 'Edited elsewhere'
        ..version = 2;

      final failure = await detail(g.id).save(name: 'My edit', type: 'TRIP');
      expect(_code(failure), ApiErrorCode.versionConflict);
      expect(g.name, 'Edited elsewhere');

      await detail(g.id).load(); // the user agreed to reload; the form keeps their text
      expect(state(g.id).group?.name, 'Edited elsewhere');
      expect(await detail(g.id).save(name: 'My edit', type: 'TRIP'), isNull);
      expect(g.name, 'My edit');
      expect(server.requests.where((r) => r.contains('PATCH')).last, contains('if-match="2"'));
    });

    test('delete: blocked when the group has expenses, otherwise gone', () async {
      final used = server.seed(hasExpenses: true);
      await detail(used.id).load();
      expect(_code(await detail(used.id).delete()), ApiErrorCode.groupNotEmpty);
      expect(server.groups.containsKey(used.id), isTrue);

      final empty = server.seed();
      await detail(empty.id).load();
      expect(await detail(empty.id).delete(), isNull);
      expect(server.groups.containsKey(empty.id), isFalse);
    });

    test('members: add, duplicate, rename, delete, blocked delete, owner protected', () async {
      final g = server.seed();
      await detail(g.id).load();
      expect(await detail(g.id).addMember('Asem'), isNull);
      expect(state(g.id).group?.members.length, 2);
      expect(_code(await detail(g.id).addMember('Asem')), ApiErrorCode.duplicateMemberName);

      final mid = '${g.id}-m2';
      expect(await detail(g.id).renameMember(mid, 'Asem K'), isNull);
      expect(state(g.id).group?.members.any((m) => m.displayName == 'Asem K'), isTrue);

      g.members.last.hasTransactions = true;
      expect(_code(await detail(g.id).deleteMember(mid)), ApiErrorCode.memberHasTransactions);
      expect(_code(await detail(g.id).deleteMember('${g.id}-m1')), ApiErrorCode.ownerMemberProtected);

      g.members.last.hasTransactions = false;
      expect(await detail(g.id).deleteMember(mid), isNull);
      expect(state(g.id).group?.members.length, 1);
    });
  });
}
