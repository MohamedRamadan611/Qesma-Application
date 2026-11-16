import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for ReminderControllerApi
void main() {
  final instance = QesmaApi().getReminderControllerApi();

  group(ReminderControllerApi, () {
    // Remind a member of a suggested transfer they owe
    //
    // Idempotency-Key (UUID) is required. fromMemberId (the debtor) and toMemberId (the creditor) must be a transfer of the current balances. The creditor may remind their own debtor; Owner/Admin may remind for any transfer (403 otherwise). The debtor must be an active member with an account. The amount is the one of the suggested transfer, set by the server. One reminder per debtor per group per 24 hours (any creditor), and a daily cap per sender: 429 REMIND_RATE_LIMITED with nextAllowedAt. A debtor who muted notifications still gets 201 (the mute is never revealed).
    //
    //Future<ReminderView> remindTransfer(String gid, String idempotencyKey, RemindCommand remindCommand) async
    test('test remindTransfer', () async {
      // TODO
    });

  });
}
