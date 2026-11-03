import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/preferences.dart';
import 'package:yuuna/utils.dart';

// A border side's defaults are 1dp and black.
const BorderSide einkBorder = BorderSide();

void main() {
  test('the e-ink border is thin and black', () {
    expect(AppStyle.eink.border.color, Colors.black);
    expect(AppStyle.eink.border.width, 1);
  });

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

  test('e-ink windows and text buttons have a thin black border', () {
    ThemeData theme = AppThemes.eink();
    expect(
        (theme.dialogTheme.shape! as RoundedRectangleBorder).side, einkBorder);
    expect((theme.popupMenuTheme.shape! as RoundedRectangleBorder).side,
        einkBorder);
    expect((theme.bottomSheetTheme.shape! as RoundedRectangleBorder).side,
        einkBorder);
    expect(theme.textButtonTheme.style!.side!.resolve({}), einkBorder);
    expect(theme.textButtonTheme.style!.foregroundColor!.resolve({}),
        Colors.black);
  });

  test('quick actions lose their tint in e-ink only', () {
    expect(AppColors.eink.quickActionBackground, Colors.transparent);
    expect(AppColors.light.quickActionBackground, const Color(0x0D000000));
    expect(AppColors.dark.quickActionBackground, const Color(0x0DFFFFFF));
  });

  test('e-ink windows stay white', () {
    ThemeData theme = AppThemes.eink();
    expect(theme.dialogTheme.backgroundColor, Colors.white);
    expect(theme.popupMenuTheme.color, Colors.white);
    expect(theme.bottomSheetTheme.backgroundColor, Colors.white);
  });

  test('light and dark have no borders', () {
    for (ThemeData theme in [AppThemes.light(), AppThemes.dark()]) {
      expect(theme.appStyle.border, BorderSide.none);
      expect((theme.dialogTheme.shape! as RoundedRectangleBorder).side,
          BorderSide.none);
      expect(theme.textButtonTheme.style!.side, isNull);
    }
  });

  test('the popup is opaque in e-ink only', () {
    expect(AppThemes.eink().appStyle.dictionaryPopupOpacity, 1);
    for (ThemeData theme in [AppThemes.light(), AppThemes.dark()]) {
      expect(theme.appStyle.dictionaryPopupOpacity, 0.95);
    }
  });

  test('quick actions are large in e-ink only', () {
    expect(AppThemes.eink().appStyle.quickActionIconSize, 25);
    expect(AppThemes.eink().appStyle.quickActionPadding, 8);
    for (ThemeData theme in [AppThemes.light(), AppThemes.dark()]) {
      expect(theme.appStyle.quickActionIconSize, 20);
      expect(theme.appStyle.quickActionPadding, 6);
    }
  });
}
