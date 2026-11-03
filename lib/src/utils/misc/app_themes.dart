import 'package:flutter/material.dart';
import 'package:yuuna/language.dart';
import 'package:yuuna/utils.dart';

/// The themes the app can show.
abstract final class AppThemes {
  /// Get the app-wide text style.
  static TextStyle get _textStyle => TextStyle(
        fontFeatures: const [FontFeature('liga', 0)],
        locale: JapaneseLanguage.locale,
        textBaseline: JapaneseLanguage.textBaseline,
      );

  /// This override is a workaround required to theme the app-wide [TextTheme]
  /// based on the [Locale] and [TextBaseline] of the active target language.
  static TextTheme get _textTheme => TextTheme(
        displayLarge: _textStyle,
        displayMedium: _textStyle,
        displaySmall: _textStyle,
        headlineLarge: _textStyle,
        headlineMedium: _textStyle,
        headlineSmall: _textStyle,
        titleLarge: _textStyle,
        titleMedium: _textStyle,
        titleSmall: _textStyle,
        bodyLarge: _textStyle,
        bodyMedium: _textStyle,
        bodySmall: _textStyle,
        labelLarge: _textStyle,
        labelMedium: _textStyle,
        labelSmall: _textStyle,
      );

  /// The light theme.
  static ThemeData light() => ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
        unselectedWidgetColor: Colors.black54,
        textTheme: _textTheme,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateColor.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.red
                : Colors.white;
          }),
          trackColor: WidgetStateColor.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.grey;
          }),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: _textTheme.labelSmall,
          unselectedLabelStyle: _textTheme.labelSmall,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          backgroundColor: Colors.white,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(),
        ),
        cardColor: Colors.white,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
          ),
        ),
        listTileTheme: ListTileThemeData(
          dense: true,
          selectedTileColor: Colors.grey.shade300,
          selectedColor: Colors.black,
          horizontalTitleGap: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black54,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thickness: WidgetStateProperty.all(3),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
        sliderTheme: const SliderThemeData(
          thumbColor: Colors.red,
          activeTrackColor: Colors.red,
          inactiveTrackColor: Colors.grey,
          trackShape: RectangularSliderTrackShape(),
          trackHeight: 2,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        ),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(
              primary: Colors.red,
              secondary: Colors.red,
              brightness: Brightness.light,
            )
            .copyWith(surface: Colors.white),
        extensions: const [AppColors.light, AppStyle.standard],
      );

  /// The dark theme.
  static ThemeData dark() => ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.black,
        textTheme: _textTheme,
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateColor.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.red
                : Colors.grey;
          }),
          trackColor: WidgetStateColor.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.grey;
          }),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: _textTheme.labelSmall,
          unselectedLabelStyle: _textTheme.labelSmall,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          backgroundColor: Colors.black,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Color.fromARGB(255, 30, 30, 30),
          shape: RoundedRectangleBorder(),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color.fromARGB(255, 30, 30, 30),
          shape: RoundedRectangleBorder(),
        ),
        cardColor: const Color.fromARGB(255, 30, 30, 30),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        listTileTheme: ListTileThemeData(
          dense: true,
          selectedTileColor: Colors.grey.shade600,
          selectedColor: Colors.white,
          horizontalTitleGap: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white70,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(true),
        ),
        sliderTheme: const SliderThemeData(
          thumbColor: Colors.red,
          activeTrackColor: Colors.red,
          inactiveTrackColor: Colors.grey,
          trackShape: RectangularSliderTrackShape(),
          trackHeight: 2,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        ),
        colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark)
            .copyWith(
              primary: Colors.red,
              secondary: Colors.red,
              onSecondary: Colors.white,
              onError: Colors.white,
            )
            .copyWith(surface: Colors.black),
        extensions: const [AppColors.dark, AppStyle.standard],
      );

  /// The e-ink theme: [light] with pure black text and icons, for the highest
  /// contrast on the text being read, and borders around windows and text
  /// buttons, which would otherwise be white on white.
  static ThemeData eink() {
    ThemeData theme = light();
    BorderSide border = AppStyle.eink.border;
    RoundedRectangleBorder windowShape = RoundedRectangleBorder(side: border);

    return theme.copyWith(
      textTheme: theme.textTheme.apply(
        bodyColor: Colors.black,
        displayColor: Colors.black,
      ),
      iconTheme: const IconThemeData(color: Colors.black),
      colorScheme: theme.colorScheme.copyWith(onSurface: Colors.black),
      dialogTheme: theme.dialogTheme.copyWith(shape: windowShape),
      popupMenuTheme: theme.popupMenuTheme.copyWith(shape: windowShape),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: windowShape,
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.black,
          side: border,
          shape: const RoundedRectangleBorder(),
        ),
      ),
      extensions: const [AppColors.eink, AppStyle.eink],
    );
  }

  /// The theme `MaterialApp` shows for a light brightness when [mode] is
  /// selected.
  static ThemeData lightFor(AppThemeMode mode) =>
      mode == AppThemeMode.eink ? eink() : light();
}
