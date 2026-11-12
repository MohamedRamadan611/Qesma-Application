import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for MemberControllerApi
void main() {
  final instance = QesmaApi().getMemberControllerApi();

  group(MemberControllerApi, () {
    //Future<MemberDto> addMember(String gid, CreateMemberRequest createMemberRequest) async
    test('test addMember', () async {
      // TODO
    });

    //Future deleteMember(String gid, String mid) async
    test('test deleteMember', () async {
      // TODO
    });

    //Future<MemberDto> renameMember(String gid, String mid, UpdateMemberRequest updateMemberRequest) async
    test('test renameMember', () async {
      // TODO
    });

    // Unlink the account from a member (the member, its history and balance stay)
    //
    // The person loses access to the group at once and the member can be claimed again. The owner's member cannot be unlinked (409 OWNER_MEMBER_PROTECTED); only the owner may unlink an admin.
    //
    //Future unlinkMember(String gid, String mid) async
    test('test unlinkMember', () async {
      // TODO
    });

  });
}
