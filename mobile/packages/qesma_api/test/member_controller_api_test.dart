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

  });
}
