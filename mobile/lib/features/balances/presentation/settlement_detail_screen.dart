import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/qesma_text.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../expenses/presentation/expense_ui.dart';
import '../../expenses/presentation/status_banner.dart';
import '../../groups/application/group_detail_controller.dart';
import '../../groups/application/group_permissions.dart';
import '../../groups/presentation/group_ui.dart';
import '../application/incoming_settlements.dart';
import '../application/settlement_actions_controller.dart';
import '../application/settlement_rules.dart';
import 'settlement_action_runner.dart';
import 'settlement_status_chip.dart';

/// `2026-10-24 11:30`, local time, Western digits, kept left-to-right inside Arabic text. Dates come from the server.
String settlementWhen(DateTime when) {
  final t = when.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return ltrIsolate('${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}');
}

/// One settlement of any status (P13-03): the amount, what each side says (from the status alone), the dates the server
/// stored, a guidance box while it is disputed, and the actions the signed-in person's role allows. Visible to both
/// parties and to Owner/Admin. The app does not arbitrate: resolution is manual (confirm or cancel).
class SettlementDetailScreen extends ConsumerWidget {
  const SettlementDetailScreen({super.key, required this.gid, required this.sid});

  final String gid;
  final String sid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(settlementDetailProvider((gid: gid, sid: sid)));
    final group = ref.watch(groupDetailControllerProvider(gid)).group;

    Widget body;
    if (detail.hasError && !detail.hasValue) {
      final failure = detail.error is ApiFailure ? detail.error! as ApiFailure : const ApiUnexpected();
      body = failure is ApiNoConnection || failure is ApiTimeout
          ? NoInternetState(onRetry: () => ref.invalidate(settlementDetailProvider((gid: gid, sid: sid))))
          : ErrorState(
              onRetry: () => ref.invalidate(settlementDetailProvider((gid: gid, sid: sid))),
              message: errorCopyFor(l10n, failure).message,
              requestId: failure.problem?.requestId,
            );
    } else if (!detail.hasValue || group == null) {
      body = const SkeletonList();
    } else if (detail.value == null) {
      body = Center(
        child: Padding(
          padding: const EdgeInsets.all(QesmaSpacing.lg),
          child: Semantics(liveRegion: true, child: Text(l10n.settlementGone, textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleMedium)),
        ),
      );
    } else {
      body = _Body(gid: gid, group: group, settlement: detail.value!);
    }
    return AppScaffold(title: l10n.settlementDetailTitle, showBack: true, onBack: () => goBackOr(context, Routes.group(gid)), body: body);
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.gid, required this.group, required this.settlement});

  final String gid;
  final GroupDto group;
  final SettlementView settlement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final c = context.colors;
    final status = settlement.statusKind;
    final nameOf = memberNameResolver(group, l10n);
    final from = nameOf(settlement.fromMemberId);
    final to = nameOf(settlement.toMemberId);
    final perms = ref.watch(groupPermissionsProvider(gid));
    final actions = settlementActionsFor(
      status: status,
      yourMemberId: group.yourMemberId,
      fromMemberId: settlement.fromMemberId,
      toMemberId: settlement.toMemberId,
      isAdminOrOwner: perms.canManageMembers,
    );
    final active = ref.watch(settlementActionsControllerProvider(gid));
    final busy = active.busy;

    Future<void> act(SettlementAction a) async {
      final outcome = await runSettlementAction(context, ref, gid: gid, settlement: settlement, action: a, nameOf: nameOf);
      // A cancelled payment stays readable here (it shows as cancelled after the re-read); nothing to close.
      if (outcome == SettlementActionOutcome.gone && context.mounted) goBackOr(context, Routes.group(gid));
    }

    final (bannerIcon, bannerTone, bannerText) = switch (status) {
      SettlementStatus.pending => (Icons.hourglass_top, BannerTone.warning, l10n.detailBannerPending),
      SettlementStatus.disputed => (Icons.warning_amber_rounded, BannerTone.error, l10n.detailBannerDisputed),
      SettlementStatus.confirmed => (Icons.check_circle, BannerTone.success, l10n.detailBannerConfirmed),
      SettlementStatus.cancelled || SettlementStatus.unknown => (Icons.cancel_outlined, BannerTone.neutral, l10n.detailBannerCancelled),
    };

    final payerSays = status == SettlementStatus.cancelled ? l10n.stmtPayerCancelled : l10n.stmtPayerPaid;
    final receiverSays = switch (status) {
      SettlementStatus.pending => l10n.stmtReceiverWaiting,
      SettlementStatus.disputed => l10n.stmtReceiverNotReceived,
      SettlementStatus.confirmed => settlement.recordedByAdmin ? l10n.stmtRecordedByAdmin : l10n.stmtReceiverConfirmed,
      SettlementStatus.cancelled || SettlementStatus.unknown => null,
    };

    final note = settlement.note;
    final dates = <String>[
      l10n.detailDateOn(dateText(settlement.settledOn)),
      l10n.detailDeclaredAt(settlementWhen(settlement.declaredAt)),
      if (settlement.disputedAt != null) l10n.detailDisputedAt(settlementWhen(settlement.disputedAt!)),
      if (settlement.confirmedAt != null) l10n.detailConfirmedAt(settlementWhen(settlement.confirmedAt!)),
      if (settlement.cancelledAt != null) l10n.detailCancelledAt(settlementWhen(settlement.cancelledAt!)),
    ];

    Widget party(String roleLabel, String id, String name, String? says, {required bool isPayer}) => MergeSemantics(
          child: Row(
            children: [
              MemberAvatar(memberId: id, name: name, size: 44),
              const SizedBox(width: QesmaSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(roleLabel, style: theme.textTheme.bodySmall?.copyWith(color: c.textHelper)),
                    Text(name, style: theme.textTheme.titleMedium),
                    if (says != null) Text(says, style: theme.textTheme.bodyMedium?.copyWith(color: isPayer ? c.textSecondary : _receiverColor(c, status))),
                  ],
                ),
              ),
            ],
          ),
        );

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, QesmaSpacing.sm, QesmaSpacing.margin, QesmaSpacing.xl),
      children: [
        StatusBanner(icon: bannerIcon, text: bannerText, tone: bannerTone),
        if (status == SettlementStatus.disputed)
          Padding(
            padding: const EdgeInsets.only(top: QesmaSpacing.xs),
            child: Text(l10n.detailBannerDisputedBody, style: theme.textTheme.bodySmall?.copyWith(color: c.textSecondary)),
          ),
        const SizedBox(height: QesmaSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                container: true,
                label: '${l10n.settlementDetailAmount}: ${moneySpoken(l10n, settlement.amountMinor)}',
                child: ExcludeSemantics(
                  child: Column(
                    children: [
                      Text(l10n.settlementDetailAmount, style: theme.textTheme.bodySmall?.copyWith(color: c.textHelper)),
                      const SizedBox(height: QesmaSpacing.xs),
                      Text(moneyDisplay(l10n, settlement.amountMinor), style: QesmaText.amountLarge()),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: QesmaSpacing.sm),
              Center(child: SettlementStatusChip(status)),
              if (status.isOpen) ...[
                const SizedBox(height: QesmaSpacing.sm),
                Text(l10n.detailNotCounted, textAlign: TextAlign.center, style: theme.textTheme.bodySmall?.copyWith(color: c.textSecondary)),
              ],
              const Divider(height: QesmaSpacing.lg),
              party(l10n.settlementPayerRole, settlement.fromMemberId, from, payerSays, isPayer: true),
              const SizedBox(height: QesmaSpacing.md),
              party(l10n.settlementReceiverRole, settlement.toMemberId, to, receiverSays, isPayer: false),
            ],
          ),
        ),
        const SizedBox(height: QesmaSpacing.md),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final d in dates) Padding(padding: const EdgeInsets.symmetric(vertical: 2), child: Text(d, style: theme.textTheme.bodyMedium)),
              if (settlement.recordedByAdmin && status != SettlementStatus.confirmed)
                Padding(padding: const EdgeInsets.only(top: 2), child: Text(l10n.settlementByAdmin, style: theme.textTheme.bodyMedium?.copyWith(color: c.textSecondary))),
              if (note != null && note.isNotEmpty) Padding(padding: const EdgeInsets.only(top: QesmaSpacing.xs), child: Text(note, style: theme.textTheme.bodyMedium)),
            ],
          ),
        ),
        if (status == SettlementStatus.disputed) ...[
          const SizedBox(height: QesmaSpacing.md),
          const _Guidance(),
        ],
        if (actions.isNotEmpty) ...[
          const SizedBox(height: QesmaSpacing.lg),
          if (actions.contains(SettlementAction.confirm))
            AppButton(
              label: l10n.detailConfirm,
              icon: Icons.check_circle_outline,
              loading: active.busyId == settlement.id && active.busyAction == SettlementAction.confirm,
              onPressed: busy ? null : () => act(SettlementAction.confirm),
            ),
          if (actions.contains(SettlementAction.dispute)) ...[
            const SizedBox(height: QesmaSpacing.sm),
            AppButton(
              label: l10n.receiverDispute,
              icon: Icons.close,
              variant: AppButtonVariant.secondary,
              loading: active.busyId == settlement.id && active.busyAction == SettlementAction.dispute,
              onPressed: busy ? null : () => act(SettlementAction.dispute),
            ),
          ],
          if (actions.contains(SettlementAction.cancel)) ...[
            const SizedBox(height: QesmaSpacing.sm),
            AppButton(
              label: l10n.cancelDialogConfirm,
              icon: Icons.block,
              variant: AppButtonVariant.destructive,
              loading: active.busyId == settlement.id && active.busyAction == SettlementAction.cancel,
              onPressed: busy ? null : () => act(SettlementAction.cancel),
            ),
          ],
        ],
      ],
    );
  }

  Color _receiverColor(QesmaPalette c, SettlementStatus status) => switch (status) {
        SettlementStatus.disputed => c.error,
        SettlementStatus.confirmed => c.success,
        _ => c.textSecondary,
      };
}

/// "Resolve it in a friendly way": both sides and the admins sort it out; the app does not decide and does not move money.
class _Guidance extends StatelessWidget {
  const _Guidance();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final c = context.colors;
    final theme = Theme.of(context);
    return MergeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(color: c.infoContainer, borderRadius: BorderRadius.circular(QesmaRadii.card)),
        child: Padding(
          padding: const EdgeInsets.all(QesmaSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: Icon(Icons.lightbulb_outline, color: c.info)),
              const SizedBox(width: QesmaSpacing.sm + 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.guidanceTitle, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(l10n.guidanceBody, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
