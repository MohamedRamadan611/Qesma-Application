import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/errors/api_failure.dart';
import '../../../core/errors/api_problem.dart';
import '../../../core/errors/error_copy.dart';
import '../../../core/format/date_format.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/palette.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../groups/presentation/group_dialogs.dart';
import '../../groups/presentation/group_ui.dart';
import '../application/join_requests_controller.dart';

/// Pending join requests of a group (Owner/Admin): who asks, which name they claim (or the new name), approve or
/// reject. Everything shown is what the server sent; no account ids are shown.
class JoinRequestsScreen extends ConsumerWidget {
  const JoinRequestsScreen({super.key, required this.gid});

  final String gid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(joinRequestsControllerProvider(gid));
    final controller = ref.read(joinRequestsControllerProvider(gid).notifier);

    final Widget body;
    if (state.loading && state.items.isEmpty) {
      body = const SkeletonList(itemCount: 3);
    } else if (state.failure != null && state.items.isEmpty) {
      body = ErrorState(
        onRetry: controller.load,
        message: errorCopyFor(l10n, state.failure!).message,
        requestId: state.failure!.problem?.requestId,
      );
    } else if (state.items.isEmpty) {
      body = RefreshIndicator(
        onRefresh: () async => controller.load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            EmptyState(icon: Icons.how_to_reg_outlined, title: l10n.inviteRequestsEmptyTitle, message: l10n.inviteRequestsEmptyBody),
          ],
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: () async => controller.load(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(QesmaSpacing.margin),
          children: [
            for (final request in state.items) ...[
              _RequestCard(
                request: request,
                busy: state.deciding.contains(request.id),
                onApprove: () => _decide(context, controller, request, approve: true),
                onReject: () => _decide(context, controller, request, approve: false),
              ),
              const SizedBox(height: QesmaSpacing.sm),
            ],
          ],
        ),
      );
    }

    return AppScaffold(
      title: l10n.inviteRequestsTitle,
      onBack: () => goBackOr(context, Routes.group(gid)),
      body: body,
    );
  }

  Future<void> _decide(BuildContext context, JoinRequestsController controller, JoinRequestView request, {required bool approve}) async {
    final l10n = AppLocalizations.of(context);
    final id = request.id;
    if (id == null) return;
    final failure = approve ? await controller.approve(id) : await controller.reject(id);
    if (!context.mounted) return;
    if (failure == null) {
      showAppSnackBar(context, approve ? l10n.inviteRequestApprovedNotice : l10n.inviteRequestRejectedNotice);
      return;
    }
    showAppSnackBar(context, _failureText(l10n, failure));
  }

  String _failureText(AppLocalizations l10n, ApiFailure failure) => switch (codeOf(failure)) {
        ApiErrorCode.memberAlreadyClaimed => l10n.inviteRequestClaimedNotice,
        ApiErrorCode.versionConflict => l10n.inviteRequestDecidedNotice,
        _ => errorCopyFor(l10n, failure).message,
      };
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.request, required this.busy, required this.onApprove, required this.onReject});

  final JoinRequestView request;
  final bool busy;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final requester = request.requesterName ?? l10n.inviteRequestUnknownName;
    final claim = request.claimMemberName;
    final what = claim != null ? l10n.inviteRequestClaims(claim) : l10n.inviteRequestNewMember(request.newMemberName ?? '');
    final created = request.createdAt;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              MemberAvatar(memberId: request.id ?? requester, name: requester, size: 44),
              const SizedBox(width: QesmaSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(requester, style: theme.textTheme.titleMedium),
                    Text(what, style: theme.textTheme.bodyMedium),
                    if (created != null)
                      Text(
                        l10n.inviteRequestWhen(isoDateTime(created)),
                        style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: QesmaSpacing.md),
          Row(
            children: [
              Expanded(
                child: Semantics(
                  label: l10n.inviteRequestRejectLabel(requester),
                  child: AppButton(label: l10n.inviteRequestReject, variant: AppButtonVariant.secondary, onPressed: busy ? null : onReject),
                ),
              ),
              const SizedBox(width: QesmaSpacing.sm),
              Expanded(
                child: Semantics(
                  label: l10n.inviteRequestApproveLabel(requester),
                  child: AppButton(label: l10n.inviteRequestApprove, icon: Icons.check, loading: busy, onPressed: busy ? null : onApprove),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
