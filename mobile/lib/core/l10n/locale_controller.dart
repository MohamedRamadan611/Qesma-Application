import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs/preference_store.dart';

/// Tests switch this off so no stored language is read.
final localeAutoLoadProvider = Provider<bool>((ref) => true);

/// The app language. Arabic is the default and always wins on first launch, whatever the device
/// language is (Arabic-first product). The in-app choice (Arabic / English) is applied at once
/// and remembered on the device; a stored value replaces the default shortly after launch.
class LocaleController extends Notifier<Locale> {
  bool _chosen = false;

  @override
  Locale build() {
    if (ref.read(localeAutoLoadProvider)) unawaited(_load());
    return const Locale('ar');
  }

  Future<void> _load() async {
    final stored = await ref.read(preferenceStoreProvider).read(kLocalePref);
    if (!ref.mounted || _chosen) return;
    if (stored == 'ar' || stored == 'en') state = Locale(stored!);
  }

  /// Applies [locale] now (the layout flips between right-to-left and left-to-right) and remembers it.
  void set(Locale locale) {
    _chosen = true;
    state = locale;
  }

  /// The user's choice in the language sheet: like [set], and persisted.
  Future<void> choose(Locale locale) async {
    set(locale);
    await ref.read(preferenceStoreProvider).write(kLocalePref, locale.languageCode);
  }
}

final localeProvider = NotifierProvider<LocaleController, Locale>(LocaleController.new);
