import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/format/clock.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../application/invite_code.dart';
import '../application/invite_sheet_controller.dart';

/// "7 days" with the Arabic forms (one, two, 3-10, 11+) and Western digits. Plural logic is here, not in the ARB,
/// because ARB number placeholders would be formatted with local digits.
String inviteDurationDays(AppLocalizations l10n, int n) =>
    n == 1 ? l10n.inviteDayOne : n == 2 ? l10n.inviteDayTwo : n <= 10 ? l10n.inviteDaysFew('$n') : l10n.inviteDaysMany('$n');

String inviteDurationHours(AppLocalizations l10n, int n) =>
    n == 1 ? l10n.inviteHourOne : n == 2 ? l10n.inviteHourTwo : n <= 10 ? l10n.inviteHoursFew('$n') : l10n.inviteHoursMany('$n');

/// "Expires in 6 days", computed from the server's `expiresAt` and the device clock.
String inviteExpiryText(AppLocalizations l10n, DateTime? expiresAt, DateTime now) => switch (inviteRemaining(expiresAt, now)) {
      RemainingDays(:final days) => l10n.inviteExpiresIn(inviteDurationDays(l10n, days)),
      RemainingHours(:final hours) => l10n.inviteExpiresIn(inviteDurationHours(l10n, hours)),
      RemainingSoon() => l10n.inviteExpiresSoon,
      RemainingNone() => l10n.inviteExpiredTitle,
    };

/// The text of the system share sheet: group, link and the code to type.
String inviteShareMessage(AppLocalizations l10n, String groupName, InviteView invite) =>
    l10n.inviteShareText(groupName, invite.link ?? '', formatInviteCode(invite.code));

/// Opens the invite sheet (P12-01) for the Owner or an Admin. The caller checks `Permissions.canManageInvites`.
Future<void> showInviteSheet(BuildContext context, {required String gid, required String groupName}) {
  final l10n = AppLocalizations.of(context);
  return showAppBottomSheet<void>(
    context,
    title: l10n.inviteSheetTitle,
    subtitle: l10n.inviteSheetSubtitle(groupName),
    child: InviteSheetBody(gid: gid, groupName: groupName),
  );
}

class InviteSheetBody extends ConsumerWidget {
  const InviteSheetBody({super.key, required this.gid, required this.groupName});

  final String gid;
  final String groupName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(inviteSheetControllerProvider(gid));
    final controller = ref.read(inviteSheetControllerProvider(gid).notifier);
    final now = ref.watch(clockProvider)();

    Widget content;
    if (state.loading && state.invites.isEmpty) {
      content = const Padding(padding: EdgeInsets.all(QesmaSpacing.lg), child: Center(child: CircularProgressIndicator()));
    } else if (state.failure != null && state.invites.isEmpty) {
      final failure = state.failure!;
      content = failure is ApiNoConnection || failure is ApiTimeout
          ? NoInternetState(onRetry: controller.load)
          : ErrorState(onRetry: controller.load, message: errorCopyFor(l10n, failure).message, requestId: failure.problem?.requestId);
    } else {
      final newest = state.invites.isEmpty ? null : state.invites.first;
      final others = state.invites.length > 1 ? state.invites.skip(1).toList() : const <InviteView>[];
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.inviteSheetIntro, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
          const SizedBox(height: QesmaSpacing.md),
          if (newest == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: QesmaSpacing.sm),
              child: Text(l10n.inviteNoActive, style: theme.textTheme.bodyLarge),
            )
          else
            _CurrentInvite(gid: gid, groupName: groupName, invite: newest, now: now),
          if (others.isNotEmpty) ...[
            const SizedBox(height: QesmaSpacing.lg),
            Semantics(header: true, child: Text(l10n.inviteOtherActiveTitle, style: theme.textTheme.titleMedium)),
            const SizedBox(height: QesmaSpacing.sm),
            for (final invite in others) ...[
              _OtherInviteRow(gid: gid, invite: invite, now: now),
              const SizedBox(height: QesmaSpacing.sm),
            ],
          ],
          const SizedBox(height: QesmaSpacing.lg),
          _NewInviteSettings(gid: gid),
        ],
      );
    }
    return content;
  }
}

class _CurrentInvite extends ConsumerWidget {
  const _CurrentInvite({required this.gid, required this.groupName, required this.invite, required this.now});

  final String gid;
  final String groupName;
  final InviteView invite;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = ref.watch(inviteSheetControllerProvider(gid).select((s) => s.busy));
    final code = formatInviteCode(invite.code);

    Future<void> copy(String text, String done) async {
      await ref.read(clipboardWriterProvider)(text);
      if (context.mounted) showAppSnackBar(context, done);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          color: context.colors.tint,
          child: Column(
            children: [
              Text(l10n.inviteCodeLabel, style: theme.textTheme.labelLarge?.copyWith(color: context.colors.onPrimaryContainer)),
              const SizedBox(height: QesmaSpacing.sm),
              // The code is one unit, always left to right, and read out character by character.
              Semantics(
                label: '${l10n.inviteCodeLabel}: ${code.split('').join(' ')}',
                excludeSemantics: true,
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(
                    code,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall?.copyWith(letterSpacing: 4, color: context.colors.primary, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: QesmaSpacing.md),
              AppButton(
                label: l10n.inviteCopyCode,
                icon: Icons.copy,
                variant: AppButtonVariant.secondary,
                onPressed: () => copy(invite.code ?? '', l10n.inviteCodeCopied),
              ),
            ],
          ),
        ),
        const SizedBox(height: QesmaSpacing.md),
        AppCard(
          padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.md, QesmaSpacing.xs, QesmaSpacing.xs, QesmaSpacing.xs),
          child: Row(
            children: [
              Expanded(
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: SelectableText(invite.link ?? '', style: theme.textTheme.bodyMedium, maxLines: 2),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                tooltip: l10n.inviteCopyLink,
                onPressed: () => copy(invite.link ?? '', l10n.inviteLinkCopied),
              ),
            ],
          ),
        ),
        const SizedBox(height: QesmaSpacing.md),
        AppButton(
          label: l10n.inviteShareLink,
          icon: Icons.share,
          onPressed: () => ref.read(inviteSharerProvider).share(inviteShareMessage(l10n, groupName, invite)),
        ),
        const SizedBox(height: QesmaSpacing.md),
        _ExpiryRow(invite: invite, now: now),
        const SizedBox(height: QesmaSpacing.sm),
        AppButton(
          label: l10n.inviteRevoke,
          variant: AppButtonVariant.text,
          loading: ref.watch(inviteSheetControllerProvider(gid).select((s) => s.revokingId == invite.id)),
          onPressed: busy ? null : () => revokeInviteWithConfirm(context, ref, gid, invite),
        ),
      ],
    );
  }
}

class _ExpiryRow extends StatelessWidget {
  const _ExpiryRow({required this.invite, required this.now});

  final InviteView invite;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            ExcludeSemantics(child: Icon(Icons.schedule, size: 20, color: context.colors.textSecondary)),
            const SizedBox(width: QesmaSpacing.sm),
            Expanded(child: Text(inviteExpiryText(l10n, invite.expiresAt, now), style: theme.textTheme.bodyMedium)),
          ],
        ),
        if (invite.requiresApproval == true)
          Padding(padding: const EdgeInsets.only(top: QesmaSpacing.xs), child: AppTag(label: l10n.inviteApprovalTag, tone: AppTagTone.info)),
      ],
    );
  }
}

class _OtherInviteRow extends ConsumerWidget {
  const _OtherInviteRow({required this.gid, required this.invite, required this.now});

  final String gid;
  final InviteView invite;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final busy = ref.watch(inviteSheetControllerProvider(gid).select((s) => s.busy));
    final max = invite.maxUses;
    final uses = max == null ? l10n.inviteUsesCount('${invite.useCount ?? 0}') : l10n.inviteUsesProgress('${invite.useCount ?? 0}', '$max');
    return AppCard(
      padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.md, QesmaSpacing.sm, QesmaSpacing.xs, QesmaSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(formatInviteCode(invite.code), style: theme.textTheme.titleMedium?.copyWith(letterSpacing: 2)),
                ),
                Text(
                  '${inviteExpiryText(l10n, invite.expiresAt, now)} · $uses',
                  style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                ),
                if (invite.requiresApproval == true)
                  Padding(padding: const EdgeInsets.only(top: QesmaSpacing.xs), child: AppTag(label: l10n.inviteApprovalTag, tone: AppTagTone.info)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.link_off),
            tooltip: l10n.inviteRevoke,
            onPressed: busy ? null : () => revokeInviteWithConfirm(context, ref, gid, invite),
          ),
        ],
      ),
    );
  }
}

/// Asks first, then revokes. Cancelling the question changes nothing.
Future<void> revokeInviteWithConfirm(BuildContext context, WidgetRef ref, String gid, InviteView invite) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showConfirmDialog(
    context,
    title: l10n.inviteRevokeConfirmTitle,
    message: l10n.inviteRevokeConfirmBody,
    confirmLabel: l10n.inviteRevoke,
    cancelLabel: l10n.inviteKeep,
    destructive: true,
  );
  final id = invite.id;
  if (!confirmed || id == null || !context.mounted) return;
  final failure = await ref.read(inviteSheetControllerProvider(gid).notifier).revoke(id);
  if (!context.mounted) return;
  showAppSnackBar(context, failure == null ? l10n.inviteRevoked : errorCopyFor(l10n, failure).message);
}

class _NewInviteSettings extends ConsumerWidget {
  const _NewInviteSettings({required this.gid});

  final String gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(inviteSheetControllerProvider(gid));
    final controller = ref.read(inviteSheetControllerProvider(gid).notifier);
    return AppCard(
      color: context.colors.surfaceLow,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(header: true, child: Text(l10n.inviteCreateNew, style: theme.textTheme.titleMedium)),
          const SizedBox(height: QesmaSpacing.md),
          Text(l10n.inviteExpiryChoiceLabel, style: theme.textTheme.labelLarge),
          const SizedBox(height: QesmaSpacing.sm),
          Wrap(
            spacing: QesmaSpacing.sm,
            runSpacing: QesmaSpacing.sm,
            children: [
              for (final days in inviteExpiryChoices)
                AppChoiceChip(
                  label: inviteDurationDays(l10n, days),
                  selected: state.expiresInDays == days,
                  onSelected: state.busy ? null : (_) => controller.setExpiry(days),
                ),
            ],
          ),
          const SizedBox(height: QesmaSpacing.md),
          MergeSemantics(
            child: Row(
              children: [
                ExcludeSemantics(child: Icon(Icons.verified_user_outlined, color: context.colors.primary)),
                const SizedBox(width: QesmaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.inviteApprovalTitle, style: theme.textTheme.titleSmall),
                      Text(l10n.inviteApprovalBody, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                    ],
                  ),
                ),
                Switch(value: state.requiresApproval, onChanged: state.busy ? null : controller.setRequiresApproval),
              ],
            ),
          ),
          const SizedBox(height: QesmaSpacing.md),
          AppButton(
            label: l10n.inviteCreate,
            icon: Icons.person_add,
            variant: AppButtonVariant.secondary,
            loading: state.creating,
            onPressed: state.busy
                ? null
                : () async {
                    final failure = await controller.create();
                    if (!context.mounted) return;
                    showAppSnackBar(context, failure == null ? l10n.inviteCreated : errorCopyFor(l10n, failure).message);
                  },
          ),
        ],
      ),
    );
  }
}
