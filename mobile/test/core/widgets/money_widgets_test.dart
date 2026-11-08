import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/theme/tokens.dart';
import 'package:qesma/core/widgets/widgets.dart';

import '../../support/test_app.dart';

void main() {
  setUpAll(loadAppFonts);

  group('MoneyText', () {
    testWidgets('ar: Western digits, grouping, non-breaking space and the Arabic currency', (tester) async {
      await pumpApp(tester, const Center(child: MoneyText(106179)));
      expect(find.text('${isolated('1,061.79')}$nbspCharج.م'), findsOneWidget);
    });

    testWidgets('en: same digits, EGP suffix', (tester) async {
      await pumpApp(tester, const Center(child: MoneyText(106179)), locale: const Locale('en'));
      expect(find.text('${isolated('1,061.79')}${nbspChar}EGP'), findsOneWidget);
    });

    testWidgets('signed amounts keep their sign inside the isolate (never reordered in RTL)', (tester) async {
      await pumpApp(
        tester,
        const Column(children: [MoneyText(10000, signed: true), MoneyText(-2000, signed: true), MoneyText(0, signed: true)]),
      );
      expect(find.text('${isolated('+100.00')}$nbspCharج.م'), findsOneWidget);
      expect(find.text('${isolated('−${'20.00'}')}$nbspCharج.م'), findsOneWidget);
      expect(find.text('${isolated('0.00')}$nbspCharج.م'), findsOneWidget);
    });

    testWidgets('visual order in Arabic: the sign stays glued to the digits, the currency sits on the far side', (tester) async {
      await pumpApp(tester, const Center(child: MoneyText(-8050, signed: true, size: MoneySize.large)));
      final rich = tester.renderObject<RenderParagraph>(find.byType(RichText).first);
      final text = rich.text.toPlainText();
      double caretX(int index) => rich.getOffsetForCaret(TextPosition(offset: index), Rect.zero).dx;

      final minusAt = text.indexOf('−');
      final firstDigitAt = text.indexOf('8');
      final currencyAt = text.indexOf('ج');
      // Left-to-right isolate: the minus is immediately LEFT of the digits (it never jumps to the right end).
      expect(caretX(minusAt), lessThan(caretX(firstDigitAt)));
      // Arabic reading order: number first (on the right), currency after it (to its left).
      expect(caretX(currencyAt), lessThan(caretX(minusAt)));
    });

    testWidgets('visual order in English: number then currency, left to right', (tester) async {
      await pumpApp(tester, const Center(child: MoneyText(-8050, signed: true)), locale: const Locale('en'));
      final rich = tester.renderObject<RenderParagraph>(find.byType(RichText).first);
      final text = rich.text.toPlainText();
      double caretX(int index) => rich.getOffsetForCaret(TextPosition(offset: index), Rect.zero).dx;
      expect(caretX(text.indexOf('−')), lessThan(caretX(text.indexOf('8'))));
      expect(caretX(text.indexOf('8')), lessThan(caretX(text.indexOf('E'))));
    });

    testWidgets('no Arabic-Indic digit is ever drawn, in either language', (tester) async {
      for (final locale in const [Locale('ar'), Locale('en')]) {
        await pumpApp(tester, const Column(children: [MoneyText(123456789), MoneyText(-5, signed: true)]), locale: locale);
        final texts = tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? '').join();
        expect(hasNonWesternDigits(texts), isFalse, reason: '${locale.languageCode}: $texts');
      }
    });

    testWidgets('screen readers hear words, not symbols (ar)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const Column(children: [MoneyText(-8000), MoneyText(8050), MoneyText(50), MoneyText(100), MoneyText(0)]),
      );
      expect(find.bySemanticsLabel('سالب 80 جنيه'), findsOneWidget);
      expect(find.bySemanticsLabel('80 جنيه و50 قرش'), findsOneWidget);
      expect(find.bySemanticsLabel('50 قرش'), findsOneWidget);
      expect(find.bySemanticsLabel('1 جنيه'), findsOneWidget);
      expect(find.bySemanticsLabel('0 جنيه'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('screen readers hear words, not symbols (en)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const Column(children: [MoneyText(-8000), MoneyText(8050)]), locale: const Locale('en'));
      expect(find.bySemanticsLabel('minus 80 pounds'), findsOneWidget);
      expect(find.bySemanticsLabel('80 pounds and 50 piasters'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('colorBySign uses the balance colours and still carries the sign', (tester) async {
      await pumpApp(
        tester,
        const Column(children: [MoneyText(500, signed: true, colorBySign: true), MoneyText(-500, signed: true, colorBySign: true)]),
      );
      final owed = tester.widget<Text>(find.textContaining('+5.00'));
      final owes = tester.widget<Text>(find.textContaining('5.00').last);
      expect(owed.style?.color, QesmaColors.owed);
      expect(owes.style?.color, QesmaColors.owes);
      expect(find.textContaining('−'), findsOneWidget);
    });

    for (final c in allConfigs) {
      testWidgets('large amount fits at ${c.name}', (tester) async {
        await pumpApp(tester, const Center(child: MoneyText(1000000000000, size: MoneySize.large)), locale: c.locale, textScale: c.textScale);
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('BalanceStatusChip', () {
    testWidgets('owed: word له, plus sign and the owed colours', (tester) async {
      await pumpApp(tester, const Center(child: BalanceStatusChip(10000)));
      expect(find.text('له ${isolated('+100.00')}$nbspCharج.م'), findsOneWidget);
      final box = tester.widget<DecoratedBox>(find.descendant(of: find.byType(BalanceStatusChip), matching: find.byType(DecoratedBox)));
      expect((box.decoration as BoxDecoration).color, QesmaColors.owedBg);
    });

    testWidgets('owes: word عليه, minus sign and the owes colours', (tester) async {
      await pumpApp(tester, const Center(child: BalanceStatusChip(-2000)));
      expect(find.text('عليه ${isolated('−${'20.00'}')}$nbspCharج.م'), findsOneWidget);
      final box = tester.widget<DecoratedBox>(find.descendant(of: find.byType(BalanceStatusChip), matching: find.byType(DecoratedBox)));
      expect((box.decoration as BoxDecoration).color, QesmaColors.owesBg);
    });

    testWidgets('settled: word خالص and neutral colours', (tester) async {
      await pumpApp(tester, const Center(child: BalanceStatusChip(0)));
      expect(find.text('خالص ${isolated('0.00')}$nbspCharج.م'), findsOneWidget);
      final box = tester.widget<DecoratedBox>(find.descendant(of: find.byType(BalanceStatusChip), matching: find.byType(DecoratedBox)));
      expect((box.decoration as BoxDecoration).color, QesmaColors.settledBg);
    });

    testWidgets('the three states are told apart by words even without colour', (tester) async {
      await pumpApp(tester, const Column(children: [BalanceStatusChip(1), BalanceStatusChip(-1), BalanceStatusChip(0)]));
      final words = ['له', 'عليه', 'خالص'];
      for (final w in words) {
        expect(find.textContaining(w), findsOneWidget);
      }
    });

    testWidgets('spoken text (ar): "له 100 جنيه", "عليه 80 جنيه", settled', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const Column(children: [BalanceStatusChip(10000), BalanceStatusChip(-8000), BalanceStatusChip(0)]));
      expect(find.bySemanticsLabel('له 100 جنيه'), findsOneWidget);
      expect(find.bySemanticsLabel('عليه 80 جنيه'), findsOneWidget);
      expect(find.bySemanticsLabel('خالص، مفيش حاجة مستحقة'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('spoken text (en)', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(tester, const Column(children: [BalanceStatusChip(10000), BalanceStatusChip(-8050)]), locale: const Locale('en'));
      expect(find.bySemanticsLabel('Owed 100 pounds'), findsOneWidget);
      expect(find.bySemanticsLabel('Owes 80 pounds and 50 piasters'), findsOneWidget);
      handle.dispose();
    });

    for (final c in allConfigs) {
      testWidgets('fits at ${c.name}', (tester) async {
        await pumpApp(
          tester,
          const Padding(padding: EdgeInsets.all(16), child: Wrap(spacing: 8, children: [BalanceStatusChip(10000), BalanceStatusChip(-8000)])),
          locale: c.locale,
          textScale: c.textScale,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('MemberAvatar', () {
    test('the same id always gets the same tint, and ids spread over the palette', () {
      expect(avatarTintIndex('11111111-1111-1111-1111-111111111111'), avatarTintIndex('11111111-1111-1111-1111-111111111111'));
      final used = {for (var i = 0; i < 200; i++) avatarTintIndex('member-$i')};
      expect(used, hasLength(QesmaColors.avatarTints.length));
      for (final index in used) {
        expect(index, inInclusiveRange(0, QesmaColors.avatarTints.length - 1));
      }
    });

    test('initial is the first letter: Arabic as is, Latin upper-cased, blank gives ?', () {
      expect(avatarInitial('عاصم'), 'ع');
      expect(avatarInitial('  mohamed'), 'M');
      expect(avatarInitial('3ali'), '3');
      expect(avatarInitial('\u{1F600}x'), 'X');
      expect(avatarInitial(''), '?');
      expect(avatarInitial('   '), '?');
    });

    testWidgets('is decoration unless a semantic label is given', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpApp(
        tester,
        const Column(children: [
          MemberAvatar(memberId: 'a', name: 'محمد'),
          MemberAvatar(memberId: 'b', name: 'عاصم', semanticLabel: 'عاصم'),
        ]),
      );
      expect(find.bySemanticsLabel('عاصم'), findsOneWidget);
      expect(find.bySemanticsLabel('م'), findsNothing);
      handle.dispose();
    });
  });
}
