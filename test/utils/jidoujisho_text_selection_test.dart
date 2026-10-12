import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/utils.dart';

void main() {
  const String text = '猫が窓の外を見た。';

  group('JidoujishoTextSelection', () {
    test('splits around a word in the middle', () {
      JidoujishoTextSelection selection = JidoujishoTextSelection(
        text: text,
        range: const TextRange(start: 2, end: 3),
      );

      expect(selection.textBefore, '猫が');
      expect(selection.textInside, '窓');
      expect(selection.textAfter, 'の外を見た。');
    });

    test('splits around a word at the start', () {
      JidoujishoTextSelection selection = JidoujishoTextSelection(
        text: text,
        range: const TextRange(start: 0, end: 1),
      );

      expect(selection.textBefore, '');
      expect(selection.textInside, '猫');
      expect(selection.textAfter, 'が窓の外を見た。');
    });

    test('splits around a word at the end', () {
      JidoujishoTextSelection selection = JidoujishoTextSelection(
        text: text,
        range: const TextRange(start: 6, end: 9),
      );

      expect(selection.textBefore, '猫が窓の外を');
      expect(selection.textInside, '見た。');
      expect(selection.textAfter, '');
    });

    test('selects the whole text', () {
      JidoujishoTextSelection selection = JidoujishoTextSelection(
        text: text,
        range: const TextRange(start: 0, end: text.length),
      );

      expect(selection.textBefore, '');
      expect(selection.textInside, text);
      expect(selection.textAfter, '');
    });

    test('is empty everywhere without a range', () {
      JidoujishoTextSelection selection = JidoujishoTextSelection(text: text);

      expect(selection.range, TextRange.empty);
      expect(selection.textBefore, '');
      expect(selection.textInside, '');
      expect(selection.textAfter, '');
    });
  });
}
