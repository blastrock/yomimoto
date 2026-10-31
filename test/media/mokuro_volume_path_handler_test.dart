import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yuuna/media.dart';

void main() {
  // The asset loader hands the handler `Uri.getPath()`: already decoded.
  group('MokuroVolumePathHandler.volumeFile', () {
    Directory directory = Directory('/volumes/uuid-1');

    String? resolve(String path) =>
        MokuroVolumePathHandler.volumeFile(directory, path)?.path;

    test('resolves the OCR file', () {
      expect(resolve('volume.mokuro'), p.join(directory.path, 'volume.mokuro'));
    });

    test('resolves images with characters that URLs encode, as given', () {
      for (String path in [
        'images/[赤坂アカ×横槍メンゴ] 【推しの子】 01/00001.webp',
        'images/100% 本/001.jpg',
        'images/a#b/c+d.png',
        'images/what?.jpg',
        'images/%E3%81%82.jpg',
      ]) {
        expect(resolve(path), p.join(directory.path, path), reason: path);
      }
    });

    test('rejects paths that leave the volume', () {
      for (String path in [
        '',
        '../x',
        'images/../../x',
        '/etc/passwd',
        'images/',
        'images/./a.jpg/..',
      ]) {
        expect(resolve(path), isNull, reason: path);
      }
    });
  });
}
