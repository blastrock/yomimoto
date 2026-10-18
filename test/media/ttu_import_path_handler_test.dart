import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yuuna/media.dart';

void main() {
  // The asset loader hands the handler `Uri.getPath()`: already decoded.
  group('TtuImportPathHandler.stagedFile', () {
    Directory directory = Directory('/staging');

    String? resolve(String path) =>
        TtuImportPathHandler.stagedFile(directory, path)?.path;

    test('resolves an ASCII name', () {
      expect(resolve('0/book.epub'), p.join('/staging', '0', 'book.epub'));
    });

    test('resolves names with characters that URLs encode', () {
      for (String name in [
        '日本語の本.epub',
        '100% 本.epub',
        'what?.epub',
        'a#b.txt',
        'a+b c.htmlz',
      ]) {
        expect(resolve('3/$name'), p.join('/staging', '3', name),
            reason: name);
      }
    });

    test('rejects paths that do not name a staged file', () {
      for (String path in [
        '',
        'book.epub',
        'x/book.epub',
        '0/',
        '0/.',
        '0/..',
        '0/a/b.epub',
      ]) {
        expect(resolve(path), isNull, reason: path);
      }
    });
  });
}
