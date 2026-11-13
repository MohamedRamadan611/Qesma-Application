import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/balances/application/settlement_rules.dart';

/// The whole viewer x status x action table of PHASE2_SPEC section 6 / decision A84, written out cell by cell (not derived
/// from the function under test). A = the payer, R = the receiver, X = a third member.
void main() {
  const payer = 'payer';
  const receiver = 'receiver';
  const other = 'other';

  Set<SettlementAction> actions(SettlementStatus status, String? viewer, {bool admin = false}) => settlementActionsFor(
        status: status,
        yourMemberId: viewer,
        fromMemberId: payer,
        toMemberId: receiver,
        isAdminOrOwner: admin,
      );

  const confirm = SettlementAction.confirm;
  const dispute = SettlementAction.dispute;
  const cancel = SettlementAction.cancel;

  // (status, viewer, isAdminOrOwner) -> expected
  final table = <(SettlementStatus, String, bool, Set<SettlementAction>)>[
    // PENDING
    (SettlementStatus.pending, payer, false, {cancel}),
    (SettlementStatus.pending, receiver, false, {confirm, dispute}),
    (SettlementStatus.pending, other, false, {}),
    (SettlementStatus.pending, payer, true, {cancel}), // the payer never confirms their own payment, not even as admin
    (SettlementStatus.pending, receiver, true, {confirm, dispute, cancel}),
    (SettlementStatus.pending, other, true, {confirm, cancel}),
    // DISPUTED (only the receiver disputes, and only from PENDING)
    (SettlementStatus.disputed, payer, false, {cancel}),
    (SettlementStatus.disputed, receiver, false, {confirm}),
    (SettlementStatus.disputed, other, false, {}),
    (SettlementStatus.disputed, payer, true, {cancel}),
    (SettlementStatus.disputed, receiver, true, {confirm, cancel}),
    (SettlementStatus.disputed, other, true, {confirm, cancel}),
    // Final states: nothing for anybody
    for (final s in [SettlementStatus.confirmed, SettlementStatus.cancelled, SettlementStatus.unknown])
      for (final v in [payer, receiver, other])
        for (final a in [false, true]) (s, v, a, <SettlementAction>{}),
  ];

  for (final (status, viewer, admin, expected) in table) {
    test('${status.name} x $viewer${admin ? ' (owner/admin)' : ''} -> ${expected.map((a) => a.name).toList()}', () {
      expect(actions(status, viewer, admin: admin), expected);
    });
  }

  test('nobody is signed in as a member: nothing', () {
    expect(actions(SettlementStatus.pending, null, admin: true), isEmpty);
  });

  test('the wire status maps to the enum; an unknown one is "unknown" (no actions, neutral chip)', () {
    expect(SettlementStatus.fromWire('PENDING'), SettlementStatus.pending);
    expect(SettlementStatus.fromWire('CONFIRMED'), SettlementStatus.confirmed);
    expect(SettlementStatus.fromWire('DISPUTED'), SettlementStatus.disputed);
    expect(SettlementStatus.fromWire('CANCELLED'), SettlementStatus.cancelled);
    expect(SettlementStatus.fromWire('SOMETHING_NEW'), SettlementStatus.unknown);
    expect(SettlementStatus.fromWire(null), SettlementStatus.unknown);
  });

  group('expectedInitialOutcome (decision A85, only a hint for the wording)', () {
    InitialOutcome outcome({required String? from, required String? to, bool account = true, bool admin = false, String? me = 'me'}) =>
        expectedInitialOutcome(yourMemberId: me, fromMemberId: from, toMemberId: to, receiverHasAccount: account, isAdminOrOwner: admin);

    test('the payer declares to a member with an account: pending', () => expect(outcome(from: 'me', to: 'x'), InitialOutcome.pending));
    test('the payer to a member without an account: refused for a member, confirmed for owner/admin', () {
      expect(outcome(from: 'me', to: 'x', account: false), InitialOutcome.notAllowed);
      expect(outcome(from: 'me', to: 'x', account: false, admin: true), InitialOutcome.confirmed);
    });
    test('the receiver records cash received: confirmed (even for a plain member)', () => expect(outcome(from: 'x', to: 'me'), InitialOutcome.confirmed));
    test('a third pair: refused for a member, confirmed on behalf for owner/admin', () {
      expect(outcome(from: 'x', to: 'y'), InitialOutcome.notAllowed);
      expect(outcome(from: 'x', to: 'y', admin: true), InitialOutcome.confirmed);
    });
    test('an incomplete form cannot be sent', () {
      expect(outcome(from: null, to: 'x'), InitialOutcome.notAllowed);
      expect(outcome(from: 'me', to: 'x', me: null), InitialOutcome.notAllowed);
    });
  });
}
