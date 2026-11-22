import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../local/insights/archive_provider.dart';
import '../features_for_mode.dart';
import '../l10n/generated/app_localizations.dart';
import '../router/app_router.dart';

/// The top-level screens (Groups, My Share when the mode has it, Account) with the bottom bar.
/// Nothing else gets a bar: group screens, forms and sheets are pushed over it.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final features = ref.watch(modeFeaturesProvider);
    final hasMyShare = features.myShare;
    // A184: once per app run, delete the archived groups whose period is over.
    if (features.archive) ref.watch(archivePurgeProvider);
    final paths = [Routes.home, if (hasMyShare) Routes.myShare, Routes.account];
    final index = paths.indexWhere((p) => p != Routes.home && location.startsWith(p));
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index < 0 ? 0 : index,
        onDestinationSelected: (i) => context.go(paths[i]),
        destinations: [
          NavigationDestination(icon: const Icon(Icons.groups_outlined), selectedIcon: const Icon(Icons.groups), label: l10n.groupsTitle),
          if (hasMyShare) NavigationDestination(icon: const Icon(Icons.pie_chart_outline), selectedIcon: const Icon(Icons.pie_chart), label: l10n.myShareTitle),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n.profileTitle),
        ],
      ),
    );
  }
}
