import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../groups/application/group_detail_controller.dart';
import '../../groups/application/groups_list_controller.dart';
import 'balances_controller.dart';
import 'incoming_settlements.dart';
import 'settlements_controller.dart';

/// Refreshes the balances and the payment history, but only those that are alive (never creates a
/// controller just to refresh it). Used after any expense change.
///
/// A controller that calls this for its own change passes `balances: false` / `settlements: false` for
/// itself (a provider cannot read itself) and refreshes itself directly.
void refreshBalanceTab(Ref ref, String gid, {bool balances = true, bool settlements = true}) {
  if (balances && ref.read(balancesControllerProvider(gid).exists)) {
    unawaited(ref.read(balancesControllerProvider(gid).notifier).refresh());
  }
  if (settlements && ref.read(settlementsControllerProvider(gid).exists)) {
    unawaited(ref.read(settlementsControllerProvider(gid).notifier).refresh());
  }
}

/// After a payment was recorded or deleted: balances and history again, and what shows the
/// numbers they change (the group header's totals and "your balance", the groups list card).
void refreshAfterPayment(Ref ref, String gid, {bool settlements = true}) {
  refreshBalanceTab(ref, gid, settlements: settlements);
  ref.invalidate(incomingPaymentsProvider(gid));
  if (ref.read(groupDetailControllerProvider(gid).exists)) {
    unawaited(ref.read(groupDetailControllerProvider(gid).notifier).load());
  }
  if (ref.read(groupsListControllerProvider.exists)) {
    unawaited(ref.read(groupsListControllerProvider.notifier).refresh());
  }
}

/// After a confirm / dispute / cancel: everything [refreshAfterPayment] reads, plus the "payments waiting for me"
/// list and the detail screens (they are auto-disposed: invalidating one that is not alive does nothing).
void refreshAfterSettlementChange(Ref ref, String gid) {
  refreshAfterPayment(ref, gid);
  ref.invalidate(incomingPaymentsProvider(gid));
  ref.invalidate(settlementDetailProvider);
}
