import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for BalanceControllerApi
void main() {
  final instance = QesmaApi().getBalanceControllerApi();

  group(BalanceControllerApi, () {
    // Net balance per member and the simplified transfers that settle the group
    //
    // Positive net = the member is owed; negative = owes. Every member is listed, zeros included. Transfers are a deterministic greedy suggestion (spec 7.7), not a guaranteed minimum.
    //
    //Future<BalanceView> getBalances(String gid) async
    test('test getBalances', () async {
      // TODO
    });

  });
}
