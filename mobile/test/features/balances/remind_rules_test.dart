import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/balances/application/remind_rules.dart';

void main() {
  final now = DateTime.utc(2026, 11, 13, 12);
  final past = now.subtract(const Duration(hours: 1));
  final future = now.add(const Duration(hours: 5));

  RemindState state({
    bool creditor = true,
    bool debtor = false,
    bool any = false,
    bool account = true,
    String status = 'ACTIVE',
    DateTime? at,
    DateTime? locked,
  }) =>
      remindStateFor(isCreditor: creditor, isDebtor: debtor,canRemindAny: any, debtorHasAccount: account, debtorStatus: status, canRemindAt: at, lockedUntil: locked, now: now);

  group('who sees the control', () {
    test('creditor: enabled', () => expect(state().kind, RemindKind.enabled));
    test('admin / owner on somebody else\'s transfer: enabled', () => expect(state(creditor: false, any: true).kind, RemindKind.enabled));
    test('a plain member who is not the creditor: hidden', () => expect(state(creditor: false).kind, RemindKind.hidden));
    test('the debtor never reminds themself, even as admin or owner', () => expect(state(creditor: false, any: true, debtor: true).kind, RemindKind.hidden));
    test('a plain member who is not the creditor stays hidden even when the server says "now"', () => expect(state(creditor: false, at: past).kind, RemindKind.hidden));
  });

  group('the debtor', () {
    test('a ghost (no account): caption, no button', () {
      final s = state(account: false);
      expect(s.kind, RemindKind.noAccount);
      expect(s.showsButton, isFalse);
    });
    test('a member who left: hidden', () => expect(state(status: 'LEFT').kind, RemindKind.hidden));
    test('a ghost who left is hidden, not captioned', () => expect(state(account: false, status: 'LEFT').kind, RemindKind.hidden));
    test('rights beat nothing: a plain member sees no ghost caption either', () => expect(state(creditor: false, account: false).kind, RemindKind.hidden));
  });

  group('the server time', () {
    test('null: enabled', () => expect(state().kind, RemindKind.enabled));
    test('in the past: enabled', () => expect(state(at: past).kind, RemindKind.enabled));
    test('exactly now: enabled', () => expect(state(at: now).kind, RemindKind.enabled));
    test('in the future: disabled until that time', () => expect(state(at: future), RemindState(RemindKind.disabled, future)));
    test('a send or a 429 of this session locks it', () => expect(state(locked: future), RemindState(RemindKind.disabled, future)));
    test('the later of the two times wins', () {
      final later = future.add(const Duration(hours: 3));
      expect(state(at: future, locked: later).until, later);
      expect(state(at: later, locked: future).until, later);
    });
    test('a stale lock does not disable', () => expect(state(at: null, locked: past).kind, RemindKind.enabled));
    test('admin on somebody else\'s transfer is disabled by the same time', () => expect(state(creditor: false, any: true, at: future).kind, RemindKind.disabled));
  });
}
