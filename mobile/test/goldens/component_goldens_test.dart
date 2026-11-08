import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qesma/core/widgets/widgets.dart';

import '../support/test_app.dart';

/// Golden images of six key components at 360x800 (Arabic, RTL, text scale 1.0).
///
/// Update after an intentional visual change:
///   flutter test --update-goldens test/goldens
/// then review the PNG diffs in git before committing.
///
/// Fonts are loaded from assets/fonts, so text is real. A 0.5% pixel tolerance absorbs
/// anti-aliasing differences between operating systems (developer Windows vs CI Linux);
/// anything bigger fails.
class _TolerantComparator extends LocalFileComparator {
  _TolerantComparator(super.testFile);

  static const double tolerance = 0.005;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final result = await GoldenFileComparator.compareLists(imageBytes, await getGoldenBytes(golden));
    if (result.passed || result.diffPercent <= tolerance) return true;
    final error = await generateFailureOutput(result, golden, basedir);
    throw FlutterError(error);
  }
}

void main() {
  setUpAll(() async {
    await loadAppFonts();
    final current = goldenFileComparator as LocalFileComparator;
    goldenFileComparator = _TolerantComparator(current.basedir.resolve('component_goldens_test.dart'));
  });

  Future<void> check(WidgetTester tester, String name) =>
      expectLater(find.byType(MaterialApp), matchesGoldenFile('$name.png'));

  testWidgets('balances: avatar rows with status chips and amounts (P9-01)', (tester) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const MoneyText(106179, size: MoneySize.large),
            const SizedBox(height: 4),
            Text('إجمالي مصاريف الجروب', style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 16),
            for (final (id, name, net) in const [
              ('1', 'محمد مصطفى', 10000),
              ('2', 'محسن فؤاد', -2000),
              ('3', 'عاصم جمال', -8000),
              ('4', 'زياد إبراهيم', 0),
            ]) ...[
              AppCard(
                child: Row(children: [
                  MemberAvatar(memberId: id, name: name, size: 44),
                  const SizedBox(width: 12),
                  Expanded(child: Text(name, style: Theme.of(context).textTheme.titleMedium)),
                  BalanceStatusChip(net),
                ]),
              ),
              const SizedBox(height: 12),
            ],
            const MoneyText(-8050, signed: true, colorBySign: true),
          ],
        ),
      ),
    );
    await check(tester, 'balances_ar');
  });

  testWidgets('buttons: every variant, an icon, loading and disabled', (tester) async {
    await pumpApp(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          AppButton(label: 'تأكيد تسجيل السداد', icon: Icons.check, onPressed: () {}),
          const SizedBox(height: 12),
          AppButton(label: 'تسجيل سداد', variant: AppButtonVariant.secondary, onPressed: () {}),
          const SizedBox(height: 12),
          AppButton(label: 'امسح', variant: AppButtonVariant.destructive, onPressed: () {}),
          const SizedBox(height: 12),
          AppButton(label: 'إلغاء وتراجع', variant: AppButtonVariant.text, onPressed: () {}),
          const SizedBox(height: 12),
          AppButton(label: 'جاري الحفظ', loading: true, onPressed: () {}),
          const SizedBox(height: 12),
          const AppButton(label: 'غير متاح', onPressed: null),
        ]),
      ),
    );
    await check(tester, 'buttons_ar');
  });

  testWidgets('text fields: empty with counter, filled, and the duplicate-name error', (tester) async {
    final empty = TextEditingController();
    final name = TextEditingController(text: 'عاصم');
    addTearDown(empty.dispose);
    addTearDown(name.dispose);
    await pumpApp(
      tester,
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          AppTextField(controller: empty, label: 'اسم الجروب', hint: 'مثال: رحلة دهب', maxLength: 60),
          const SizedBox(height: 16),
          AppTextField(
            controller: name,
            label: 'اسم العضو داخل الجروب',
            maxLength: 40,
            errorText: 'الاسم «عاصم» موجود قبل كده في المجموعة. جرّب تضيف اللقب عشان نفرّق بينهم.',
          ),
        ]),
      ),
    );
    await check(tester, 'text_fields_ar');
  });

  testWidgets('add-member sheet (P4): title, field with error, sticky save button', (tester) async {
    final name = TextEditingController(text: 'عاصم');
    addTearDown(name.dispose);
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Center(
          child: TextButton(
            onPressed: () => showAppBottomSheet<void>(
              context,
              title: 'إضافة عضو جديد',
              subtitle: 'أضف اسم الصديق ليتمكن المنظم من توزيع المصاريف عليه بسهولة.',
              action: Column(mainAxisSize: MainAxisSize.min, children: [
                AppButton(label: 'حفظ العضو', icon: Icons.check, onPressed: () {}),
                AppButton(label: 'إلغاء الأمر', variant: AppButtonVariant.text, onPressed: () {}),
              ]),
              child: AppTextField(
                controller: name,
                label: 'اسم العضو داخل الجروب',
                maxLength: 40,
                errorText: 'الاسم «عاصم» موجود قبل كده. جرّب تضيف اللقب.',
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await check(tester, 'add_member_sheet_ar');
  });

  testWidgets('skeleton list while loading (P11-03)', (tester) async {
    await pumpApp(tester, const SkeletonList(itemCount: 6));
    await check(tester, 'skeleton_ar');
  });

  testWidgets('error state with a request id (P11-02)', (tester) async {
    await pumpApp(tester, ErrorState(onRetry: () {}, requestId: '880c9476-6788-4ad5-a104-d721303361b1'));
    await check(tester, 'error_state_ar');
  });
}
