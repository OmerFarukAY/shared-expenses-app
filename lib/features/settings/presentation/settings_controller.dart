import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kLanguageKey = 'denk_preferred_language';
const _kThemeModeKey = 'denk_preferred_theme_mode';

class AppLocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    _loadSaved();
    return null; // Null means follow system default locale
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_kLanguageKey);
      if (code != null && code.isNotEmpty) {
        state = Locale(code);
      }
    } catch (_) {}
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale != null) {
        await prefs.setString(_kLanguageKey, locale.languageCode);
      } else {
        await prefs.remove(_kLanguageKey);
      }
    } catch (_) {}
  }
}

final appLocaleProvider = NotifierProvider<AppLocaleNotifier, Locale?>(
  AppLocaleNotifier.new,
);

class AppThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadSaved();
    return ThemeMode.system;
  }

  Future<void> _loadSaved() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final modeStr = prefs.getString(_kThemeModeKey);
      if (modeStr != null) {
        if (modeStr == 'light') state = ThemeMode.light;
        if (modeStr == 'dark') state = ThemeMode.dark;
        if (modeStr == 'system') state = ThemeMode.system;
      }
    } catch (_) {}
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      final str = mode == ThemeMode.light
          ? 'light'
          : mode == ThemeMode.dark
          ? 'dark'
          : 'system';
      await prefs.setString(_kThemeModeKey, str);
    } catch (_) {}
  }
}

final appThemeModeProvider = NotifierProvider<AppThemeModeNotifier, ThemeMode>(
  AppThemeModeNotifier.new,
);
