import 'package:built_collection/built_collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qesma_api/qesma_api.dart';

import '../../../core/auth/auth_providers.dart';
import '../../../core/errors/api_failure.dart';

/// One page of the settlement history.
typedef SettlementsPage = ({List<SettlementView> items, int page, int totalPages, int total});

/// The only code that talks to the generated balances and settlements API. Everything it throws
/// is an [ApiFailure]; widgets and notifiers never see Dio. It returns what the server said and
/// calculates nothing.
class BalancesRepository {
  BalancesRepository(this._api);

  final QesmaApi _api;

  static const int pageSize = 20;

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } catch (error) {
      throw mapApiError(error);
    }
  }

  /// Nets (every member, server order) and the suggested transfers.
  Future<BalanceView> balances(String gid) => _run(() async {
        final body = (await _api.getBalanceControllerApi().getBalances(gid: gid)).data;
        if (body == null) throw const ApiUnexpected();
        return body;
      });

  /// Newest first (the server sorts), 20 per page. [statuses] narrows to those states (the server filter); empty = every status.
  Future<SettlementsPage> settlements(String gid, {int page = 0, int size = pageSize, List<String> statuses = const []}) => _run(() async {
        final body = (await _api.getSettlementControllerApi().listSettlements(
          gid: gid,
          status: statuses.isEmpty ? null : BuiltList<String>(statuses),
          page: page,
          size: size,
        )).data;
        if (body == null) throw const ApiUnexpected();
        return (items: body.items.toList(), page: body.page, totalPages: body.totalPages, total: body.totalElements);
      });

  /// Declares / records a payment. [key] is the `Idempotency-Key` of this user action.
  Future<SettlementView> record(String gid, SettlementCommand command, String key) => _run(() async {
        final body = (await _api.getSettlementControllerApi().createSettlement(gid: gid, idempotencyKey: key, settlementCommand: command)).data;
        if (body == null) throw const ApiUnexpected();
        return body;
      });

  /// The three transitions (B13). No body and no key: they are idempotent by state, the server answers 200 with the current view.
  Future<SettlementView> confirm(String gid, String sid) => _run(() async {
        final body = (await _api.getSettlementControllerApi().confirmSettlement(gid: gid, sid: sid)).data;
        if (body == null) throw const ApiUnexpected();
        return body;
      });

  Future<SettlementView> dispute(String gid, String sid) => _run(() async {
        final body = (await _api.getSettlementControllerApi().disputeSettlement(gid: gid, sid: sid)).data;
        if (body == null) throw const ApiUnexpected();
        return body;
      });

  Future<SettlementView> cancel(String gid, String sid) => _run(() async {
        final body = (await _api.getSettlementControllerApi().cancelSettlement(gid: gid, sid: sid)).data;
        if (body == null) throw const ApiUnexpected();
        return body;
      });
}

final balancesRepositoryProvider = Provider<BalancesRepository>((ref) => BalancesRepository(ref.watch(qesmaApiProvider)));
