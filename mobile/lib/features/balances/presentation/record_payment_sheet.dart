import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../../expenses/presentation/status_banner.dart';
import '../../groups/application/group_detail_controller.dart';
import '../application/record_payment_controller.dart';
import '../application/settlement_rules.dart';
import '../../groups/application/group_permissions.dart';
import '../application/record_payment_state.dart';
import 'member_picker_sheet.dart';
import '../../../core/theme/palette.dart';

/// Opens the payment sheet (P9-02, FL13). [seed] is a tapped transfer (from, to, the server's amount) or empty for a payment
/// the user describes. Returns what the server created (its `status` says PENDING or CONFIRMED) or null when nothing was
/// recorded. Closing it after changes asks first. The sheet shows no "effect of this payment": the new balances come from
/// the server, and the status the person sees afterwards is the server's.
///
/// Who may name whom (A85): a Member records their own payments (they are the payer, or the receiver of cash); an Owner/Admin
/// may also record on behalf of others. The wording hint is a prediction of the server's rule, never a result.
Future<SettlementView?> showRecordPaymentSheet(BuildContext context, {required String gid, PaymentSeed seed = const PaymentSeed()}) async {
  final key = (gid: gid, seed: seed);
  final result = await showModalBottomSheet<SettlementView>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: _PaymentSheet(pkey: key),
    ),
  );
  return result;
}

class _PaymentSheet extends ConsumerStatefulWidget {
  const _PaymentSheet({required this.pkey});

  final PaymentKey pkey;

  @override
  ConsumerState<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends ConsumerState<_PaymentSheet> {
  final _note = TextEditingController();
  bool _amountTouched = false;

  RecordPaymentController get _controller => ref.read(recordPaymentControllerProvider(widget.pkey).notifier);

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  List<MemberDto> get _members => ref.read(groupDetailControllerProvider(widget.pkey.gid)).group?.members.toList() ?? const [];

  Future<void> _pickFrom(PaymentForm form) async {
    final id = await showMemberPicker(context, members: _members, selectedId: form.fromId, excludeId: form.toId);
    if (id != null) _controller.setFrom(id);
  }

  Future<void> _pickTo(PaymentForm form) async {
    final id = await showMemberPicker(context, members: _members, selectedId: form.toId, excludeId: form.fromId);
    if (id != null) _controller.setTo(id);
  }

  Future<void> _pickDate(PaymentForm form) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: form.dateValid ? form.date.toDateTime() : Date.now().toDateTime(),
      firstDate: kFirstPaymentDate.toDateTime(),
      lastDate: kLastPaymentDate.toDateTime(),
    );
    if (picked != null && mounted) _controller.setDate(picked.toDate());
  }

  Future<void> _send() async {
    setState(() => _amountTouched = true);
    final outcome = await _controller.send();
    if (outcome == PaymentOutcome.recorded && mounted) Navigator.of(context).pop(ref.read(recordPaymentControllerProvider(widget.pkey)).created);
  }

  Future<void> _askDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showConfirmDialog(
      context,
      title: l10n.paymentDiscardTitle,
      message: l10n.paymentDiscardBody,
      confirmLabel: l10n.paymentDiscardConfirm,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (discard && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final view = ref.watch(recordPaymentControllerProvider(widget.pkey));
    final form = view.form;
    final group = ref.watch(groupDetailControllerProvider(widget.pkey.gid)).group;
    final nameOf = memberNameResolver(group, l10n);
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final amount = form.amountMinor;
    final suggested = form.suggestedMinor;
    final you = group?.yourMemberId;
    final isAdmin = ref.watch(groupPermissionsProvider(widget.pkey.gid)).canManageMembers;
    final toMember = group?.members.where((m) => m.id == form.toId).firstOrNull;
    final outcome = expectedInitialOutcome(
      yourMemberId: you,
      fromMemberId: form.fromId,
      toMemberId: form.toId,
      receiverHasAccount: toMember?.hasAccount ?? false,
      isAdminOrOwner: isAdmin,
    );
    // A Member never picks the payer (it is them) unless they are the receiver of cash, then the receiver is them. Owner/Admin pick both.
    final fromLocked = !isAdmin && form.toId != you;
    final toLocked = !isAdmin && form.toId == you;
    final title = form.fromId == you ? l10n.paymentTitleDeclare : (form.toId == you ? l10n.paymentTitleReceived : l10n.paymentTitleOnBehalf);
    final toName = form.toId == null ? '' : nameOf(form.toId!);

    final from = _MemberField(label: l10n.paymentFrom, memberId: form.fromId, nameOf: nameOf, onTap: view.sending || fromLocked ? null : () => _pickFrom(form));
    final to = _MemberField(label: l10n.paymentTo, memberId: form.toId, nameOf: nameOf, onTap: view.sending || toLocked ? null : () => _pickTo(form));

    final amountError = _amountTouched && amount == null;
    final dateError = !form.dateValid;
    final noteError = !form.noteValid;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (stacked) ...[from, const SizedBox(height: QesmaSpacing.sm), to] else Row(children: [Expanded(child: from), const SizedBox(width: QesmaSpacing.sm), Expanded(child: to)]),
        if (form.firstError == PaymentFieldError.sameMember) ...[
          const SizedBox(height: QesmaSpacing.sm),
          Semantics(liveRegion: true, child: Text(l10n.paymentSameMember, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error))),
        ],
        const SizedBox(height: QesmaSpacing.md),
        Text(l10n.paymentAmountLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: QesmaSpacing.sm),
        AmountBox(
          text: form.amountText,
          semanticLabel: l10n.paymentAmountLabel,
          expand: true,
          hasError: amountError,
          enabled: !view.sending,
          onChanged: (text) {
            _amountTouched = true;
            _controller.setAmount(text);
          },
        ),
        if (amountError) ...[
          const SizedBox(height: QesmaSpacing.xs),
          Semantics(liveRegion: true, child: Text(l10n.paymentAmountError, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error))),
        ],
        if (suggested != null) ...[
          const SizedBox(height: QesmaSpacing.sm),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: AppButton(
              label: l10n.paymentFullAmount(moneyDisplay(l10n, suggested)),
              icon: Icons.check_circle_outline,
              variant: AppButtonVariant.secondary,
              expand: false,
              onPressed: view.sending ? null : _controller.useFullAmount,
            ),
          ),
        ],
        const SizedBox(height: QesmaSpacing.md),
        Text(l10n.paymentDateLabel, style: theme.textTheme.labelLarge),
        const SizedBox(height: QesmaSpacing.sm),
        AppButton(
          label: dateText(form.date),
          icon: Icons.calendar_today_outlined,
          variant: AppButtonVariant.secondary,
          onPressed: view.sending ? null : () => _pickDate(form),
        ),
        if (dateError) ...[
          const SizedBox(height: QesmaSpacing.xs),
          Semantics(liveRegion: true, child: Text(l10n.paymentDateError, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.error))),
        ],
        const SizedBox(height: QesmaSpacing.md),
        AppTextField(
          controller: _note,
          label: l10n.paymentNoteLabel,
          hint: l10n.paymentNoteHint,
          maxLength: kPaymentNoteMax,
          enabled: !view.sending,
          errorText: noteError ? l10n.paymentNoteError : null,
          onChanged: _controller.setNote,
        ),
        const SizedBox(height: QesmaSpacing.md),
        _OutcomeHint(outcome: outcome, from: form.fromId == you, receiverName: toName),
        if (view.failure != null) ...[
          const SizedBox(height: QesmaSpacing.md),
          StatusBanner(icon: Icons.error_outline, text: errorCopyFor(l10n, view.failure!).message, tone: BannerTone.error),
        ],
      ],
    );

    final action = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AppButton(
          label: amount == null ? l10n.paymentConfirmNoAmount : l10n.paymentConfirm(moneyDisplay(l10n, amount)),
          icon: Icons.check,
          loading: view.sending,
          onPressed: form.canSend && !view.sending && outcome != InitialOutcome.notAllowed ? _send : null,
        ),
        const SizedBox(height: QesmaSpacing.xs),
        AppButton(
          label: l10n.commonCancel,
          variant: AppButtonVariant.text,
          onPressed: view.sending ? null : () => Navigator.of(context).maybePop(),
        ),
      ],
    );

    final dirty = _controller.dirty || _note.text.isNotEmpty;
    return PopScope(
      canPop: !dirty || view.sending,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askDiscard();
      },
      child: AppBottomSheet(title: title, subtitle: l10n.paymentSubtitle, action: action, child: body),
    );
  }
}

/// A "from" or "to" picker: the member's avatar and name under a small label; opens the picker.
class _MemberField extends StatelessWidget {
  const _MemberField({required this.label, required this.memberId, required this.nameOf, required this.onTap});

  final String label;
  final String? memberId;
  final String Function(String) nameOf;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = memberId == null ? '' : nameOf(memberId!);
    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '$label: $name',
      onTap: onTap,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
        child: Row(
          children: [
            if (memberId != null) ...[MemberAvatar(memberId: memberId!, name: name, size: 36), const SizedBox(width: QesmaSpacing.sm)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
                  Text(name, style: theme.textTheme.titleSmall),
                ],
              ),
            ),
            Icon(Icons.expand_more, color: context.colors.textHelper),
          ],
        ),
      ),
    );
  }
}

/// What will happen to the payment, in words, before it is sent (a prediction of the server's rule A85; the status shown
/// after sending is the server's).
class _OutcomeHint extends StatelessWidget {
  const _OutcomeHint({required this.outcome, required this.from, required this.receiverName});

  final InitialOutcome outcome;

  /// The signed-in person is the payer.
  final bool from;
  final String receiverName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final (icon, tone, text) = switch (outcome) {
      InitialOutcome.pending => (Icons.hourglass_top, BannerTone.warning, l10n.paymentHintPending(fsIsolate(receiverName))),
      InitialOutcome.confirmed => (Icons.check_circle_outline, BannerTone.success, l10n.paymentHintConfirmed),
      InitialOutcome.notAllowed => (
          Icons.info_outline,
          BannerTone.neutral,
          from ? l10n.paymentHintNoAccount(fsIsolate(receiverName)) : l10n.paymentHintNotAllowed,
        ),
    };
    return StatusBanner(icon: icon, text: text, tone: tone);
  }
}
