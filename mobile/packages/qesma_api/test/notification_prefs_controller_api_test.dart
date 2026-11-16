import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for NotificationPrefsControllerApi
void main() {
  final instance = QesmaApi().getNotificationPrefsControllerApi();

  group(NotificationPrefsControllerApi, () {
    // Mute or unmute one group for yourself
    //
    // muted=true: you get no new notification from this group, reminders and disputes included. The group activity feed still shows everything. Any active member may do this for themselves.
    //
    //Future<GroupNotificationPrefsView> updateGroupNotificationPrefs(String gid, UpdateGroupNotificationPrefsRequest updateGroupNotificationPrefsRequest) async
    test('test updateGroupNotificationPrefs', () async {
      // TODO
    });

    // Switch all your notifications on or off
    //
    // enabled=false: you get no new notification from any group, reminders and disputes included. Activity feeds still show everything. Notifications you already have are kept; switching back on does not backfill what you missed.
    //
    //Future<NotificationPrefsView> updateNotificationPrefs(UpdateNotificationPrefsRequest updateNotificationPrefsRequest) async
    test('test updateNotificationPrefs', () async {
      // TODO
    });

  });
}
