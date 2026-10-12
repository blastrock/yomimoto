import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/utils.dart';

StashItem _item({
  String sentence = '彼は漢字を書いた。',
  int wordStart = 2,
  int wordLength = 2,
}) {
  return StashItem(
    mediaSourceIdentifier: 'reader_ttu',
    mediaIdentifier: 'b.html?id=3',
    term: '漢字',
    reading: 'かんじ',
    dictionaryName: 'JMdict',
    definitions: ['kanji'],
    sentence: sentence,
    wordStart: wordStart,
    wordLength: wordLength,
    position: 425,
    dateAdded: DateTime(2026, 10, 12),
  );
}

void main() {
  group('StashItem', () {
    test('is keyed by source, book, term and reading', () {
      expect(_item().stashKey, 'reader_ttu/b.html?id=3/漢字/かんじ');
    });

    test('selects the word in its sentence', () {
      JidoujishoTextSelection selection = _item().getSelection();

      expect(selection.text, '彼は漢字を書いた。');
      expect(selection.range, const TextRange(start: 2, end: 4));
      expect(selection.textBefore, '彼は');
      expect(selection.textInside, '漢字');
      expect(selection.textAfter, 'を書いた。');
    });

    // A zero length gives a collapsed range at wordStart, not
    // TextRange.empty. AddToStashAction stores 0/0 when the reader had no
    // word range, so the whole sentence ends up in textAfter.
    test('with no word, selects nothing at the word start', () {
      JidoujishoTextSelection selection = _item(
        wordStart: 0,
        wordLength: 0,
      ).getSelection();

      expect(selection.range, const TextRange.collapsed(0));
      expect(selection.range, isNot(TextRange.empty));
      expect(selection.textBefore, '');
      expect(selection.textInside, '');
      expect(selection.textAfter, '彼は漢字を書いた。');
    });

    test('with no word inside the sentence, splits at the word start', () {
      JidoujishoTextSelection selection = _item(
        wordStart: 4,
        wordLength: 0,
      ).getSelection();

      expect(selection.textBefore, '彼は漢字');
      expect(selection.textInside, '');
      expect(selection.textAfter, 'を書いた。');
    });
  });
}
