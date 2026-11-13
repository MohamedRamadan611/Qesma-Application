import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for SettlementControllerApi
void main() {
  final instance = QesmaApi().getSettlementControllerApi();

  group(SettlementControllerApi, () {
    // Cancel (the payer, or an Owner/Admin); replaces the Phase 1 delete
    //
    // PENDING or DISPUTED -> CANCELLED; the row stays in the history. Repeating it returns the current settlement unchanged. 409 INVALID_STATE_TRANSITION from CONFIRMED.
    //
    //Future<SettlementView> cancelSettlement(String gid, String sid) async
    test('test cancelSettlement', () async {
      // TODO
    });

    // Confirm \"received\" (the receiver, or an Owner/Admin who is not the payer)
    //
    // PENDING or DISPUTED -> CONFIRMED. Repeating it returns the current settlement unchanged. 409 INVALID_STATE_TRANSITION from CANCELLED.
    //
    //Future<SettlementView> confirmSettlement(String gid, String sid) async
    test('test confirmSettlement', () async {
      // TODO
    });

    // Declare or record a settlement (a real-world payment between two members)
    //
    // Idempotency-Key (UUID) is required. amountMinor is in piasters, 1 to 10^12. The status is decided by the server: the payer declares (PENDING, to a member with an account); the receiver or an Owner/Admin recording it makes it CONFIRMED (Owner/Admin on behalf: recordedByAdmin). 403 for a member recording a payment between two others or to a member without an account.
    //
    //Future<SettlementView> createSettlement(String gid, String idempotencyKey, SettlementCommand settlementCommand) async
    test('test createSettlement', () async {
      // TODO
    });

    // Dispute \"not received\" (the receiver only)
    //
    // PENDING -> DISPUTED. Repeating it returns the current settlement unchanged. 409 INVALID_STATE_TRANSITION from CONFIRMED or CANCELLED.
    //
    //Future<SettlementView> disputeSettlement(String gid, String sid) async
    test('test disputeSettlement', () async {
      // TODO
    });

    // List settlements, newest first (cancelled ones included)
    //
    // Optional repeatable filter status=PENDING|CONFIRMED|DISPUTED|CANCELLED; without it every status is listed. Only CONFIRMED settlements move balances.
    //
    //Future<PageResponseSettlementView> listSettlements(String gid, { BuiltList<String> status, int page, int size }) async
    test('test listSettlements', () async {
      // TODO
    });

  });
}
