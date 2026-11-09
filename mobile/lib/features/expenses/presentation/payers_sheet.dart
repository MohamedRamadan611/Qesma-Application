import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/money/money.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/expense_command_builder.dart';
import '../application/expense_form_controller.dart';
import '../application/expense_form_state.dart';
import '../application/expense_preview_controller.dart';

/// Opens the paid-by editor (P6-01). The user picks who paid and types what each paid; the
/// sheet keeps a draft and only writes it into the form on "confirm".
Future<void> showPayersSheet(BuildContext context, {required ExpenseFormKey formKey}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.92),
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
      child: PayersSheet(formKey: formKey),
    ),
  );
}

/// Who paid, with a running "left to assign" (the typed amounts added up against the total).
/// The server decides whether the payers match: the "matches" message appears only when the
/// latest preview for exactly these amounts says so.
class PayersSheet extends ConsumerStatefulWidget {
  const PayersSheet({super.key, required this.formKey});

  final ExpenseFormKey formKey;

  @override
  ConsumerState<PayersSheet> createState() => _PayersSheetState();
}

class _PayersSheetState extends ConsumerState<PayersSheet> {
  /// The draft: a key is a payer, the value is what they typed.
  late Map<String, String> _texts;
  bool _splitting = false;
  bool _splitFailed = false;

  ExpenseFormController get _controller => ref.read(expenseFormControllerProvider(widget.formKey).notifier);

  @override
  void initState() {
    super.initState();
    final f = _controller.form!;
    final total = f.totalMinor;
    if (f.payerMode == PayerMode.single) {
      final payer = f.singlePayerId;
      _texts = payer == null || total == null ? {} : {payer: Money.formatPlain(total)};
    } else {
      _texts = {...f.payerTexts};
    }
  }

  PreviewKey get _previewKey => (gid: widget.formKey.gid, slot: PreviewSlot.payers);

  Map<String, int>? _typedMinors() {
    final minors = <String, int>{};
    for (final entry in _texts.entries) {
      final minor = Money.parse(entry.value);
      if (minor == null) return null;
      minors[entry.key] = minor;
    }
    return minors;
  }

  /// The command whose preview tells whether these payers cover the total (null while it cannot be asked).
  ExpenseCommand? _checkCommand(ExpenseFormState f, Map<String, int>? minors) {
    final total = f.totalMinor;
    if (total == null || minors == null || minors.isEmpty) return null;
    return buildPayersCheck(title: f.title, date: f.date, totalMinor: total, memberIds: _controller.memberIds, payers: minors);
  }

  Future<void> _splitEqually(List<String> payerIds) async {
    setState(() {
      _splitting = true;
      _splitFailed = false;
    });
    try {
      final texts = await _controller.equalAmongPayers(payerIds);
      if (!mounted) return;
      setState(() {
        _texts = {..._texts, ...texts};
        _splitting = false;
      });
    } on ApiFailure {
      if (!mounted) return;
      setState(() {
        _splitting = false;
        _splitFailed = true;
      });
    }
  }

  void _confirm(List<String> orderedPayerIds) {
    if (orderedPayerIds.length == 1) {
      _controller.applyPayers(mode: PayerMode.single, singlePayerId: orderedPayerIds.first);
    } else {
      _controller.applyPayers(mode: PayerMode.multiple, texts: {for (final id in orderedPayerIds) id: _texts[id] ?? ''});
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final f = ref.watch(expenseFormControllerProvider(widget.formKey)).form!;
    final members = _controller.members;
    final total = f.totalMinor;
    final minors = _typedMinors();
    final sum = _texts.values.fold<int>(0, (s, t) => s + (Money.parse(t) ?? 0));
    final remaining = total == null ? null : total - sum;

    // Ask the server whether these payers cover the total (debounced, stale answers ignored).
    final command = _checkCommand(f, minors);
    final wantedKey = command == null ? null : commandKey(command);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(expensePreviewControllerProvider(_previewKey).notifier).request(command);
    });
    final check = ref.watch(expensePreviewControllerProvider(_previewKey));
    final answered = check.isCurrentFor(wantedKey);
    // The server only contradicts the user when the typed amounts say they add up (otherwise "left to assign" is the news).
    final serverSaysMismatch = remaining == 0 && answered && !check.preview!.payersTotalMatches;
    final serverConfirms = answered && check.preview!.payersTotalMatches;

    final ordered = [for (final m in members) if (_texts.containsKey(m.id)) m.id];
    final canConfirm = total != null && minors != null && minors.isNotEmpty && remaining == 0 && !serverSaysMismatch && minors.values.every((v) => v > 0);

    Widget banner;
    if (total == null) {
      banner = _Banner(icon: Icons.info_outline, text: l10n.expensePayersNeedTotal, tone: _BannerTone.warning);
    } else if (serverSaysMismatch) {
      banner = _Banner(icon: Icons.error_outline, text: l10n.expensePayersServerMismatch, tone: _BannerTone.error);
    } else if (remaining == 0 && _texts.isNotEmpty) {
      banner = serverConfirms
          ? _Banner(icon: Icons.check_circle_outline, text: l10n.expensePayersMatched, tone: _BannerTone.success)
          : _Banner(icon: Icons.hourglass_empty, text: l10n.expensePayersChecking, tone: _BannerTone.neutral);
    } else if (remaining != null && remaining < 0) {
      banner = _Banner(icon: Icons.warning_amber_rounded, text: l10n.expensePayersOver(moneyDisplay(l10n, -remaining)), tone: _BannerTone.warning);
    } else {
      banner = _Banner(icon: Icons.warning_amber_rounded, text: l10n.expensePayersRemaining(moneyDisplay(l10n, remaining ?? 0)), tone: _BannerTone.warning);
    }

    return AppBottomSheet(
      title: l10n.expensePayersSheetTitle,
      subtitle: l10n.expensePayersSheetSubtitle,
      action: AppButton(
        label: l10n.expensePayersConfirm(total == null ? '' : moneyDisplay(l10n, total)),
        icon: Icons.check_circle_outline,
        onPressed: canConfirm ? () => _confirm(ordered) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (total != null)
            AppCard(
              color: QesmaColors.tint,
              child: Row(
                children: [
                  Expanded(child: Text(l10n.expensePayersTotalLabel, style: theme.textTheme.bodyMedium)),
                  MoneyText(total, size: MoneySize.medium),
                ],
              ),
            ),
          const SizedBox(height: QesmaSpacing.sm),
          banner,
          const SizedBox(height: QesmaSpacing.sm),
          Wrap(
            spacing: QesmaSpacing.sm,
            runSpacing: QesmaSpacing.xs,
            children: [
              AppButton(
                label: l10n.expensePayersSplitEqually,
                icon: Icons.balance,
                variant: AppButtonVariant.secondary,
                expand: false,
                loading: _splitting,
                onPressed: total == null || ordered.isEmpty || _splitting ? null : () => _splitEqually(ordered),
              ),
              AppButton(
                label: l10n.expensePayersClear,
                icon: Icons.refresh,
                variant: AppButtonVariant.text,
                expand: false,
                onPressed: _texts.isEmpty ? null : () => setState(() => _texts = {for (final id in _texts.keys) id: ''}),
              ),
            ],
          ),
          if (_splitFailed)
            Padding(
              padding: const EdgeInsets.only(top: QesmaSpacing.sm),
              child: Semantics(liveRegion: true, child: Text(l10n.expensePayersFailed, style: theme.textTheme.bodySmall?.copyWith(color: QesmaColors.error))),
            ),
          const SizedBox(height: QesmaSpacing.md),
          for (final member in members)
            Padding(
              padding: const EdgeInsets.only(bottom: QesmaSpacing.sm),
              child: _PayerRow(
                member: member,
                checked: _texts.containsKey(member.id),
                text: _texts[member.id] ?? '',
                onToggle: () => setState(() {
                  _texts = {..._texts};
                  if (_texts.containsKey(member.id)) {
                    _texts.remove(member.id);
                  } else {
                    _texts[member.id] = '';
                  }
                }),
                onChanged: (text) => setState(() => _texts = {..._texts, member.id: text}),
              ),
            ),
          const SizedBox(height: QesmaSpacing.sm),
          Row(
            children: [
              Expanded(child: Text(l10n.expensePayersEntered, style: theme.textTheme.bodyMedium?.copyWith(color: QesmaColors.textSecondary))),
              MoneyText(sum, size: MoneySize.medium),
            ],
          ),
        ],
      ),
    );
  }
}

enum _BannerTone { neutral, success, warning, error }

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text, required this.tone});

  final IconData icon;
  final String text;
  final _BannerTone tone;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (tone) {
      _BannerTone.success => (QesmaColors.success, QesmaColors.successContainer),
      _BannerTone.warning => (QesmaColors.warning, QesmaColors.warningContainer),
      _BannerTone.error => (QesmaColors.error, QesmaColors.errorContainer),
      _BannerTone.neutral => (QesmaColors.textSecondary, QesmaColors.tint),
    };
    // Icon and words carry the meaning; colour only reinforces it. Announced when it changes.
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(QesmaRadii.control)),
        child: Padding(
          padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
          child: Row(
            children: [
              ExcludeSemantics(child: Icon(icon, color: fg, size: 20)),
              const SizedBox(width: QesmaSpacing.sm),
              Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: fg))),
            ],
          ),
        ),
      ),
    );
  }
}

class _PayerRow extends StatelessWidget {
  const _PayerRow({required this.member, required this.checked, required this.text, required this.onToggle, required this.onChanged});

  final MemberDto member;
  final bool checked;
  final String text;
  final VoidCallback onToggle;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    // At large text sizes the amount drops under the name instead of squeezing it.
    final stacked = MediaQuery.textScalerOf(context).scale(1) > 1.3;
    final typed = Money.parse(text);
    final spoken = checked
        ? l10n.expensePayersRowSpoken(member.displayName, text.isEmpty ? '' : (typed == null ? text : moneySpoken(l10n, typed)))
        : l10n.expensePayersRowUnchecked(member.displayName);
    final box = AmountBox(
      text: text,
      enabled: checked,
      semanticLabel: l10n.expensePayersAmountLabel(member.displayName),
      onChanged: onChanged,
      width: stacked ? 200 : 120,
    );
    final top = Row(
      children: [
        Semantics(
          label: spoken,
          checked: checked,
          child: SizedBox(width: kMinTouch - 8, height: kMinTouch - 8, child: Checkbox(value: checked, onChanged: (_) => onToggle())),
        ),
        MemberAvatar(memberId: member.id, name: member.displayName, size: 36),
        const SizedBox(width: QesmaSpacing.sm + 4),
        Expanded(
          child: Wrap(
            spacing: QesmaSpacing.sm,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(member.displayName, style: theme.textTheme.titleMedium),
              if (member.isYou) AppTag(label: l10n.membersYouTag, tone: AppTagTone.primary),
            ],
          ),
        ),
        if (!stacked) ...[const SizedBox(width: QesmaSpacing.sm), box],
      ],
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: checked ? QesmaColors.tint : QesmaColors.card,
        borderRadius: BorderRadius.circular(QesmaRadii.control),
        border: Border.all(color: QesmaColors.hairline),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kMinTouch),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: QesmaSpacing.sm + 4, vertical: QesmaSpacing.sm),
          child: stacked
              ? Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [top, const SizedBox(height: QesmaSpacing.sm), Align(alignment: AlignmentDirectional.centerEnd, child: box)])
              : top,
        ),
      ),
    );
  }
}
