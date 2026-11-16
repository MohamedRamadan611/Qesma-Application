import 'package:test/test.dart';
import 'package:qesma_api/qesma_api.dart';


/// tests for MeControllerApi
void main() {
  final instance = QesmaApi().getMeControllerApi();

  group(MeControllerApi, () {
    //Future<TokenResponse> changePassword(ChangePasswordRequest changePasswordRequest) async
    test('test changePassword', () async {
      // TODO
    });

    // Delete your account
    //
    // Body {confirm: \"DELETE\", password}: password accounts must send the current password. 409 OWNER_MUST_TRANSFER (with the groups) while you own a group that has history or other active members.
    //
    //Future deleteMe(DeleteAccountRequest deleteAccountRequest) async
    test('test deleteMe', () async {
      // TODO
    });

    //Future<UserDto> getMe() async
    test('test getMe', () async {
      // TODO
    });

    // Your own InstaPay address and mobile-wallet number
    //
    // Personal data. Co-members see a receiver's handles only on the balances transfers they pay (or as Owner/Admin).
    //
    //Future<PaymentHandlesView> getPaymentHandles() async
    test('test getPaymentHandles', () async {
      // TODO
    });

    //Future<UserDto> updateMe(UpdateMeRequest updateMeRequest) async
    test('test updateMe', () async {
      // TODO
    });

    // Replace your payment handles
    //
    // A null, absent or blank field removes that handle. Wallet: Egyptian mobile (Arabic digits, spaces, dashes and +20 accepted), stored as 01XXXXXXXXX. InstaPay: name@bank, 3 to 60 ASCII characters, stored lower case.
    //
    //Future<PaymentHandlesView> updatePaymentHandles(UpdatePaymentHandlesRequest updatePaymentHandlesRequest) async
    test('test updatePaymentHandles', () async {
      // TODO
    });

  });
}
