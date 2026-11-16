import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for ActivityControllerApi
void main() {
  final instance = QesmaApi().getActivityControllerApi();

  group(ActivityControllerApi, () {
    // The group's activity feed, newest first (keyset pagination)
    //
    // Every ACTIVE member reads the whole history. limit: 1 to 50 (default 20). before: the opaque nextBefore of the previous page (422 if malformed). nextBefore is null on the last page. payload holds ids, a version and integer amounts only; subject is the expense title (EXPENSE_* events, also after the expense was deleted) or the member's name (member events), resolved at read time.
    //
    //Future<ActivityPage> listGroupActivity(String gid, { int limit, String before }) async
    test('test listGroupActivity', () async {
      // TODO
    });

  });
}
