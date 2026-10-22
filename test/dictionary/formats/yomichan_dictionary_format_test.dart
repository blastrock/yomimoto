import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/dictionary.dart';

void main() {
  group('yomichanResourcePath', () {
    const String dir = '/res';

    test('extracts images and other files, subdirectories included', () {
      expect(yomichanResourcePath(dir, 'img/a.png'), '/res/img/a.png');
      expect(yomichanResourcePath(dir, 'styles.css'), '/res/styles.css');
      expect(yomichanResourcePath(dir, 'sub/term_bank_1.json'),
          '/res/sub/term_bank_1.json');
      expect(yomichanResourcePath(dir, 'sub/kanji_meta_bank_1.json'),
          '/res/sub/kanji_meta_bank_1.json');
    });

    test('skips the index, root bank files and directories', () {
      for (String name in [
        'index.json',
        'term_bank_1.json',
        'tag_bank_1.json',
        'kanji_bank_2.json',
        'term_meta_bank_1.json',
        'kanji_meta_bank_1.json',
        'tag_bank_extra.json',
        'img/',
      ]) {
        expect(yomichanResourcePath(dir, name), isNull, reason: name);
      }
    });

    test('never extracts outside the directory', () {
      for (String name in ['../evil.png', 'img/../../evil.png', '/etc/evil']) {
        expect(yomichanResourcePath(dir, name), isNull, reason: name);
      }
    });
  });
}
