import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for JoinControllerApi
void main() {
  final instance = QesmaApi().getJoinControllerApi();

  group(JoinControllerApi, () {
    // Look at an invitation before joining
    //
    // Group name, who invited you, member count and the members nobody has claimed yet. No balances and no accounts. 404 for an unknown code, 410 when expired, used up or revoked.
    //
    //Future<InvitePreview> getInvitePreview(String code) async
    test('test getInvitePreview', () async {
      // TODO
    });

    // Join the group: claim an existing member or become a new one
    //
    // Idempotency-Key (UUID) is required. Send exactly one of claimMemberId or newMemberName. 201 JOINED, or 202 PENDING_APPROVAL when an admin must approve first.
    //
    //Future<JoinView> joinGroup(String code, String idempotencyKey, JoinCommand joinCommand) async
    test('test joinGroup', () async {
      // TODO
    });

  });
}
