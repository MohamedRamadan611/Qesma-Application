import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/api/idempotent_action.dart';
import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../../core/format/clock.dart';
import '../../../core/money/money.dart';
import '../../groups/application/group_detail_controller.dart';
import '../data/balances_repository.dart';
import 'balances_refresh.dart';
import 'record_payment_state.dart';

/// Which sheet: the group and what it opened with.
typedef PaymentKey = ({String gid, PaymentSeed seed});

/// What a send came to.
enum PaymentOutcome {
  /// Nothing was sent (a field is not acceptable yet, or a send is already in flight).
  invalid,

  /// Recorded.
  recorded,

  /// The server or the network refused; [RecordPaymentView.failure] says how. The form is kept.
  failed,
}

class RecordPaymentView {
  const RecordPaymentView({required this.form, this.sending = false, this.failure, this.created});

  final PaymentForm form;
  final bool sending;
  final ApiFailure? failure;

  /// What the server created (its status says PENDING or CONFIRMED); set after a successful send.
  final SettlementView? created;

  RecordPaymentView copyWith({PaymentForm? form, bool? sending, ApiFailure? failure, bool clearFailure = false, SettlementView? created}) => RecordPaymentView(
        form: form ?? this.form,
        sending: sending ?? this.sending,
        failure: clearFailure ? null : (failure ?? this.failure),
        created: created ?? this.created,
      );
}

/// The payment sheet: the inputs and one idempotent send. The key lives in an
/// [IdempotentAction]: reused when the same body is sent again (a retry after offline or a 5xx),
/// replaced as soon as any input changes, forgotten after success or a definitive refusal.
class RecordPaymentController extends Notifier<RecordPaymentView> {
  RecordPaymentController(this.key);

  final PaymentKey key;

  late final BalancesRepository _repo = ref.read(balancesRepositoryProvider);
  final IdempotentAction _action = IdempotentAction();
  late final PaymentForm _initial;

  String get gid => key.gid;

  @override
  RecordPaymentView build() {
    final group = ref.read(groupDetailControllerProvider(gid)).group;
    final members = group?.members.toList() ?? const <MemberDto>[];
    final seed = key.seed;
    final you = group?.yourMemberId;
    final fromId = seed.fromId ?? you ?? members.firstOrNull?.id;
    final toId = seed.toId ?? members.where((m) => m.id != fromId).firstOrNull?.id;
    _initial = PaymentForm(
      fromId: fromId,
      toId: toId,
      amountText: seed.amountMinor == null ? '' : Money.formatPlain(seed.amountMinor!),
      date: ref.read(clockProvider)().toDate(),
      suggestedMinor: seed.amountMinor,
    );
    return RecordPaymentView(form: _initial);
  }

  /// The user changed something compared with how the sheet opened.
  bool get dirty => state.form.differsFrom(_initial);

  void _set(PaymentForm form) => state = state.copyWith(form: form, clearFailure: true);

  /// Changing one side to the member already on the other side swaps them, so the two are never equal.
  void setFrom(String id) {
    final f = state.form;
    _set(id == f.toId ? f.copyWith(fromId: id, toId: f.fromId) : f.copyWith(fromId: id));
  }

  void setTo(String id) {
    final f = state.form;
    _set(id == f.fromId ? f.copyWith(toId: id, fromId: f.toId) : f.copyWith(toId: id));
  }

  void setAmount(String text) => _set(state.form.copyWith(amountText: text));

  /// Puts the tapped transfer's own amount back (a copy of what the server suggested).
  void useFullAmount() {
    final suggested = state.form.suggestedMinor;
    if (suggested != null) _set(state.form.copyWith(amountText: Money.formatPlain(suggested)));
  }

  void setDate(Date date) => _set(state.form.copyWith(date: date));

  void setNote(String note) => _set(state.form.copyWith(note: note));

  /// Sends the payment. One at a time: a second tap while one is in flight does nothing.
  Future<PaymentOutcome> send() async {
    if (state.sending) return PaymentOutcome.invalid;
    final command = buildSettlementCommand(state.form);
    if (command == null) return PaymentOutcome.invalid;
    state = state.copyWith(sending: true, clearFailure: true);
    try {
      SettlementView created;
      try {
        created = await _action.run(settlementBodyJson(command), (k) => _repo.record(gid, command, k));
      } on ApiHttpFailure catch (failure) {
        // A key the server already tied to another body is a client bug: try once more with a fresh key.
        if (failure.problem?.code != ApiErrorCode.idempotencyKeyReused) rethrow;
        _action.reset();
        created = await _action.run(settlementBodyJson(command), (k) => _repo.record(gid, command, k));
      }
      if (ref.mounted) state = state.copyWith(sending: false, created: created);
      refreshAfterSettlementChange(ref, gid);
      return PaymentOutcome.recorded;
    } on ApiFailure catch (failure) {
      if (ref.mounted) state = state.copyWith(sending: false, failure: failure);
      if (failure is ApiHttpFailure && failure.problem?.code == ApiErrorCode.memberNotInGroup) {
        // A member was removed meanwhile: re-read the members so the pickers show who is left.
        unawaited(ref.read(groupDetailControllerProvider(gid).notifier).load());
      }
      return PaymentOutcome.failed;
    }
  }
}

final recordPaymentControllerProvider =
    NotifierProvider.autoDispose.family<RecordPaymentController, RecordPaymentView, PaymentKey>(RecordPaymentController.new);
