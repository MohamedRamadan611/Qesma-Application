import 'dart:async';
import 'dart:io';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/app_mode.dart';
import 'package:qesma/core/format/cairo_day.dart';
import 'package:qesma/features/receipt_scan/application/ocr_settings_store.dart';
import 'package:qesma/features/receipt_scan/application/receipt_reader.dart';
import 'package:qesma/features/receipt_scan/application/receipt_scan_providers.dart';
import 'package:qesma/features/receipt_scan/presentation/scan_consent_row.dart';
import 'package:qesma/features/receipt_scan/presentation/scan_flow.dart';

import '../../support/test_app.dart';
import 'support/fakes.dart';

/// SA12 flow screens, ar/en at text scale 1.0 and 2.0 (a layout overflow fails the test): consent once, the source
/// sheet, and for every failure kind its own message and a "type manually" action. A fake reader and picker stand in
/// for Google and the camera.
void main() {
  setUpAll(loadAppFonts);

  ScanFlowResult? result;

  Future<void> pumpHost(WidgetTester tester, Config config, {required FakeReceiptReader reader, required MemoryOcrStore store, FakePhotoPicker? picker}) async {
    result = null;
    tester.platformDispatcher.textScaleFactorTestValue = config.textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpApp(
      tester,
      ProviderScope(
        overrides: [
          appModeProvider.overrideWithValue(AppMode.local),
          receiptReaderProvider.overrideWithValue(reader),
          ocrSettingsStoreProvider.overrideWithValue(store),
          receiptPhotoPickerProvider.overrideWithValue(picker ?? FakePhotoPicker(fakeJpeg())),
        ],
        child: Consumer(
          builder: (context, ref, _) => Column(
            children: [
              ElevatedButton(key: const Key('scan'), onPressed: () async => result = await runReceiptScan(context, ref), child: const Text('go')),
              const ScanConsentRow(),
            ],
          ),
        ),
      ),
      locale: config.locale,
      textScale: config.textScale,
      size: const Size(400, 900),
    );
    await tester.pumpAndSettle();
  }

  for (final config in allConfigs) {
    group(config.name, () {
      testWidgets('consent is asked once: decline types manually without sending, agree remembers', (tester) async {
        final reader = FakeReceiptReader([goodJson]);
        final store = MemoryOcrStore();
        await pumpHost(tester, config, reader: reader, store: store);
        final l10n = l10nOf(tester);

        await tester.tap(find.byKey(const Key('scan')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.scanConsentSent), findsOneWidget);
        expect(find.text(l10n.scanConsentFree), findsOneWidget, reason: 'the free-tier data use is stated (A146)');
        await tester.scrollUntilVisible(find.text(l10n.scanConsentAvoid), 200);
        expect(find.text(l10n.scanConsentAvoid), findsOneWidget);
        await tester.scrollUntilVisible(find.text(l10n.scanConsentDecline), 200);
        await tester.drag(find.byType(ListView), const Offset(0, -150));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.scanConsentDecline));
        await tester.pumpAndSettle();
        expect(result, isA<ScanFlowManual>());
        expect(store.value.consented, isFalse);
        expect(reader.received, isEmpty);

        await tester.tap(find.byKey(const Key('scan')));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text(l10n.scanConsentAccept), 200);
        await tester.drag(find.byType(ListView), const Offset(0, -150));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.scanConsentAccept));
        await tester.pumpAndSettle();
        expect(store.value.consented, isTrue);
        expect(find.text(l10n.scanSourceCamera), findsOneWidget);
        await tester.tapAt(const Offset(5, 5)); // dismiss the sheet
        await tester.pumpAndSettle();
        expect(result, isA<ScanFlowCancelled>());

        // Consent is remembered: the next scan goes straight to the source sheet.
        await tester.tap(find.byKey(const Key('scan')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.scanConsentSent), findsNothing);
        expect(find.text(l10n.scanSourceGallery), findsOneWidget);
      });

      testWidgets('the profile row shows the consent and revoking it makes the next scan ask again', (tester) async {
        final store = MemoryOcrStore(const OcrSettings(consentAt: 5));
        await pumpHost(tester, config, reader: FakeReceiptReader([goodJson]), store: store);
        final l10n = l10nOf(tester);
        expect(find.text(l10n.scanProfileOn), findsOneWidget);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        expect(store.value.consented, isFalse);
        expect(find.text(l10n.scanProfileOff), findsOneWidget);
        await tester.tap(find.byKey(const Key('scan')));
        await tester.pumpAndSettle();
        expect(find.text(l10n.scanConsentTitle), findsWidgets);
      });

      testWidgets('a good scan returns the proposal (nothing is saved) and the photo goes to the reader once', (tester) async {
        final reader = FakeReceiptReader([goodJson]);
        final store = MemoryOcrStore(const OcrSettings(consentAt: 5));
        await pumpHost(tester, config, reader: reader, store: store);
        final l10n = l10nOf(tester);
        await tester.tap(find.byKey(const Key('scan')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.scanSourceGallery));
        await tester.pumpAndSettle();
        final draft = (result! as ScanFlowDraft).draft;
        expect(draft.itemized.items.map((i) => (i.name, i.amountText, i.assigneeIds.isEmpty)), [('Tea', '12.50', true), ('Cake', '30', true)]);
        expect(draft.printedTotalMinor, 4250);
        expect(reader.received.length, 1);
      });

      final failures = <ReceiptScanFailure, Object>{
        ReceiptScanFailure.offline: const SocketException('Failed host lookup'),
        ReceiptScanFailure.timeout: TimeoutException('slow'),
        ReceiptScanFailure.quotaExhausted: QuotaExceeded('quota'),
        ReceiptScanFailure.permissionDenied: ServerException('PERMISSION_DENIED: App Check'),
        ReceiptScanFailure.unreadablePhoto: '{"items":[]}',
        ReceiptScanFailure.invalidResponse: 'not json',
        ReceiptScanFailure.unavailable: StateError('boom'),
        ReceiptScanFailure.dailyCapReached: 'cap',
      };
      for (final entry in failures.entries) {
        testWidgets('${entry.key.name}: its own message, a "type manually" action${scanFailureRetryable(entry.key) ? ' and a retry' : ''}', (tester) async {
          final now = DateTime.now().toUtc();
          final store = MemoryOcrStore(
            entry.key == ReceiptScanFailure.dailyCapReached
                ? OcrSettings(consentAt: 5, scanDay: cairoDay(now), scanCount: kDailyScanCap)
                : const OcrSettings(consentAt: 5),
          );
          await pumpHost(tester, config, reader: FakeReceiptReader([entry.value]), store: store);
          final l10n = l10nOf(tester);
          await tester.tap(find.byKey(const Key('scan')));
          await tester.pumpAndSettle();
          await tester.tap(find.text(l10n.scanSourceCamera));
          await tester.pumpAndSettle();

          expect(find.text(l10n.scanErrorTitle), findsOneWidget);
          expect(find.text(scanFailureMessage(l10n, entry.key)), findsOneWidget);
          expect(find.text(l10n.scanTryAgain), scanFailureRetryable(entry.key) ? findsOneWidget : findsNothing);
          // Each kind has a different message.
          final messages = {for (final f in ReceiptScanFailure.values) scanFailureMessage(l10n, f)};
          expect(messages.length, ReceiptScanFailure.values.length);

          await tester.tap(find.text(l10n.scanTypeManually));
          await tester.pumpAndSettle();
          expect(result, isA<ScanFlowManual>());
        });
      }

      testWidgets('retry after an error goes back to the source sheet and can succeed', (tester) async {
        final reader = FakeReceiptReader([const SocketException('x'), goodJson]);
        await pumpHost(tester, config, reader: reader, store: MemoryOcrStore(const OcrSettings(consentAt: 5)));
        final l10n = l10nOf(tester);
        await tester.tap(find.byKey(const Key('scan')));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.scanSourceCamera));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.scanTryAgain));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.scanSourceCamera));
        await tester.pumpAndSettle();
        expect(result, isA<ScanFlowDraft>());
      });
    });
  }
}
