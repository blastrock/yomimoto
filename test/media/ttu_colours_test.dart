import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/media.dart';

void main() {
  test('e-ink colours go on the wire in full', () {
    expect(TtuColours.eink.toJson(), {
      'fontColor': 'rgba(0, 0, 0, 1.000)',
      'backgroundColor': 'rgba(255, 255, 255, 1.000)',
      'selectionFontColor': 'rgba(255, 255, 255, 1.000)',
      'selectionBackgroundColor': 'rgba(0, 0, 0, 1.000)',
      'hintFuriganaFontColor': 'rgba(0, 0, 0, 0.380)',
      'hintFuriganaShadowColor': 'rgba(0, 0, 0, 0.302)',
      'tooltipTextFontColor': 'rgba(0, 0, 0, 1.000)',
    });
  });

  test("light keeps ttu's own text colour", () {
    expect(TtuColours.light.toJson()['fontColor'], 'rgba(0, 0, 0, 0.871)');
  });

  test("dark keeps ttu's black theme", () {
    expect(TtuColours.black.toJson()['backgroundColor'],
        'rgba(0, 0, 0, 1.000)');
    expect(TtuColours.black.toJson()['fontColor'],
        'rgba(255, 255, 255, 0.871)');
  });

  test('colours compare by value', () {
    TtuColours eink = TtuColours.eink;
    TtuColours same = TtuColours(
      font: eink.font,
      background: eink.background,
      selectionFont: eink.selectionFont,
      selectionBackground: eink.selectionBackground,
      hintFuriganaFont: eink.hintFuriganaFont,
      hintFuriganaShadow: eink.hintFuriganaShadow,
      tooltipTextFont: eink.tooltipTextFont,
    );

    expect(same, eink);
    expect(same.hashCode, eink.hashCode);
    expect(eink, isNot(TtuColours.light));
  });
}
