import 'package:flutter/material.dart';

class ThemeModeController extends ValueNotifier<ThemeMode> {
  ThemeModeController._() : super(ThemeMode.system);

  static final ThemeModeController instance = ThemeModeController._();

  void toggleDarkLight() {
    value = value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
  }
}