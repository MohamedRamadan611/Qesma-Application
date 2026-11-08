import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for GroupControllerApi
void main() {
  final instance = QesmaApi().getGroupControllerApi();

  group(GroupControllerApi, () {
    //Future<GroupDto> createGroup(CreateGroupRequest createGroupRequest) async
    test('test createGroup', () async {
      // TODO
    });

    //Future deleteGroup(String gid) async
    test('test deleteGroup', () async {
      // TODO
    });

    //Future<GroupDto> getGroup(String gid) async
    test('test getGroup', () async {
      // TODO
    });

    //Future<PageResponseGroupSummaryDto> listGroups({ int page, int size }) async
    test('test listGroups', () async {
      // TODO
    });

    //Future<GroupDto> updateGroup(String gid, String ifMatch, UpdateGroupRequest updateGroupRequest) async
    test('test updateGroup', () async {
      // TODO
    });

  });
}
