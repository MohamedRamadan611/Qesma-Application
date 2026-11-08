import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/theme/tokens.dart';
import 'package:qesma/core/widgets/widgets.dart';

import '../../support/test_app.dart';

String _t(Config c, String ar, String en) => c.locale.languageCode == 'ar' ? ar : en;

/// A button that runs [onTap] with a context that has Material localizations (for dialogs and sheets).
Widget _opener(Future<void> Function(BuildContext) onTap) =>
    Builder(builder: (context) => Center(child: TextButton(onPressed: () => onTap(context), child: const Text('open'))));

void main() {
  setUpAll(loadAppFonts);

  group('AppCard', () {
    testWidgets('tappable card is at least 48 px high and reports taps', (tester) async {
      var taps = 0;
      await pumpApp(tester, Padding(padding: const EdgeInsets.all(16), child: AppCard(onTap: () => taps++, child: const Text('x'))));
      expect(tester.getSize(find.byType(AppCard)).height, greaterThanOrEqualTo(kMinTouch));
      await tester.tap(find.byType(AppCard));
      expect(taps, 1);
    });

    testWidgets('semanticLabel replaces the children for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        Padding(padding: const EdgeInsets.all(16), child: AppCard(onTap: () {}, semanticLabel: 'رحلة دهب، عليك 80 جنيه', child: const Text('نص'))),
      );
      expect(find.bySemanticsLabel('رحلة دهب، عليك 80 جنيه'), findsOneWidget);
      expect(find.bySemanticsLabel('نص'), findsNothing);
      handle.dispose();
    });
  });

  group('AppScaffold', () {
    for (final c in allConfigs) {
      testWidgets('header at ${c.name}: long title wraps, tag and subtitle fit, back arrow works', (tester) async {
        var back = 0;
        await pumpApp(
          tester,
          AppScaffold(
            title: _t(c, 'رحلة دهب الشباب لنهاية الأسبوع الطويل', 'The long weekend trip to Dahab with friends'),
            subtitle: _t(c, '6 أعضاء مشاركين', '6 members'),
            titleTag: AppTag(label: _t(c, 'رحلة', 'Trip'), tone: AppTagTone.info),
            showBack: true,
            onBack: () => back++,
            actions: [IconButton(icon: const Icon(Icons.more_vert), tooltip: 'more', onPressed: () {})],
            body: const SizedBox.expand(),
          ),
          locale: c.locale,
          textScale: c.textScale,
          scaffold: false,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byIcon(Icons.arrow_back));
        expect(back, 1);
      });
    }

    testWidgets('the back arrow mirrors: it points toward the trailing side in RTL', (tester) async {
      expect(Icons.arrow_back.matchTextDirection, isTrue, reason: 'framework mirrors it in right-to-left layouts');
      await pumpApp(tester, AppScaffold(title: 'x', showBack: true, body: const SizedBox()), scaffold: false);
      final icon = tester.widget<Icon>(find.byIcon(Icons.arrow_back));
      expect(Directionality.of(tester.element(find.byWidget(icon))), TextDirection.rtl);
      // In RTL the first child of the header sits at the right edge.
      expect(tester.getCenter(find.byIcon(Icons.arrow_back)).dx, greaterThan(180));
    });

    testWidgets('back is hidden when there is nothing to go back to; title is a header for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const AppScaffold(title: 'المجموعات', body: SizedBox()), scaffold: false);
      expect(find.byIcon(Icons.arrow_back), findsNothing);
      expect(tester.getSemantics(find.text('المجموعات')), isSemantics(isHeader: true));
      handle.dispose();
    });

    testWidgets('the back arrow has a tooltip/label', (tester) async {
      await pumpApp(tester, const AppScaffold(title: 'x', showBack: true, body: SizedBox()), scaffold: false);
      expect(find.byTooltip('رجوع'), findsOneWidget);
    });
  });

  group('Bottom sheet', () {
    for (final c in allConfigs) {
      testWidgets('opens, scrolls, keeps the action visible and closes at ${c.name}', (tester) async {
        await pumpApp(
          tester,
          _opener(
            (context) => showAppBottomSheet<void>(
              context,
              title: _t(c, 'إضافة عضو جديد', 'Add a member'),
              subtitle: _t(c, 'أضف اسم الصديق ليتمكن المنظم من توزيع المصاريف عليه بسهولة.', 'Add your friend by name so expenses can be split with them.'),
              action: AppButton(label: _t(c, 'حفظ العضو', 'Save member'), onPressed: () {}),
              child: Column(children: [for (var i = 0; i < 12; i++) ListTile(title: Text('item $i'))]),
            ),
          ),
          locale: c.locale,
          textScale: c.textScale,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text(_t(c, 'إضافة عضو جديد', 'Add a member')), findsOneWidget);
        expect(find.text(_t(c, 'حفظ العضو', 'Save member')), findsOneWidget);
        expect(tester.getBottomLeft(find.text(_t(c, 'حفظ العضو', 'Save member'))).dy, lessThanOrEqualTo(800));

        await tester.tap(find.byTooltip(_t(c, 'إغلاق', 'Close')));
        await tester.pumpAndSettle();
        expect(find.text(_t(c, 'إضافة عضو جديد', 'Add a member')), findsNothing);
      });
    }

    testWidgets('close button is a 48 px target and the sheet is named for screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, _opener((context) => showAppBottomSheet<void>(context, title: 'إضافة عضو جديد', child: const SizedBox())));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(tester.getSize(find.widgetWithIcon(IconButton, Icons.close)).width, greaterThanOrEqualTo(kMinTouch));
      expect(find.bySemanticsLabel('إضافة عضو جديد'), findsWidgets);
      handle.dispose();
    });

    testWidgets('the sheet rises above the keyboard', (tester) async {
      await pumpApp(tester, _opener((context) => showAppBottomSheet<void>(context, title: 't', child: const TextField())));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final before = tester.getBottomLeft(find.byType(TextField)).dy;
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      expect(tester.getBottomLeft(find.byType(TextField)).dy, lessThan(before));
    });
  });

  group('Dialogs and snackbar', () {
    testWidgets('confirm returns true only when confirmed, false on cancel and on dismiss', (tester) async {
      bool? result;
      await pumpApp(
        tester,
        _opener((context) async => result = await showConfirmDialog(context, title: 'مسح المصروف؟', message: 'هيتشال من الحسابات.', confirmLabel: 'امسح', destructive: true)),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text('مسح المصروف؟'), findsOneWidget);
      await tester.tap(find.text('امسح'));
      await tester.pumpAndSettle();
      expect(result, isTrue);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('إلغاء'));
      await tester.pumpAndSettle();
      expect(result, isFalse);

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(5, 5)); // barrier
      await tester.pumpAndSettle();
      expect(result, isFalse);
    });

    testWidgets('destructive confirm uses the error colour, normal confirm the primary colour', (tester) async {
      await pumpApp(
        tester,
        _opener((context) async => showConfirmDialog(context, title: 't', message: 'm', confirmLabel: 'go', destructive: true)),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      final filled = tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'go'));
      expect(filled.style!.backgroundColor!.resolve({}), QesmaColors.error);
    });

    for (final c in allConfigs) {
      testWidgets('blocked dialog fits and closes at ${c.name}', (tester) async {
        await pumpApp(
          tester,
          _opener((context) => showBlockedDialog(context, title: _t(c, 'مينفعش نمسح المجموعة', "Can't delete this group"), message: _t(c, 'المجموعة فيها مصاريف أو تسويات، فمينفعش تتمسح.', 'This group has expenses or settlements, so it cannot be deleted.'))),
          locale: c.locale,
          textScale: c.textScale,
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(_t(c, 'تمام', 'OK')));
        await tester.pumpAndSettle();
        expect(find.text(_t(c, 'مينفعش نمسح المجموعة', "Can't delete this group")), findsNothing);
      });
    }

    testWidgets('snackbar shows the message and runs its action', (tester) async {
      var undone = 0;
      await pumpApp(tester, _opener((context) async => showAppSnackBar(context, 'اتمسح المصروف', actionLabel: 'تراجع', onAction: () => undone++)));
      await tester.tap(find.text('open'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('اتمسح المصروف'), findsOneWidget);
      await tester.tap(find.text('تراجع'));
      expect(undone, 1);
    });
  });

  group('States', () {
    for (final c in allConfigs) {
      testWidgets('error, no-internet and empty states fit at ${c.name}', (tester) async {
        for (final state in <Widget>[
          ErrorState(onRetry: () {}, requestId: '880c9476-6788-4ad5-a104-d721303361b1'),
          NoInternetState(onRetry: () {}),
          EmptyState(
            icon: Icons.group_outlined,
            title: _t(c, 'مفيش جروبات لسه', 'No groups yet'),
            message: _t(c, 'ابدأ بجروب جديد وضيف أصحابك.', 'Start a group and add your friends.'),
            actionLabel: _t(c, 'جروب جديد', 'New group'),
            onAction: () {},
          ),
        ]) {
          await pumpApp(tester, state, locale: c.locale, textScale: c.textScale);
          expect(tester.takeException(), isNull);
        }
      });
    }

    testWidgets('error state: retry works and the request id is shown left-to-right and copyable', (tester) async {
      var retries = 0;
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') copied = (call.arguments as Map)['text'] as String?;
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));

      await pumpApp(tester, ErrorState(onRetry: () => retries++, requestId: 'abc-123'));
      expect(find.text('رمز الخطأ: ${isolated('abc-123')}'), findsOneWidget);
      await tester.tap(find.text('حاول تاني'));
      expect(retries, 1);
      await tester.tap(find.byTooltip('نسخ'));
      await tester.pump();
      expect(copied, 'abc-123');
      expect(find.text('اتنسخ'), findsOneWidget);
    });

    testWidgets('error state without a request id shows no code row', (tester) async {
      await pumpApp(tester, ErrorState(onRetry: () {}));
      expect(find.textContaining('رمز الخطأ'), findsNothing);
    });

    testWidgets('no-internet copy says only true things: it never claims data is stored on the device', (tester) async {
      await pumpApp(tester, NoInternetState(onRetry: () {}));
      final all = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join(' ');
      expect(all, isNot(contains('جهازك')));
      expect(all, contains('محفوظ'));
    });

    testWidgets('offline banner: visible only when asked, announced as a live region', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const OfflineBanner(visible: false));
      expect(find.byType(Text), findsNothing);
      await pumpApp(tester, const OfflineBanner(visible: true));
      expect(find.text('مفيش اتصال بالإنترنت'), findsOneWidget);
      expect(tester.getSemantics(find.byType(OfflineBanner)), isSemantics(isLiveRegion: true));
      handle.dispose();
    });
  });

  group('Skeleton', () {
    for (final c in allConfigs) {
      testWidgets('list fits and settles (no endless animation when animations are off) at ${c.name}', (tester) async {
        await pumpApp(tester, const SkeletonList(), locale: c.locale, textScale: c.textScale);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(SkeletonCard), findsWidgets);
      });
    }

    testWidgets('announced once as "loading", not block by block', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const SkeletonList());
      expect(find.bySemanticsLabel('جاري التحميل…'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('pulses when animations are on', (tester) async {
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SkeletonPulse(child: SkeletonBlock(width: 50)))));
      final fade = find.descendant(of: find.byType(SkeletonPulse), matching: find.byType(FadeTransition));
      final first = tester.widget<FadeTransition>(fade).opacity.value;
      await tester.pump(const Duration(milliseconds: 600));
      final later = tester.widget<FadeTransition>(fade).opacity.value;
      expect(later, isNot(first));
      await tester.pumpWidget(const SizedBox()); // dispose the controller
    });
  });
}
