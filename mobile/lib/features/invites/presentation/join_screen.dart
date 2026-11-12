import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../groups/application/groups_list_controller.dart';
import '../../groups/data/group_type.dart';
import '../../groups/presentation/group_ui.dart';
import '../application/join_controller.dart';

/// Join a group from an invite (P12-02). Shows what the server says about the invite and nothing about the group's
/// money: the preview carries no balances, and a person who has not joined must not see any.
class JoinScreen extends ConsumerWidget {
  const JoinScreen({super.key, required this.code});

  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(joinControllerProvider(code));
    final controller = ref.read(joinControllerProvider(code).notifier);

    ref.listen(joinControllerProvider(code).select((s) => s.joinedGroupId), (_, id) {
      if (id == null) return;
      context.go(id.isEmpty ? Routes.home : Routes.group(id));
    });

    Future<void> openGroup() async {
      // The preview names the group but has no id: find it in the refreshed list, else show the list.
      await ref.read(groupsListControllerProvider.notifier).refresh();
      if (!context.mounted) return;
      final name = state.groupName;
      final matches = ref.read(groupsListControllerProvider).items.where((g) => g.name == name).toList();
      context.go(matches.length == 1 ? Routes.group(matches.first.id) : Routes.home);
    }

    final Widget body = switch (state.phase) {
      JoinPhase.loading => const SkeletonList(itemCount: 3),
      JoinPhase.ready => _JoinForm(code: code, state: state),
      JoinPhase.expired => _StateView(
          icon: Icons.timer_off_outlined,
          tone: _Tone.warning,
          title: l10n.inviteExpiredTitle,
          message: l10n.inviteExpiredBody,
          actions: [AppButton(label: l10n.inviteBackHome, onPressed: () => context.go(Routes.home))],
        ),
      JoinPhase.revoked => _StateView(
          icon: Icons.link_off,
          tone: _Tone.error,
          title: l10n.inviteRevokedTitle,
          message: l10n.inviteRevokedBody,
          actions: [AppButton(label: l10n.inviteBackHome, onPressed: () => context.go(Routes.home))],
        ),
      JoinPhase.notFound => _StateView(
          icon: Icons.search_off,
          tone: _Tone.neutral,
          title: l10n.inviteNotFoundTitle,
          message: l10n.inviteNotFoundBody,
          actions: [
            AppButton(label: l10n.inviteEnterCodeTitle, onPressed: () => context.go(Routes.join)),
            AppButton(label: l10n.inviteBackHome, variant: AppButtonVariant.text, onPressed: () => context.go(Routes.home)),
          ],
        ),
      JoinPhase.alreadyMember => _StateView(
          icon: Icons.check_circle_outline,
          tone: _Tone.success,
          title: l10n.inviteAlreadyMemberTitle,
          message: l10n.inviteAlreadyMemberBody,
          actions: [AppButton(label: l10n.inviteOpenGroup, onPressed: openGroup)],
        ),
      JoinPhase.awaitingApproval => _StateView(
          icon: Icons.hourglass_top,
          tone: _Tone.info,
          title: l10n.inviteWaitingTitle,
          message: l10n.inviteWaitingBody(state.groupName ?? ''),
          actions: [
            AppButton(
              label: l10n.inviteRefreshStatus,
              icon: Icons.refresh,
              loading: state.refreshing,
              onPressed: () async {
                await controller.refreshStatus();
                if (!context.mounted) return;
                if (ref.read(joinControllerProvider(code)).phase == JoinPhase.awaitingApproval) {
                  showAppSnackBar(context, l10n.inviteStillWaiting);
                }
              },
            ),
            AppButton(label: l10n.inviteBackHome, variant: AppButtonVariant.text, onPressed: () => context.go(Routes.home)),
          ],
        ),
      JoinPhase.rateLimited || JoinPhase.failed => state.failure is ApiNoConnection || state.failure is ApiTimeout
          ? NoInternetState(onRetry: controller.load)
          : ErrorState(
              onRetry: controller.load,
              message: state.failure == null ? null : errorCopyFor(l10n, state.failure!).message,
              requestId: state.failure?.problem?.requestId,
            ),
    };

    return AppScaffold(
      title: l10n.inviteJoinTitle,
      showBack: true,
      onBack: () => goBackOr(context, Routes.home),
      body: body,
    );
  }
}

class _JoinForm extends ConsumerStatefulWidget {
  const _JoinForm({required this.code, required this.state});

  final String code;
  final JoinState state;

  @override
  ConsumerState<_JoinForm> createState() => _JoinFormState();
}

class _JoinFormState extends ConsumerState<_JoinForm> {
  late final TextEditingController _name = TextEditingController(text: widget.state.newName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(joinControllerProvider(widget.code));
    final controller = ref.read(joinControllerProvider(widget.code).notifier);
    final preview = state.preview;
    final unclaimed = state.unclaimed;
    final type = GroupType.fromWire(preview?.groupType ?? '');
    final failure = state.failure;
    final nameError = state.duplicateName ? l10n.errorDuplicateMemberName(state.newName.trim()) : null;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(QesmaSpacing.margin),
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: QesmaSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Semantics(header: true, child: Text(preview?.groupName ?? '', style: theme.textTheme.headlineMedium)),
                        AppTag(label: type.label(l10n), tone: AppTagTone.info),
                      ],
                    ),
                    const SizedBox(height: QesmaSpacing.sm),
                    Row(
                      children: [
                        ExcludeSemantics(child: Icon(Icons.person_add, size: 18, color: context.colors.textSecondary)),
                        const SizedBox(width: QesmaSpacing.sm),
                        Expanded(child: Text(l10n.inviteInvitedBy(preview?.inviterName ?? ''), style: theme.textTheme.bodyMedium)),
                      ],
                    ),
                    const SizedBox(height: QesmaSpacing.xs),
                    Row(
                      children: [
                        ExcludeSemantics(child: Icon(Icons.group_outlined, size: 18, color: context.colors.textSecondary)),
                        const SizedBox(width: QesmaSpacing.sm),
                        Text(memberCountText(l10n, preview?.memberCount ?? 0), style: theme.textTheme.bodyMedium),
                      ],
                    ),
                    if (preview?.requiresApproval == true) ...[
                      const SizedBox(height: QesmaSpacing.sm),
                      AppTag(label: l10n.inviteNeedsApprovalNote, tone: AppTagTone.warning),
                    ],
                  ],
                ),
              ),
              if (unclaimed.isNotEmpty) ...[
                const SizedBox(height: QesmaSpacing.lg),
                Semantics(header: true, child: Text(l10n.inviteWhoAreYou, style: theme.textTheme.titleLarge)),
                const SizedBox(height: QesmaSpacing.xs),
                Text(l10n.inviteWhoBody, style: theme.textTheme.bodyMedium?.copyWith(color: context.colors.textSecondary)),
                const SizedBox(height: QesmaSpacing.md),
                if (state.claimedNotice) ...[ErrorBanner(l10n.inviteClaimedNotice), const SizedBox(height: QesmaSpacing.md)],
                for (final member in unclaimed) ...[
                  _ChoiceCard(
                    selected: state.claimMemberId == member.id,
                    onTap: state.joining || member.id == null ? null : () => controller.selectMember(member.id!),
                    leading: MemberAvatar(memberId: member.id ?? '', name: member.name ?? '', size: 44),
                    title: member.name ?? '',
                  ),
                  const SizedBox(height: QesmaSpacing.sm),
                ],
              ] else
                const SizedBox(height: QesmaSpacing.lg),
              _ChoiceCard(
                selected: state.joinAsNew,
                onTap: state.joining ? null : controller.selectNew,
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: context.colors.primary,
                  child: Icon(Icons.person_add, color: context.colors.onPrimary, size: 22),
                ),
                title: l10n.inviteNewMember,
                subtitle: l10n.inviteNewMemberBody,
                child: state.joinAsNew
                    ? Padding(
                        padding: const EdgeInsets.only(top: QesmaSpacing.md),
                        child: AppTextField(
                          controller: _name,
                          label: l10n.inviteNameLabel,
                          maxLength: joinNameMax,
                          errorText: nameError,
                          enabled: !state.joining,
                          textInputAction: TextInputAction.done,
                          onChanged: controller.setName,
                        ),
                      )
                    : null,
              ),
              if (failure != null) ...[
                const SizedBox(height: QesmaSpacing.md),
                ErrorBanner(errorCopyFor(l10n, failure).message),
              ],
              const SizedBox(height: QesmaSpacing.lg),
              AppButton(
                label: l10n.inviteJoinButton,
                icon: Icons.person_add,
                loading: state.joining,
                onPressed: state.canSubmit ? controller.submit : null,
              ),
              const SizedBox(height: QesmaSpacing.sm),
              Text(
                l10n.inviteJoinNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A radio card (the design's member cards): one mutually exclusive choice, read out as selected or not.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({required this.selected, required this.onTap, required this.leading, required this.title, this.subtitle, this.child});

  final bool selected;
  final VoidCallback? onTap;
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      enabled: onTap != null,
      child: AppCard(
        onTap: onTap,
        color: selected ? context.colors.tint : null,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ExcludeSemantics(child: leading),
                const SizedBox(width: QesmaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      if (subtitle != null) Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: Icon(selected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: selected ? context.colors.primary : context.colors.textHelper),
                ),
              ],
            ),
            ?child,
          ],
        ),
      ),
    );
  }
}

enum _Tone { neutral, info, success, warning, error }

/// A full-screen outcome (expired, revoked, waiting, ...): icon, title, explanation and the next step.
class _StateView extends StatelessWidget {
  const _StateView({required this.icon, required this.tone, required this.title, required this.message, required this.actions});

  final IconData icon;
  final _Tone tone;
  final String title;
  final String message;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (bg, fg) = switch (tone) {
      _Tone.neutral => (context.colors.primaryContainer, context.colors.onPrimaryContainer),
      _Tone.info => (context.colors.infoContainer, context.colors.info),
      _Tone.success => (context.colors.successContainer, context.colors.success),
      _Tone.warning => (context.colors.warningContainer, context.colors.warning),
      _Tone.error => (context.colors.errorContainer, context.colors.error),
    };
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(QesmaSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: ExcludeSemantics(
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                    child: Icon(icon, size: 48, color: fg),
                  ),
                ),
              ),
              const SizedBox(height: QesmaSpacing.lg),
              Semantics(header: true, liveRegion: true, child: Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center)),
              const SizedBox(height: QesmaSpacing.sm),
              Text(message, style: theme.textTheme.bodyLarge?.copyWith(color: context.colors.textSecondary), textAlign: TextAlign.center),
              const SizedBox(height: QesmaSpacing.lg),
              for (final action in actions) ...[action, const SizedBox(height: QesmaSpacing.sm)],
            ],
          ),
        ),
      ),
    );
  }
}
