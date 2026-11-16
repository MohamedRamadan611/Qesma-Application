import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/idempotent_action.dart';
import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../groups/application/group_detail_controller.dart';
import '../data/balances_repository.dart';
import 'balances_refresh.dart';

/// What one tap on "Remind" came to.
enum RemindOutcome {
  /// 201 (or an idempotent replay of it): the button is disabled until the server's time.
  sent,

  /// 429 `REMIND_RATE_LIMITED`: somebody (or this device) already reminded this debtor; disabled until `nextAllowedAt`.
  rateLimited,

  /// 422: the transfer is not there any more (or the debtor left / has no account). Balances and group were read again.
  gone,

  /// 403: the role changed meanwhile. The group was read again.
  forbidden,

  /// Offline, timeout, 5xx, ...: nothing was sent that we know of. The same tap can be repeated with the same key.
  failed,
}

typedef RemindResult = ({RemindOutcome outcome, DateTime? until, ApiFailure? failure});

String remindPairKey(String fromId, String toId) => '$fromId>$toId';

class RemindSendState {
  const RemindSendState({this.busyPair, this.lockedUntil = const {}});

  /// The pair being sent now (its button shows progress; every other Remind button is disabled too: one at a time).
  final String? busyPair;

  /// The server's "may remind again" time per pair, from a 201 or a 429 in this session.
  final Map<String, DateTime> lockedUntil;

  bool get busy => busyPair != null;

  RemindSendState copyWith({String? busyPair, bool clearBusy = false, Map<String, DateTime>? lockedUntil}) =>
      RemindSendState(busyPair: clearBusy ? null : (busyPair ?? this.busyPair), lockedUntil: lockedUntil ?? this.lockedUntil);
}

/// Sends reminders for one group. One user tap = one request: the `Idempotency-Key` is made once per pair and body and is
/// reused when the same tap is retried after a timeout or while offline ([IdempotentAction]). The client never decides
/// whether a reminder is allowed: it shows the server's `canRemindAt` and handles the server's answers.
class RemindController extends Notifier<RemindSendState> {
  RemindController(this.gid);

  final String gid;

  late final BalancesRepository _repo = ref.read(balancesRepositoryProvider);
  final Map<String, IdempotentAction> _actions = {};

  @override
  RemindSendState build() => const RemindSendState();

  Future<RemindResult> remind(String fromId, String toId) async {
    if (state.busy) return (outcome: RemindOutcome.failed, until: null, failure: null);
    final pair = remindPairKey(fromId, toId);
    final action = _actions.putIfAbsent(pair, IdempotentAction.new);
    state = state.copyWith(busyPair: pair);
    try {
      final view = await action.run({'fromMemberId': fromId, 'toMemberId': toId}, (key) => _repo.remind(gid, fromId, toId, key));
      _lock(pair, view.canRemindAt);
      if (ref.mounted) refreshBalanceTab(ref, gid, settlements: false);
      return (outcome: RemindOutcome.sent, until: view.canRemindAt, failure: null);
    } on ApiFailure catch (failure) {
      if (ref.mounted) state = state.copyWith(clearBusy: true);
      final problem = failure is ApiHttpFailure ? failure.problem : null;
      switch (problem?.code) {
        case ApiErrorCode.remindRateLimited:
          final until = problem?.nextAllowedAt;
          if (until != null) _lock(pair, until);
          if (ref.mounted) refreshBalanceTab(ref, gid, settlements: false);
          return (outcome: RemindOutcome.rateLimited, until: until, failure: failure);
        case ApiErrorCode.validationError || ApiErrorCode.memberInactive || ApiErrorCode.memberNotInGroup:
          if (ref.mounted) {
            refreshBalanceTab(ref, gid, settlements: false);
            unawaited(ref.read(groupDetailControllerProvider(gid).notifier).load());
          }
          return (outcome: RemindOutcome.gone, until: null, failure: failure);
        case ApiErrorCode.forbidden:
          if (ref.mounted) unawaited(ref.read(groupDetailControllerProvider(gid).notifier).load());
          return (outcome: RemindOutcome.forbidden, until: null, failure: failure);
        default:
          return (outcome: RemindOutcome.failed, until: null, failure: failure);
      }
    }
  }

  void _lock(String pair, DateTime? until) {
    if (!ref.mounted) return;
    state = RemindSendState(lockedUntil: until == null ? state.lockedUntil : {...state.lockedUntil, pair: until});
  }
}

final remindControllerProvider = NotifierProvider.autoDispose.family<RemindController, RemindSendState, String>(RemindController.new);
