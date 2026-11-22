import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/recap/application/trip_recap_sharer.dart';
import '../l10n/generated/app_localizations.dart';
import '../theme/tokens.dart';
import 'app_button.dart';

/// Shows [card] in a dialog with a "share as image" button. The card is captured as a PNG (3x) and handed to the
/// system share sheet through the same seam as the trip recap, so tests can fake it. Names and amounts leave the
/// phone only when the user taps share.
Future<void> showShareImageDialog(BuildContext context, {required Widget card}) => showDialog<void>(
      context: context,
      builder: (_) => _ShareImageDialog(card: card),
    );

class _ShareImageDialog extends ConsumerStatefulWidget {
  const _ShareImageDialog({required this.card});

  final Widget card;

  @override
  ConsumerState<_ShareImageDialog> createState() => _ShareImageDialogState();
}

class _ShareImageDialogState extends ConsumerState<_ShareImageDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    setState(() => _sharing = true);
    try {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return;
      await ref.read(tripRecapSharerProvider).shareImage(data.buffer.asUint8List());
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      insetPadding: const EdgeInsets.all(QesmaSpacing.md),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(QesmaSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: RepaintBoundary(key: _boundaryKey, child: widget.card),
              ),
            ),
            const SizedBox(height: QesmaSpacing.md),
            AppButton(label: l10n.recapShareImage, icon: Icons.photo, onPressed: _sharing ? null : _share),
          ],
        ),
      ),
    );
  }
}

/// The frame every shared card uses: fixed 360 dp width, text scale fixed so the image never depends on the
/// viewer's font setting, title and the app watermark.
class ShareCardFrame extends StatelessWidget {
  const ShareCardFrame({super.key, required this.title, this.subtitle, required this.children});

  final String title;
  final String? subtitle;
  final List<Widget> children;

  static const width = 360.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = Theme.of(context).colorScheme;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(QesmaSpacing.md),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(QesmaRadii.card),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            if (subtitle != null)
              Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: QesmaSpacing.md),
            ...children,
            const SizedBox(height: QesmaSpacing.md),
            Text(
              l10n.recapWatermark,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

/// One "label ........ amount" row of a shared card.
class ShareCardRow extends StatelessWidget {
  const ShareCardRow({super.key, required this.label, required this.value, this.boldLabel = false});

  final String label;
  final String value;
  final bool boldLabel;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Expanded(child: Text(label, style: boldLabel ? const TextStyle(fontWeight: FontWeight.bold) : null)),
            const SizedBox(width: QesmaSpacing.sm),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
}
