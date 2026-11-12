import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for JoinRequestControllerApi
void main() {
  final instance = QesmaApi().getJoinRequestControllerApi();

  group(JoinRequestControllerApi, () {
    // Approve a join request: the person becomes a member (or claims the member they chose)
    //
    // Repeating the same decision returns the stored result. A member somebody else claimed in the meantime is 409 and the request stays pending so it can be rejected.
    //
    //Future<JoinRequestView> approveJoinRequest(String gid, String rid) async
    test('test approveJoinRequest', () async {
      // TODO
    });

    // List the requests waiting for a decision, oldest first (the requester by display name only)
    //
    //Future<PageResponseJoinRequestView> listJoinRequests(String gid, { int page, int size }) async
    test('test listJoinRequests', () async {
      // TODO
    });

    // Reject a join request
    //
    //Future<JoinRequestView> rejectJoinRequest(String gid, String rid) async
    test('test rejectJoinRequest', () async {
      // TODO
    });

  });
}
