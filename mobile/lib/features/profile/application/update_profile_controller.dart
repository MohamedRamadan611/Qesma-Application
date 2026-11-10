import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/widgets/code_point_limit.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../data/profile_repository.dart';

/// The longest display name the server accepts, in code points.
const int kDisplayNameMax = 60;

enum NameError { empty, tooLong }

/// The inputs of the edit-profile screen. Pure: validation lives here.
class ProfileForm {
  const ProfileForm({required this.original, required this.name});

  final String original;
  final String name;

  String get trimmed => name.trim();

  NameError? get error {
    if (trimmed.isEmpty) return NameError.empty;
    if (codePointCount(trimmed) > kDisplayNameMax) return NameError.tooLong;
    return null;
  }

  /// What the user typed differs from the saved name (decides the discard question).
  bool get dirty => trimmed != original.trim();

  /// Saving makes sense: a valid name that is not the one already saved.
  bool get canSave => error == null && dirty;
}

class UpdateProfileState {
  const UpdateProfileState({required this.form, this.saving = false, this.failure});

  final ProfileForm form;
  final bool saving;
  final ApiFailure? failure;

  UpdateProfileState copyWith({ProfileForm? form, bool? saving, ApiFailure? failure, bool clearFailure = false}) => UpdateProfileState(
        form: form ?? this.form,
        saving: saving ?? this.saving,
        failure: clearFailure ? null : (failure ?? this.failure),
      );
}

/// Edits the display name (`PATCH /me`). On success the signed-in user is replaced everywhere.
class UpdateProfileController extends Notifier<UpdateProfileState> {
  @override
  UpdateProfileState build() {
    final auth = ref.read(authControllerProvider);
    final name = auth is AuthSignedIn ? auth.user.displayName : '';
    return UpdateProfileState(form: ProfileForm(original: name, name: name));
  }

  void setName(String text) => state = state.copyWith(form: ProfileForm(original: state.form.original, name: text), clearFailure: true);

  /// Returns true when the name was saved. A failure stays in [UpdateProfileState.failure] and keeps the form.
  Future<bool> save() async {
    final form = state.form;
    if (state.saving || !form.canSave) return false;
    state = state.copyWith(saving: true, clearFailure: true);
    try {
      final user = await ref.read(profileRepositoryProvider).updateName(form.trimmed);
      if (!ref.mounted) return true;
      ref.read(authControllerProvider.notifier).updateUser(user);
      state = state.copyWith(saving: false, form: ProfileForm(original: user.displayName, name: user.displayName));
      return true;
    } on ApiFailure catch (failure) {
      if (ref.mounted) state = state.copyWith(saving: false, failure: failure);
      return false;
    }
  }
}

final updateProfileControllerProvider = NotifierProvider.autoDispose<UpdateProfileController, UpdateProfileState>(UpdateProfileController.new);
