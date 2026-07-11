import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';


// Locale State Manager
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale('en');
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

// Theme Mode Manager
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    _loadTheme();
    return ThemeMode.system; // Default: follow OS theme
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('themeMode');
    if (saved != null) {
      ThemeMode mode;
      switch (saved) {
        case 'dark':
          mode = ThemeMode.dark;
          break;
        case 'light':
          mode = ThemeMode.light;
          break;
        default:
          mode = ThemeMode.system;
      }
      state = mode;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    String val;
    switch (mode) {
      case ThemeMode.dark:
        val = 'dark';
        break;
      case ThemeMode.light:
        val = 'light';
        break;
      default:
        val = 'system';
    }
    await prefs.setString('themeMode', val);
  }

  Future<void> toggleThemeMode() async {
    // Cycle: system -> light -> dark -> system
    ThemeMode next;
    switch (state) {
      case ThemeMode.system:
        next = ThemeMode.light;
        break;
      case ThemeMode.light:
        next = ThemeMode.dark;
        break;
      default:
        next = ThemeMode.system;
    }
    await setThemeMode(next);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

// Mock/Firebase Database Toggler
class MockModeNotifier extends Notifier<bool> {
  @override
  bool build() {
    try {
      return Firebase.apps.isEmpty;
    } catch (_) {
      return true;
    }
  }

  @override
  set state(bool value) => super.state = value;
}

final mockModeProvider = NotifierProvider<MockModeNotifier, bool>(MockModeNotifier.new);

