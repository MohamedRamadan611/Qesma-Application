import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../prefs/preference_store.dart';

/// Key of the stored appearance.
const String kThemeModePref = 'theme_mode';

/// Tests switch this off so no stored appearance is read.
final themeModeAutoLoadProvider = Provider<bool>((ref) => true);

/// Light, dark, or whatever the phone says (the default). The choice applies at once and is
/// remembered on the device like the language; signing out keeps it.
class ThemeModeController extends Notifier<ThemeMode> {
  bool _chosen = false;

  @override
  ThemeMode build() {
    if (ref.read(themeModeAutoLoadProvider)) unawaited(_load());
    return ThemeMode.system;
  }

  Future<void> _load() async {
    final stored = await ref.read(preferenceStoreProvider).read(kThemeModePref);
    if (!ref.mounted || _chosen) return;
    final mode = _parse(stored);
    if (mode != null) state = mode;
  }

  static ThemeMode? _parse(String? value) => switch (value) {
        'system' => ThemeMode.system,
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => null,
      };

  /// Applies [mode] now (no restart) and remembers it.
  Future<void> choose(ThemeMode mode) async {
    _chosen = true;
    state = mode;
    await ref.read(preferenceStoreProvider).write(kThemeModePref, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(ThemeModeController.new);
