import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for NotificationControllerApi
void main() {
  final instance = QesmaApi().getNotificationControllerApi();

  group(NotificationControllerApi, () {
    // How many of your notifications are unread
    //
    //Future<UnreadCount> getUnreadNotificationCount() async
    test('test getUnreadNotificationCount', () async {
      // TODO
    });

    // Your notifications, newest first (keyset pagination)
    //
    // limit: 1 to 50 (default 20). before: the opaque nextBefore of the previous page (422 if malformed). groupName is always present; actorName and subject only while you are still an ACTIVE member of that group. Notifications stay readable after you leave a group.
    //
    //Future<NotificationPage> listNotifications({ int limit, String before }) async
    test('test listNotifications', () async {
      // TODO
    });

    // Mark your notifications read
    //
    // Body: exactly one of ids (1 to 100 notification ids) or all: true (else 422). Ids that are unknown or belong to someone else are ignored (the answer is identical). marked counts the rows that changed now. Not a create: no Idempotency-Key, repeating it is harmless.
    //
    //Future<MarkReadResult> markNotificationsRead(MarkReadRequest markReadRequest) async
    test('test markNotificationsRead', () async {
      // TODO
    });

  });
}
