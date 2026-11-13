import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/groups/presentation/members_tab.dart';

import '../../support/expenses_ui.dart' show l10nFor;
import '../../support/fake_groups_server.dart';
import '../../support/test_app.dart';
import '../groups/groups_screens_test.dart' show pumpGroupsApp, tapText;

/// FL12: the members tab v2 on a fake server: badges and chips, the options sheet per role and target, join
/// requests, leave, transfer ownership, error codes and refetching after each change.
const _ar = Locale('ar');
const _en = Locale('en');

FakeGroup seedGroup(FakeGroupsServer server, String viewerRole) {
  final g = server.seed(name: 'Dahab');
  g.yourRole = viewerRole;
  g.members.first.role = viewerRole;
  g.members.addAll([
    if (viewerRole != 'OWNER') FakeMember(id: '${g.id}-nour', name: 'Nour', sortOrder: 2, role: 'OWNER', linked: true),
    if (viewerRole != 'ADMIN') FakeMember(id: '${g.id}-ali', name: 'Ali', sortOrder: 3, role: 'ADMIN', linked: true),
    FakeMember(id: '${g.id}-sara', name: 'Sara', sortOrder: 4, linked: true),
    FakeMember(id: '${g.id}-omar', name: 'Omar', sortOrder: 5),
    FakeMember(id: '${g.id}-hana', name: 'Hana', sortOrder: 6, status: 'LEFT', linked: true),
  ]);
  return g;
}

Future<AppLocalizations> openMembers(WidgetTester tester, FakeGroupsServer server, {Locale locale = _en, double scale = 1.0}) async {
  await pumpGroupsApp(tester, server, locale: locale, textScale: scale, height: 3000);
  final l10n = l10nFor(locale);
  await tapText(tester, 'Dahab');
  await tapText(tester, l10n.groupTabMembers);
  return l10n;
}

Finder inSheet(Finder f) => find.descendant(of: find.byType(AppBottomSheet), matching: f);

Future<void> openOptions(WidgetTester tester, AppLocalizations l10n, String name) async {
  final button = find.byTooltip(l10n.membersOptions(name));
  await tester.ensureVisible(button);
  await tester.tap(button);
  await tester.pumpAndSettle();
}

Future<void> confirmDialog(WidgetTester tester, String label) async {
  await tester.tap(find.descendant(of: find.byType(AlertDialog), matching: find.text(label)));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(loadAppFonts);

  late FakeGroupsServer server;
  setUp(() => server = FakeGroupsServer());

  for (final (locale, scale) in [(_ar, 1.0), (_en, 2.0)]) {
    final tag = '${locale.languageCode} ${scale}x';

    group('badges and chips ($tag)', () {
      testWidgets('every state is text plus icon, never colour alone; LEFT stays in the list', (tester) async {
        seedGroup(server, 'OWNER');
        final l10n = await openMembers(tester, server, locale: locale, scale: scale);
        for (final text in [l10n.membersRoleOwner, l10n.membersRoleAdmin, l10n.membersBadgeConnected, l10n.membersBadgeNameOnly, l10n.membersLeftChip, l10n.membersYouTag]) {
          expect(find.text(text, skipOffstage: false), findsWidgets, reason: text);
        }
        expect(find.byIcon(Icons.link, skipOffstage: false), findsWidgets, reason: 'linked badge icon');
        expect(find.byIcon(Icons.person_outline, skipOffstage: false), findsWidgets, reason: 'name-only badge icon');
        expect(find.byIcon(Icons.logout, skipOffstage: false), findsWidgets, reason: 'left chip icon');
        expect(find.text('Hana', skipOffstage: false), findsOneWidget, reason: 'a member who left is kept');
        expect(tester.takeException(), isNull);
      });

      testWidgets('a plain member has no role chip and no options', (tester) async {
        seedGroup(server, 'MEMBER');
        final l10n = await openMembers(tester, server, locale: locale, scale: scale);
        expect(find.byTooltip(l10n.membersOptions('Sara')), findsNothing);
        expect(find.text(l10n.membersLeave, skipOffstage: false), findsOneWidget);
        expect(find.text(l10n.membersTransfer, skipOffstage: false), findsNothing);
      });
    });
  }

  // The options-sheet matrix, written out literally (labels of the actions the sheet must show).
  // Viewer -> target name -> actions.
  const rename = 'rename', delete = 'delete', promote = 'promote', demote = 'demote';
  const unlink = 'unlink', markLeft = 'markLeft', reactivate = 'reactivate', transfer = 'transfer';
  final matrix = <String, Map<String, Set<String>>>{
    'OWNER': {
      'Me': {rename},
      'Ali': {rename, demote, unlink, markLeft, transfer},
      'Sara': {rename, promote, unlink, markLeft, transfer},
      'Omar': {rename, delete, markLeft},
      'Hana': {rename, reactivate},
    },
    'ADMIN': {
      'Me': {rename},
      'Nour': {rename},
      'Sara': {rename, unlink, markLeft},
      'Omar': {rename, delete, markLeft},
      'Hana': {rename, reactivate},
    },
  };

  for (final (locale, scale) in [(_ar, 1.0), (_en, 2.0)]) {
    final tag = '${locale.languageCode} ${scale}x';
    for (final viewer in matrix.entries) {
      for (final target in viewer.value.entries) {
        testWidgets('options sheet ($tag): ${viewer.key} -> ${target.key}', (tester) async {
          seedGroup(server, viewer.key);
          final l10n = await openMembers(tester, server, locale: locale, scale: scale);
          final labels = {
            rename: l10n.membersRename,
            delete: l10n.membersDelete,
            promote: l10n.membersActionPromote,
            demote: l10n.membersActionDemote,
            unlink: l10n.membersActionUnlink,
            markLeft: l10n.membersActionMarkLeft,
            reactivate: l10n.membersActionReactivate,
            transfer: l10n.membersActionTransfer,
          };
          await openOptions(tester, l10n, target.key);
          for (final entry in labels.entries) {
            expect(
              inSheet(find.text(entry.value, skipOffstage: false)),
              target.value.contains(entry.key) ? findsOneWidget : findsNothing,
              reason: '${entry.key} for ${viewer.key} -> ${target.key}',
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  group('join requests', () {
    final l10n = l10nFor(_en);

    FakeGroup seedWithRequests({String role = 'OWNER'}) {
      final g = seedGroup(server, role);
      server.joinRequests[g.id] = [
        FakeJoinRequest(id: 'r1', requester: 'Mona', claimName: 'Omar'),
        FakeJoinRequest(id: 'r2', requester: 'Karim', newName: 'Karim K'),
      ];
      return g;
    }

    testWidgets('the banner counts them for an admin and opens the inbox; a member sees nothing', (tester) async {
      seedWithRequests(role: 'ADMIN');
      await openMembers(tester, server);
      expect(find.text(l10n.inviteRequestsBanner('2')), findsOneWidget);
      await tapText(tester, l10n.inviteRequestsBanner('2'));
      expect(find.text(l10n.inviteRequestsTitle), findsOneWidget);
      expect(find.text('Mona'), findsOneWidget);
      expect(find.text(l10n.inviteRequestClaims('Omar')), findsOneWidget);
      expect(find.text('Karim'), findsOneWidget);
      expect(find.text(l10n.inviteRequestNewMember('Karim K')), findsOneWidget);
    });

    testWidgets('a plain member does not see the banner and never asks for the requests', (tester) async {
      seedWithRequests(role: 'MEMBER');
      await openMembers(tester, server);
      expect(find.textContaining(l10n.inviteRequestsBanner('2')), findsNothing);
      expect(server.requests.where((r) => r.contains('join-requests')), isEmpty);
    });

    testWidgets('approve: the request leaves the inbox, the members are re-read', (tester) async {
      final g = seedWithRequests();
      await openMembers(tester, server);
      await tapText(tester, l10n.inviteRequestsBanner('2'));
      final readsBefore = server.groupReads;
      await tester.tap(find.widgetWithText(AppButton, l10n.inviteRequestApprove).first);
      await tester.pumpAndSettle();
      expect(server.requests, contains('POST /api/v1/groups/${g.id}/join-requests/r1/approve'));
      expect(find.text('Mona'), findsNothing);
      expect(find.text('Karim'), findsOneWidget);
      expect(server.groupReads, greaterThan(readsBefore));
    });

    testWidgets('reject removes it', (tester) async {
      final g = seedWithRequests();
      await openMembers(tester, server);
      await tapText(tester, l10n.inviteRequestsBanner('2'));
      await tester.tap(find.widgetWithText(AppButton, l10n.inviteRequestReject).last);
      await tester.pumpAndSettle();
      expect(server.requests, contains('POST /api/v1/groups/${g.id}/join-requests/r2/reject'));
      expect(find.text('Karim'), findsNothing);
    });

    testWidgets('MEMBER_ALREADY_CLAIMED on approve: a clear notice and the list is read again', (tester) async {
      seedWithRequests();
      await openMembers(tester, server);
      await tapText(tester, l10n.inviteRequestsBanner('2'));
      server.lifecycleFaults.add((409, 'MEMBER_ALREADY_CLAIMED'));
      final listsBefore = server.requests.where((r) => r.startsWith('GET') && r.contains('/join-requests')).length;
      await tester.tap(find.widgetWithText(AppButton, l10n.inviteRequestApprove).first);
      await tester.pumpAndSettle();
      expect(find.text(l10n.inviteRequestClaimedNotice), findsOneWidget);
      expect(server.requests.where((r) => r.startsWith('GET') && r.contains('/join-requests')).length, greaterThan(listsBefore));
    });

    testWidgets('VERSION_CONFLICT (decided the other way elsewhere) explains it', (tester) async {
      seedWithRequests();
      await openMembers(tester, server);
      await tapText(tester, l10n.inviteRequestsBanner('2'));
      server.lifecycleFaults.add((409, 'VERSION_CONFLICT'));
      await tester.tap(find.widgetWithText(AppButton, l10n.inviteRequestReject).first);
      await tester.pumpAndSettle();
      expect(find.text(l10n.inviteRequestDecidedNotice), findsOneWidget);
    });

    testWidgets('empty inbox state (opened after the last request was decided)', (tester) async {
      final g = seedGroup(server, 'OWNER');
      server.joinRequests[g.id] = [FakeJoinRequest(id: 'r1', requester: 'Mona', newName: 'Mona M')];
      await openMembers(tester, server);
      await tapText(tester, l10n.inviteRequestsBanner('1'));
      await tester.tap(find.widgetWithText(AppButton, l10n.inviteRequestApprove));
      await tester.pumpAndSettle();
      expect(find.text(l10n.inviteRequestsEmptyTitle), findsOneWidget);
      expect(find.text(l10n.inviteRequestsEmptyBody), findsOneWidget);
    });
  });

  group('leave group', () {
    final l10n = l10nFor(_en);

    testWidgets('confirm explains the consequence; leaving goes back to the groups list', (tester) async {
      final g = seedGroup(server, 'MEMBER');
      await openMembers(tester, server);
      await tapText(tester, l10n.membersLeave);
      expect(find.text(l10n.groupLeaveConfirmTitle), findsOneWidget);
      expect(find.text(l10n.groupLeaveConfirmBody), findsOneWidget);
      await confirmDialog(tester, l10n.groupLeaveConfirmAction);
      expect(server.requests, contains('POST /api/v1/groups/${g.id}/leave'));
      expect(find.byType(MembersTab), findsNothing);
      expect(find.text(l10n.groupsEmptyTitle), findsOneWidget, reason: 'back on the (now empty) groups list');
    });

    testWidgets('cancel does nothing', (tester) async {
      seedGroup(server, 'MEMBER');
      await openMembers(tester, server);
      await tapText(tester, l10n.membersLeave);
      await confirmDialog(tester, l10n.commonCancel);
      expect(server.requests.where((r) => r.contains('/leave')), isEmpty);
      expect(find.byType(MembersTab), findsOneWidget);
    });

    testWidgets('an owner is never offered Leave', (tester) async {
      seedGroup(server, 'OWNER');
      await openMembers(tester, server);
      expect(find.text(l10n.membersLeave, skipOffstage: false), findsNothing);
    });

    testWidgets('OWNER_MUST_TRANSFER (stale role): explained, then the transfer picker opens', (tester) async {
      seedGroup(server, 'MEMBER');
      await openMembers(tester, server);
      server.lifecycleFaults.add((409, 'OWNER_MUST_TRANSFER'));
      await tapText(tester, l10n.membersLeave);
      await confirmDialog(tester, l10n.groupLeaveConfirmAction);
      expect(find.text(l10n.errorOwnerMustTransferTitle), findsOneWidget);
      await confirmDialog(tester, l10n.commonOk);
      expect(inSheet(find.text(l10n.memberTransferPickerTitle)), findsOneWidget, reason: 'routed to the transfer flow');
    });
  });

  group('transfer ownership', () {
    final l10n = l10nFor(_en);

    testWidgets('the picker lists only active linked members; after the transfer the chips come from the refetch', (tester) async {
      final g = seedGroup(server, 'OWNER');
      await openMembers(tester, server);
      await tapText(tester, l10n.membersTransfer);
      expect(inSheet(find.text('Ali')), findsOneWidget);
      expect(inSheet(find.text('Sara')), findsOneWidget);
      expect(inSheet(find.text('Omar')), findsNothing, reason: 'a name-only member has no account');
      expect(inSheet(find.text('Hana')), findsNothing, reason: 'left');
      expect(inSheet(find.text('Me')), findsNothing, reason: 'not me');

      await tester.tap(inSheet(find.text('Sara')));
      await tester.pumpAndSettle();
      expect(find.text(l10n.memberTransferConfirmTitle('Sara')), findsOneWidget);
      expect(find.text(l10n.memberTransferConfirmBody('Sara')), findsOneWidget);
      final readsBefore = server.groupReads;
      await confirmDialog(tester, l10n.memberTransferConfirmAction);

      expect(server.requests, contains('POST /api/v1/groups/${g.id}/transfer-ownership'));
      expect(server.groupReads, greaterThan(readsBefore));
      expect(find.text(l10n.membersTransfer, skipOffstage: false), findsNothing, reason: 'no longer the owner');
      expect(find.text(l10n.membersLeave, skipOffstage: false), findsOneWidget, reason: 'now an admin, who may leave');
      expect(find.text(l10n.membersRoleOwner, skipOffstage: false), findsOneWidget, reason: 'one owner chip, on Sara');
    });

    testWidgets('nobody to transfer to: says why', (tester) async {
      final g = server.seed(name: 'Dahab');
      g.members.add(FakeMember(id: '${g.id}-omar', name: 'Omar', sortOrder: 2));
      await openMembers(tester, server);
      await tapText(tester, l10n.membersTransfer);
      expect(inSheet(find.text(l10n.memberTransferPickerEmptyTitle)), findsOneWidget);
    });
  });

  group('actions, confirmations and errors', () {
    final l10n = l10nFor(_en);

    testWidgets('unlink asks first, says the history stays, then calls the server and re-reads', (tester) async {
      final g = seedGroup(server, 'OWNER');
      await openMembers(tester, server);
      await openOptions(tester, l10n, 'Sara');
      await tester.tap(inSheet(find.text(l10n.membersActionUnlink)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.memberUnlinkConfirmBody('Sara')), findsOneWidget);
      final readsBefore = server.groupReads;
      await confirmDialog(tester, l10n.memberUnlinkConfirmAction);
      expect(server.requests, contains('POST /api/v1/groups/${g.id}/members/${g.id}-sara/unlink'));
      expect(server.groupReads, greaterThan(readsBefore));
      // Sara is name-only now: she can no longer be offered the account actions.
      await openOptions(tester, l10n, 'Sara');
      expect(inSheet(find.text(l10n.membersActionUnlink)), findsNothing);
    });

    testWidgets('promote, then demote: roles come from the server', (tester) async {
      seedGroup(server, 'OWNER');
      await openMembers(tester, server);
      await openOptions(tester, l10n, 'Sara');
      await tester.tap(inSheet(find.text(l10n.membersActionPromote)));
      await tester.pumpAndSettle();
      await confirmDialog(tester, l10n.memberPromoteConfirmAction);
      expect(server.memberPatches.last, {'role': 'ADMIN'});
      expect(find.text(l10n.membersRoleAdmin, skipOffstage: false), findsNWidgets(2), reason: 'Ali and Sara');

      await openOptions(tester, l10n, 'Sara');
      await tester.tap(inSheet(find.text(l10n.membersActionDemote)));
      await tester.pumpAndSettle();
      await confirmDialog(tester, l10n.memberDemoteConfirmAction);
      expect(server.memberPatches.last, {'role': 'MEMBER'});
      expect(find.text(l10n.membersRoleAdmin, skipOffstage: false), findsOneWidget);
    });

    testWidgets('mark as left keeps the person in the list with the chip; reactivate brings them back', (tester) async {
      seedGroup(server, 'OWNER');
      await openMembers(tester, server);
      await openOptions(tester, l10n, 'Omar');
      await tester.tap(inSheet(find.text(l10n.membersActionMarkLeft)));
      await tester.pumpAndSettle();
      expect(find.text(l10n.memberMarkLeftConfirmBody('Omar')), findsOneWidget);
      await confirmDialog(tester, l10n.memberMarkLeftConfirmAction);
      expect(server.memberPatches.last, {'status': 'LEFT'});
      expect(find.text('Omar', skipOffstage: false), findsOneWidget);
      expect(find.text(l10n.membersLeftChip, skipOffstage: false), findsNWidgets(2), reason: 'Hana and Omar');

      await openOptions(tester, l10n, 'Omar');
      await tester.tap(inSheet(find.text(l10n.membersActionReactivate)));
      await tester.pumpAndSettle();
      expect(server.memberPatches.last, {'status': 'ACTIVE'});
      expect(find.text(l10n.membersLeftChip, skipOffstage: false), findsOneWidget);
      expect(find.text(l10n.memberReactivatedNotice('Omar')), findsOneWidget);
    });

    testWidgets('FORBIDDEN: the role message, nothing changed locally', (tester) async {
      seedGroup(server, 'OWNER');
      await openMembers(tester, server);
      server.lifecycleFaults.add((403, 'FORBIDDEN'));
      await openOptions(tester, l10n, 'Sara');
      await tester.tap(inSheet(find.text(l10n.membersActionPromote)));
      await tester.pumpAndSettle();
      await confirmDialog(tester, l10n.memberPromoteConfirmAction);
      expect(find.text(l10n.errorForbidden), findsOneWidget);
      expect(find.text(l10n.membersRoleAdmin, skipOffstage: false), findsOneWidget, reason: 'only Ali');
    });

    testWidgets('MEMBER_INACTIVE: explained and the list is read again', (tester) async {
      seedGroup(server, 'OWNER');
      await openMembers(tester, server);
      server.lifecycleFaults.add((422, 'MEMBER_INACTIVE'));
      await openOptions(tester, l10n, 'Sara');
      await tester.tap(inSheet(find.text(l10n.membersActionPromote)));
      await tester.pumpAndSettle();
      final readsBefore = server.groupReads;
      await confirmDialog(tester, l10n.memberPromoteConfirmAction);
      expect(find.text(l10n.errorMemberInactive), findsOneWidget);
      expect(server.groupReads, greaterThan(readsBefore));
    });

    testWidgets('cancelling a confirmation changes nothing', (tester) async {
      seedGroup(server, 'OWNER');
      await openMembers(tester, server);
      await openOptions(tester, l10n, 'Sara');
      await tester.tap(inSheet(find.text(l10n.membersActionUnlink)));
      await tester.pumpAndSettle();
      await confirmDialog(tester, l10n.commonCancel);
      expect(server.requests.where((r) => r.contains('unlink')), isEmpty);
    });
  });
}
