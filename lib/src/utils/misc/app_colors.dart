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
    required this.quickActionBackground,
    required this.nestedChipBackground,
    this.chipBackground,
    this.chipForeground,
    this.nestedChipForeground,
    this.dictionaryLink,
  });

  /// Colours for the light theme.
  static const AppColors light = AppColors(
    searchBarBackground: Color.fromARGB(255, 229, 229, 229),
    searchBarBackdrop: Colors.white,
    dictionaryCard: Color.fromARGB(255, 249, 249, 249),
    dictionaryPopup: Color.fromARGB(255, 242, 242, 242),
    imagePlaceholder: Colors.black12,
    quickActionBackground: Color(0x0D000000),
    nestedChipBackground: Color(0xFFEF5350),
  );

  /// Colours for the dark theme.
  static const AppColors dark = AppColors(
    searchBarBackground: Color.fromARGB(255, 30, 30, 30),
    searchBarBackdrop: Colors.black,
    dictionaryCard: Color.fromARGB(255, 16, 16, 16),
    dictionaryPopup: Color.fromARGB(255, 43, 43, 43),
    imagePlaceholder: Colors.white10,
    quickActionBackground: Color(0x0DFFFFFF),
    nestedChipBackground: Color(0xFFEF5350),
  );

  /// Colours for the e-ink theme.
  static const AppColors eink = AppColors(
    searchBarBackground: Color.fromARGB(255, 229, 229, 229),
    searchBarBackdrop: Colors.white,
    dictionaryCard: Colors.white,
    dictionaryPopup: Colors.white,
    imagePlaceholder: Colors.black12,
    quickActionBackground: Colors.transparent,
    nestedChipBackground: Colors.white,
    chipBackground: Colors.black,
    chipForeground: Colors.white,
    nestedChipForeground: Colors.black,
    dictionaryLink: Colors.black,
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

  /// Tint behind the icon of a dictionary quick action.
  final Color quickActionBackground;

  /// Background of a chip nested in a chip, like a dictionary's frequencies.
  final Color nestedChipBackground;

  /// Background of every chip. If null, each chip keeps its own colour.
  final Color? chipBackground;

  /// Text colour of every chip. If null, each chip keeps its own colour.
  final Color? chipForeground;

  /// Text colour of a nested chip. If null, it is that of its chip.
  final Color? nestedChipForeground;

  /// Colour of the links in a definition. If null, it is the colour scheme's
  /// error colour.
  final Color? dictionaryLink;

  @override
  AppColors copyWith({
    Color? searchBarBackground,
    Color? searchBarBackdrop,
    Color? dictionaryCard,
    Color? dictionaryPopup,
    Color? imagePlaceholder,
    Color? quickActionBackground,
    Color? nestedChipBackground,
    Color? chipBackground,
    Color? chipForeground,
    Color? nestedChipForeground,
    Color? dictionaryLink,
  }) {
    return AppColors(
      searchBarBackground: searchBarBackground ?? this.searchBarBackground,
      searchBarBackdrop: searchBarBackdrop ?? this.searchBarBackdrop,
      dictionaryCard: dictionaryCard ?? this.dictionaryCard,
      dictionaryPopup: dictionaryPopup ?? this.dictionaryPopup,
      imagePlaceholder: imagePlaceholder ?? this.imagePlaceholder,
      quickActionBackground:
          quickActionBackground ?? this.quickActionBackground,
      nestedChipBackground: nestedChipBackground ?? this.nestedChipBackground,
      chipBackground: chipBackground ?? this.chipBackground,
      chipForeground: chipForeground ?? this.chipForeground,
      nestedChipForeground: nestedChipForeground ?? this.nestedChipForeground,
      dictionaryLink: dictionaryLink ?? this.dictionaryLink,
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
      quickActionBackground:
          Color.lerp(quickActionBackground, other.quickActionBackground, t)!,
      nestedChipBackground:
          Color.lerp(nestedChipBackground, other.nestedChipBackground, t)!,
      chipBackground: t < 0.5 ? chipBackground : other.chipBackground,
      chipForeground: t < 0.5 ? chipForeground : other.chipForeground,
      nestedChipForeground:
          t < 0.5 ? nestedChipForeground : other.nestedChipForeground,
      dictionaryLink: t < 0.5 ? dictionaryLink : other.dictionaryLink,
    );
  }
}

/// Access to [AppColors] from a theme.
extension AppColorsTheme on ThemeData {
  /// The theme's [AppColors]. Every theme built by the app carries them.
  AppColors get appColors => extension<AppColors>()!;
}
