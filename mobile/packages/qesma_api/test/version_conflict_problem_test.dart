import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';

// tests for VersionConflictProblem
void main() {
  final instance = VersionConflictProblemBuilder();
  // TODO add properties to the builder and call build()

  group(VersionConflictProblem, () {
    // Stable machine-readable error code.
    // String code
    test('to test the property `code`', () async {
      // TODO
    });

    // String detail
    test('to test the property `detail`', () async {
      // TODO
    });

    // Only with OWNER_MUST_TRANSFER on DELETE /me: your groups that still depend on you as Owner.
    // BuiltList<ProblemGroupsInner> groups
    test('to test the property `groups`', () async {
      // TODO
    });

    // String instance
    test('to test the property `instance`', () async {
      // TODO
    });

    // Only with REMIND_RATE_LIMITED: the earliest time a reminder for this member may be sent again (UTC).
    // DateTime nextAllowedAt
    test('to test the property `nextAllowedAt`', () async {
      // TODO
    });

    // Echoes the X-Request-Id response header.
    // String requestId
    test('to test the property `requestId`', () async {
      // TODO
    });

    // int status
    test('to test the property `status`', () async {
      // TODO
    });

    // String title
    test('to test the property `title`', () async {
      // TODO
    });

    // String type
    test('to test the property `type`', () async {
      // TODO
    });

    // The latest state the caller may GET: an ExpenseView (expense operations) or a GroupDto (PATCH group). Absent if it could not be read at the moment of the conflict.
    // JsonObject current
    test('to test the property `current`', () async {
      // TODO
    });

    // The version now stored; re-send the edit with If-Match set to it to re-apply.
    // int currentVersion
    test('to test the property `currentVersion`', () async {
      // TODO
    });

  });
}
