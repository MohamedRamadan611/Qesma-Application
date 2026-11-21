import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/app.dart';
import 'package:qesma/core/l10n/generated/app_localizations.dart';
import 'package:qesma/core/l10n/locale_controller.dart';
import 'package:qesma/core/router/app_router.dart';
import 'package:qesma/core/widgets/widgets.dart';
import 'package:qesma/features/expenses/presentation/assignee_summary_chip.dart';
import 'package:qesma/features/expenses/presentation/expense_form_screen.dart';
import 'package:qesma/features/expenses/presentation/itemized_items_card.dart';
import 'package:qesma/features/receipt_scan/application/ocr_settings_store.dart';
import 'package:qesma/features/receipt_scan/application/receipt_scan_providers.dart';
import 'package:qesma/local/backend/local_backend_overrides.dart';

import '../../local/backend/support/local_http.dart';
import '../../support/test_app.dart' show allConfigs, loadAppFonts;
import 'support/fakes.dart';

/// SA12 end to end on the real local backend: group, FAB menu, "Scan receipt", consent, photo, then the add form
/// opens as an UNSAVED itemized bill (nobody assigned, so not saveable), then the user assigns members -> the editor's own
/// preview total is compared with the printed total (match banner / mismatch banner). Nothing is saved by the scan.
const _wrongTotal = '{"items":[{"name":"Tea","amount":"12.50"},{"name":"Cake","amount":"30"}],"total":"50","currency":"EGP"}';

/// Scrolls the form's list until [target] is on screen (bounded; pumps frames instead of settling, because the
/// preview spinner animates while the local backend answers).
Future<void> reveal(WidgetTester tester, Finder target, double delta) async {
  final list = find.descendant(of: find.byType(ExpenseFormScreen), matching: find.byType(ListView)).first;
  for (var i = 0; i < 40; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    if (target.evaluate().isNotEmpty && target.hitTestable().evaluate().isNotEmpty) return;
    await tester.drag(list, Offset(0, -delta));
  }
  fail('never found $target');
}

/// Lets the local backend (real async I/O) answer the preview, then draws the result.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 60)));
    await tester.pump(const Duration(milliseconds: 100));
  }
}

/// Assigns Asem alone to each named item through the accordion and the member picker.
Future<void> assignAsem(WidgetTester tester, AppLocalizations l10n, List<String> names) async {
  for (final name in names) {
    // One item is open at a time: a collapsed row is tapped open first; the open one has the member button.
    final row = find.widgetWithText(ItemSummaryRow, name);
    if (row.evaluate().isNotEmpty) {
      await tester.ensureVisible(row);
      await tester.tap(row);
      await tester.pumpAndSettle();
    }
    await tester.ensureVisible(find.byType(AssigneeSummaryChip).first);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(AssigneeSummaryChip).first);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AppBottomSheet), matching: find.text('Asem')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: find.byType(AppBottomSheet), matching: find.byType(FilledButton)));
    await tester.pumpAndSettle();
  }
}

void main() {
  setUpAll(loadAppFonts);

  late LocalHttp http;
  late String gid;

  setUp(() async {
    http = await LocalHttp.open(profileName: 'Mona');
    gid = (await http.group(name: 'Sokhna'))['id'] as String;
    await http.member(gid, 'Asem');
  });
  tearDown(() => http.close());

  for (final config in allConfigs) {
    testWidgets('scan -> unsaved itemized draft -> assign -> total banners (${config.name})', timeout: const Timeout(Duration(seconds: 40)), (tester) async {
      tester.view.devicePixelRatio = 1.0;
      tester.view.physicalSize = const Size(400, 900);
      tester.platformDispatcher.textScaleFactorTestValue = config.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final reader = FakeReceiptReader([goodJson, _wrongTotal]);
      final container = ProviderContainer(overrides: [
        ...localModeOverrides(http.db),
        receiptReaderProvider.overrideWithValue(reader),
        receiptPhotoPickerProvider.overrideWithValue(FakePhotoPicker(fakeJpeg())),
      ]);
      addTearDown(container.dispose);
      container.read(localeProvider.notifier).set(config.locale);
      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const QesmaApp()));
      await tester.pumpAndSettle();
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
      final router = container.read(routerProvider);

      router.go(Routes.group(gid));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();
      expect(find.text(l10n.scanReceiptHint), findsOneWidget);
      await tester.tap(find.text(l10n.scanReceiptAction));
      await tester.pumpAndSettle();

      // Consent first, stored in the real drift database.
      expect(find.text(l10n.scanConsentTitle), findsWidgets);
      await tester.scrollUntilVisible(find.text(l10n.scanConsentAccept), 200);
      await tester.drag(find.byType(ListView), const Offset(0, -150));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.scanConsentAccept));
      await tester.pumpAndSettle();
      expect((await tester.runAsync(() => container.read(ocrSettingsStoreProvider).read()))!.consented, isTrue);

      await tester.tap(find.text(l10n.scanSourceCamera));
      await tester.pumpAndSettle();
      expect((await tester.runAsync(() => container.read(ocrSettingsStoreProvider).read()))!.scanCount, 1);

      // The add form is open with the proposed items, as an unsaved restaurant bill.
      await reveal(tester, find.text(l10n.expenseItemizedItemsTitle), 300);
      expect(find.text('Tea'), findsOneWidget);
      expect(find.text('Cake'), findsOneWidget);
      expect((await tester.runAsync(() => http.get('/groups/$gid/expenses')))!.data['items'] as List, isEmpty, reason: 'the scan saves nothing');

      // Nobody is assigned: the bill is incomplete, so there is no total to compare yet.
      expect(find.text(l10n.expenseItemizedIncomplete), findsOneWidget);

      // The user assigns members: both items to Asem.
      await assignAsem(tester, l10n, ['Tea', 'Cake']);
      await settle(tester);
      await reveal(tester, find.text(l10n.expenseBreakdownTitle), 300);
      await tester.pumpAndSettle();
      final matches = find.textContaining(l10n.scanTotalMatches('').split('(').first.trim(), findRichText: true);
      await reveal(tester, matches, 150);
      expect(find.textContaining(l10n.scanTotalMatches('').split('(').first.trim(), findRichText: true), findsOneWidget);
      expect(find.textContaining(l10n.scanTotalDiffers('').split('(').first.trim(), findRichText: true), findsNothing);

      // Scan again from the editor: it asks before replacing what is there, and the new printed total differs.
      await reveal(tester, find.text(l10n.scanReceiptAction), -300);
      await tester.tap(find.text(l10n.scanReceiptAction));
      await tester.pumpAndSettle();
      expect(find.text(l10n.scanReplaceTitle), findsOneWidget);
      await tester.tap(find.text(l10n.scanReplaceConfirm));
      await tester.pumpAndSettle();
      await tester.tap(find.text(l10n.scanSourceGallery));
      await tester.pumpAndSettle();
      await settle(tester);
      await settle(tester);
      await settle(tester);
      expect(reader.received, hasLength(2), reason: 'the second scan ran');
      // The replaced items are unassigned again; assign and compare: 42.50 against the printed 50.
      await assignAsem(tester, l10n, ['Tea', 'Cake']);
      await settle(tester);
      await reveal(tester, find.text(l10n.expenseBreakdownTitle), 300);
      await tester.pumpAndSettle();
      final differs = find.textContaining(l10n.scanTotalDiffers('').split('(').first.trim(), findRichText: true);
      await reveal(tester, differs, 150);
      expect(find.textContaining(l10n.scanTotalDiffers('').split('(').first.trim(), findRichText: true), findsOneWidget);
      expect((await tester.runAsync(() => http.get('/groups/$gid/expenses')))!.data['items'] as List, isEmpty);
    });
  }
}
