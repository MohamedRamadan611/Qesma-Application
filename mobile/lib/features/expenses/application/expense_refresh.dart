import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../groups/application/group_detail_controller.dart';
import '../../groups/application/groups_list_controller.dart';
import '../../balances/application/balances_refresh.dart';
import 'expenses_list_controller.dart';

/// After an expense was saved or deleted: refresh what other screens show (the expenses list,
/// the group header totals, the groups list), but only those that are alive. Never creates a
/// controller just to refresh it.
void refreshExpenseViews(Ref ref, String gid) {
  if (ref.read(expensesListControllerProvider(gid).exists)) {
    unawaited(ref.read(expensesListControllerProvider(gid).notifier).refresh());
  }
  refreshBalanceTab(ref, gid);
  if (ref.read(groupDetailControllerProvider(gid).exists)) {
    unawaited(ref.read(groupDetailControllerProvider(gid).notifier).load());
  }
  if (ref.read(groupsListControllerProvider.exists)) {
    unawaited(ref.read(groupsListControllerProvider.notifier).refresh());
  }
}
