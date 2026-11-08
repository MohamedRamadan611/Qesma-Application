import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for SettlementControllerApi
void main() {
  final instance = QesmaApi().getSettlementControllerApi();

  group(SettlementControllerApi, () {
    // Record a settlement (a real-world payment between two members)
    //
    // Idempotency-Key (UUID) is required. amountMinor is in piasters, 1 to 10^12.
    //
    //Future<SettlementView> createSettlement(String gid, String idempotencyKey, SettlementCommand settlementCommand) async
    test('test createSettlement', () async {
      // TODO
    });

    // Delete a settlement (soft delete; its effect on balances is reversed)
    //
    //Future deleteSettlement(String gid, String sid) async
    test('test deleteSettlement', () async {
      // TODO
    });

    // List settlements, newest first (deleted ones are not listed)
    //
    //Future<PageResponseSettlementView> listSettlements(String gid, { int page, int size }) async
    test('test listSettlements', () async {
      // TODO
    });

  });
}
