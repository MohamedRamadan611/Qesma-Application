import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/theme/tokens.dart';
import 'package:qesma/core/widgets/widgets.dart';

import '../../support/test_app.dart';

String _t(Config c, String ar, String en) => c.locale.languageCode == 'ar' ? ar : en;

void main() {
  setUpAll(loadAppFonts);

  group('AppButton', () {
    for (final c in allConfigs) {
      group(c.name, () {
        testWidgets('every variant: min 48 px high, taps work, no overflow, long label wraps', (tester) async {
          var taps = 0;
          final label = _t(c, 'تسجيل سداد نقدي لعضو في المجموعة بالكامل', 'Record a cash payment for a group member in full');
          await pumpApp(
            tester,
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  for (final v in AppButtonVariant.values) ...[
                    AppButton(label: label, variant: v, icon: Icons.check, onPressed: () => taps++),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            locale: c.locale,
            textScale: c.textScale,
          );
          expect(tester.takeException(), isNull);
          for (final button in find.byWidgetPredicate((w) => w is FilledButton || w is OutlinedButton || w is TextButton).evaluate()) {
            expect(tester.getSize(find.byWidget(button.widget)).height, greaterThanOrEqualTo(kMinTouch));
          }
          await tester.tap(find.byType(FilledButton).first);
          expect(taps, 1);
        });

        testWidgets('loading: ignores taps (no double submit) and says "loading"', (tester) async {
          var taps = 0;
          final handle = tester.ensureSemantics();
          await pumpApp(
            tester,
            Center(child: AppButton(label: 'x', loading: true, onPressed: () => taps++)),
            locale: c.locale,
            textScale: c.textScale,
          );
          await tester.tap(find.byType(FilledButton), warnIfMissed: false);
          expect(taps, 0);
          expect(find.byType(CircularProgressIndicator), findsOneWidget);
          expect(tester.getSemantics(find.byType(AppButton)).label, contains(_t(c, 'جاري التحميل', 'Loading')));
          expect(tester.takeException(), isNull);
          handle.dispose();
        });
      });
    }

    testWidgets('disabled when onPressed is null', (tester) async {
      await pumpApp(tester, const Center(child: AppButton(label: 'x', onPressed: null)));
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);
    });

    testWidgets('destructive uses the error colour', (tester) async {
      await pumpApp(tester, Center(child: AppButton(label: 'x', variant: AppButtonVariant.destructive, onPressed: () {})));
      final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
      expect(style.backgroundColor!.resolve({}), QesmaColors.error);
    });
  });

  group('AppTextField', () {
    for (final c in allConfigs) {
      group(c.name, () {
        testWidgets('label above the field, counter in Western digits, error text, no overflow', (tester) async {
          final controller = TextEditingController(text: _t(c, 'عاصم', 'Asem'));
          addTearDown(controller.dispose);
          await pumpApp(
            tester,
            Padding(
              padding: const EdgeInsets.all(16),
              child: AppTextField(
                controller: controller,
                label: _t(c, 'اسم العضو داخل الجروب', 'Member name'),
                maxLength: 40,
                errorText: _t(c, 'الاسم «عاصم» موجود قبل كده. جرّب تضيف اللقب عشان نفرّق بينهم.', 'That name already exists in this group. Try adding a surname.'),
              ),
            ),
            locale: c.locale,
            textScale: c.textScale,
          );
          expect(tester.takeException(), isNull);
          expect(find.text('4/40'), findsOneWidget, reason: 'counter uses Western digits even in Arabic');
          expect(tester.getTopLeft(find.text(_t(c, 'اسم العضو داخل الجروب', 'Member name'))).dy,
              lessThan(tester.getTopLeft(find.byType(TextField)).dy));
          expect(find.textContaining(_t(c, 'موجود قبل كده', 'already exists')), findsOneWidget);
        });
      });
    }

    testWidgets('counter follows typing and never shows Arabic-Indic digits', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpApp(tester, Padding(padding: const EdgeInsets.all(16), child: AppTextField(controller: controller, label: 'x', maxLength: 60)));
      expect(find.text('0/60'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'مرحبا');
      await tester.pump();
      expect(find.text('5/60'), findsOneWidget);
    });

    testWidgets('limit is counted in code points (like the backend), never splitting an emoji', (tester) async {
      final controller = TextEditingController();
      addTearDown(controller.dispose);
      await pumpApp(tester, Padding(padding: const EdgeInsets.all(16), child: AppTextField(controller: controller, label: 'x', maxLength: 5)));
      await tester.enterText(find.byType(TextField), 'a\u{1F600}b\u{1F600}c\u{1F600}d');
      await tester.pump();
      expect(controller.text.runes.length, 5);
      expect(controller.text, 'a\u{1F600}b\u{1F600}c');
      expect(find.text('5/5'), findsOneWidget);
    });

    test('CodePointLimitFormatter leaves short text alone and cuts long text', () {
      const f = CodePointLimitFormatter(3);
      const empty = TextEditingValue.empty;
      expect(f.formatEditUpdate(empty, const TextEditingValue(text: 'ab')).text, 'ab');
      expect(f.formatEditUpdate(empty, const TextEditingValue(text: 'abcdef')).text, 'abc');
      expect(codePointCount('a\u{1F600}'), 2);
    });

    testWidgets('clear button empties the field, tells the owner, and disappears', (tester) async {
      final controller = TextEditingController(text: 'abc');
      addTearDown(controller.dispose);
      String? changed;
      await pumpApp(tester, Padding(padding: const EdgeInsets.all(16), child: AppTextField(controller: controller, label: 'x', onChanged: (v) => changed = v)));
      await tester.tap(find.byTooltip('مسح النص'));
      await tester.pump();
      expect(controller.text, isEmpty);
      expect(changed, '');
      expect(find.byTooltip('مسح النص'), findsNothing);
    });

    testWidgets('the clear button is a 48 px target', (tester) async {
      final controller = TextEditingController(text: 'abc');
      addTearDown(controller.dispose);
      await pumpApp(tester, Padding(padding: const EdgeInsets.all(16), child: AppTextField(controller: controller, label: 'x')));
      final size = tester.getSize(find.byType(IconButton));
      expect(size.width, greaterThanOrEqualTo(kMinTouch));
      expect(size.height, greaterThanOrEqualTo(kMinTouch));
    });
  });

  group('Chips and tabs', () {
    testWidgets('choice chip: tap toggles, selected shows a check (not colour alone), 48 px high', (tester) async {
      bool? changed;
      await pumpApp(
        tester,
        Center(child: AppChoiceChip(label: 'رحلة', selected: false, onSelected: (v) => changed = v)),
      );
      expect(find.byIcon(Icons.check), findsNothing);
      expect(tester.getSize(find.byType(InkWell)).height, greaterThanOrEqualTo(kMinTouch));
      await tester.tap(find.text('رحلة'));
      expect(changed, isTrue);

      await pumpApp(tester, Center(child: AppChoiceChip(label: 'رحلة', selected: true, onSelected: (_) {})));
      expect(find.byIcon(Icons.check), findsOneWidget);
    });

    testWidgets('selection and role are exposed to screen readers', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, Center(child: AppChoiceChip(label: 'رحلة', selected: true, onSelected: (_) {})));
      final node = tester.getSemantics(find.byType(AppChoiceChip));
      expect(node, isSemantics(isSelected: true, isButton: true));
      handle.dispose();
    });

    for (final c in allConfigs) {
      testWidgets('segmented tabs at ${c.name}: logical order follows the layout direction, taps select, 48 px', (tester) async {
        int? selected;
        final labels = [_t(c, 'المصاريف', 'Expenses'), _t(c, 'الأرصدة', 'Balances'), _t(c, 'الأعضاء', 'Members')];
        await pumpApp(
          tester,
          Padding(
            padding: const EdgeInsets.all(16),
            child: AppSegmentedTabs(items: [for (final l in labels) AppTabItem(label: l)], selectedIndex: 0, onChanged: (i) => selected = i),
          ),
          locale: c.locale,
          textScale: c.textScale,
        );
        expect(tester.takeException(), isNull);
        final x = [for (final l in labels) tester.getCenter(find.text(l)).dx];
        if (c.locale.languageCode == 'ar') {
          expect(x[0], greaterThan(x[1]), reason: 'ar: first tab on the right');
          expect(x[1], greaterThan(x[2]));
        } else {
          expect(x[0], lessThan(x[1]), reason: 'en: first tab on the left');
          expect(x[1], lessThan(x[2]));
        }
        for (final inkWell in tester.widgetList(find.byType(InkWell))) {
          expect(tester.getSize(find.byWidget(inkWell)).height, greaterThanOrEqualTo(kMinTouch));
        }
        await tester.tap(find.text(labels[2]));
        expect(selected, 2);
      });
    }

    testWidgets('tabs expose "selected" and one exclusive group', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        AppSegmentedTabs(items: const [AppTabItem(label: 'أ'), AppTabItem(label: 'ب')], selectedIndex: 1, onChanged: (_) {}),
      );
      expect(tester.getSemantics(find.bySemanticsLabel('ب')), isSemantics(isSelected: true));
      expect(tester.getSemantics(find.bySemanticsLabel('أ')), isNot(isSemantics(isSelected: true)));
      handle.dispose();
    });

    for (final c in allConfigs) {
      testWidgets('tags fit at ${c.name}', (tester) async {
        await pumpApp(
          tester,
          Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(spacing: 8, children: [
              for (final tone in AppTagTone.values) AppTag(label: _t(c, 'رحلة', 'Trip'), tone: tone, icon: Icons.beach_access),
            ]),
          ),
          locale: c.locale,
          textScale: c.textScale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });
}
