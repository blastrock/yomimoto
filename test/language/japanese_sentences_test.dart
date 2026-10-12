import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/language.dart';
import 'package:yuuna/utils.dart';

void main() {
  JapaneseLanguage language = JapaneseLanguage.instance;

  // getSentences interleaves the sentences with whatever lies between
  // matches, usually an empty string, and ends with the unmatched tail. The
  // pieces always join back into the input.
  group('getSentences', () {
    Map<String, List<String>> cases = {
      'あいう。': ['', 'あいう。', ''],
      '猫が鳴いた。犬も吠えた。': ['', '猫が鳴いた。', '', '犬も吠えた。', ''],
      '本当？！嘘。。': ['', '本当？！', '', '嘘。。', ''],
      'Hi. Ok? Yes!': ['', 'Hi.', '', ' Ok?', '', ' Yes!', ''],
      '一行目\n二行目。': ['', '一行目\n', '', '二行目。', ''],
      // No terminator at all: the whole text.
      'あいう': ['あいう'],
      // The last sentence has no terminator: it survives as the tail.
      '猫が鳴いた。犬も': ['', '猫が鳴いた。', '犬も'],
      // A sentence needs a character before its terminator, so a leading
      // newline is left between matches.
      '\nあ。': ['\n', 'あ。', ''],
      '\n\n': ['\n\n'],
      '': [''],
    };

    cases.forEach((text, sentences) {
      test(text.replaceAll('\n', r'\n'), () {
        expect(language.getSentences(text), sentences);
        expect(language.getSentences(text).join(), text);
      });
    });
  });

  group('getSentenceFromParagraph', () {
    const String paragraph = '猫が鳴いた。犬も吠えた。鳥が飛んだ。';

    JidoujishoTextSelection select(String paragraph, int start, int length) {
      return language.getSentenceFromParagraph(
        paragraph: paragraph,
        index: start,
        startOffset: start,
        endOffset: start + length,
      );
    }

    test('finds a word in the first sentence', () {
      JidoujishoTextSelection selection = select(paragraph, 0, 1);

      expect(selection.text, '猫が鳴いた。');
      expect(selection.range, const TextRange(start: 0, end: 1));
      expect(selection.textInside, '猫');
    });

    test('finds a word starting a middle sentence', () {
      JidoujishoTextSelection selection = select(paragraph, 6, 1);

      expect(selection.text, '犬も吠えた。');
      expect(selection.range, const TextRange(start: 0, end: 1));
      expect(selection.textInside, '犬');
    });

    test('finds a word inside a middle sentence', () {
      JidoujishoTextSelection selection = select(paragraph, 8, 2);

      expect(selection.text, '犬も吠えた。');
      expect(selection.range, const TextRange(start: 2, end: 4));
      expect(selection.textInside, '吠え');
    });

    test('finds a word in the last sentence', () {
      JidoujishoTextSelection selection = select(paragraph, 14, 2);

      expect(selection.text, '鳥が飛んだ。');
      expect(selection.range, const TextRange(start: 2, end: 4));
      expect(selection.textInside, '飛ん');
    });

    test('finds a word in an unterminated last sentence', () {
      JidoujishoTextSelection selection = select('猫が鳴いた。犬も', 6, 1);

      expect(selection.text, '犬も');
      expect(selection.range, const TextRange(start: 0, end: 1));
    });

    test('returns a paragraph without terminator whole', () {
      JidoujishoTextSelection selection = select('あいうえお', 2, 1);

      expect(selection.text, 'あいうえお');
      expect(selection.range, const TextRange(start: 2, end: 3));
    });

    // Past the end, the last piece is returned: the empty tail after a
    // terminated sentence, with a range outside it. The reader never asks
    // for an index outside the tapped paragraph.
    test('returns the empty tail for an index past the end', () {
      JidoujishoTextSelection selection = select(paragraph, 30, 1);

      expect(selection.text, '');
      expect(selection.range, const TextRange(start: 12, end: 13));
    });

    test('returns an unterminated tail for an index past the end', () {
      JidoujishoTextSelection selection = select('猫が鳴いた。犬も', 20, 1);

      expect(selection.text, '犬も');
      expect(selection.range, const TextRange(start: 14, end: 15));
    });
  });
}
