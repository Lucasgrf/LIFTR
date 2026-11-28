import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:personal_fitness_os/core/storage/shared_preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persists the active [ThemeMode] preference for LIFTR (system by default).
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier(this._prefs) : super(_load(_prefs));

  static const String _storageKey = 'liftr_theme_mode_v1';
  final SharedPreferences? _prefs;

  static ThemeMode _load(SharedPreferences? prefs) {
    final raw = prefs?.getString(_storageKey);
    return switch (raw) {
      'dark' => ThemeMode.dark,
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      _ => ThemeMode.system,
    };
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _prefs?.setString(_storageKey, mode.name);
  }
}

/// Active theme mode preference provider for LIFTR (system by default).
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  return ThemeModeNotifier(ref.watch(sharedPreferencesProvider));
});
