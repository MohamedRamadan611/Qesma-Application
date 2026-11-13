import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for MembershipControllerApi
void main() {
  final instance = QesmaApi().getMembershipControllerApi();

  group(MembershipControllerApi, () {
    // Leave the group
    //
    // The member row, its history and its balance stay; the group disappears from the caller's list and becomes 404 for them. The owner gets 409 OWNER_MUST_TRANSFER.
    //
    //Future leaveGroup(String gid) async
    test('test leaveGroup', () async {
      // TODO
    });

    // Make another member the owner (the old owner becomes ADMIN)
    //
    // Owner only. The target must be an ACTIVE member with an account (a member who left is 422 MEMBER_INACTIVE). One transaction.
    //
    //Future transferOwnership(String gid, TransferOwnershipRequest transferOwnershipRequest) async
    test('test transferOwnership', () async {
      // TODO
    });

  });
}
