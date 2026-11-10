import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../data/expenses_repository.dart';
import 'expense_command_builder.dart';

/// Debounce between the last edit and the request (spec 9, "client rules": about 300 ms).
/// Tests shorten or drive it.
final previewDebounceProvider = Provider<Duration>((ref) => const Duration(milliseconds: 300));

/// The form asks the server for two independent things: the split shown in the member list,
/// and whether the payers being edited cover the total.
enum PreviewSlot { split, payers, match }

enum PreviewStatus { idle, loading, ready, failed }

typedef PreviewKey = ({String gid, PreviewSlot slot});

/// The latest answer of the preview endpoint for ONE command, identified by [key] (the
/// command's canonical text). It is only ever shown for that command: see [isCurrentFor].
class PreviewState {
  const PreviewState({this.key, this.status = PreviewStatus.idle, this.preview, this.failure});

  final String? key;
  final PreviewStatus status;
  final ExpensePreview? preview;
  final ApiFailure? failure;

  /// True only when this is a finished answer for exactly [wantedKey]. Anything else (still
  /// loading, an older command, a failure) must not be drawn as if it were the current numbers.
  bool isCurrentFor(String? wantedKey) => wantedKey != null && key == wantedKey && status == PreviewStatus.ready && preview != null;

  @override
  String toString() => 'PreviewState($status)';
}

/// Debounced, cancellable, race-safe preview. Every number the form shows per member comes from
/// here (or from the one-shot calls the controller makes for explicit actions); the client never
/// calculates a split.
class ExpensePreviewController extends Notifier<PreviewState> {
  ExpensePreviewController(this.arg);

  final PreviewKey arg;

  late final ExpensesRepository _repo = ref.read(expensesRepositoryProvider);

  Timer? _timer;
  void Function()? _cancelCall;

  /// Bumped by every request, so an answer for an older command is dropped (out-of-order replies).
  int _generation = 0;
  ExpenseCommand? _last;

  @override
  PreviewState build() {
    ref.onDispose(_stop);
    return const PreviewState();
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
    _cancelCall?.call();
    _cancelCall = null;
  }

  /// The form now wants [command] previewed (null = nothing to preview). Restarts the debounce,
  /// cancels the call in flight and drops the old numbers at once, so they are never shown for the
  /// new input. A request for the command already loading or shown changes nothing.
  void request(ExpenseCommand? command) {
    if (command == null) {
      _stop();
      _generation++;
      _last = null;
      if (state.status != PreviewStatus.idle) state = const PreviewState();
      return;
    }
    final key = commandKey(command);
    final same = state.key == key && (state.status == PreviewStatus.loading || state.status == PreviewStatus.ready);
    if (same) return;
    _stop();
    final generation = ++_generation;
    _last = command;
    state = PreviewState(key: key, status: PreviewStatus.loading);
    _timer = Timer(ref.read(previewDebounceProvider), () => _send(command, key, generation));
  }

  /// Sends the last command again (after a failure).
  void retry() {
    final command = _last;
    if (command == null) return;
    _stop();
    final key = commandKey(command);
    final generation = ++_generation;
    state = PreviewState(key: key, status: PreviewStatus.loading);
    _timer = Timer(Duration.zero, () => _send(command, key, generation));
  }

  Future<void> _send(ExpenseCommand command, String key, int generation) async {
    _timer = null;
    final call = _repo.preview(arg.gid, command);
    _cancelCall = call.cancel;
    try {
      final preview = await call.result;
      if (!ref.mounted || generation != _generation) return;
      state = PreviewState(key: key, status: PreviewStatus.ready, preview: preview);
    } on ApiFailure catch (failure) {
      if (!ref.mounted || generation != _generation || failure is ApiCancelled) return;
      state = PreviewState(key: key, status: PreviewStatus.failed, failure: failure);
    }
  }
}

final expensePreviewControllerProvider =
    NotifierProvider.autoDispose.family<ExpensePreviewController, PreviewState, PreviewKey>(ExpensePreviewController.new);
