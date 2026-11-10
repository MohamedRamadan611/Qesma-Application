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
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository(ref.watch(qesmaApiProvider)));
