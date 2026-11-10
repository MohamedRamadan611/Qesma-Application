import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../groups/application/group_detail_controller.dart';
import '../../groups/presentation/group_ui.dart';
import '../application/expense_command_builder.dart';
import '../application/expense_detail_controller.dart';
import '../application/expense_form_controller.dart';
import '../application/expense_form_state.dart';
import '../application/expense_preview_controller.dart';
import 'itemized_editor.dart';
import 'expense_ui.dart';
import 'payers_sheet.dart';
import 'split_section.dart';
import '../../../core/theme/palette.dart';

/// Add expense (P5-01) and edit expense. Title, total, date, who paid, and how it is split
/// (everyone / selected / exact amounts; the restaurant bill is FL6). Every per-member number
/// is the server's; the form only adds up what the user typed.
class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({super.key, required this.gid, this.eid});

  final String gid;

  /// Null when adding.
  final String? eid;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _title = TextEditingController();
  final _amount = TextEditingController();
  bool _synced = false;
  bool _titleTouched = false;

  ExpenseFormKey get _key => (gid: widget.gid, eid: widget.eid);
  bool get _isEdit => widget.eid != null;

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    super.dispose();
  }

  ExpenseFormController get _controller => ref.read(expenseFormControllerProvider(_key).notifier);

  void _goBack() => goBackOr(context, _isEdit ? Routes.expense(widget.gid, widget.eid!) : Routes.group(widget.gid));

  /// The header's back arrow: leaves at once, or asks first when something was typed.
  void _onBackPressed() {
    if (_controller.dirty && ref.read(expenseFormControllerProvider(_key)).savedId == null) {
      _confirmLeave();
    } else {
      _goBack();
    }
  }

  Future<void> _confirmLeave() async {
    final l10n = AppLocalizations.of(context);
    final leave = await showConfirmDialog(
      context,
      title: l10n.expenseFormLeaveTitle,
      message: l10n.expenseFormLeaveBody,
      confirmLabel: l10n.expenseFormLeaveConfirm,
      cancelLabel: l10n.expenseFormLeaveKeep,
      destructive: true,
    );
    if (leave && mounted) _goBack();
  }

  void _onSaved(String id) {
    final l10n = AppLocalizations.of(context);
    showAppSnackBar(context, l10n.expenseFormSaved);
    if (_isEdit) {
      // The details page underneath shows the old copy: read it again.
      final details = expenseDetailControllerProvider((gid: widget.gid, eid: id));
      if (ref.read(details.exists)) ref.read(details.notifier).load();
      _goBack();
    } else {
      context.pushReplacement(Routes.expense(widget.gid, id));
    }
  }

  Future<void> _onFailure(ApiFailure failure) async {
    final code = failure is ApiHttpFailure ? failure.problem?.code : null;
    if (code == ApiErrorCode.memberNotInGroup) {
      await _controller.reloadMembers();
    } else if (code == ApiErrorCode.versionConflict && _isEdit) {
      final l10n = AppLocalizations.of(context);
      final reload = await showConfirmDialog(
        context,
        title: l10n.expenseFormConflictTitle,
        message: l10n.expenseFormConflictBody,
        confirmLabel: l10n.groupConflictReload,
      );
      if (!reload || !mounted) return;
      final outcome = await _controller.reloadLatest();
      if (outcome == ReloadOutcome.gone && mounted) showAppSnackBar(context, AppLocalizations.of(context).expenseGoneTitle);
    }
  }

  Future<void> _pickDate(ExpenseFormState form) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: form.date.toDateTime(),
      firstDate: kFirstExpenseDate.toDateTime(),
      lastDate: kLastExpenseDate.toDateTime(),
    );
    if (picked != null && mounted) _controller.setDate(picked.toDate());
  }

  Future<void> _save() async {
    final outcome = await _controller.save();
    if (!mounted) return;
    if (outcome == SaveOutcome.invalid) setState(() => _titleTouched = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final group = ref.watch(groupDetailControllerProvider(widget.gid)).group;
    final view = ref.watch(expenseFormControllerProvider(_key));

    ref.listen<String?>(expenseFormControllerProvider(_key).select((v) => v.savedId), (previous, next) {
      if (next != null) _onSaved(next);
    });
    ref.listen<ApiFailure?>(expenseFormControllerProvider(_key).select((v) => v.failure), (previous, next) {
      if (next != null) _onFailure(next);
    });

    final title = _isEdit ? l10n.expenseEdit : l10n.expensesAdd;

    Widget scaffold(Widget body, {Widget? bottomBar}) => AppScaffold(title: title, showBack: true, onBack: _onBackPressed, body: body, bottomBar: bottomBar);

    if (group == null) {
      final groupState = ref.watch(groupDetailControllerProvider(widget.gid));
      if (groupState.failure == null) return scaffold(const SkeletonList(itemCount: 3));
      final failure = groupState.failure!;
      final retry = ref.read(groupDetailControllerProvider(widget.gid).notifier).load;
      return scaffold(
        failure is ApiNoConnection || failure is ApiTimeout
            ? NoInternetState(onRetry: retry)
            : ErrorState(onRetry: retry, message: errorCopyFor(l10n, failure).message, requestId: failure.problem?.requestId),
      );
    }

    if (view.form == null) {
      if (view.phase == FormPhase.loading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          if (_isEdit) {
            _controller.startEdit();
          } else {
            _controller.startCreate();
          }
        });
        return scaffold(const SkeletonList(itemCount: 3));
      }
      return switch (view.phase) {
        FormPhase.gone => scaffold(
            EmptyState(icon: Icons.search_off, title: l10n.expenseGoneTitle, actionLabel: l10n.expenseBackToList, onAction: () => goBackOr(context, Routes.group(widget.gid))),
          ),
        _ => scaffold(
            view.loadFailure is ApiNoConnection || view.loadFailure is ApiTimeout
                ? NoInternetState(onRetry: _controller.retryLoad)
                : ErrorState(
                    onRetry: _controller.retryLoad,
                    message: errorCopyFor(l10n, view.loadFailure ?? const ApiUnexpected()).message,
                    requestId: view.loadFailure?.problem?.requestId,
                  ),
          ),
      };
    }

    final form = view.form!;
    if (!_synced) {
      _synced = true;
      _title.text = form.title;
      _amount.text = form.amountText;
    }

    final members = _controller.members;
    final memberIds = _controller.memberIds;
    final nameOf = memberNameResolver(group, l10n);

    // The split shown in the member list: the server's EQUAL split among the participants.
    final total = form.totalMinor;
    final participants = form.participantIds(memberIds);
    final isItemized = form.splitMode == SplitMode.itemized;
    final splitCommand = (form.splitMode == SplitMode.all || form.splitMode == SplitMode.selected) && total != null && participants.isNotEmpty
        ? buildEqualPreview(title: form.title, date: form.date, totalMinor: total, participantIds: participants)
        : null;
    final previewKey = splitCommand == null ? null : commandKey(splitCommand);
    if (!isItemized) {
      // A restaurant bill's previews are driven by the controller, which owns that total.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) ref.read(expensePreviewControllerProvider((gid: widget.gid, slot: PreviewSlot.split)).notifier).request(splitCommand);
      });
    }

    final failure = view.failure;
    final failureCode = failure is ApiHttpFailure ? failure.problem?.code : null;
    final payersBanner = failureCode == ApiErrorCode.payersTotalMismatch ? errorCopyFor(l10n, failure!).message : null;
    final splitBanner = failureCode == ApiErrorCode.splitTotalMismatch ? errorCopyFor(l10n, failure!).message : null;
    final generalFailure = failure != null &&
        failureCode != ApiErrorCode.payersTotalMismatch &&
        failureCode != ApiErrorCode.splitTotalMismatch &&
        !(failureCode == ApiErrorCode.versionConflict && _isEdit);

    final canSave = form.canSave(memberIds);
    final payersMismatch = form.payerMode == PayerMode.multiple && total != null && !form.payersValid;

    final body = PopScope(
      canPop: !_controller.dirty || view.savedId != null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _confirmLeave();
      },
      child: ListView(
        padding: const EdgeInsets.all(QesmaSpacing.margin),
        children: [
          if (view.latestReloaded) ...[
            _Note(text: l10n.expenseFormConflictNote),
            const SizedBox(height: QesmaSpacing.md),
          ],
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppTextField(
                  controller: _title,
                  label: l10n.expenseFormTitleLabel,
                  hint: l10n.expenseFormTitleHint,
                  maxLength: kExpenseTitleMax,
                  errorText: _titleTouched && form.trimmedTitle.isEmpty ? l10n.expenseFormTitleRequired : null,
                  textInputAction: TextInputAction.next,
                  onChanged: (value) {
                    _titleTouched = true;
                    _controller.setTitle(value);
                  },
                ),
                const SizedBox(height: QesmaSpacing.md),
                if (isItemized)
                  _BillTotal(totalMinor: total)
                else ...[
                  AppTextField(
                    controller: _amount,
                    label: l10n.expenseFormAmountLabel,
                    hint: l10n.expenseFormAmountHint,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [amountInputFormatter],
                    errorText: form.amountTyped && total == null ? l10n.expenseFormAmountInvalid : null,
                    showClear: false,
                    onChanged: _controller.setAmount,
                  ),
                  const SizedBox(height: QesmaSpacing.xs),
                  Text(l10n.expenseFormCurrencyNote, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                ],
                const SizedBox(height: QesmaSpacing.md),
                AppButton(
                  label: '${l10n.expenseFormDateLabel}: ${dateText(form.date)}',
                  icon: Icons.calendar_today_outlined,
                  variant: AppButtonVariant.secondary,
                  onPressed: () => _pickDate(form),
                ),
              ],
            ),
          ),
          const SizedBox(height: QesmaSpacing.md),
          _PaidByCard(
            form: form,
            nameOf: nameOf,
            mismatch: payersMismatch,
            serverBanner: payersBanner,
            onEdit: () => showPayersSheet(context, formKey: _key),
          ),
          const SizedBox(height: QesmaSpacing.md),
          SplitSection(formKey: _key, form: form, members: members, previewKey: previewKey),
          if (isItemized) ...[
            const SizedBox(height: QesmaSpacing.md),
            ItemizedEditor(formKey: _key, form: form, members: members, nameOf: nameOf),
          ],
          if (splitBanner != null) ...[const SizedBox(height: QesmaSpacing.sm), ErrorBanner(splitBanner)],
          if (generalFailure) ...[
            const SizedBox(height: QesmaSpacing.md),
            _SaveFailure(failure: failure, onRetry: _save),
          ],
          const SizedBox(height: QesmaSpacing.lg),
        ],
      ),
    );

    return scaffold(
      body,
      bottomBar: _BottomBar(
        form: form,
        memberIds: memberIds,
        canSave: canSave,
        billTotalMinor: isItemized ? total : null,
        submitting: view.submitting,
        isEdit: _isEdit,
        onSave: _save,
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
        liveRegion: true,
        child: DecoratedBox(
          decoration: BoxDecoration(color: context.colors.tint, borderRadius: BorderRadius.circular(QesmaRadii.control)),
          child: Padding(
            padding: const EdgeInsets.all(QesmaSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(Icons.info_outline, color: context.colors.primary, size: 20)),
                const SizedBox(width: QesmaSpacing.sm),
                Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
        ),
      );
}

class _PaidByCard extends StatelessWidget {
  const _PaidByCard({required this.form, required this.nameOf, required this.mismatch, required this.serverBanner, required this.onEdit});

  final ExpenseFormState form;
  final String Function(String) nameOf;
  final bool mismatch;
  final String? serverBanner;
  final VoidCallback onEdit;

  String _summary(AppLocalizations l10n) {
    if (form.payerMode == PayerMode.single) {
      final id = form.singlePayerId;
      return l10n.expensePaidBy(id == null ? l10n.expenseUnknownMember : nameOf(id));
    }
    final parts = [
      for (final entry in form.payerTexts.entries)
        fsIsolate(l10n.expensePayerAmount(nameOf(entry.key), Money.parse(entry.value) == null ? '' : plainAmount(Money.parse(entry.value)!))),
    ];
    return l10n.expensePaidBy(parts.join(l10n.expenseListSeparator));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final count = form.payerMode == PayerMode.single ? 1 : form.payerTexts.length;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Semantics(header: true, child: Text(l10n.expenseFormPaidByTitle, style: theme.textTheme.titleMedium))),
              if (count > 0)
                Text(
                  countPhrase(count, one: l10n.expensePayersCountOne, two: l10n.expensePayersCountTwo, few: l10n.expensePayersCount, many: l10n.expensePayersCountMany),
                  style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper),
                ),
            ],
          ),
          const SizedBox(height: QesmaSpacing.sm),
          Semantics(label: stripIsolates(_summary(l10n)), child: ExcludeSemantics(child: Text(_summary(l10n), style: theme.textTheme.bodyMedium))),
          const SizedBox(height: QesmaSpacing.sm),
          AppButton(label: l10n.expenseFormEditPayers, icon: Icons.edit_outlined, variant: AppButtonVariant.secondary, onPressed: onEdit),
          if (mismatch) ...[const SizedBox(height: QesmaSpacing.sm), ErrorBanner(l10n.expenseFormPayersMismatch)],
          if (serverBanner != null) ...[const SizedBox(height: QesmaSpacing.sm), ErrorBanner(serverBanner!)],
        ],
      ),
    );
  }
}

class _SaveFailure extends StatelessWidget {
  const _SaveFailure({required this.failure, required this.onRetry});

  final ApiFailure failure;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unknown = failure is ApiTimeout || (failure is ApiHttpFailure && (failure as ApiHttpFailure).status >= 500);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ErrorBanner(errorCopyFor(l10n, failure).message),
        if (unknown) ...[
          const SizedBox(height: QesmaSpacing.sm),
          Text(l10n.expenseFormOutcomeUnknown, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
        ],
        if (failure.retryable) ...[
          const SizedBox(height: QesmaSpacing.sm),
          AppButton(label: l10n.expenseFormSaveRetry, icon: Icons.refresh, variant: AppButtonVariant.secondary, onPressed: onRetry),
        ],
      ],
    );
  }
}

/// Exact mode's "typed so far against the total" line and the save button.
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.form, required this.memberIds, required this.canSave, required this.submitting, required this.isEdit, required this.onSave, this.billTotalMinor});

  final ExpenseFormState form;
  final List<String> memberIds;
  final bool canSave;
  final bool submitting;
  final bool isEdit;
  final VoidCallback onSave;

  /// A restaurant bill's total (the server's), shown next to the save button.
  final int? billTotalMinor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final total = form.totalMinor;
    Widget? summary;
    if (form.splitMode == SplitMode.exact && total != null) {
      final sum = form.exactSum(memberIds);
      final remaining = total - sum;
      final (icon, text, color) = remaining == 0
          ? (Icons.check_circle_outline, l10n.expenseFormExactMatches, context.colors.success)
          : remaining > 0
              ? (Icons.warning_amber_rounded, l10n.expenseFormExactRemaining(moneyDisplay(l10n, remaining)), context.colors.warning)
              : (Icons.warning_amber_rounded, l10n.expenseFormExactOver(moneyDisplay(l10n, -remaining)), context.colors.error);
      summary = Semantics(
        liveRegion: true,
        label: '${l10n.expenseFormExactSummary(moneySpoken(l10n, sum), moneySpoken(l10n, total))}. $text',
        child: ExcludeSemantics(
          child: Padding(
            padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
            child: Wrap(
              spacing: QesmaSpacing.sm,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Icon(icon, color: color, size: 20),
                Text(l10n.expenseFormExactSummary(moneyDisplay(l10n, sum), moneyDisplay(l10n, total)), style: theme.textTheme.titleSmall),
                Text(text, style: theme.textTheme.bodyMedium?.copyWith(color: color)),
              ],
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, QesmaSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ?summary,
          if (form.splitMode == SplitMode.itemized)
            Padding(
              padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
              // A wrap, not a row: at large text the amount goes under its label instead of squeezing it.
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: QesmaSpacing.sm,
                runSpacing: QesmaSpacing.xs,
                children: [
                  Text(l10n.expenseItemizedBarTotal, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
                  if (billTotalMinor != null) MoneyText(billTotalMinor!, size: MoneySize.large) else const SkeletonBlock(width: 96, height: 24),
                ],
              ),
            ),
          AppButton(
            label: isEdit ? l10n.expenseFormSaveChanges : l10n.expenseFormSave,
            icon: Icons.check,
            loading: submitting,
            onPressed: canSave && !submitting ? onSave : null,
          ),
        ],
      ),
    );
  }
}

/// A restaurant bill's total is not typed: it is the server's number for the items, service, tax
/// and adjustment as they are now (a placeholder while it is being worked out).
class _BillTotal extends StatelessWidget {
  const _BillTotal({required this.totalMinor});

  final int? totalMinor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(l10n.expenseBillTotal, style: theme.textTheme.labelLarge),
        const SizedBox(height: QesmaSpacing.xs),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: totalMinor == null ? const SkeletonBlock(width: 120, height: 28) : MoneyText(totalMinor!, size: MoneySize.large),
        ),
        const SizedBox(height: QesmaSpacing.xs),
        Text(l10n.expenseItemizedTotalNote, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
      ],
    );
  }
}
