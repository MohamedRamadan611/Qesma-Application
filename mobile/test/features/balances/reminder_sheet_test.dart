import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/features/balances/application/reminder_launcher.dart';
import 'package:qesma/features/balances/application/reminder_tone_store.dart';
import 'package:qesma/features/balances/domain/reminder_tone.dart';
import 'package:qesma/features/balances/presentation/reminder_sheet.dart';

import '../../support/test_app.dart';

class InMemoryReminderToneStore implements ReminderToneStore {
  InMemoryReminderToneStore([this.currentTone = ReminderTone.soft]);
  ReminderTone currentTone;

  @override
  Future<ReminderTone> getLastTone() async => currentTone;

  @override
  Future<void> setLastTone(ReminderTone tone) async => currentTone = tone;
}

class FakeReminderLauncher implements ReminderLauncher {
  bool result = true;
  String? lastMessage;

  @override
  Future<bool> launchWhatsApp(String message) async {
    lastMessage = message;
    return true;
  }

  @override
  Future<bool> shareFallback(String message) async {
    lastMessage = message;
    return true;
  }

  @override
  Future<bool> launchOrShare(String message) async {
    lastMessage = message;
    return result;
  }
}

void main() {
  setUpAll(loadAppFonts);

  late InMemoryReminderToneStore toneStore;
  late FakeReminderLauncher launcher;

  setUp(() {
    toneStore = InMemoryReminderToneStore(ReminderTone.soft);
    launcher = FakeReminderLauncher();
  });

  Widget buildSheet({
    String debtorName = 'كريم',
    int amountMinor = 15000,
    String groupName = 'رحلة دهب',
    String? instapayHandle,
    ReminderTone initialTone = ReminderTone.soft,
  }) {
    return ProviderScope(
      overrides: [
        reminderToneStoreProvider.overrideWithValue(toneStore),
        reminderLauncherProvider.overrideWithValue(launcher),
      ],
      child: SingleChildScrollView(
        child: ReminderSheet(
          debtorName: debtorName,
          amountMinor: amountMinor,
          groupName: groupName,
          instapayHandle: instapayHandle,
          initialTone: initialTone,
        ),
      ),
    );
  }

  testWidgets('renders debtor info, tone chips, and prefilled message in Arabic', (tester) async {
    await pumpApp(
      tester,
      buildSheet(instapayHandle: 'kareem@instapay'),
      locale: const Locale('ar'),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

    expect(find.text('كريم'), findsOneWidget);
    expect(find.text(l10n.reminderToneLabel), findsOneWidget);
    expect(find.text(l10n.reminderToneSoftChip), findsOneWidget);
    expect(find.text(l10n.reminderToneFirmChip), findsOneWidget);
    expect(find.text(l10n.reminderToneFunnyChip), findsOneWidget);

    // InstaPay switch is visible when handle exists
    expect(find.text(l10n.reminderIncludeInstapay), findsOneWidget);
    expect(find.text('kareem@instapay'), findsOneWidget);

    // Initial message contains soft tone text and instapay handle
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, contains('صباح الفل يا كريم'));
    expect(textField.controller?.text, contains('kareem@instapay'));
  });

  testWidgets('renders in English with correct labels', (tester) async {
    await pumpApp(
      tester,
      buildSheet(debtorName: 'Kareem', groupName: 'Dahab Trip', instapayHandle: 'kareem@instapay'),
      locale: const Locale('en'),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('en'));

    expect(find.text('Kareem'), findsOneWidget);
    expect(find.text(l10n.reminderToneLabel), findsOneWidget);
    expect(find.text(l10n.reminderToneSoftChip), findsOneWidget);
    expect(find.text(l10n.reminderIncludeInstapay), findsOneWidget);

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, contains('friendly reminder'));
    expect(textField.controller?.text, contains('kareem@instapay'));
  });

  testWidgets('switching tones updates the text field and persists the tone to store', (tester) async {
    await pumpApp(
      tester,
      buildSheet(),
      locale: const Locale('ar'),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

    // Tap on Funny chip
    await tester.tap(find.text(l10n.reminderToneFunnyChip));
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.controller?.text, contains('قبل ما الجيب يعلن إفلاسه'));
    expect(toneStore.currentTone, equals(ReminderTone.funny));

    // Tap on Firm chip
    await tester.tap(find.text(l10n.reminderToneFirmChip));
    await tester.pumpAndSettle();

    final textField2 = tester.widget<TextField>(find.byType(TextField));
    expect(textField2.controller?.text, contains('بنقفل حسابات'));
    expect(toneStore.currentTone, equals(ReminderTone.firm));
  });

  testWidgets('toggle InstaPay handle updates the text field', (tester) async {
    await pumpApp(
      tester,
      buildSheet(instapayHandle: 'user@instapay'),
      locale: const Locale('ar'),
    );
    await tester.pumpAndSettle();

    final textFieldBefore = tester.widget<TextField>(find.byType(TextField));
    expect(textFieldBefore.controller?.text, contains('user@instapay'));

    // Toggle off
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    final textFieldAfter = tester.widget<TextField>(find.byType(TextField));
    expect(textFieldAfter.controller?.text, isNot(contains('user@instapay')));
  });

  testWidgets('when profile has no handle, toggle switch is hidden', (tester) async {
    await pumpApp(
      tester,
      buildSheet(instapayHandle: null),
      locale: const Locale('ar'),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));
    expect(find.text(l10n.reminderIncludeInstapay), findsNothing);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('tapping Open WhatsApp invokes reminder launcher with edited text', (tester) async {
    await pumpApp(
      tester,
      buildSheet(instapayHandle: null),
      locale: const Locale('ar'),
    );
    await tester.pumpAndSettle();

    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

    // Edit the text
    await tester.enterText(find.byType(TextField), 'رسالة مخصصة معدلة يدوياً');
    await tester.pumpAndSettle();

    // Tap Open WhatsApp
    await tester.tap(find.text(l10n.reminderOpenWhatsapp));
    await tester.pumpAndSettle();

    expect(launcher.lastMessage, equals('رسالة مخصصة معدلة يدوياً'));
  });

  testWidgets('survives text scale 2.0 without overflow', (tester) async {
    await pumpApp(
      tester,
      buildSheet(instapayHandle: 'kareem@instapay'),
      locale: const Locale('ar'),
      textScale: 2.0,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('a late tone load does not overwrite what the user already typed', (tester) async {
    await pumpApp(tester, buildSheet(), locale: const Locale('ar'));
    await tester.enterText(find.byType(TextField), 'نص كتبته بإيدي');
    toneStore.currentTone = ReminderTone.funny;
    await tester.pumpAndSettle();

    expect(find.text('نص كتبته بإيدي'), findsOneWidget);
  });

  testWidgets('when neither WhatsApp nor the share sheet opens, the sheet stays and tells the user', (tester) async {
    launcher.result = false;
    await pumpApp(tester, buildSheet(), locale: const Locale('ar'));
    await tester.pumpAndSettle();
    final l10n = await AppLocalizations.delegate.load(const Locale('ar'));

    await tester.tap(find.text(l10n.reminderOpenWhatsapp));
    await tester.pumpAndSettle();

    expect(find.text(l10n.reminderLaunchFailed), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });
}
