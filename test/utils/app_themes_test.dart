import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/preferences.dart';
import 'package:yuuna/utils.dart';

void main() {
  test('stored theme names still read as the same theme', () {
    expect(Preferences.themeMode.key, 'theme_mode');
    expect(Preferences.themeMode.fromJson('system'), AppThemeMode.system);
    expect(Preferences.themeMode.fromJson('light'), AppThemeMode.light);
    expect(Preferences.themeMode.fromJson('dark'), AppThemeMode.dark);
    expect(Preferences.themeMode.toJson(AppThemeMode.eink), 'eink');
  });

  test('e-ink is a light theme to MaterialApp', () {
    expect(AppThemeMode.eink.materialMode, ThemeMode.light);
    expect(AppThemeMode.system.materialMode, ThemeMode.system);
    expect(AppThemes.lightFor(AppThemeMode.eink).appColors, AppColors.eink);
    expect(AppThemes.lightFor(AppThemeMode.dark).appColors, AppColors.light);
  });

  test('e-ink text and icons are pure black on white', () {
    ThemeData theme = AppThemes.eink();
    expect(theme.brightness, Brightness.light);
    expect(theme.textTheme.bodyMedium!.color, Colors.black);
    expect(theme.textTheme.titleLarge!.color, Colors.black);
    expect(theme.textTheme.bodySmall!.color, Colors.black);
    expect(theme.iconTheme.color, Colors.black);
    expect(theme.colorScheme.onSurface, Colors.black);
    expect(theme.scaffoldBackgroundColor, Colors.white);
  });

  test('the e-ink dictionary surfaces are white', () {
    expect(AppColors.eink.dictionaryPopup, Colors.white);
    expect(AppColors.eink.dictionaryCard, Colors.white);
  });
}
