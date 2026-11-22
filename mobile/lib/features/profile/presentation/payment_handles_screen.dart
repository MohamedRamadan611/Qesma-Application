import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/presentation/status_banner.dart';
import '../application/payment_handles_controller.dart';
import '../application/payment_handles_input.dart';

/// Payment details (P13-05): the caller's InstaPay address and mobile wallet number. They are shown to the members of the
/// caller's groups (never anywhere else) so a friend can pay them outside the app; the app itself moves no money.
///
/// The checks here only normalise and catch obvious typos: the server is authoritative. Emptying a field and saving removes
/// that handle (after a confirmation). Nothing typed here is ever logged or sent anywhere but `PUT /me/payment-handles`.
class PaymentHandlesScreen extends ConsumerStatefulWidget {
  const PaymentHandlesScreen({super.key});

  @override
  ConsumerState<PaymentHandlesScreen> createState() => _PaymentHandlesScreenState();
}

class _PaymentHandlesScreenState extends ConsumerState<PaymentHandlesScreen> {
  final _instapay = TextEditingController();
  final _wallet = TextEditingController();
  bool _filled = false;
  bool _touchedInstapay = false;
  bool _touchedWallet = false;

  @override
  void dispose() {
    _instapay.dispose();
    _wallet.dispose();
    super.dispose();
  }

  HandlesDraft get _draft => evaluateHandles(instapay: _instapay.text, wallet: _wallet.text);

  bool _dirty(StoredHandles stored) => _instapay.text.trim() != (stored.instapay ?? '') || _wallet.text.trim() != (stored.wallet ?? '');

  /// Puts what the server holds into the fields (first load and after every save).
  void _fill(StoredHandles stored) {
    _instapay.text = stored.instapay ?? '';
    _wallet.text = stored.wallet ?? '';
    _filled = true;
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _touchedInstapay = true;
      _touchedWallet = true;
    });
    final draft = _draft;
    if (!draft.isValid) return;
    final controller = ref.read(paymentHandlesControllerProvider.notifier);
    final stored = ref.read(paymentHandlesControllerProvider).stored;
    final removed = handlesRemoved(draft, stored);
    if (removed.isNotEmpty) {
      final what = [
        if (removed.contains(HandleIssue.instapay)) l10n.payInstapayLabel,
        if (removed.contains(HandleIssue.wallet)) l10n.payWalletLabel,
      ].join(' + ');
      final ok = await showConfirmDialog(
        context,
        title: l10n.handlesRemoveTitle(what),
        message: l10n.handlesRemoveBody,
        confirmLabel: l10n.handlesRemoveConfirm,
        destructive: true,
      );
      if (!ok || !mounted) return;
    }
    final saved = await controller.save(draft);
    if (!mounted) return;
    if (saved) {
      _fill(ref.read(paymentHandlesControllerProvider).stored);
      setState(() {
        _touchedInstapay = false;
        _touchedWallet = false;
      });
      showAppSnackBar(context, l10n.handlesSaved);
    }
  }

  Future<void> _askDiscard() async {
    final l10n = AppLocalizations.of(context);
    final discard = await showConfirmDialog(
      context,
      title: l10n.profileDiscardTitle,
      message: l10n.handlesDiscardBody,
      confirmLabel: l10n.profileDiscardConfirm,
      destructive: true,
    );
    if (discard && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(paymentHandlesControllerProvider);
    final controller = ref.read(paymentHandlesControllerProvider.notifier);
    if (state.status == HandlesStatus.ready && !_filled) _fill(state.stored);

    final Widget body;
    switch (state.status) {
      case HandlesStatus.loading:
        body = const SkeletonList();
      case HandlesStatus.failed:
        final failure = state.loadFailure!;
        body = failure is ApiNoConnection || failure is ApiTimeout
            ? NoInternetState(onRetry: controller.load)
            : ErrorState(onRetry: controller.load, message: errorCopyFor(l10n, failure).message, requestId: failure.problem?.requestId);
      case HandlesStatus.ready:
        body = _form(state);
    }
    final dirty = state.status == HandlesStatus.ready && _dirty(state.stored);
    return PopScope(
      canPop: !dirty || state.saving,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _askDiscard();
      },
      child: AppScaffold(title: l10n.profilePaymentDetails, body: body),
    );
  }

  Widget _form(PaymentHandlesState state) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final draft = _draft;
    final dirty = _dirty(state.stored);
    final bothEmpty = _instapay.text.trim().isEmpty && _wallet.text.trim().isEmpty;
    final instapayError = _touchedInstapay && draft.instapay.issue != null ? l10n.handlesInstapayInvalid : null;
    final walletError = _touchedWallet && draft.wallet.issue != null ? l10n.handlesWalletInvalid : null;
    final failure = state.saveFailure;
    final rejected = failure is ApiHttpFailure && failure.problem?.code == ApiErrorCode.validationError;

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, QesmaSpacing.xl),
      children: [
        // Always visible: who sees these details (PHASE2_SPEC section 7).
        MergeSemantics(
          child: AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ExcludeSemantics(child: Icon(Icons.lock_outline, color: context.colors.primary)),
                const SizedBox(width: QesmaSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.handlesPrivacy, style: theme.textTheme.titleSmall),
                      const SizedBox(height: QesmaSpacing.xs),
                      Text(l10n.handlesIntro, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: QesmaSpacing.lg),
        AppTextField(
          controller: _instapay,
          label: l10n.payInstapayLabel,
          hint: l10n.handlesInstapayHint,
          errorText: instapayError,
          enabled: !state.saving,
          keyboardType: TextInputType.url,
          textInputAction: TextInputAction.next,
          onChanged: (_) => setState(() {
            _touchedInstapay = true;
            ref.read(paymentHandlesControllerProvider.notifier).clearSaveFailure();
          }),
        ),
        const SizedBox(height: QesmaSpacing.md),
        AppTextField(
          controller: _wallet,
          label: l10n.payWalletLabel,
          hint: l10n.handlesWalletHint,
          errorText: walletError,
          enabled: !state.saving,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          // Arabic-Indic digits, spaces and dashes are all accepted: they are normalised on save.
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9٠-٩۰-۹+\s\-]'))],
          onChanged: (_) => setState(() {
            _touchedWallet = true;
            ref.read(paymentHandlesControllerProvider.notifier).clearSaveFailure();
          }),
          onSubmitted: (_) => _save(),
        ),
        if (bothEmpty) ...[
          const SizedBox(height: QesmaSpacing.md),
          Text(l10n.handlesEmpty, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
        ],
        if (failure != null) ...[
          const SizedBox(height: QesmaSpacing.md),
          StatusBanner(icon: Icons.error_outline, text: rejected ? l10n.handlesRejected : l10n.handlesSaveFailed, tone: BannerTone.error),
        ],
        const SizedBox(height: QesmaSpacing.lg),
        AppButton(label: l10n.handlesSave, icon: Icons.check, loading: state.saving, onPressed: dirty && !state.saving ? _save : null),
      ],
    );
  }
}
