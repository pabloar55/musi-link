import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeKey = 'theme_mode';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _values = {
    'dark': ThemeMode.dark,
    'light': ThemeMode.light,
    'system': ThemeMode.system,
  };

  @override
  ThemeMode build() {
    // Carga sincrónica desde el SharedPreferences ya inicializado en main.
    final prefs = ref.read(sharedPreferencesProvider);
    final saved = prefs.getString(_kThemeKey);
    return _values[saved] ?? ThemeMode.system;
  }

  bool get isDark {
    if (state == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return state == ThemeMode.dark;
  }

  void toggleDarkLight() {
    state = isDark ? ThemeMode.light : ThemeMode.dark;
    _persist(state);
  }

  void _persist(ThemeMode mode) {
    final key = _values.entries.firstWhere((e) => e.value == mode).key;
    ref.read(sharedPreferencesProvider).setString(_kThemeKey, key);
  }
}

final themeModeProvider =
    NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

/// Provider derivado que indica si el tema actual es oscuro.
final isDarkProvider = Provider<bool>((ref) {
  final mode = ref.watch(themeModeProvider);
  if (mode == ThemeMode.system) {
    return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
  }
  return mode == ThemeMode.dark;
});

/// SharedPreferences inyectado como provider para poder accederlo desde notifiers.
/// Se sobreescribe en main() antes de runApp con el valor real.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Must be overridden in main'),
);
