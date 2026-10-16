import 'package:flutter/material.dart';

/// Colours the app needs that have no slot in [ColorScheme]. Each theme sets
/// its own values; read them with [AppColorsTheme.appColors].
@immutable
class AppColors extends ThemeExtension<AppColors> {
  /// Create the colours for one theme.
  const AppColors({
    required this.searchBarBackground,
    required this.searchBarBackdrop,
    required this.dictionaryCard,
    required this.dictionaryPopup,
    required this.imagePlaceholder,
  });

  /// Colours for the light theme.
  static const AppColors light = AppColors(
    searchBarBackground: Color.fromARGB(255, 229, 229, 229),
    searchBarBackdrop: Colors.white,
    dictionaryCard: Color.fromARGB(255, 249, 249, 249),
    dictionaryPopup: Color.fromARGB(255, 242, 242, 242),
    imagePlaceholder: Colors.black12,
  );

  /// Colours for the dark theme.
  static const AppColors dark = AppColors(
    searchBarBackground: Color.fromARGB(255, 30, 30, 30),
    searchBarBackdrop: Colors.black,
    dictionaryCard: Color.fromARGB(255, 16, 16, 16),
    dictionaryPopup: Color.fromARGB(255, 43, 43, 43),
    imagePlaceholder: Colors.white10,
  );

  /// Background of the floating search bars.
  final Color searchBarBackground;

  /// Backdrop behind an open floating search bar on the home tabs.
  final Color searchBarBackdrop;

  /// Background of each dictionary entry, before the entry opacity is
  /// applied.
  final Color dictionaryCard;

  /// Background of the reader's dictionary popup, before the popup opacity
  /// is applied.
  final Color dictionaryPopup;

  /// Filler for an empty slot in the creator's image carousel.
  final Color imagePlaceholder;

  @override
  AppColors copyWith({
    Color? searchBarBackground,
    Color? searchBarBackdrop,
    Color? dictionaryCard,
    Color? dictionaryPopup,
    Color? imagePlaceholder,
  }) {
    return AppColors(
      searchBarBackground: searchBarBackground ?? this.searchBarBackground,
      searchBarBackdrop: searchBarBackdrop ?? this.searchBarBackdrop,
      dictionaryCard: dictionaryCard ?? this.dictionaryCard,
      dictionaryPopup: dictionaryPopup ?? this.dictionaryPopup,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
    );
  }

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) {
      return this;
    }

    return AppColors(
      searchBarBackground:
          Color.lerp(searchBarBackground, other.searchBarBackground, t)!,
      searchBarBackdrop:
          Color.lerp(searchBarBackdrop, other.searchBarBackdrop, t)!,
      dictionaryCard: Color.lerp(dictionaryCard, other.dictionaryCard, t)!,
      dictionaryPopup: Color.lerp(dictionaryPopup, other.dictionaryPopup, t)!,
      imagePlaceholder:
          Color.lerp(imagePlaceholder, other.imagePlaceholder, t)!,
    );
  }
}

/// Access to [AppColors] from a theme.
extension AppColorsTheme on ThemeData {
  /// The theme's [AppColors]. Every theme built by the app carries them.
  AppColors get appColors => extension<AppColors>()!;
}
