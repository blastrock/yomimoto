import 'package:flutter/material.dart';

/// The theme picked in the settings. The names are stored in the
/// `theme_mode` preference: do not rename them.
enum AppThemeMode {
  /// Light or dark, following the system.
  system,

  /// The light theme.
  light,

  /// The dark theme.
  dark,

  /// The light theme made for e-ink screens.
  eink;

  /// The mode `MaterialApp` runs in. E-ink is a light theme to it.
  ThemeMode get materialMode => switch (this) {
        AppThemeMode.system => ThemeMode.system,
        AppThemeMode.light || AppThemeMode.eink => ThemeMode.light,
        AppThemeMode.dark => ThemeMode.dark,
      };
}
