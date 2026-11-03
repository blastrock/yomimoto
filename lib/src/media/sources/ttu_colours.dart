import 'package:flutter/material.dart';

/// The colours of the ttu reader, which the app sets through
/// `TtuBridge.setTheme`. Each app theme carries its own.
@immutable
class TtuColours {
  /// Create a set of reader colours.
  const TtuColours({
    required this.font,
    required this.background,
    required this.selectionFont,
    required this.selectionBackground,
    required this.hintFuriganaFont,
    required this.hintFuriganaShadow,
    required this.tooltipTextFont,
  });

  /// ttu's `light-theme`.
  static const TtuColours light = TtuColours(
    font: Color(0xDE000000),
    background: Color(0xFFFFFFFF),
    selectionFont: Color(0xFFF5F5F5),
    selectionBackground: Color(0xFF979797),
    hintFuriganaFont: Color(0x54000000),
    hintFuriganaShadow: Color(0x4D222231),
    tooltipTextFont: Color(0x99000000),
  );

  /// ttu's `black-theme`.
  static const TtuColours black = TtuColours(
    font: Color(0xDEFFFFFF),
    background: Color(0xFF000000),
    selectionFont: Color(0x99555A5C),
    selectionBackground: Color(0xCCD4D9DC),
    hintFuriganaFont: Color(0x54FFFFFF),
    hintFuriganaShadow: Color(0x4DF0F0F1),
    tooltipTextFont: Color(0x99FFFFFF),
  );

  /// Pure black on pure white. The furigana hint stays faint: it marks hidden
  /// furigana rather than being text to read.
  static const TtuColours eink = TtuColours(
    font: Color(0xFF000000),
    background: Color(0xFFFFFFFF),
    selectionFont: Color(0xFFFFFFFF),
    selectionBackground: Color(0xFF000000),
    hintFuriganaFont: Color(0x61000000),
    hintFuriganaShadow: Color(0x4D000000),
    tooltipTextFont: Color(0xFF000000),
  );

  /// The book's text.
  final Color font;

  /// The page behind the text.
  final Color background;

  /// Selected text.
  final Color selectionFont;

  /// Behind selected text.
  final Color selectionBackground;

  /// Hidden furigana, in the styles that hint at it.
  final Color hintFuriganaFont;

  /// The shadow of hidden furigana.
  final Color hintFuriganaShadow;

  /// Tooltips and the reader's status text.
  final Color tooltipTextFont;

  /// The wire form: a ttu `ThemeOption`, of CSS colours.
  Map<String, String> toJson() => {
        'fontColor': _css(font),
        'backgroundColor': _css(background),
        'selectionFontColor': _css(selectionFont),
        'selectionBackgroundColor': _css(selectionBackground),
        'hintFuriganaFontColor': _css(hintFuriganaFont),
        'hintFuriganaShadowColor': _css(hintFuriganaShadow),
        'tooltipTextFontColor': _css(tooltipTextFont),
      };

  static String _css(Color color) {
    int r = (color.r * 255).round();
    int g = (color.g * 255).round();
    int b = (color.b * 255).round();

    return 'rgba($r, $g, $b, ${color.a.toStringAsFixed(3)})';
  }

  @override
  bool operator ==(Object other) =>
      other is TtuColours &&
      font == other.font &&
      background == other.background &&
      selectionFont == other.selectionFont &&
      selectionBackground == other.selectionBackground &&
      hintFuriganaFont == other.hintFuriganaFont &&
      hintFuriganaShadow == other.hintFuriganaShadow &&
      tooltipTextFont == other.tooltipTextFont;

  @override
  int get hashCode => Object.hash(
        font,
        background,
        selectionFont,
        selectionBackground,
        hintFuriganaFont,
        hintFuriganaShadow,
        tooltipTextFont,
      );
}
