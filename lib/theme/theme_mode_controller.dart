import 'package:flutter/material.dart';

class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController._() : super(ThemeMode.system);

  static final ThemeModeController instance = ThemeModeController._();

  bool get isDark {
    if (value == ThemeMode.system) {
      return WidgetsBinding.instance.platformDispatcher.platformBrightness ==
          Brightness.dark;
    }
    return value == ThemeMode.dark;
  }

  void toggleDarkLight() {
    value = isDark ? ThemeMode.light : ThemeMode.dark;
  }
}