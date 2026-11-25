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
import 'expense_draft.dart';
import 'expense_form_prefill.dart';
import 'expense_form_state.dart';
import 'expense_preview_controller.dart';
import 'expense_refresh.dart';
import 'shares_field_errors.dart';

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
  ///
  /// With a [draft] (SA11 calculator) the form opens filled in from it, while "how it was opened" stays the empty
  /// form: leaving without saving asks first, so a calculated draft is never lost silently nor saved silently.
  void startCreate({ExpenseDraft? draft, ScanDraft? scanDraft, bool startAsShares = false}) {
    if (_started) return;
    _started = true;
    final today = ref.read(clockProvider)().toDate();
    final f = ExpenseFormState(title: '', amountText: '', date: today, singlePayerId: _defaultPayerId);
    _initial = f;
    final filled = scanDraft != null
        ? formFromScan(scanDraft, date: today, payerId: _defaultPayerId)
        : draft != null
            ? formFromDraft(draft, date: today)
            : f;
    state = ExpenseFormView(form: filled, phase: FormPhase.ready);
    if (startAsShares && scanDraft == null && draft == null) {
      setSplitMode(SplitMode.shares);
      // Opening on shares is not a user edit: leaving right away must not ask to discard.
      _initial = form;
    }
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
    if (key == null) return;

    // A174: the engine refused the adjustment the tolerance set (A12): take it back and keep the mismatch banner.
    if (next.key == key && next.status == PreviewStatus.failed && f.itemized.adjustmentAuto) {
      final base = f.itemized.copyWith(adjustmentText: '', adjustmentAuto: false);
      _autoRejectedKey = _itemizedKey(f.copyWith(itemized: base));
      _set(f.copyWith(itemized: base, clearAutoAdjusted: true));
      return;
    }
    if (!next.isCurrentFor(key)) return;
    final total = next.preview!.totalMinor;

    // A174 (STANDALONE_SPEC 18.3): a scanned receipt's printed total within the tolerance of the preview, and an
    // adjustment the user never touched: set the adjustment to the difference and ask again.
    final printed = f.printedTotalMinor;
    final draft = f.itemized;
    if (printed != null && !draft.adjustmentManual && !draft.adjustmentAuto && draft.adjustmentText.trim().isEmpty && key != _autoRejectedKey) {
      final gap = toleratedGap(printed, total);
      if (gap != null) {
        _set(f.copyWith(
          itemized: draft.copyWith(adjustmentText: Money.formatPlain(gap), adjustmentAuto: true),
          autoAdjustedPiasters: Money.magnitude(gap),
        ));
        return;
      }
    }

    if (f.serverTotalMinor == total) return;
    state = state.copyWith(form: f.copyWith(serverTotalMinor: total));
    _syncItemizedPreviews(); // the payers are valid now that the total is known
  }

  // ---- the restaurant bill ----

  int _itemSeq = 0;

  /// The base key (the bill without the automatic adjustment) the engine refused an automatic adjustment for: the
  /// tolerance is not tried again for it, so a rejection cannot loop (A174).
  String? _autoRejectedKey;

  /// Every user edit of the bill goes through here. An automatic adjustment (A174) belongs to the inputs it was
  /// measured for, so any other edit drops it; the next preview measures the bill again.
  void _setItemized(ItemizedDraft draft) {
    final f = form;
    if (f == null) return;
    var next = draft;
    var clearAuto = false;
    if (f.itemized.adjustmentAuto && next.adjustmentAuto) {
      next = next.copyWith(adjustmentText: '', adjustmentAuto: false);
      clearAuto = true;
    }
    _set(f.copyWith(itemized: next, clearAutoAdjusted: clearAuto || !next.adjustmentAuto));
  }

  ItemDraft _newItem() => ItemDraft(id: 'new-${_itemSeq++}', assigneeIds: {...memberIds});

  /// SA12: replaces the bill with a scan's proposal (called from the itemized editor, after the user agreed). The
  /// scan proposes only: nothing is saved and nobody is assigned. SA17 (A176): the shop name fills the title only
  /// while the title is empty, and the category guess fills the category only while the user has not chosen one.
  void applyScan(ScanDraft scan) {
    final f = form;
    if (f == null) return;
    _autoRejectedKey = null;
    final merchant = scan.merchantName;
    final category = scan.category;
    final fillTitle = merchant != null && f.trimmedTitle.isEmpty;
    final fillCategory = category != null && !f.categoryTouched;
    _set(f.copyWith(
      splitMode: SplitMode.itemized,
      itemized: scan.itemized,
      printedTotalMinor: scan.printedTotalMinor,
      scanNotes: {...scan.notes, if (fillTitle || fillCategory) ScanNote.titleCategorySuggested},
      title: fillTitle ? merchant : null,
      category: fillCategory ? category : null,
      clearAutoAdjusted: true,
    ));
  }

  /// A new item starts with everyone selected (the user unchecks). Returns its id (the screen opens it), or null at
  /// the item limit.
  String? addItem() {
    final f = form;
    if (f == null || f.itemized.items.length >= kMaxItems) return null;
    final item = _newItem();
    _setItemized(f.itemized.copyWith(items: [...f.itemized.items, item]));
    return item.id;
  }

  /// By-person mode: a new item shared by this person only. Returns its id, or null at the item limit.
  String? addItemFor(String personId) {
    final f = form;
    if (f == null || f.itemized.items.length >= kMaxItems) return null;
    final item = ItemDraft(id: 'new-${_itemSeq++}', assigneeIds: {personId}, touched: false);
    _setItemized(f.itemized.copyWith(items: [...f.itemized.items, item]));
    return item.id;
  }

  /// Asks the items card to open this item (the validation summary's rows). Screen intent only: it changes nothing in the bill.
  void requestOpenItem(String id) {
    final f = form;
    if (f == null) return;
    state = state.copyWith(form: f.copyWith(openItemId: id, openItemNonce: f.openItemNonce + 1));
  }

  /// The user closed a scan notice.
  void dismissScanNote(ScanNote note) {
    final f = form;
    if (f == null || !f.scanNotes.contains(note)) return;
    _set(f.copyWith(scanNotes: {...f.scanNotes}..remove(note)));
  }

  /// Removes an item and returns it with its position, so the screen can offer "undo" ([restoreItem]).
  ({ItemDraft item, int index})? removeItem(String id) {
    final f = form;
    if (f == null) return null;
    final index = f.itemized.items.indexWhere((i) => i.id == id);
    if (index < 0) return null;
    final removed = f.itemized.items[index];
    _setItemized(f.itemized.copyWith(items: [for (final i in f.itemized.items) if (i.id != id) i]));
    return (item: removed, index: index);
  }

  /// Puts back an item removed by [removeItem] at its old position (clamped).
  void restoreItem(ItemDraft item, int index) {
    final f = form;
    if (f == null || f.itemized.items.length >= kMaxItems || f.itemized.items.any((i) => i.id == item.id)) return;
    final items = [...f.itemized.items];
    items.insert(index.clamp(0, items.length), item);
    _setItemized(f.itemized.copyWith(items: items));
  }

  /// A copy of the item (same name, price, quantity and people) right after it.
  void duplicateItem(String id) {
    final f = form;
    if (f == null || f.itemized.items.length >= kMaxItems) return;
    final items = [...f.itemized.items];
    final index = items.indexWhere((i) => i.id == id);
    if (index < 0) return;
    items.insert(index + 1, items[index].withId('new-${_itemSeq++}'));
    _setItemized(f.itemized.copyWith(items: items));
  }

  /// "X got 2, Y got 1": replaces the item with one item per person, each with that person's number of units and the
  /// same unit price (STANDALONE_SPEC 18.5, A172: units are not assigned per person inside one item, so the split is
  /// made of separate items and the engine's normal rules apply). People with 0 units get none. Returns false when
  /// nothing changed (no units, or the bill would pass [kMaxItems]).
  bool splitItemUnits(String id, Map<String, int> unitsByMember) {
    final f = form;
    if (f == null) return false;
    final items = [...f.itemized.items];
    final index = items.indexWhere((i) => i.id == id);
    if (index < 0) return false;
    final people = [for (final memberId in memberIds) if ((unitsByMember[memberId] ?? 0) > 0) memberId];
    if (people.isEmpty || items.length - 1 + people.length > kMaxItems) return false;
    final source = items[index];
    final parts = [
      for (final memberId in people)
        source.withId('new-${_itemSeq++}', assigneeIds: {memberId}, quantity: unitsByMember[memberId]!.clamp(kMinQuantity, kMaxQuantity)).copyWith(touched: true),
    ];
    items.replaceRange(index, index + 1, parts);
    _setItemized(f.itemized.copyWith(items: items));
    return true;
  }

  void _changeItem(String id, ItemDraft Function(ItemDraft) change) {
    final f = form;
    if (f == null) return;
    _setItemized(f.itemized.copyWith(items: [for (final i in f.itemized.items) i.id == id ? change(i) : i]));
  }

  void setItemName(String id, String value) => _changeItem(id, (i) => i.copyWith(name: value, touched: true));

  /// The unit price as typed.
  void setItemAmount(String id, String value) => _changeItem(id, (i) => i.copyWith(amountText: value, touched: true));

  void setItemQuantity(String id, int value) =>
      _changeItem(id, (i) => i.copyWith(quantity: value.clamp(kMinQuantity, kMaxQuantity), touched: true));

  void stepItemQuantity(String id, int delta) {
    final item = form?.itemized.items.where((i) => i.id == id).firstOrNull;
    if (item != null) setItemQuantity(id, item.quantity + delta);
  }

  void toggleAssignee(String id, String memberId) => _changeItem(id, (i) {
        final next = {...i.assigneeIds};
        if (!next.add(memberId)) next.remove(memberId);
        return i.copyWith(assigneeIds: next, touched: true);
      });

  /// The member picker's result: exactly these people share the item.
  void setAssignees(String id, Set<String> memberIdSet) => _changeItem(id, (i) => i.copyWith(assigneeIds: {...memberIdSet}, touched: true));

  /// Everyone (or nobody) shares the item.
  void setAllAssignees(String id, {required bool all}) => setAssignees(id, all ? {...memberIds} : <String>{});

  /// By-person mode: ticks or unticks one item for one person.
  void toggleAssigneeForPerson(String personId, String itemId) => toggleAssignee(itemId, personId);

  /// By-person mode: puts a person on every item, or takes them off every item.
  void setPersonOnAllItems(String personId, {required bool on}) {
    final f = form;
    if (f == null) return;
    _setItemized(f.itemized.copyWith(items: [
      for (final i in f.itemized.items)
        i.copyWith(assigneeIds: on ? {...i.assigneeIds, personId} : ({...i.assigneeIds}..remove(personId)), touched: true),
    ]));
  }

  /// The user tapped Save on an incomplete bill: every item is marked touched so each missing field shows its error.
  void revealErrors() {
    final f = form;
    if (f == null) return;
    state = state.copyWith(
      form: f.copyWith(
        itemized: f.itemized.copyWith(items: [for (final i in f.itemized.items) i.copyWith(touched: true)]),
        showAllErrors: true,
      ),
    );
  }

  // ---- charges ----

  void setDiscountOn(bool on) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(discountOn: on));
  }

  void setServiceOn(bool on) {
    final f = form;
    if (f == null) return;
    // Switching it on offers the usual rate; the field stays editable and keeps whatever the user typed.
    final empty = f.itemized.servicePercentText.trim().isEmpty;
    _setItemized(f.itemized.copyWith(serviceOn: on, servicePercentText: on && empty ? kDefaultServicePercent : null));
  }

  void setTaxOn(bool on) {
    final f = form;
    if (f == null) return;
    final empty = f.itemized.taxPercentText.trim().isEmpty;
    _setItemized(f.itemized.copyWith(taxOn: on, taxPercentText: on && empty ? kDefaultTaxPercent : null));
  }

  /// The `% | ج.م` toggle. The text of the other mode is kept, so switching back restores what was typed.
  void setChargeMode(ChargeKind kind, ChargeMode mode) {
    final f = form;
    if (f == null) return;
    final d = f.itemized;
    _setItemized(switch (kind) {
      ChargeKind.discount => d.copyWith(discountMode: mode),
      ChargeKind.service => d.copyWith(serviceMode: mode),
      ChargeKind.tax => d.copyWith(taxMode: mode),
    });
  }

  /// The value box of a charge row: written to the text of the row's current mode.
  void setChargeText(ChargeKind kind, String text) {
    final f = form;
    if (f == null) return;
    final d = f.itemized;
    _setItemized(switch (kind) {
      ChargeKind.discount => d.discountMode == ChargeMode.percent ? d.copyWith(discountPercentText: text) : d.copyWith(discountAmountText: text),
      ChargeKind.service => d.serviceMode == ChargeMode.percent ? d.copyWith(servicePercentText: text) : d.copyWith(serviceAmountText: text),
      ChargeKind.tax => d.taxMode == ChargeMode.percent ? d.copyWith(taxPercentText: text) : d.copyWith(taxAmountText: text),
    });
  }

  void setServicePercent(String text) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(serviceMode: ChargeMode.percent, servicePercentText: text));
  }

  void setTaxPercent(String text) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(taxMode: ChargeMode.percent, taxPercentText: text));
  }

  /// A180: the delivery switch (an amount only; the field keeps whatever was typed).
  void setDeliveryOn(bool on) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(deliveryOn: on));
  }

  void setDeliveryAmount(String text) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(deliveryAmountText: text));
  }

  void setTaxBase(TaxBase base) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(taxBase: base));
  }

  /// A typed adjustment: the user's own, so the printed-total tolerance leaves it alone from now on.
  void setAdjustment(String text) {
    final f = form;
    if (f != null) _setItemized(f.itemized.copyWith(adjustmentText: text, adjustmentAuto: false, adjustmentManual: true));
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
    _setItemized(f.itemized.copyWith(adjustmentText: next == 0 ? '' : Money.formatPlain(next), adjustmentAuto: false, adjustmentManual: true));
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

  void setCategory(String value) {
    final f = form;
    if (f != null) _set(f.copyWith(category: value, categoryTouched: true));
  }

  /// SA10 (A135): "Paid from the pool". On makes the treasurer the single payer (the payer editor is off while it
  /// is on); off keeps the treasurer as the payer, who can then be changed as usual.
  void setPaidFromPool(bool on, {required String treasurerId}) {
    final f = form;
    if (f == null) return;
    _set(on
        ? f.copyWith(paidFromPool: true, payerMode: PayerMode.single, singlePayerId: treasurerId, payerTexts: const {})
        : f.copyWith(paidFromPool: false));
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
    if (mode == SplitMode.shares) {
      // Everyone starts with their default share (or 1); the user edits from there. Nothing is calculated here.
      if (next.shares.rows.isEmpty) next = next.copyWith(shares: next.shares.copyWith(rows: _shareRows(memberIds)));
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

  // ---- shares (SA19) ----

  /// One row per id in [ids] (in member order), with the member's default share or 1 unit.
  List<ShareRowDraft> _shareRows(Iterable<String> ids, {List<ShareRowDraft> keep = const []}) {
    final wanted = ids.toSet();
    final kept = {for (final r in keep) r.memberId: r};
    return [
      for (final m in members)
        if (wanted.contains(m.id)) kept[m.id] ?? ShareRowDraft(memberId: m.id, units: (m.defaultShareUnits ?? kMinShareUnits).clamp(kMinShareUnits, kMaxShareUnits)),
    ];
  }

  void _setShares(SharesDraft draft) {
    final f = form;
    if (f != null) _set(f.copyWith(shares: draft));
  }

  /// One step of a person's units, kept inside the allowed range.
  void stepShareUnits(String memberId, int delta) {
    final f = form;
    if (f == null) return;
    final rows = [
      for (final r in f.shares.rows) r.memberId == memberId ? r.copyWith(units: (r.units + delta).clamp(kMinShareUnits, kMaxShareUnits)) : r,
    ];
    _setShares(f.shares.copyWith(rows: rows));
  }

  /// The people picked in the member picker: new people start with their default share, removed ones are dropped, the
  /// rest keep what was set.
  void setShareMembers(Set<String> ids) {
    final f = form;
    if (f == null) return;
    _setShares(f.shares.copyWith(rows: _shareRows(ids, keep: f.shares.rows)));
  }

  /// The billing period, both dates at once. A person's presence that is no longer inside it goes back to "full
  /// period" (a comparison of dates only).
  void setPeriod(Date from, Date to) {
    final f = form;
    if (f == null) return;
    final rows = [
      for (final r in f.shares.rows)
        r.hasPresence && (r.presentFrom!.compareTo(from) < 0 || r.presentTo!.compareTo(to) > 0) ? r.copyWith(clearPresence: true) : r,
    ];
    _setShares(f.shares.copyWith(rows: rows, periodOn: true, periodFrom: from, periodTo: to));
  }

  /// Billing period off: no period and nobody has a presence range.
  void clearPeriod() {
    final f = form;
    if (f == null) return;
    _setShares(f.shares.copyWith(rows: [for (final r in f.shares.rows) r.copyWith(clearPresence: true)], periodOn: false, clearPeriod: true));
  }

  void setPresence(String memberId, Date from, Date to) {
    final f = form;
    if (f == null) return;
    _setShares(f.shares.copyWith(rows: [for (final r in f.shares.rows) r.memberId == memberId ? r.copyWith(presentFrom: from, presentTo: to) : r]));
  }

  void resetPresence(String memberId) {
    final f = form;
    if (f == null) return;
    _setShares(f.shares.copyWith(rows: [for (final r in f.shares.rows) r.memberId == memberId ? r.copyWith(clearPresence: true) : r]));
  }

  /// Which row or the period the server's last refusal named (the last save, or the split preview of the form as it is).
  SharesFieldErrors sharesFieldErrors() {
    final f = form;
    if (f == null || f.splitMode != SplitMode.shares) return SharesFieldErrors.none;
    final command = buildExpenseCommand(f, edit: isEdit, memberIds: memberIds, preview: true);
    final preview = ref.read(expensePreviewControllerProvider((gid: gid, slot: PreviewSlot.split)));
    final previewFailure = command != null && preview.key == commandKey(command) && preview.status == PreviewStatus.failed ? preview.failure : null;
    return sharesFieldErrorsOf([state.failure, previewFailure], f.participantIds(memberIds));
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
