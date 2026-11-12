import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/api/dio_factory.dart';
import 'package:qesma/features/invites/application/invite_code.dart';
import 'package:qesma/features/invites/application/invite_sheet_controller.dart';

void main() {
  group('normaliseInviteCode', () {
    test('accepts the canonical form, dashes, spaces and lower case', () {
      expect(normaliseInviteCode('ABCD2345'), 'ABCD2345');
      expect(normaliseInviteCode('abcd-2345'), 'ABCD2345');
      expect(normaliseInviteCode('  ab cd 23 45 '), 'ABCD2345');
    });

    test('Arabic-Indic and Eastern Arabic-Indic digits become Western digits', () {
      expect(normaliseInviteCode('ABCD-٢٣٤٥'), 'ABCD2345');
      expect(normaliseInviteCode('abcd۲۳۴۵'), 'ABCD2345');
    });

    test('a pasted link or a link with a query gives the code', () {
      expect(normaliseInviteCode('https://qesma.app/join/ABCD-2345'), 'ABCD2345');
      expect(normaliseInviteCode('https://qesma.app/join/abcd2345?utm=x#y'), 'ABCD2345');
    });

    test('invisible direction marks from a paste are ignored', () {
      expect(normaliseInviteCode('${String.fromCharCode(0x2066)}ABCD-2345${String.fromCharCode(0x2069)}'), 'ABCD2345');
      expect(normaliseInviteCode('ABCD${String.fromCharCode(0x200B)}2345'), 'ABCD2345');
    });

    test('anything that cannot be a code is null', () {
      expect(normaliseInviteCode(null), isNull);
      expect(normaliseInviteCode(''), isNull);
      expect(normaliseInviteCode('ABC'), isNull);
      expect(normaliseInviteCode('ABCD23456'), isNull);
      // the alphabet leaves out 0, 1, I, O to avoid look-alikes
      expect(normaliseInviteCode('ABCD0123'), isNull);
      expect(normaliseInviteCode('ABCDIO45'), isNull);
      expect(normaliseInviteCode('//evil.example/x'), isNull);
    });

    test('formatInviteCode shows XXXX-XXXX and leaves other lengths alone', () {
      expect(formatInviteCode('ABCD2345'), 'ABCD-2345');
      expect(formatInviteCode('SHORT'), 'SHORT');
      expect(formatInviteCode(null), '');
    });

    test('codeFromJoinPath reads the App Link path', () {
      expect(codeFromJoinPath('/join/ABCD2345'), 'ABCD2345');
      expect(codeFromJoinPath('/join/abcd-2345'), 'ABCD2345');
      expect(codeFromJoinPath('/join/nope'), isNull);
      expect(codeFromJoinPath('/groups/ABCD2345'), isNull);
      expect(codeFromJoinPath('/join'), isNull);
    });
  });

  group('the request log never carries an invite code', () {
    test('the code in /invites/<code> and /invites/<code>/join is hidden', () {
      expect(RequestLogInterceptor.redactSecrets('/api/v1/invites/ABCD2345'), '/api/v1/invites/***');
      expect(RequestLogInterceptor.redactSecrets('/api/v1/invites/ABCD2345/join'), '/api/v1/invites/***/join');
      expect(RequestLogInterceptor.redactSecrets('/api/v1/groups/g1/invites'), '/api/v1/groups/g1/invites');
      expect(RequestLogInterceptor.redactSecrets('/api/v1/groups/g1/expenses'), '/api/v1/groups/g1/expenses');
    });
  });

  group('inviteRemaining (from the server expiresAt)', () {
    final now = DateTime.utc(2026, 10, 18, 12);
    test('days, hours, soon and past', () {
      expect((inviteRemaining(now.add(const Duration(days: 6, hours: 23)), now) as RemainingDays).days, 6);
      expect((inviteRemaining(now.add(const Duration(days: 7)), now) as RemainingDays).days, 7);
      expect((inviteRemaining(now.add(const Duration(hours: 5)), now) as RemainingHours).hours, 5);
      expect(inviteRemaining(now.add(const Duration(minutes: 20)), now), isA<RemainingSoon>());
      expect(inviteRemaining(now, now), isA<RemainingNone>());
      expect(inviteRemaining(now.subtract(const Duration(days: 1)), now), isA<RemainingNone>());
      expect(inviteRemaining(null, now), isA<RemainingNone>());
    });
  });
}
