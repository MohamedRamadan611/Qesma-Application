import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/core/prefs/preference_store.dart';

/// FL9 on-device smoke: the REAL app UI on a real phone against the REAL local backend (profiles `local,fake-auth,seed`):
/// welcome -> debug sign-in (fake token of the seeded Dahab owner) -> the seeded trip in the list -> its Balances tab shows
/// the documented numbers (the server's, never client arithmetic).
///
///   adb reverse tcp:18080 tcp:18080
///   flutter test integration_test/dahab_smoke_test.dart -d DEVICE_ID --dart-define=API_BASE_URL=http://localhost:18080
///
/// The phone must be unlocked and awake. The app runs in English here (the preference store is preset) so the finders
/// are stable; Arabic and RTL are covered by the golden and widget tests and by the device checklist.
Future<void> main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpUntil(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 30)}) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().toList();
        throw TestFailure('timed out waiting for $finder; visible texts: $texts');
      }
      await tester.pump(const Duration(milliseconds: 250));
    }
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('the seeded Dahab trip shows the documented balances on the phone', (tester) async {
    final prefs = InMemoryPreferenceStore();
    await prefs.write(kLocalePref, 'en');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
        preferenceStoreProvider.overrideWithValue(prefs),
        authLogProvider.overrideWithValue(RecordingAuthLog()),
      ],
      child: const QesmaApp(),
    ));

    await pumpUntil(tester, find.text('Get started'));
    await tester.tap(find.text('Get started'));
    await pumpUntil(tester, find.text('Debug sign-in (development only)'));
    await tester.tap(find.text('Debug sign-in (development only)'));

    await pumpUntil(tester, find.text('رحلة دهب'));
    await tester.tap(find.text('رحلة دهب'));

    await pumpUntil(tester, find.text('Balances'));
    await tester.tap(find.text('Balances'));

    // The four suggested transfers (amounts come from the server, never from client arithmetic).
    await pumpUntil(tester, find.text('Suggested transfers'));
    expect(find.textContaining('4 transfers needed'), findsOneWidget);
    for (final amount in ['720.00', '394.02', '294.01']) {
      expect(find.textContaining(amount), findsWidgets, reason: 'transfer of $amount EGP');
    }

    // The documented nets are lower on the screen: scroll to each.
    for (final net in ['1,014.01', '1,114.02', '688.03']) {
      await tester.scrollUntilVisible(find.textContaining(net), 300, scrollable: find.byType(Scrollable).first, maxScrolls: 30);
      expect(find.textContaining(net), findsWidgets, reason: 'net $net EGP');
    }
  });
}
