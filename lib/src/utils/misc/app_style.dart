import 'package:flutter/material.dart';

/// What differs between the themes other than colours. Each theme sets its
/// own values; read them with [AppStyleTheme.appStyle].
@immutable
class AppStyle extends ThemeExtension<AppStyle> {
  /// Create the style of one theme.
  const AppStyle({
    required this.border,
    required this.dictionaryPopupOpacity,
    required this.quickActionIconSize,
    required this.quickActionPadding,
  });

  /// Style of the light and dark themes.
  static const AppStyle standard = AppStyle(
    border: BorderSide.none,
    dictionaryPopupOpacity: 0.95,
    quickActionIconSize: 20,
    quickActionPadding: 6,
  );

  /// Style of the e-ink theme: everything is white on white, so windows and
  /// buttons need an edge, and the screen's touch accuracy is poor, so the
  /// buttons stay large.
  static const AppStyle eink = AppStyle(
    // The defaults of a border side: 1dp, black.
    border: BorderSide(),
    dictionaryPopupOpacity: 1,
    quickActionIconSize: 25,
    quickActionPadding: 8,
  );

  /// The edge of windows and buttons.
  final BorderSide border;

  /// Opacity of the reader's dictionary popup background.
  final double dictionaryPopupOpacity;

  /// Size of the icon of a dictionary quick action.
  final double quickActionIconSize;

  /// Padding around the icon of a dictionary quick action.
  final double quickActionPadding;

  @override
  AppStyle copyWith({
    BorderSide? border,
    double? dictionaryPopupOpacity,
    double? quickActionIconSize,
    double? quickActionPadding,
  }) {
    return AppStyle(
      border: border ?? this.border,
      dictionaryPopupOpacity:
          dictionaryPopupOpacity ?? this.dictionaryPopupOpacity,
      quickActionIconSize: quickActionIconSize ?? this.quickActionIconSize,
      quickActionPadding: quickActionPadding ?? this.quickActionPadding,
    );
  }

  @override
  AppStyle lerp(AppStyle? other, double t) {
    if (other == null) {
      return this;
    }

    return t < 0.5 ? this : other;
  }
}

/// Access to [AppStyle] from a theme.
extension AppStyleTheme on ThemeData {
  /// The theme's [AppStyle]. Every theme built by the app carries it.
  AppStyle get appStyle => extension<AppStyle>()!;
}
