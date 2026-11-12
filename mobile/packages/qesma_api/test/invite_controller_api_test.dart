import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for InviteControllerApi
void main() {
  final instance = QesmaApi().getInviteControllerApi();

  group(InviteControllerApi, () {
    // Create an invitation (code and link)
    //
    // Idempotency-Key (UUID) is required. Defaults: expires in 7 days (1 to 30), unlimited uses (or 1 to 1000), no approval. The code (8 characters, shown XXXX-XXXX) is typed by hand and is also the end of the link.
    //
    //Future<InviteView> createInvite(String gid, String idempotencyKey, { InviteCommand inviteCommand }) async
    test('test createInvite', () async {
      // TODO
    });

    // List the group's invitations, newest first (with their codes)
    //
    //Future<PageResponseInviteView> listInvites(String gid, { int page, int size }) async
    test('test listInvites', () async {
      // TODO
    });

    // Revoke an invitation (the code stops working; revoking again is not an error)
    //
    //Future revokeInvite(String gid, String iid) async
    test('test revokeInvite', () async {
      // TODO
    });

  });
}
