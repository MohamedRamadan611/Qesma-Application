import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import '../../../local/insights/trip_recap_provider.dart';
import '../../../local/insights/trip_recap_repository.dart';
import '../../balances/application/balances_controller.dart';
import '../../groups/application/group_detail_controller.dart';
import '../application/trip_recap_formatter.dart';
import '../application/trip_recap_sharer.dart';
import 'trip_recap_card.dart';

class TripRecapScreen extends ConsumerStatefulWidget {
  const TripRecapScreen({
    super.key,
    required this.gid,
  });

  final String gid;

  @override
  ConsumerState<TripRecapScreen> createState() => _TripRecapScreenState();
}

class _TripRecapScreenState extends ConsumerState<TripRecapScreen> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _isSharing = false;

  Future<bool> _confirmSharePrivacy(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    return showConfirmDialog(
      context,
      title: l10n.recapConfirmShareTitle,
      message: l10n.recapConfirmShareBody,
      confirmLabel: l10n.recapConfirmShareAction,
      cancelLabel: l10n.commonCancel,
    );
  }

  Future<void> _shareImage(BuildContext context, TripRecapResult recap, String groupName) async {
    if (_isSharing) return;
    final confirmed = await _confirmSharePrivacy(context);
    if (!confirmed || !mounted) return;

    final boundary =
        _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    assert(boundary != null, 'boundary must not be null');
    if (boundary == null) return;

    setState(() => _isSharing = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      assert(byteData != null, 'byteData must not be null');
      if (byteData == null) return;

      final pngBytes = byteData.buffer.asUint8List();
      await ref.read(tripRecapSharerProvider).shareImage(pngBytes);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _shareText(BuildContext context, TripRecapResult recap, String groupName) async {
    if (_isSharing) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirmSharePrivacy(context);
    if (!confirmed || !mounted) return;

    setState(() => _isSharing = true);
    try {
      final groupDetail = ref.read(groupDetailControllerProvider(widget.gid));
      final members = groupDetail.group?.members;
      final memberMap = <String, String>{
        if (members != null)
          for (final m in members) m.id: m.displayName,
      };
      String nameOf(String id) => memberMap[id] ?? id;

      final balancesState = ref.read(balancesControllerProvider(widget.gid));
      final transfers = balancesState.balances?.transfers.toList() ?? [];

      final text = TripRecapFormatter.formatTextSummary(
        l10n: l10n,
        groupName: groupName,
        totalSpentMinor: recap.totalSpentMinor,
        expenseCount: recap.expenseCount,
        transfers: transfers,
        nameOf: nameOf,
      );

      await ref.read(tripRecapSharerProvider).shareText(text);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groupDetail = ref.watch(groupDetailControllerProvider(widget.gid));
    final group = groupDetail.group;
    final groupName = group?.name ?? '';

    final recapAsync = ref.watch(tripRecapProvider(widget.gid));

    return AppScaffold(
      title: l10n.recapTitle,
      showBack: true,
      body: recapAsync.when(
        loading: () => const SkeletonList(itemCount: 3),
        error: (_, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.commonRetry,
          message: l10n.recapEmptyBody,
        ),
        data: (recap) {
          if (recap == null) {
            return EmptyState(
              icon: Icons.receipt_long_outlined,
              title: l10n.recapEmptyTitle,
              message: l10n.recapEmptyBody,
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(QesmaSpacing.margin),
            child: Column(
              children: [
                Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: RepaintBoundary(
                      key: _boundaryKey,
                      child: TripRecapCard(
                        groupName: groupName,
                        recap: recap,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: QesmaSpacing.lg),
                AppButton(
                  label: l10n.recapShareImage,
                  icon: Icons.photo,
                  onPressed: _isSharing ? null : () => _shareImage(context, recap, groupName),
                ),
                const SizedBox(height: QesmaSpacing.sm),
                AppButton(
                  label: l10n.recapShareText,
                  icon: Icons.share,
                  variant: AppButtonVariant.secondary,
                  onPressed: _isSharing ? null : () => _shareText(context, recap, groupName),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
