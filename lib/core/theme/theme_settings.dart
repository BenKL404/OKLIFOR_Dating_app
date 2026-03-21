import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// À `true`, l’app reste en [ThemeMode.dark] (clair et système ignorés).
const bool kOklLightThemeBlocked = false;

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError('sharedPreferencesProvider doit être surchargé dans main()');
});

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'okl_theme_mode';

  @override
  ThemeMode build() {
    if (kOklLightThemeBlocked) return ThemeMode.dark;
    final prefs = ref.read(sharedPreferencesProvider);
    return _decode(prefs.getString(_key));
  }

  ThemeMode _decode(String? raw) {
    return switch (raw) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.dark,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await ref.read(sharedPreferencesProvider).setString(_key, mode.name);
    state = kOklLightThemeBlocked ? ThemeMode.dark : mode;
  }
}
