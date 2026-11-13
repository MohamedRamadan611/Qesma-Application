import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../groups/application/group_detail_controller.dart';
import '../data/balances_repository.dart';
import 'balances_refresh.dart';
import 'settlement_rules.dart';

/// What one confirm / dispute / cancel came to.
enum SettlementActionOutcome {
  /// 200: the server's view is returned (a repeat of the same transition is a 200 too, A84).
  done,

  /// 409 `INVALID_STATE_TRANSITION`: somebody else moved it first. Everything was re-read; the screens now show the current state.
  stateChanged,

  /// 404: the payment is not there any more (or the caller is no longer in the group). Re-read as well.
  gone,

  /// Anything else (offline, 5xx, 403, ...); the failure is returned next to this value. Nothing changed.
  failed,
}

typedef SettlementActionResult = ({SettlementActionOutcome outcome, SettlementView? view, ApiFailure? failure});

/// A settlement action in flight: which payment and which action (their buttons stay disabled).
class SettlementActionState {
  const SettlementActionState({this.busyId, this.busyAction});

  final String? busyId;
  final SettlementAction? busyAction;

  bool get busy => busyId != null;
}

/// Confirm / dispute / cancel of one group's settlements. One action at a time. After **every** attempt that reached
/// the server (done, 409, 404) the balances, the settlements, the group and the incoming list are read again, so what
/// is on screen is what is true now. The client never works out the new state itself.
class SettlementActionsController extends Notifier<SettlementActionState> {
  SettlementActionsController(this.gid);

  final String gid;

  late final BalancesRepository _repo = ref.read(balancesRepositoryProvider);

  @override
  SettlementActionState build() => const SettlementActionState();

  Future<SettlementActionResult> perform(String sid, SettlementAction action) async {
    if (state.busy) return (outcome: SettlementActionOutcome.failed, view: null, failure: null);
    state = SettlementActionState(busyId: sid, busyAction: action);
    try {
      final view = switch (action) {
        SettlementAction.confirm => await _repo.confirm(gid, sid),
        SettlementAction.dispute => await _repo.dispute(gid, sid),
        SettlementAction.cancel => await _repo.cancel(gid, sid),
      };
      _finish();
      refreshAfterSettlementChange(ref, gid);
      return (outcome: SettlementActionOutcome.done, view: view, failure: null);
    } on ApiFailure catch (failure) {
      _finish();
      final code = failure is ApiHttpFailure ? failure.problem?.code : null;
      if (code == ApiErrorCode.invalidStateTransition || code == ApiErrorCode.notFound) {
        if (ref.mounted) refreshAfterSettlementChange(ref, gid);
        return (
          outcome: code == ApiErrorCode.notFound ? SettlementActionOutcome.gone : SettlementActionOutcome.stateChanged,
          view: null,
          failure: failure,
        );
      }
      if (code == ApiErrorCode.forbidden && ref.mounted) {
        // The role changed meanwhile: re-read the group so the buttons catch up.
        unawaited(ref.read(groupDetailControllerProvider(gid).notifier).load());
      }
      return (outcome: SettlementActionOutcome.failed, view: null, failure: failure);
    }
  }

  void _finish() {
    if (ref.mounted) state = const SettlementActionState();
  }
}

final settlementActionsControllerProvider =
    NotifierProvider.autoDispose.family<SettlementActionsController, SettlementActionState, String>(SettlementActionsController.new);
