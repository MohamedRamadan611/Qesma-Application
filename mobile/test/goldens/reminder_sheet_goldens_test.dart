import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/features/balances/application/reminder_launcher.dart';
import 'package:qesma/features/balances/application/reminder_tone_store.dart';
import 'package:qesma/features/balances/domain/reminder_tone.dart';
import 'package:qesma/features/balances/presentation/reminder_sheet.dart';

import '../support/test_app.dart';

class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const double tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(
        imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

class InMemoryReminderToneStore implements ReminderToneStore {
  InMemoryReminderToneStore([this.currentTone = ReminderTone.soft]);
  ReminderTone currentTone;

  @override
  Future<ReminderTone> getLastTone() async => currentTone;

  @override
  Future<void> setLastTone(ReminderTone tone) async => currentTone = tone;
}

class FakeReminderLauncher implements ReminderLauncher {
  @override
  Future<bool> launchWhatsApp(String message) async => true;

  @override
  Future<bool> shareFallback(String message) async => true;

  @override
  Future<bool> launchOrShare(String message) async => true;
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator =
        _TolerantComparator(current.basedir.resolve('reminder_sheet_goldens_test.dart'));
  });

  Future<void> pumpSheet(WidgetTester tester, Locale locale) async {
    final store = InMemoryReminderToneStore(ReminderTone.soft);
    final launcher = FakeReminderLauncher();

    await pumpApp(
      tester,
      ProviderScope(
        overrides: [
          reminderToneStoreProvider.overrideWithValue(store),
          reminderLauncherProvider.overrideWithValue(launcher),
        ],
        child: SingleChildScrollView(
          child: ReminderSheet(
            debtorName: locale.languageCode == 'ar' ? 'كريم' : 'Kareem',
            amountMinor: 15000,
            groupName: locale.languageCode == 'ar' ? 'رحلة دهب' : 'Dahab Trip',
            instapayHandle: 'user@instapay',
          ),
        ),
      ),
      locale: locale,
      size: const Size(360, 640),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reminder sheet golden (ar)', (tester) async {
    await pumpSheet(tester, const Locale('ar'));
    await expectLater(find.byType(ReminderSheet), matchesGoldenFile('reminder_sheet_ar.png'));
  });

  testWidgets('reminder sheet golden (en)', (tester) async {
    await pumpSheet(tester, const Locale('en'));
    await expectLater(find.byType(ReminderSheet), matchesGoldenFile('reminder_sheet_en.png'));
  });
}
