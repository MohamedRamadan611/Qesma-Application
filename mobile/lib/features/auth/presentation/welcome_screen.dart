import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/widgets/widgets.dart';
import 'auth_widgets.dart';
import '../../../core/theme/palette.dart';

/// Static value propositions and the start button. No guest mode: "start" leads to sign-in.
/// [from] is the location the user wanted before being asked to sign in; it travels on to
/// the sign-in screen and is validated by the router before it is used.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, this.from});

  final String? from;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final safeFrom = safeReturnLocation(from);

    Widget value(IconData icon, Color bg, Color fg, String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: QesmaSpacing.sm + 4),
          child: AppCard(
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(QesmaRadii.control)),
                    child: Icon(icon, color: fg),
                  ),
                ),
                const SizedBox(width: QesmaSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(body, style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );

    return Scaffold(
      backgroundColor: context.colors.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(QesmaSpacing.margin),
                children: [
                  const SizedBox(height: QesmaSpacing.md),
                  Center(child: BrandHeader(tagline: l10n.welcomeTitle, logoSize: 80)),
                  const SizedBox(height: QesmaSpacing.lg),
                  value(Icons.verified, context.colors.primaryContainer, context.colors.onPrimaryContainer, l10n.welcomeValue1Title, l10n.welcomeValue1Body),
                  value(Icons.receipt_long, context.colors.infoContainer, context.colors.info, l10n.welcomeValue2Title, l10n.welcomeValue2Body),
                  value(Icons.bolt, context.colors.warningContainer, context.colors.warning, l10n.welcomeValue3Title, l10n.welcomeValue3Body),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(QesmaSpacing.margin, 0, QesmaSpacing.margin, QesmaSpacing.sm),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppButton(
                    label: l10n.welcomeStart,
                    icon: Icons.arrow_forward,
                    onPressed: () => context.go(
                      safeFrom == null ? Routes.signIn : Uri(path: Routes.signIn, queryParameters: {'from': safeFrom}).toString(),
                    ),
                  ),
                  const SizedBox(height: QesmaSpacing.xs),
                  const ConsentFooter(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
