import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/locale_controller.dart';
import '../../theme/tokens.dart';
import '../widgets.dart';
import '../../theme/palette.dart';

/// DEBUG-ONLY component catalogue (`/_catalog`, see app_router.dart). Shows every shared
/// component with sample data, with switches for language/direction and text scale, so a
/// design review does not need feature screens. Not part of release builds; its sample
/// strings are the one place outside the ARB files allowed to hold literal text.
class ComponentCatalogue extends ConsumerStatefulWidget {
  const ComponentCatalogue({super.key});

  @override
  ConsumerState<ComponentCatalogue> createState() => _ComponentCatalogueState();
}

class _ComponentCatalogueState extends ConsumerState<ComponentCatalogue> {
  final _name = TextEditingController(text: 'عاصم');
  final _empty = TextEditingController();
  double _scale = 1;
  int _tab = 0;
  bool _chip = true;

  @override
  void dispose() {
    _name.dispose();
    _empty.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final isAr = locale.languageCode == 'ar';
    final theme = Theme.of(context);

    Widget section(String title, Widget child) => Padding(
          padding: const EdgeInsets.only(bottom: QesmaSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.textTheme.titleLarge),
              const SizedBox(height: QesmaSpacing.sm),
              child,
            ],
          ),
        );

    final body = ListView(
      padding: const EdgeInsets.all(QesmaSpacing.margin),
      children: [
        section(
          'Switches',
          Column(children: [
            AppSegmentedTabs(
              items: const [AppTabItem(label: 'العربية (RTL)'), AppTabItem(label: 'English (LTR)')],
              selectedIndex: isAr ? 0 : 1,
              onChanged: (i) => ref.read(localeProvider.notifier).set(Locale(i == 0 ? 'ar' : 'en')),
            ),
            const SizedBox(height: QesmaSpacing.sm),
            AppSegmentedTabs(
              items: const [AppTabItem(label: 'Text 1.0x'), AppTabItem(label: 'Text 2.0x')],
              selectedIndex: _scale == 1 ? 0 : 1,
              onChanged: (i) => setState(() => _scale = i == 0 ? 1 : 2),
            ),
          ]),
        ),
        section(
          'Buttons',
          Column(children: [
            AppButton(label: isAr ? 'حفظ العضو' : 'Save member', icon: Icons.check, onPressed: () {}),
            const SizedBox(height: 8),
            AppButton(label: isAr ? 'تسجيل سداد' : 'Record payment', variant: AppButtonVariant.secondary, onPressed: () {}),
            const SizedBox(height: 8),
            AppButton(label: isAr ? 'امسح' : 'Delete', variant: AppButtonVariant.destructive, onPressed: () {}),
            const SizedBox(height: 8),
            AppButton(label: isAr ? 'إلغاء' : 'Cancel', variant: AppButtonVariant.text, onPressed: () {}),
            const SizedBox(height: 8),
            AppButton(label: isAr ? 'جاري الحفظ' : 'Saving', loading: true, onPressed: () {}),
            const SizedBox(height: 8),
            const AppButton(label: 'Disabled', onPressed: null),
          ]),
        ),
        section(
          'Text field',
          Column(children: [
            AppTextField(controller: _empty, label: isAr ? 'اسم الجروب' : 'Group name', hint: isAr ? 'مثال: رحلة دهب' : 'e.g. Dahab trip', maxLength: 60),
            const SizedBox(height: QesmaSpacing.md),
            AppTextField(
              controller: _name,
              label: isAr ? 'اسم العضو داخل الجروب' : 'Member name',
              maxLength: 40,
              errorText: isAr ? 'الاسم «عاصم» موجود قبل كده في المجموعة.' : 'The name "عاصم" already exists in this group.',
            ),
          ]),
        ),
        section(
          'Chips, tabs and tags',
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, children: [
              AppChoiceChip(label: isAr ? 'رحلة' : 'Trip', selected: _chip, onSelected: (v) => setState(() => _chip = v)),
              AppChoiceChip(label: isAr ? 'سكن' : 'Housing', selected: !_chip, onSelected: (v) => setState(() => _chip = !v)),
              AppChoiceChip(label: isAr ? 'خروجة' : 'Outing', selected: false, onSelected: (_) {}),
            ]),
            const SizedBox(height: QesmaSpacing.sm),
            AppSegmentedTabs(
              items: [
                AppTabItem(label: isAr ? 'المصاريف' : 'Expenses', icon: Icons.receipt_long),
                AppTabItem(label: isAr ? 'الأرصدة' : 'Balances', icon: Icons.account_balance_wallet_outlined),
                AppTabItem(label: isAr ? 'الأعضاء' : 'Members', icon: Icons.group_outlined),
              ],
              selectedIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            const SizedBox(height: QesmaSpacing.sm),
            Wrap(spacing: 8, runSpacing: 8, children: [
              AppTag(label: isAr ? 'رحلة' : 'Trip', tone: AppTagTone.info),
              AppTag(label: isAr ? 'بالتساوي' : 'Equal', tone: AppTagTone.success),
              AppTag(label: isAr ? 'فاتورة مفصلة' : 'Itemized', tone: AppTagTone.warning),
              AppTag(label: isAr ? 'عادي' : 'Neutral'),
              AppTag(label: isAr ? 'أساسي' : 'Primary', tone: AppTagTone.primary),
            ]),
          ]),
        ),
        section(
          'Money and balances',
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const MoneyText(106179, size: MoneySize.large),
            const SizedBox(height: 4),
            const MoneyText(56179, size: MoneySize.medium),
            const SizedBox(height: 4),
            const MoneyText(-8050, signed: true, colorBySign: true),
            const SizedBox(height: QesmaSpacing.sm),
            const Wrap(spacing: 8, runSpacing: 8, children: [
              BalanceStatusChip(10000),
              BalanceStatusChip(-8000),
              BalanceStatusChip(0),
            ]),
          ]),
        ),
        section(
          'Cards and avatars',
          AppCard(
            onTap: () {},
            child: Row(children: [
              const MemberAvatar(memberId: 'm1', name: 'محمد مصطفى', size: 44),
              const SizedBox(width: QesmaSpacing.md),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(isAr ? 'محمد مصطفى' : 'Mohamed Mostafa', style: theme.textTheme.titleMedium),
                  Text(isAr ? 'دفع الفندق' : 'Paid the hotel', style: theme.textTheme.bodySmall?.copyWith(color: context.colors.textHelper)),
                ]),
              ),
              const BalanceStatusChip(10000),
            ]),
          ),
        ),
        section(
          'Avatars (tints)',
          Wrap(spacing: 8, children: [
            for (var i = 0; i < 6; i++) MemberAvatar(memberId: 'tint-$i-${i * 7}', name: ['م', 'ع', 'ك', 'ز', 'س', 'ي'][i]),
          ]),
        ),
        section(
          'Sheets, dialogs, snackbar',
          Wrap(spacing: 8, runSpacing: 8, children: [
            AppButton(
              label: 'Sheet',
              expand: false,
              variant: AppButtonVariant.secondary,
              onPressed: () => showAppBottomSheet<void>(
                context,
                title: isAr ? 'إضافة عضو جديد' : 'Add a member',
                subtitle: isAr ? 'أضف اسم الصديق ليتمكن المنظم من توزيع المصاريف عليه.' : 'Add your friend by name.',
                action: AppButton(label: isAr ? 'حفظ العضو' : 'Save member', icon: Icons.check, onPressed: () => Navigator.of(context).pop()),
                child: AppTextField(controller: TextEditingController(), label: isAr ? 'اسم العضو' : 'Name', maxLength: 40),
              ),
            ),
            AppButton(
              label: 'Confirm',
              expand: false,
              variant: AppButtonVariant.secondary,
              onPressed: () => showConfirmDialog(
                context,
                title: isAr ? 'مسح المصروف؟' : 'Delete expense?',
                message: isAr ? 'هيتشال من الحسابات.' : 'It will be removed from the balances.',
                confirmLabel: isAr ? 'امسح' : 'Delete',
                destructive: true,
              ),
            ),
            AppButton(
              label: 'Blocked',
              expand: false,
              variant: AppButtonVariant.secondary,
              onPressed: () => showBlockedDialog(
                context,
                title: isAr ? 'مينفعش نمسح المجموعة' : "Can't delete this group",
                message: isAr ? 'المجموعة فيها مصاريف أو تسويات.' : 'This group has expenses or settlements.',
              ),
            ),
            AppButton(
              label: 'Snackbar',
              expand: false,
              variant: AppButtonVariant.secondary,
              onPressed: () => showAppSnackBar(context, isAr ? 'اتمسح المصروف' : 'Expense deleted', actionLabel: isAr ? 'تمام' : 'OK'),
            ),
          ]),
        ),
        section('Offline banner', const OfflineBanner(visible: true)),
        section('Empty state', SizedBox(height: 320, child: EmptyState(icon: Icons.group_outlined, title: isAr ? 'مفيش جروبات لسه' : 'No groups yet', message: isAr ? 'ابدأ بجروب جديد وضيف أصحابك.' : 'Start a group and add friends.', actionLabel: isAr ? 'جروب جديد' : 'New group', onAction: () {}))),
        section('Error state', SizedBox(height: 460, child: ErrorState(onRetry: () {}, requestId: '880c9476-6788-4ad5-a104-d721303361b1'))),
        section('No internet state', SizedBox(height: 520, child: NoInternetState(onRetry: () {}))),
        section('Skeleton list', const SizedBox(height: 330, child: SkeletonList(itemCount: 3))),
      ],
    );

    return AppScaffold(
      title: isAr ? 'كتالوج المكوّنات' : 'Component catalogue',
      subtitle: 'debug only',
      titleTag: const AppTag(label: 'DEBUG', tone: AppTagTone.warning),
      showBack: false,
      body: MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(_scale)),
        child: body,
      ),
    );
  }
}
