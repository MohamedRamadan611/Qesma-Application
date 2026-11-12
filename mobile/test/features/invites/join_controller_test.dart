import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/auth/application/auth_state.dart';
import 'package:qesma/features/invites/application/join_controller.dart';
import 'package:qesma/features/invites/application/pending_invite.dart';

import '../../support/fake_invites_server.dart';
import '../../support/invites_rig.dart';

const _code = 'ABCD2345';

Future<(InvitesHarness, JoinController)> _open(FakeInvitesServer server, {String? stored}) async {
  final h = InvitesHarness(server, storedPending: stored);
  addTearDown(h.dispose);
  // keep the autoDispose provider alive for the whole test
  h.container.listen(joinControllerProvider(_code), (_, _) {});
  final controller = h.container.read(joinControllerProvider(_code).notifier);
  await controller.load();
  return (h, controller);
}

JoinState _state(InvitesHarness h) => h.container.read(joinControllerProvider(_code));

void main() {
  group('preview', () {
    test('a backend-shaped preview fills the form: unclaimed names only, the name prefilled from the account', () async {
      final (h, _) = await _open(inviteServer());
      final s = _state(h);
      expect(s.phase, JoinPhase.ready);
      expect(s.preview!.groupName, 'رحلة دهب');
      expect(s.preview!.inviterName, 'محمد');
      expect(s.preview!.memberCount, 5);
      expect(s.unclaimed.map((m) => m.name), ['محسن', 'يوسف', 'كريم']);
      expect(s.newName, 'Test User');
      expect(s.canSubmit, isFalse, reason: 'disabled until a choice is made');
    });

    test('the long display name is cut to the 40 code points the backend allows', () async {
      final longUser = testUser.rebuild((b) => b.displayName = 'ا' * 60);
      final h = InvitesHarness(inviteServer(), auth: AuthSignedIn(longUser));
      addTearDown(h.dispose);
      h.container.listen(joinControllerProvider(_code), (_, _) {});
      expect(h.container.read(joinControllerProvider(_code)).newName.runes.length, joinNameMax);
    });

    test('with no unclaimed names the only choice is "new member"', () async {
      final (h, controller) = await _open(inviteServer(preview: FakePreview(unclaimed: [])));
      expect(_state(h).joinAsNew, isTrue);
      expect(_state(h).canSubmit, isTrue, reason: 'the prefilled name is a valid choice');
      controller.setName('   ');
      expect(_state(h).canSubmit, isFalse);
    });
  });

  group('the right state for every error', () {
    final table = <String, (int, String, JoinPhase)>{
      'expired': (410, 'INVITE_EXPIRED', JoinPhase.expired),
      'revoked': (410, 'INVITE_REVOKED', JoinPhase.revoked),
      'unknown': (404, 'NOT_FOUND', JoinPhase.notFound),
      'already a member': (409, 'ALREADY_MEMBER', JoinPhase.alreadyMember),
      'rate limited': (429, 'RATE_LIMITED', JoinPhase.rateLimited),
      'server error': (500, 'INTERNAL_ERROR', JoinPhase.failed),
    };
    for (final entry in table.entries) {
      test('preview: ${entry.key}', () async {
        final server = inviteServer()..previewFaults.add((entry.value.$1, entry.value.$2));
        final (h, _) = await _open(server, stored: _code);
        expect(_state(h).phase, entry.value.$3);
      });
    }

    test('a dead invite clears the pending code, a retryable failure keeps it', () async {
      for (final (status, code, clears) in [(410, 'INVITE_EXPIRED', true), (410, 'INVITE_REVOKED', true), (404, 'NOT_FOUND', true), (500, 'INTERNAL_ERROR', false)]) {
        final h = InvitesHarness(inviteServer()..previewFaults.add((status, code)));
        addTearDown(h.dispose);
        await h.container.read(pendingInviteProvider.notifier).remember(_code);
        h.container.listen(joinControllerProvider(_code), (_, _) {});
        await h.container.read(joinControllerProvider(_code).notifier).load();
        await Future<void>.delayed(Duration.zero);
        expect(h.container.read(pendingInviteProvider).code, clears ? isNull : _code, reason: code);
        expect(h.pending.value, clears ? isNull : _code, reason: '$code (secure storage)');
      }
    });

    test('the preview of a member says "already a member"; of a waiting person says "waiting"', () async {
      final (h, _) = await _open(inviteServer(preview: FakePreview(callerState: 'ALREADY_MEMBER')));
      expect(_state(h).phase, JoinPhase.alreadyMember);
      final (h2, _) = await _open(inviteServer(preview: FakePreview(callerState: 'PENDING_APPROVAL')));
      expect(_state(h2).phase, JoinPhase.awaitingApproval);
    });

    test('join: DUPLICATE_MEMBER_NAME stays on the form as an inline error and clears when the name changes', () async {
      final server = inviteServer()..joinFaults.add((409, 'DUPLICATE_MEMBER_NAME'));
      final (h, c) = await _open(server);
      c.selectNew();
      c.setName('محسن');
      await c.submit();
      expect(_state(h).phase, JoinPhase.ready);
      expect(_state(h).duplicateName, isTrue);
      c.setName('محسن علي');
      expect(_state(h).duplicateName, isFalse);
    });

    test('join: MEMBER_ALREADY_CLAIMED re-reads the list, drops the taken name and keeps the typed name', () async {
      final server = inviteServer()..joinFaults.add((409, 'MEMBER_ALREADY_CLAIMED'));
      final (h, c) = await _open(server);
      c.setName('اسم كتبته');
      c.selectMember('u1');
      // somebody else took u1 before our request
      server.previews[_code]!.unclaimed = [(id: 'u2', name: 'يوسف'), (id: 'u3', name: 'كريم')];
      await c.submit();
      await Future<void>.delayed(Duration.zero);
      final s = _state(h);
      expect(s.phase, JoinPhase.ready);
      expect(s.claimedNotice, isTrue);
      expect(s.claimMemberId, isNull);
      expect(s.unclaimed.map((m) => m.id), ['u2', 'u3']);
      expect(s.newName, 'اسم كتبته', reason: 'the form is kept');
    });

    test('join: INVITE_EXPIRED / REVOKED / ALREADY_MEMBER / RATE_LIMITED move to their state', () async {
      for (final (status, code, phase) in [
        (410, 'INVITE_EXPIRED', JoinPhase.expired),
        (410, 'INVITE_REVOKED', JoinPhase.revoked),
        (409, 'ALREADY_MEMBER', JoinPhase.alreadyMember),
      ]) {
        final server = inviteServer()..joinFaults.add((status, code));
        final (h, c) = await _open(server);
        c.selectMember('u1');
        await c.submit();
        expect(_state(h).phase, phase, reason: code);
      }
      final server = inviteServer()..joinFaults.add((429, 'RATE_LIMITED'));
      final (h, c) = await _open(server);
      c.selectMember('u1');
      await c.submit();
      expect(_state(h).phase, JoinPhase.ready, reason: 'the form stays, the banner explains');
      expect(_state(h).failure, isNotNull);
    });
  });

  group('join outcomes', () {
    test('201: the groups list is refreshed, the group id is handed to the screen, the pending code is gone', () async {
      final server = inviteServer();
      final (h, c) = await _open(server, stored: _code);
      await h.container.read(pendingInviteProvider.notifier).remember(_code);
      c.selectMember('u1');
      await c.submit();
      expect(_state(h).joinedGroupId, 'g1');
      expect(server.joinBodies.single, {'claimMemberId': 'u1'});
      expect(server.requests.where((r) => r.startsWith('GET /api/v1/groups')), isNotEmpty, reason: 'groups refetched');
      await Future<void>.delayed(Duration.zero);
      expect(h.pending.value, isNull);
    });

    test('202: waiting, and a refresh that finds the member turns it into "already a member"', () async {
      final server = inviteServer(preview: FakePreview(requiresApproval: true))..joinNeedsApproval = true;
      final (h, c) = await _open(server);
      c.setName('Test User');
      c.selectNew();
      await c.submit();
      expect(_state(h).phase, JoinPhase.awaitingApproval);
      expect(server.joinBodies.single, {'newMemberName': 'Test User'});
      // still waiting
      server.previews[_code]!.callerState = 'PENDING_APPROVAL';
      await c.refreshStatus();
      expect(_state(h).phase, JoinPhase.awaitingApproval);
      // approved meanwhile
      server.previews[_code]!.callerState = 'ALREADY_MEMBER';
      await c.refreshStatus();
      expect(_state(h).phase, JoinPhase.alreadyMember);
    });

    test('a failed refresh keeps the waiting screen', () async {
      final server = inviteServer(preview: FakePreview(callerState: 'PENDING_APPROVAL'));
      final (h, c) = await _open(server);
      server.previewFaults.add((500, 'INTERNAL_ERROR'));
      await c.refreshStatus();
      expect(_state(h).phase, JoinPhase.awaitingApproval);
    });
  });

  group('Idempotency-Key of the join', () {
    test('a retry after an unknown outcome reuses the key, a changed body gets a new one', () async {
      final server = inviteServer()..loseNextJoinResponse = true;
      final (h, c) = await _open(server);
      c.selectMember('u1');
      await c.submit(); // the answer is lost: timeout
      expect(_state(h).phase, JoinPhase.ready);
      expect(_state(h).failure, isNotNull);
      final first = server.joinKeys.single;
      expect(c.currentKey, first, reason: 'kept for the retry');

      await c.submit(); // same choice, same key
      expect(server.joinKeys, [first, first]);
    });

    test('another member or another name is another request: new key', () async {
      final server = inviteServer()..joinFaults.addAll([(500, 'INTERNAL_ERROR'), (500, 'INTERNAL_ERROR'), (500, 'INTERNAL_ERROR')]);
      final (_, c) = await _open(server);
      c.selectMember('u1');
      await c.submit();
      c.selectMember('u2');
      await c.submit();
      c.selectNew();
      c.setName('Test User');
      await c.submit();
      expect(server.joinKeys.toSet().length, 3);
    });

    test('success and definitive errors forget the key', () async {
      final server = inviteServer()..joinFaults.add((409, 'DUPLICATE_MEMBER_NAME'));
      final (_, c) = await _open(server);
      c.selectNew();
      c.setName('x');
      await c.submit();
      expect(c.currentKey, isNull, reason: 'a definitive error');
      await c.submit();
      expect(c.currentKey, isNull, reason: 'success');
    });

    test('IDEMPOTENCY_KEY_REUSED is retried once with a new key', () async {
      final server = inviteServer()..joinFaults.add((422, 'IDEMPOTENCY_KEY_REUSED'));
      final (h, c) = await _open(server);
      c.selectMember('u1');
      await c.submit();
      expect(server.joinKeys.length, 2);
      expect(server.joinKeys[0], isNot(server.joinKeys[1]));
      expect(_state(h).joinedGroupId, 'g1');
    });
  });
}
