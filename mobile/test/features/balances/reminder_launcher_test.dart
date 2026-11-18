import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/balances/application/reminder_launcher.dart';

void main() {
  const message = 'صباح الفل\nعليك 150.00 ج.م';

  test('opens a wa.me link with the encoded text and does not share when it succeeds', () async {
    Uri? opened;
    String? shared;
    final launcher = SystemReminderLauncher(
      opener: (uri) async {
        opened = uri;
        return true;
      },
      sharer: (text) async {
        shared = text;
        return true;
      },
    );

    expect(await launcher.launchOrShare(message), isTrue);
    expect(opened!.host, 'wa.me');
    expect(opened!.queryParameters['text'], message);
    expect(shared, isNull);
  });

  test('falls back to the share sheet when the opener returns false', () async {
    String? shared;
    final launcher = SystemReminderLauncher(opener: (_) async => false, sharer: (t) async {
      shared = t;
      return true;
    });

    expect(await launcher.launchOrShare(message), isTrue);
    expect(shared, message);
  });

  test('falls back to the share sheet when the opener throws', () async {
    String? shared;
    final launcher = SystemReminderLauncher(
      opener: (_) => throw StateError('no handler'),
      sharer: (t) async {
      shared = t;
      return true;
    },
    );

    expect(await launcher.launchOrShare(message), isTrue);
    expect(shared, message);
  });

  test('returns false when both the opener and the share sheet fail or are dismissed', () async {
    final launcher = SystemReminderLauncher(opener: (_) async => false, sharer: (_) async => false);
    expect(await launcher.launchOrShare(message), isFalse);

    final throwing = SystemReminderLauncher(opener: (_) => throw StateError('x'), sharer: (_) => throw StateError('y'));
    expect(await throwing.launchOrShare(message), isFalse);
  });
}
