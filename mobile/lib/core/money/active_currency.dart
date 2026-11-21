import '../l10n/generated/app_localizations.dart';

/// A currency a group can use. Amounts stay integer minor units (2 decimals), so only 2-decimal currencies are listed;
/// there is no conversion between currencies (STANDALONE_SPEC: one currency per group).
class CurrencyOption {
  const CurrencyOption(this.code, this.nameAr, this.nameEn);

  final String code;
  final String nameAr;
  final String nameEn;

  String name(bool arabic) => arabic ? nameAr : nameEn;
}

const String kDefaultCurrency = 'EGP';

/// EGP first: it is the default.
const List<CurrencyOption> kCurrencyOptions = [
  CurrencyOption('EGP', 'جنيه مصري', 'Egyptian pound'),
  CurrencyOption('SAR', 'ريال سعودي', 'Saudi riyal'),
  CurrencyOption('AED', 'درهم إماراتي', 'UAE dirham'),
  CurrencyOption('QAR', 'ريال قطري', 'Qatari riyal'),
  CurrencyOption('USD', 'دولار أمريكي', 'US dollar'),
  CurrencyOption('EUR', 'يورو', 'Euro'),
  CurrencyOption('GBP', 'جنيه إسترليني', 'Pound sterling'),
];

/// The currency of the group being shown. Amounts are drawn with its label ("ج.م" for EGP, the code otherwise).
/// Set whenever a group is loaded; EGP until then.
abstract final class ActiveCurrency {
  static String code = kDefaultCurrency;

  static void set(String? value) => code = (value == null || value.isEmpty) ? kDefaultCurrency : value;

  /// "ج.م" / "EGP" for the Egyptian pound (the localized suffix), else the ISO code.
  static String label(AppLocalizations l10n) => code == kDefaultCurrency ? l10n.moneyCurrency : code;
}
