import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app language. Arabic is the default and always wins on first launch, whatever the
/// device language is (Arabic-first product). FL8 adds the in-app language switch and
/// persistence on top of this provider.
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => const Locale('ar');

  void set(Locale locale) => state = locale;
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
