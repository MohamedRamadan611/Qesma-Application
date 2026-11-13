import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../groups/application/group_detail_controller.dart';
import '../data/balances_repository.dart';
import 'settlement_rules.dart';

/// A failed read is shown (or hidden) as it is and read again by the next refetch: no automatic retry loop.
Duration? _noRetry(int count, Object error) => null;

/// The PENDING payments addressed to the signed-in person ("Yousef says he paid you 720.00"), read from the
/// settlements list with the server's status filter and narrowed to `toMemberId == yourMemberId`. They come from
/// the list and not from `balances.transfers`: a pending payment without a suggested transfer is not in there (A83).
/// An error is an `AsyncError`; the screens then simply show nothing (the balances tab has its own error state).
final incomingPaymentsProvider = FutureProvider.autoDispose.family<List<SettlementView>, String>((ref, gid) async {
  final you = ref.watch(groupDetailControllerProvider(gid).select((s) => s.group?.yourMemberId));
  if (you == null) return const [];
  final page = await ref.watch(balancesRepositoryProvider).settlements(gid, size: 100, statuses: [SettlementStatus.pending.wire]);
  return [
    for (final s in page.items)
      if (s.toMemberId == you && s.statusKind == SettlementStatus.pending) s,
  ];
}, retry: _noRetry);

typedef SettlementKey = ({String gid, String sid});

/// One settlement of any status, for the detail screen. There is no "get one" endpoint: the open ones (PENDING and
/// DISPUTED, server filter) are read first, then the full history page by page. Null = not found (it does not exist
/// in this group, or the person is not a member): the screen says so.
final settlementDetailProvider = FutureProvider.autoDispose.family<SettlementView?, SettlementKey>((ref, key) async {
  final repo = ref.watch(balancesRepositoryProvider);
  final open = await repo.settlements(key.gid, size: 100, statuses: [SettlementStatus.pending.wire, SettlementStatus.disputed.wire]);
  for (final s in open.items) {
    if (s.id == key.sid) return s;
  }
  for (var page = 0; page < 5; page++) {
    final result = await repo.settlements(key.gid, page: page, size: 100);
    for (final s in result.items) {
      if (s.id == key.sid) return s;
    }
    if (page + 1 >= result.totalPages) break;
  }
  return null;
}, retry: _noRetry);
