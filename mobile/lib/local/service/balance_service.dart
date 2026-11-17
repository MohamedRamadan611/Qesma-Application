import 'package:built_collection/built_collection.dart';
import 'package:qesma_api/qesma_api.dart';
import 'package:qesma_engine/qesma_engine.dart';

import 'ledger.dart';
import 'local_context.dart';
import 'profile_service.dart';

/// Balances of a group (spec 7.7, A83): nets of every member and the simplified transfers, all from `qesma_engine`
/// over non-deleted expenses and CONFIRMED settlements. Locally nothing is ever pending or disputed and Remind is
/// server-only, so `pendingMinor` is 0, `hasDispute` false, `openSettlementIds` empty and `canRemindAt` absent.
final class BalanceService {
  BalanceService(this._ctx)
      : _ledger = Ledger(_ctx.db),
        _profile = ProfileService(_ctx);

  final LocalContext _ctx;
  final Ledger _ledger;
  final ProfileService _profile;

  Future<BalanceView> balances(String groupId) => _ctx.db.transaction(() async {
        final access = await _ctx.requireGroup(groupId);
        final nets = await _ledger.nets(groupId, access.members);
        final transfers = Simplifier.simplify(nets, Ledger.refs(access.members));
        // Receiver handles: the Owner sees them on every transfer, and only "you" has an account (and handles).
        final own = await _profile.handlesOf(access.profile.id);
        final ownHandles = own.instapay == null && own.wallet == null ? null : own;
        return BalanceView((b) => b
          ..nets = ListBuilder([
            for (final e in nets.entries)
              Net((n) => n
                ..memberId = e.key
                ..netMinor = e.value),
          ])
          ..transfers = ListBuilder([
            for (final t in transfers)
              TransferView((v) => v
                ..fromMemberId = t.fromMemberId
                ..toMemberId = t.toMemberId
                ..amountMinor = t.amountMinor
                ..pendingMinor = 0
                ..hasDispute = false
                ..openSettlementIds = ListBuilder<String>()
                ..receiverHandles = t.toMemberId == access.me.id ? ownHandles?.toBuilder() : null),
          ]));
      });
}
