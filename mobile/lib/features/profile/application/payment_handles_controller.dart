import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/api_failure.dart';
import '../data/profile_repository.dart';
import 'payment_handles_input.dart';

enum HandlesStatus { loading, ready, failed }

/// Never contains anything that is logged: the values only live in this state and in the text fields.
class PaymentHandlesState {
  const PaymentHandlesState({
    this.status = HandlesStatus.loading,
    this.stored = (instapay: null, wallet: null),
    this.loadFailure,
    this.saving = false,
    this.saveFailure,
  });

  final HandlesStatus status;
  final StoredHandles stored;
  final ApiFailure? loadFailure;
  final bool saving;

  /// The last save failed (offline, 422 the client could not foresee, 5xx). The form is kept as it is.
  final ApiFailure? saveFailure;

  PaymentHandlesState copyWith({
    HandlesStatus? status,
    StoredHandles? stored,
    ApiFailure? loadFailure,
    bool clearLoadFailure = false,
    bool? saving,
    ApiFailure? saveFailure,
    bool clearSaveFailure = false,
  }) =>
      PaymentHandlesState(
        status: status ?? this.status,
        stored: stored ?? this.stored,
        loadFailure: clearLoadFailure ? null : (loadFailure ?? this.loadFailure),
        saving: saving ?? this.saving,
        saveFailure: clearSaveFailure ? null : (saveFailure ?? this.saveFailure),
      );
}

/// The caller's own payment handles (`GET` / `PUT /me/payment-handles`). The server is authoritative: what it answers to the
/// PUT (normalised) replaces what is shown.
class PaymentHandlesController extends Notifier<PaymentHandlesState> {
  @override
  PaymentHandlesState build() {
    Future.microtask(load);
    return const PaymentHandlesState();
  }

  Future<void> load() async {
    state = state.copyWith(status: HandlesStatus.loading, clearLoadFailure: true);
    try {
      final view = await ref.read(profileRepositoryProvider).paymentHandles();
      if (!ref.mounted) return;
      state = state.copyWith(status: HandlesStatus.ready, stored: (instapay: view.instapay, wallet: view.wallet));
    } on ApiFailure catch (failure) {
      if (ref.mounted) state = state.copyWith(status: HandlesStatus.failed, loadFailure: failure);
    }
  }

  /// Full replace: an empty field in [draft] removes that handle. Returns true when the server stored it.
  Future<bool> save(HandlesDraft draft) async {
    if (state.saving || !draft.isValid) return false;
    state = state.copyWith(saving: true, clearSaveFailure: true);
    try {
      final view = await ref.read(profileRepositoryProvider).savePaymentHandles(instapay: draft.instapay.value, wallet: draft.wallet.value);
      if (!ref.mounted) return true;
      state = state.copyWith(saving: false, stored: (instapay: view.instapay, wallet: view.wallet));
      return true;
    } on ApiFailure catch (failure) {
      if (ref.mounted) state = state.copyWith(saving: false, saveFailure: failure);
      return false;
    }
  }

  void clearSaveFailure() => state = state.copyWith(clearSaveFailure: true);
}

final paymentHandlesControllerProvider = NotifierProvider.autoDispose<PaymentHandlesController, PaymentHandlesState>(PaymentHandlesController.new);
