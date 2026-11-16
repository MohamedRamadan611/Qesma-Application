import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/api_failure.dart';

/// The only code that talks to `/me` for profile edits. Everything it throws is an [ApiFailure].
class ProfileRepository {
  ProfileRepository(this._api);

  final QesmaApi _api;

  /// `PATCH /me` with the new display name; returns the user as the server stored it.
  Future<UserDto> updateName(String displayName) async {
    try {
      final response = await _api.getMeControllerApi().updateMe(updateMeRequest: UpdateMeRequest((b) => b.displayName = displayName));
      final user = response.data;
      if (user == null) throw const ApiUnexpected();
      return user;
    } catch (error) {
      throw mapApiError(error);
    }
  }

  /// `GET /me/payment-handles`: the caller's own handles (null = not set).
  Future<PaymentHandlesView> paymentHandles() async {
    try {
      final body = (await _api.getMeControllerApi().getPaymentHandles()).data;
      if (body == null) throw const ApiUnexpected();
      return body;
    } catch (error) {
      throw mapApiError(error);
    }
  }

  /// `PUT /me/payment-handles` is a full replace (A93): a null field removes that handle. Returns what the server stored
  /// (wallet as `01XXXXXXXXX`, InstaPay lower case). No Idempotency-Key: a repeat of the same PUT is harmless.
  Future<PaymentHandlesView> savePaymentHandles({String? instapay, String? wallet}) async {
    try {
      final request = UpdatePaymentHandlesRequest((b) {
        b.instapay = instapay;
        b.wallet = wallet;
      });
      final body = (await _api.getMeControllerApi().updatePaymentHandles(updatePaymentHandlesRequest: request)).data;
      if (body == null) throw const ApiUnexpected();
      return body;
    } catch (error) {
      throw mapApiError(error);
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository(ref.watch(qesmaApiProvider)));
