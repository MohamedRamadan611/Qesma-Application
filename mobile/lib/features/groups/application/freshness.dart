import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/forbidden_events.dart';
import '../../../core/format/clock.dart';
import '../../../core/router/app_router.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/application/auth_state.dart';
import '../../balances/application/balances_controller.dart';
import '../../balances/application/settlements_controller.dart';
import '../../expenses/application/expenses_list_controller.dart';
import 'group_detail_controller.dart';
import 'groups_list_controller.dart';

/// Coming back to the app refreshes what is on screen, but not more often than this (a quick switch to another
/// app and back must not hit the server again).
const Duration resumeRefreshMinGap = Duration(seconds: 15);

/// The location the person is looking at, as a path (`/groups/{gid}/...`). Tests replace it.
final freshnessLocationProvider = Provider<String Function()>((ref) {
  return () => ref.read(routerProvider).routeInformationProvider.value.uri.path;
});

/// Keeps what a person sees in step with other people's changes without sockets or timers (PHASE2_SPEC 12, point 1):
/// a refetch when the app returns to the foreground, and a reload of the group after the server said 403 (the role
/// may have changed). Only controllers that are alive are refreshed; none is created for the purpose.
class Freshness {
  Freshness(this._ref) : _lastRefresh = _ref.read(clockProvider)();

  final Ref _ref;
  DateTime _lastRefresh;

  /// The app was in the background and is visible again.
  void onResumed() {
    if (_ref.read(authControllerProvider) is! AuthSignedIn) return;
    final now = _ref.read(clockProvider)();
    if (now.difference(_lastRefresh) < resumeRefreshMinGap) return;
    _lastRefresh = now;

    if (_ref.read(groupsListControllerProvider.exists)) {
      unawaited(_ref.read(groupsListControllerProvider.notifier).refresh());
    }
    final gid = groupIdOfPath(_ref.read(freshnessLocationProvider)());
    if (gid != null) refreshGroup(gid);
  }

  /// The server answered 403 for this group: re-read it (and the list) so the role and the buttons catch up.
  void onForbidden(String gid) {
    if (_ref.read(authControllerProvider) is! AuthSignedIn) return;
    if (_ref.read(groupDetailControllerProvider(gid).exists)) {
      unawaited(_ref.read(groupDetailControllerProvider(gid).notifier).load());
    }
    if (_ref.read(groupsListControllerProvider.exists)) {
      unawaited(_ref.read(groupsListControllerProvider.notifier).refresh());
    }
  }

  /// Everything alive about one group.
  void refreshGroup(String gid) {
    if (_ref.read(groupDetailControllerProvider(gid).exists)) {
      unawaited(_ref.read(groupDetailControllerProvider(gid).notifier).load());
    }
    if (_ref.read(expensesListControllerProvider(gid).exists)) {
      unawaited(_ref.read(expensesListControllerProvider(gid).notifier).refresh());
    }
    if (_ref.read(balancesControllerProvider(gid).exists)) {
      unawaited(_ref.read(balancesControllerProvider(gid).notifier).refresh());
    }
    if (_ref.read(settlementsControllerProvider(gid).exists)) {
      unawaited(_ref.read(settlementsControllerProvider(gid).notifier).refresh());
    }
  }
}

final freshnessProvider = Provider<Freshness>((ref) => Freshness(ref));

/// Sits above the whole app: tells [Freshness] when the app comes back to the foreground and when a 403 arrived.
class FreshnessHost extends ConsumerStatefulWidget {
  const FreshnessHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<FreshnessHost> createState() => _FreshnessHostState();
}

class _FreshnessHostState extends ConsumerState<FreshnessHost> with WidgetsBindingObserver {
  bool _wasInBackground = false;

  @override
  void initState() {
    super.initState();
    // Created now, not at the first resume: the gap is counted from the start of the app.
    ref.read(freshnessProvider);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // `inactive` alone also happens for a permission prompt or the app switcher: only a real trip to the background counts.
    if (state == AppLifecycleState.paused || state == AppLifecycleState.hidden) {
      _wasInBackground = true;
    } else if (state == AppLifecycleState.resumed && _wasInBackground) {
      _wasInBackground = false;
      ref.read(freshnessProvider).onResumed();
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<ForbiddenEvent?>(forbiddenEventsProvider, (previous, next) {
      if (next != null) ref.read(freshnessProvider).onForbidden(next.gid);
    });
    return widget.child;
  }
}
