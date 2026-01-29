import 'package:flutter/material.dart';

class ThemeController {
  // Valor actual del modo de tema de la app
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(
    ThemeMode.system,
  );

  static void setThemeMode(ThemeMode mode) {
    themeMode.value = mode;
  }
}
