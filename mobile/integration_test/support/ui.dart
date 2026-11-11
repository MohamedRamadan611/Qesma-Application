import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/auth/auth_log.dart';
import 'package:qesma/core/auth/auth_providers.dart';
import 'package:qesma/core/auth/token_store.dart';
import 'package:qesma/core/prefs/preference_store.dart';
import 'package:qesma/features/auth/application/auth_controller.dart';
import 'package:qesma/features/auth/application/auth_state.dart';

/// Shared helpers of the on-device flows (real UI, real backend, English copy so the finders are stable).
class Session {
  Session(this.container);
  final ProviderContainer container;
}

/// Starts the real app in English with an empty token store and signs a fresh fake user in (no UI taps: the sign-in
/// screens have their own tests). [seed] is the fake-auth subject; use one per file so flows never share data.
Future<Session> startSignedIn(WidgetTester tester, String subject, {String name = 'Tester'}) async {
  final container = ProviderContainer(overrides: [
    tokenStoreProvider.overrideWithValue(InMemoryTokenStore()),
    preferenceStoreProvider.overrideWithValue(InMemoryPreferenceStore({'locale': 'en'})),
    authLogProvider.overrideWithValue(RecordingAuthLog()),
  ]);
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
  await pumpUntil(tester, find.text('Get started'));
  await container.read(authControllerProvider.notifier).signInWithIdToken('fake:$subject:$subject@example.com:$name');
  expect(container.read(authControllerProvider), isA<AuthSignedIn>(), reason: 'is the backend running with local,fake-auth?');
  await pumpUntil(tester, find.text('No groups yet'));
  return Session(container);
}

/// Pumps until [finder] matches (state-based wait, never a fixed sleep).
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

Future<void> tapText(WidgetTester tester, String text, {bool last = false}) async {
  await pumpUntil(tester, find.text(text));
  final finder = last ? find.text(text).last : find.text(text).first;
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 400));
}

Future<void> typeInto(WidgetTester tester, int fieldIndex, String text) async {
  final field = find.byType(TextField).at(fieldIndex);
  await tester.ensureVisible(field);
  await tester.enterText(field, text);
  await tester.pump(const Duration(milliseconds: 300));
}

/// Hides the keyboard so buttons below the fields can be reached.
Future<void> hideKeyboard(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));
}

/// Taps the first widget whose text contains [part] (for labels with an amount in them).
Future<void> tapContaining(WidgetTester tester, String part) async {
  await pumpUntil(tester, find.textContaining(part));
  final finder = find.textContaining(part).first;
  await tester.ensureVisible(finder);
  await tester.pump(const Duration(milliseconds: 200));
  await tester.tap(finder, warnIfMissed: false);
  await tester.pump(const Duration(milliseconds: 400));
}
