import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/api/idempotent_action.dart';
import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../../core/format/clock.dart';
import '../../../core/money/money.dart';
import '../../groups/application/group_detail_controller.dart';
import '../data/expenses_repository.dart';
import 'expense_command_builder.dart';
import 'expense_form_prefill.dart';
import 'expense_form_state.dart';
import 'expense_preview_controller.dart';
import 'expense_refresh.dart';

/// `(gid, eid)`: eid is null when adding. Records compare by value, so they work as a family key.
typedef ExpenseFormKey = ({String gid, String? eid});

enum FormPhase { loading, ready, failed, gone }

enum SaveOutcome {
  /// Saved (201 / 200): [ExpenseFormView.savedId] is the expense to open.
  saved,

  /// The form cannot make a valid request yet (the button is disabled; this is a safety net).
  invalid,

  /// A save is already running.
  busy,

  /// The request failed: [ExpenseFormView.failure] says how; the form is kept.
  failed,
}

enum ReloadOutcome {
  /// The latest version is loaded and its version recorded; the user's input is untouched.
  reloaded,

  /// The earlier save had in fact applied (its reply was lost): nothing more to do.
  alreadyApplied,

  /// The expense no longer exists.
  gone,

  /// The reload itself failed ([ExpenseFormView.failure]).
  failed,
}

/// What the add/edit screen shows. [form] is null only while an edit is loading or failed.
class ExpenseFormView {
  const ExpenseFormView({
    this.form,
    this.phase = FormPhase.loading,
    this.submitting = false,
    this.failure,
    this.loadFailure,
    this.savedId,
    this.prefilling = false,
    this.prefillFailed = false,
    this.latestReloaded = false,
  });

  final ExpenseFormState? form;
  final FormPhase phase;
  final bool submitting;

  /// The last save (or reload) failed; the form is kept as typed.
  final ApiFailure? failure;

  /// Opening an edit failed.
  final ApiFailure? loadFailure;

  /// Set once the expense was saved: the screen opens its details.
  final String? savedId;

  /// The server is working out the equal amounts for Exact mode (or failed to).
  final bool prefilling;
  final bool prefillFailed;

  /// Edit only: the latest version was loaded after a conflict; the user's input was kept.
  final bool latestReloaded;

  ExpenseFormView copyWith({
    ExpenseFormState? form,
    FormPhase? phase,
    bool? submitting,
    ApiFailure? failure,
    bool clearFailure = false,
    ApiFailure? loadFailure,
    String? savedId,
    bool? prefilling,
    bool? prefillFailed,
    bool? latestReloaded,
  }) =>
      ExpenseFormView(
        form: form ?? this.form,
        phase: phase ?? this.phase,
        submitting: submitting ?? this.submitting,
        failure: clearFailure ? null : (failure ?? this.failure),
        loadFailure: loadFailure ?? this.loadFailure,
        savedId: savedId ?? this.savedId,
        prefilling: prefilling ?? this.prefilling,
        prefillFailed: prefillFailed ?? this.prefillFailed,
        latestReloaded: latestReloaded ?? this.latestReloaded,
      );
}

/// The add and edit expense form: holds what the user typed, asks the server for every number
/// shown per member, saves with an idempotency key (create) or `If-Match` (edit) and never
/// calculates a split itself.
class ExpenseFormController extends Notifier<ExpenseFormView> {
  ExpenseFormController(this.key);

  final ExpenseFormKey key;

  String get gid => key.gid;
  bool get isEdit => key.eid != null;

  late final ExpensesRepository _repo = ref.read(expensesRepositoryProvider);

  /// One per screen: the key lives while the same body is retried (SCREEN_MAP rule 6).
  final IdempotentAction _action = IdempotentAction();

  ExpenseFormState? _initial;
  bool _started = false;
  Timer? _prefillTimer;
  int _prefillGeneration = 0;
  String? _lastSentKey;
  bool _maybeApplied = false;

  @override
  ExpenseFormView build() {
    ref.onDispose(() {
      _prefillTimer?.cancel();
      _action.reset();
    });
    // The restaurant bill's total is the server's: copy it from the preview once that preview is
    // the answer for exactly the bill as it is now.
    ref.listen<PreviewState>(expensePreviewControllerProvider((gid: gid, slot: PreviewSlot.split)), (previous, next) => _onSplitPreview(next));
    // Held open so the editor's "do the payers match" answer survives rebuilds.
    ref.listen<PreviewState>(expensePreviewControllerProvider((gid: gid, slot: PreviewSlot.match)), (previous, next) {});
    return const ExpenseFormView();
  }

  // ---- group data ----

  GroupDto? get _group => ref.read(groupDetailControllerProvider(gid)).group;

  /// The group's members in their fixed order (the order shares and previews use).
  List<MemberDto> get members {
    final list = (_group?.members.toList() ?? <MemberDto>[])..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  List<String> get memberIds => [for (final m in members) m.id];

  String? get _defaultPayerId => _group?.yourMemberId ?? members.firstOrNull?.id;

  ExpenseFormState? get form => state.form;

  /// Anything typed or chosen differs from how the form was opened.
  bool get dirty {
    final f = state.form;
    final initial = _initial;
    return f != null && initial != null && f.differsFrom(initial);
  }

  // ---- opening ----

  /// Add mode: an empty form, today's date, you as the payer. Safe to call on every build.
  void startCreate() {
    if (_started) return;
    _started = true;
    final today = ref.read(clockProvider)().toDate();
    final f = ExpenseFormState(title: '', amountText: '', date: today, singlePayerId: _defaultPayerId);
    _initial = f;
    state = ExpenseFormView(form: f, phase: FormPhase.ready);
  }

  /// Edit mode: reads the expense (which also records its version for `If-Match`) and fills the form.
  Future<void> startEdit() async {
    if (_started) return;
    _started = true;
    await _loadForEdit();
  }

  Future<void> retryLoad() async {
    state = const ExpenseFormView();
    await _loadForEdit();
  }

  Future<void> _loadForEdit() async {
    try {
      final expense = await _repo.get(gid, key.eid!);
      if (!ref.mounted) return;
      final filled = formFromExpense(expense, memberIds: memberIds, fallbackPayerId: _defaultPayerId);
      _initial = filled;
      state = ExpenseFormView(form: filled, phase: FormPhase.ready);
      _syncItemizedPreviews();
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return;
      final gone = failure is ApiHttpFailure && failure.problem?.code == ApiErrorCode.notFound;
      state = ExpenseFormView(phase: gone ? FormPhase.gone : FormPhase.failed, loadFailure: failure);
    }
  }

  // ---- editing the form ----

  /// Replaces the form. Any change to a restaurant bill's inputs forgets the server's total for it
  /// at once (the new total is copied in when the preview for the new inputs arrives), so a total
  /// that belongs to older inputs can never be saved or paid against.
  void _set(ExpenseFormState next) {
    var f = next;
    final old = state.form;
    if (f.splitMode == SplitMode.itemized && old != null && _itemizedKey(old) != _itemizedKey(f)) {
      f = f.copyWith(clearServerTotal: true);
    }
    state = state.copyWith(form: f, clearFailure: true);
    if (f.splitMode == SplitMode.itemized || old?.splitMode == SplitMode.itemized) _syncItemizedPreviews();
  }

  /// Canonical text of the question the preview would be asked for this bill (null while it is incomplete).
  String? _itemizedKey(ExpenseFormState f) {
    final command = buildItemizedPreview(f, memberIds: memberIds);
    return command == null ? null : commandKey(command);
  }

  /// In restaurant-bill mode the controller keeps the two previews up to date (the numbers, and
  /// the one with the payers for the match banner); in other modes the screen drives the split one.
  void _syncItemizedPreviews() {
    final f = form;
    if (f == null) return;
    final match = ref.read(expensePreviewControllerProvider((gid: gid, slot: PreviewSlot.match)).notifier);
    if (f.splitMode != SplitMode.itemized) {
      match.request(null);
      return;
    }
    ref.read(expensePreviewControllerProvider((gid: gid, slot: PreviewSlot.split)).notifier).request(buildItemizedPreview(f, memberIds: memberIds));
    match.request(buildItemizedPreview(f, memberIds: memberIds, withPayers: true));
  }

  void _onSplitPreview(PreviewState next) {
    final f = form;
    if (f == null || f.splitMode != SplitMode.itemized) return;
    final key = _itemizedKey(f);
    if (key == null || !next.isCurrentFor(key)) return;
    final total = next.preview!.totalMinor;
    if (f.serverTotalMinor == total) return;
    state = state.copyWith(form: f.copyWith(serverTotalMinor: total));
    _syncItemizedPreviews(); // the payers are valid now that the total is known
  }

  // ---- the restaurant bill ----

  int _itemSeq = 0;

  void _setItemized(ItemizedDraft draft) {
    final f = form;
    if (f != null) _set(f.copyWith(itemized: draft));
  }

  ItemDraft _newItem() => ItemDraft(id: 'new-${_itemSeq++}', assigneeIds: {...memberIds});

  /// A new item starts with everyone selected (the user unchecks).
  void addItem() {
    final f = form;
    if (f == null || f.itemized.items.length >= kMaxItems) return;
    _setItemized(f.itemized.copyWith(items: [...f.itemized.items, _newItem()]));
  }

  void removeItem(String id) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(items: [for (final i in f.itemized.items) if (i.id != id) i]));
  }

  void _changeItem(String id, ItemDraft Function(ItemDraft) change) {
    final f = form;
    if (f == null) return;
    _setItemized(f.itemized.copyWith(items: [for (final i in f.itemized.items) i.id == id ? change(i) : i]));
  }

  void setItemName(String id, String value) => _changeItem(id, (i) => i.copyWith(name: value, touched: true));

  void setItemAmount(String id, String value) => _changeItem(id, (i) => i.copyWith(amountText: value, touched: true));

  void toggleAssignee(String id, String memberId) => _changeItem(id, (i) {
        final next = {...i.assigneeIds};
        if (!next.add(memberId)) next.remove(memberId);
        return i.copyWith(assigneeIds: next, touched: true);
      });

  void setServiceOn(bool on) {
    final f = form;
    if (f == null) return;
    // Switching it on offers the usual rate; the field stays editable and keeps whatever the user typed.
    final empty = f.itemized.servicePercentText.trim().isEmpty;
    _setItemized(f.itemized.copyWith(serviceOn: on, servicePercentText: on && empty ? kDefaultServicePercent : null));
  }

  void setServicePercent(String text) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(servicePercentText: text));
  }

  void setTaxOn(bool on) {
    final f = form;
    if (f == null) return;
    final empty = f.itemized.taxPercentText.trim().isEmpty;
    _setItemized(f.itemized.copyWith(taxOn: on, taxPercentText: on && empty ? kDefaultTaxPercent : null));
  }

  void setTaxPercent(String text) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(taxPercentText: text));
  }

  void setTaxBase(TaxBase base) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(taxBase: base));
  }

  void setAdjustment(String text) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(adjustmentText: text));
  }

  /// The +/- buttons of the adjustment: one piaster (0.01 EGP) more or less than what was typed.
  /// Zero is shown as an empty box (no adjustment).
  void stepAdjustment(int piasters) {
    final f = form;
    if (f == null) return;
    final current = f.itemized.adjustmentMinor;
    if (current == null) return; // unreadable text: nothing to step from
    final next = current + piasters;
    if (next.abs() > Money.maxMinor) return;
    _setItemized(f.itemized.copyWith(adjustmentText: next == 0 ? '' : Money.formatPlain(next)));
  }

  void setTitle(String value) {
    final f = form;
    if (f != null) _set(f.copyWith(title: value));
  }

  void setAmount(String value) {
    final f = form;
    if (f == null) return;
    final next = f.copyWith(amountText: value);
    _set(next);
    // Exact mode with nothing typed yet: fill it from the server as soon as the total is usable.
    if (next.splitMode == SplitMode.exact && next.exactTexts.isEmpty && next.totalMinor != null) _schedulePrefill();
  }

  void setDate(Date value) {
    final f = form;
    if (f != null) _set(f.copyWith(date: value));
  }

  /// Switches the tab. The restaurant bill starts with one empty item so the editor shows something to fill.
  void setSplitMode(SplitMode mode) {
    final f = form;
    if (f == null || mode == f.splitMode) return;
    var next = f.copyWith(splitMode: mode);
    if (mode == SplitMode.itemized) {
      if (next.itemized.items.isEmpty) next = next.copyWith(itemized: next.itemized.copyWith(items: [_newItem()]));
      _set(next);
      return;
    }
    if (mode != SplitMode.all && (f.splitMode == SplitMode.all || f.selectedIds.isEmpty)) {
      next = next.copyWith(selectedIds: {...memberIds});
    }
    if (mode == SplitMode.exact) next = next.copyWith(exactTexts: const {});
    _set(next);
    if (mode == SplitMode.exact) unawaited(prefillExact());
  }

  /// Checks or unchecks a member in Selected and Exact mode.
  void toggleMember(String memberId) {
    final f = form;
    if (f == null) return;
    final selected = {...f.selectedIds};
    final texts = {...f.exactTexts};
    if (!selected.add(memberId)) {
      selected.remove(memberId);
      texts.remove(memberId);
    } else if (f.splitMode == SplitMode.exact) {
      texts[memberId] = '';
    }
    _set(f.copyWith(selectedIds: selected, exactTexts: texts));
  }

  void setExactText(String memberId, String text) {
    final f = form;
    if (f != null) _set(f.copyWith(exactTexts: {...f.exactTexts, memberId: text}));
  }

  /// The paid-by sheet's result. One payer paying the whole total is stored as "single".
  void applyPayers({required PayerMode mode, String? singlePayerId, Map<String, String> texts = const {}}) {
    final f = form;
    if (f == null) return;
    _set(f.copyWith(payerMode: mode, singlePayerId: singlePayerId ?? f.singlePayerId, payerTexts: texts));
  }

  // ---- numbers from the server ----

  void _schedulePrefill() {
    _prefillTimer?.cancel();
    _prefillTimer = Timer(ref.read(previewDebounceProvider), () => unawaited(prefillExact()));
  }

  /// Exact mode: asks the server for the EQUAL split among the selected members and puts its
  /// `owedMinor` numbers into the boxes. The user edits from there. No client division.
  Future<void> prefillExact() async {
    final f = form;
    final total = f?.totalMinor;
    if (f == null || total == null) return;
    final ids = f.participantIds(memberIds);
    if (ids.isEmpty) return;
    final command = buildEqualPreview(title: f.title, date: f.date, totalMinor: total, participantIds: ids);
    final asked = commandKey(command);
    final generation = ++_prefillGeneration;
    state = state.copyWith(prefilling: true, prefillFailed: false);
    try {
      final preview = await _repo.preview(gid, command).result;
      if (!ref.mounted || generation != _prefillGeneration) return;
      final now = form;
      final nowTotal = now?.totalMinor;
      if (now == null || nowTotal == null) return;
      final stillAsked = commandKey(buildEqualPreview(
        title: now.title,
        date: now.date,
        totalMinor: nowTotal,
        participantIds: now.participantIds(memberIds),
      ));
      if (stillAsked != asked) {
        state = state.copyWith(prefilling: false); // the user moved on; a newer request follows
        return;
      }
      final texts = {
        for (final share in preview.members)
          if (ids.contains(share.memberId)) share.memberId: Money.formatPlain(share.owedMinor),
      };
      state = state.copyWith(form: now.copyWith(exactTexts: texts), prefilling: false, clearFailure: true);
    } on ApiFailure {
      if (!ref.mounted || generation != _prefillGeneration) return;
      state = state.copyWith(prefilling: false, prefillFailed: true);
    }
  }

  /// "Split equally among the selected payers": the server's EQUAL split of the total among
  /// [payerIds], as typed texts (member -> "125"). Throws the [ApiFailure] if it cannot be calculated.
  Future<Map<String, String>> equalAmongPayers(List<String> payerIds) async {
    final f = form;
    final total = f?.totalMinor;
    if (f == null || total == null || payerIds.isEmpty) return const {};
    final command = buildEqualPreview(title: f.title, date: f.date, totalMinor: total, participantIds: payerIds);
    final preview = await _repo.preview(gid, command).result;
    return {
      for (final share in preview.members)
        if (payerIds.contains(share.memberId)) share.memberId: Money.formatPlain(share.owedMinor),
    };
  }

  // ---- saving ----

  /// Create: with an Idempotency-Key that lives while the same body is retried and changes as
  /// soon as the user edits. Edit: `PUT` with `If-Match` and the explicit participant list.
  Future<SaveOutcome> save() async {
    final f = form;
    if (f == null) return SaveOutcome.invalid;
    if (state.submitting) return SaveOutcome.busy;
    final command = buildExpenseCommand(f, edit: isEdit, memberIds: memberIds);
    if (command == null) return SaveOutcome.invalid;

    final sent = commandKey(command);
    state = state.copyWith(submitting: true, clearFailure: true);
    try {
      final ExpenseView saved;
      if (isEdit) {
        saved = await _repo.update(gid, key.eid!, command);
      } else {
        saved = (await _action.run(commandJson(command), (idempotencyKey) => _repo.create(gid, command, idempotencyKey))).expense;
      }
      _maybeApplied = false;
      if (!ref.mounted) return SaveOutcome.saved;
      state = state.copyWith(submitting: false, savedId: saved.id);
      refreshExpenseViews(ref, gid);
      return SaveOutcome.saved;
    } on ApiFailure catch (failure) {
      // A PUT has no key: after an unknown outcome, a later 409 may just be our own earlier save, so
      // the unknown outcome (and what was sent) is remembered until something definitive happens.
      if (isEdit) {
        final conflict = failure is ApiHttpFailure && failure.problem?.code == ApiErrorCode.versionConflict;
        if (failure.retryable) {
          _maybeApplied = true;
          _lastSentKey = sent;
        } else if (!conflict) {
          _maybeApplied = false;
        }
      }
      if (!ref.mounted) return SaveOutcome.failed;
      state = state.copyWith(submitting: false, failure: failure);
      return SaveOutcome.failed;
    }
  }

  /// After a `VERSION_CONFLICT` (or to check an unknown outcome): reads the latest version so the
  /// next save carries it, and KEEPS what the user typed. If the latest version is exactly what
  /// we tried to save, the earlier attempt had applied and there is nothing left to do.
  Future<ReloadOutcome> reloadLatest() async {
    try {
      final latest = await _repo.get(gid, key.eid!);
      if (!ref.mounted) return ReloadOutcome.reloaded;
      final sent = _lastSentKey;
      if (_maybeApplied && sent != null) {
        final asForm = formFromExpense(latest, memberIds: memberIds, fallbackPayerId: _defaultPayerId);
        final asCommand = buildExpenseCommand(asForm, edit: true, memberIds: memberIds);
        if (asCommand != null && commandKey(asCommand) == sent) {
          _maybeApplied = false;
          state = state.copyWith(savedId: key.eid, clearFailure: true);
          refreshExpenseViews(ref, gid);
          return ReloadOutcome.alreadyApplied;
        }
      }
      _maybeApplied = false;
      state = state.copyWith(latestReloaded: true, clearFailure: true);
      return ReloadOutcome.reloaded;
    } on ApiFailure catch (failure) {
      if (!ref.mounted) return ReloadOutcome.failed;
      final gone = failure is ApiHttpFailure && failure.problem?.code == ApiErrorCode.notFound;
      state = state.copyWith(failure: failure);
      return gone ? ReloadOutcome.gone : ReloadOutcome.failed;
    }
  }

  /// The group's members changed under us (MEMBER_NOT_IN_GROUP): read them again.
  Future<void> reloadMembers() => ref.read(groupDetailControllerProvider(gid).notifier).load();
}

final expenseFormControllerProvider =
    NotifierProvider.autoDispose.family<ExpenseFormController, ExpenseFormView, ExpenseFormKey>(ExpenseFormController.new);
