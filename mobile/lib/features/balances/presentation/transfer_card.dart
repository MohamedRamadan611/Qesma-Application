import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/balance_colors.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/qesma_text.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';

/// Whose transfer this is for the signed-in person.
enum TransferRole {
  /// I pay: the card shows the receiver's payment details, the fixed "the app does not move money" note and "I paid".
  payer,

  /// I am owed: "I received it" records money that arrived outside the app (the only way to settle with a member who has no account).
  receiver,

  /// Somebody else's: only an Owner/Admin gets a button ("record on behalf").
  other,
}

/// One of the server's suggested transfers. Every value is the server's and nothing is derived: the amount is
/// [TransferView.amountMinor] (confirmed payments only), a payment waiting for confirmation is [TransferView.pendingMinor]
/// shown next to it and never subtracted from it, and the receiver's handles come in [TransferView.receiverHandles].
class TransferCard extends StatelessWidget {
  const TransferCard({
    super.key,
    required this.transfer,
    required this.nameOf,
    required this.role,
    required this.onRecord,
  });

  final TransferView transfer;
  final String Function(String memberId) nameOf;
  final TransferRole role;

  /// Opens the payment sheet for exactly this transfer; null = no button (a plain member on somebody else's transfer).
  final VoidCallback? onRecord;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.balanceColors;
    final from = nameOf(transfer.fromMemberId);
    final to = nameOf(transfer.toMemberId);
    final amount = transfer.amountMinor;

    Widget person(String id, String name, String roleText, Color roleColor) => Expanded(
          child: Column(
            children: [
              MemberAvatar(memberId: id, name: name, size: 44),
              const SizedBox(height: QesmaSpacing.xs),
              Text(name, textAlign: TextAlign.center, style: theme.textTheme.titleSmall),
              Text(roleText, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: roleColor, fontWeight: FontWeight.w600)),
            ],
          ),
        );

    final handles = transfer.receiverHandles;
    final instapay = _present(handles?.instapay);
    final wallet = _present(handles?.wallet);

    final (buttonLabel, buttonIcon, buttonSpoken, primary) = switch (role) {
      TransferRole.payer => (l10n.payButton, Icons.check, l10n.payButtonSpoken(moneySpoken(l10n, amount), to), true),
      TransferRole.receiver => (l10n.payReceived, Icons.download_done, l10n.balancesRecordPaymentSpoken(from, to, moneySpoken(l10n, amount)), false),
      TransferRole.other => (l10n.payOnBehalf, Icons.edit_note, l10n.balancesRecordPaymentSpoken(from, to, moneySpoken(l10n, amount)), false),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            container: true,
            label: l10n.balancesTransferSpoken(from, moneySpoken(l10n, amount), to),
            child: ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      person(transfer.fromMemberId, from, l10n.balancesPays, colors.owes),
                      Padding(
                        padding: const EdgeInsets.only(top: QesmaSpacing.sm + 4),
                        child: Icon(Icons.arrow_forward, color: context.colors.textHelper),
                      ),
                      person(transfer.toMemberId, to, l10n.balancesReceives, colors.owed),
                    ],
                  ),
                  const SizedBox(height: QesmaSpacing.md),
                  Center(child: Text(moneyDisplay(l10n, amount), style: QesmaText.amountMedium())),
                ],
              ),
            ),
          ),
          if (transfer.pendingMinor > 0 || transfer.hasDispute) ...[
            const SizedBox(height: QesmaSpacing.sm + 4),
            TransferPendingInfo(transfer: transfer),
          ],
          if (role == TransferRole.payer) ...[
            const SizedBox(height: QesmaSpacing.md),
            _Handles(to: to, instapay: instapay, wallet: wallet),
            const SizedBox(height: QesmaSpacing.sm + 4),
            _NoMoneyNote(),
          ],
          if (onRecord != null) ...[
            const SizedBox(height: QesmaSpacing.md),
            Semantics(
              button: true,
              excludeSemantics: true,
              label: buttonSpoken,
              onTap: onRecord,
              child: AppButton(
                label: buttonLabel,
                icon: buttonIcon,
                variant: primary ? AppButtonVariant.primary : AppButtonVariant.secondary,
                onPressed: onRecord,
              ),
            ),
          ],
          if (role == TransferRole.payer && (instapay != null || wallet != null)) ...[
            const SizedBox(height: QesmaSpacing.sm),
            AppButton(
              label: l10n.payCopyAll,
              icon: Icons.copy_all_outlined,
              variant: AppButtonVariant.secondary,
              onPressed: () => copyToClipboard(context, [?instapay, ?wallet].join('\n')),
            ),
          ],
        ],
      ),
    );
  }
}

String? _present(String? value) {
  final v = value?.trim();
  return v == null || v.isEmpty ? null : v;
}

/// Puts exactly [text] on the clipboard and says so.
Future<void> copyToClipboard(BuildContext context, String text) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) showAppSnackBar(context, AppLocalizations.of(context).payCopied);
}

/// "A payment is waiting for confirmation" and its explanation (both numbers are the server's), and the dispute flag.
/// Shown for any transfer with `pendingMinor > 0` or `hasDispute`; never adds or subtracts anything.
class TransferPendingInfo extends StatelessWidget {
  const TransferPendingInfo({super.key, required this.transfer});

  final TransferView transfer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = context.colors;
    Widget line(IconData icon, Color fg, Color bg, String title, {String? body}) => MergeSemantics(
          child: DecoratedBox(
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(QesmaRadii.control)),
            child: Padding(
              padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(child: Icon(icon, color: fg, size: 20)),
                  const SizedBox(width: QesmaSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleSmall?.copyWith(color: fg)),
                        if (body != null) Text(body, style: theme.textTheme.bodySmall?.copyWith(color: fg)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (transfer.pendingMinor > 0)
          line(
            Icons.hourglass_top,
            c.warning,
            c.warningContainer,
            l10n.pendingBadge,
            body: l10n.pendingExplain(moneyDisplay(l10n, transfer.pendingMinor), moneyDisplay(l10n, transfer.amountMinor)),
          ),
        if (transfer.pendingMinor > 0 && transfer.hasDispute) const SizedBox(height: QesmaSpacing.sm),
        if (transfer.hasDispute) line(Icons.warning_amber_rounded, c.error, c.errorContainer, l10n.disputeFlag),
      ],
    );
  }
}

/// The receiver's payment details with a copy button each (a row is left out when the receiver has not added it), or the
/// "no details yet" explanation. Text only: the app never starts a transfer.
class _Handles extends StatelessWidget {
  const _Handles({required this.to, required this.instapay, required this.wallet});

  final String to;
  final String? instapay;
  final String? wallet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (instapay == null && wallet == null) {
      return Text(l10n.payNoHandles(fsIsolate(to)), style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(header: true, child: Text(l10n.payHandlesTitle(fsIsolate(to)), style: theme.textTheme.titleSmall)),
        const SizedBox(height: QesmaSpacing.sm),
        if (instapay != null) _HandleRow(label: l10n.payInstapayLabel, value: instapay!),
        if (instapay != null && wallet != null) const SizedBox(height: QesmaSpacing.sm),
        if (wallet != null) _HandleRow(label: l10n.payWalletLabel, value: wallet!),
      ],
    );
  }
}

class _HandleRow extends StatelessWidget {
  const _HandleRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
              SelectableText(ltrIsolate(value), style: theme.textTheme.titleSmall),
            ],
          ),
        ),
        Semantics(
          button: true,
          excludeSemantics: true,
          label: l10n.payCopyOneSpoken(label),
          onTap: () => copyToClipboard(context, value),
          child: AppButton(
            label: l10n.payCopyOne,
            icon: Icons.copy,
            variant: AppButtonVariant.secondary,
            expand: false,
            onPressed: () => copyToClipboard(context, value),
          ),
        ),
      ],
    );
  }
}

/// "The app does not move money" - on every card where a person is told to transfer outside the app.
class _NoMoneyNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.infoContainer, borderRadius: BorderRadius.circular(QesmaRadii.control)),
        child: Padding(
          padding: const EdgeInsets.all(QesmaSpacing.sm + 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(Icons.info_outline, color: c.info, size: 20)),
              const SizedBox(width: QesmaSpacing.sm),
              Expanded(child: Text(l10n.payNoMoveNote, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: c.textPrimary))),
            ],
          ),
        ),
      ),
    );
  }
}
