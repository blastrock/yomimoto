import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/media.dart';

/// A minimal valid volume, with [overrides] replacing its top-level keys.
String volumeJson([Map<String, Object?> overrides = const {}]) {
  return jsonEncode({
    'version': '0.2.5',
    'title': '【推しの子】',
    'title_uuid': '38bc1aea-28d8-57b2-8f13-4ff43a4c9af9',
    'volume': '[赤坂アカ×横槍メンゴ] 【推しの子】 01',
    'volume_uuid': 'dc4fde69-7299-4806-bbfb-435cddacc9be',
    'pages': [
      {
        'img_path': '01/00001.webp',
        'img_width': 1000,
        'img_height': 1500,
        'blocks': <Object>[],
      },
    ],
    ...overrides,
  });
}

void main() {
  group('MokuroVolume.parse', () {
    test('reads a volume written by the mokuro tool', () {
      MokuroVolume volume = MokuroVolume.parse(
          File('test/media/fixtures/vol1.mokuro').readAsStringSync());

      expect(volume.title, 'test0');
      expect(volume.volume, 'vol1');
      expect(volume.volumeUuid, '1f55a3b0-34f5-4415-ac85-8d906a71adcd');
      expect(volume.pages.length, 6);
      expect(volume.pages.first.imgPath, '000a.jpg');
      expect(volume.displayTitle, 'test0 vol1');
    });

    test('reads page sizes', () {
      MokuroPage page = MokuroVolume.parse(volumeJson()).pages.single;

      expect(page.imgPath, '01/00001.webp');
      expect(page.width, 1000);
      expect(page.height, 1500);
    });

    test('ignores keys it does not know', () {
      MokuroVolume volume = MokuroVolume.parse(volumeJson({
        'ocr_engine': {'id': 'hayai-nova'},
        'something_new': 3,
      }));

      expect(volume.pages.length, 1);
    });

    test('rejects what is not a volume', () {
      for (String json in [
        '[]',
        '{',
        volumeJson({'volume_uuid': null}),
        volumeJson({'volume_uuid': '../x'}),
        volumeJson({'volume_uuid': ''}),
        volumeJson({'title': 3}),
        volumeJson({'volume': null}),
        volumeJson({'pages': <Object>[]}),
        volumeJson({'pages': 'x'}),
        volumeJson({
          'pages': [
            {'img_width': 1, 'img_height': 1},
          ],
        }),
        volumeJson({
          'pages': [
            {'img_path': 'a.jpg', 'img_width': '1', 'img_height': 1},
          ],
        }),
      ]) {
        expect(() => MokuroVolume.parse(json), throwsFormatException,
            reason: json);
      }
    });
  });

  group('MokuroVolume.displayTitle', () {
    test('is the volume name alone when it contains the title', () {
      expect(MokuroVolume.parse(volumeJson()).displayTitle,
          '[赤坂アカ×横槍メンゴ] 【推しの子】 01');
    });

    test('puts the title before a volume name without it', () {
      expect(
          MokuroVolume.parse(volumeJson({'volume': '01'})).displayTitle,
          '【推しの子】 01');
    });
  });
}
