import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yuuna/media.dart';

void main() {
  MokuroImportResult result({String? coverPath = '/v/uuid-1/images/a.jpg'}) {
    return MokuroImportResult(
      volumeUuid: 'uuid-1',
      title: '【推しの子】 01',
      pageCount: 224,
      missingPages: 0,
      directory: '/v/uuid-1',
      coverPath: coverPath,
    );
  }

  group('ReaderMokuroSource.volumeItem', () {
    test('makes a new library entry at the first page', () {
      MediaItem item = ReaderMokuroSource.volumeItem(result: result());

      expect(item.id, isNull);
      expect(item.mediaSourceIdentifier, 'reader_mokuro');
      expect(item.mediaIdentifier, 'uuid-1');
      expect(item.title, '【推しの子】 01');
      expect(item.imageUrl, 'file:///v/uuid-1/images/a.jpg');
      expect(item.position, 0);
      expect(item.duration, 224);
      expect(item.canDelete, isFalse);
      expect(item.canEdit, isTrue);
    });

    test('keeps the row, position and title of a volume imported again', () {
      MediaItem existing = MediaItem(
        id: 7,
        mediaIdentifier: 'uuid-1',
        title: 'old title',
        mediaSourceIdentifier: 'reader_mokuro',
        position: 42,
        duration: 200,
        canDelete: false,
        canEdit: true,
        overrideTitle: 'Mine',
      );

      MediaItem item =
          ReaderMokuroSource.volumeItem(result: result(), existing: existing);

      expect(item.id, 7);
      expect(item.position, 42);
      expect(item.overrideTitle, 'Mine');
      expect(item.title, '【推しの子】 01');
      expect(item.duration, 224);
    });

    test('has no cover when the first page is missing', () {
      expect(
          ReaderMokuroSource.volumeItem(result: result(coverPath: null))
              .imageUrl,
          isNull);
    });
  });

  group('ReaderMokuroSource.imagePathOfPage', () {
    test("gives a page's image, as the OCR names it", () {
      Directory volume = Directory.systemTemp.createTempSync('volume');
      addTearDown(() => volume.deleteSync(recursive: true));
      File('test/media/fixtures/vol1.mokuro')
          .copySync(p.join(volume.path, 'volume.mokuro'));

      expect(ReaderMokuroSource.imagePathOfPage(volume, 0), '000a.jpg');
      expect(ReaderMokuroSource.imagePathOfPage(volume, 1), '000b.jpg');
      expect(ReaderMokuroSource.imagePathOfPage(volume, 99), isNull);
      expect(ReaderMokuroSource.imagePathOfPage(volume, -1), isNull);
    });

    test('gives nothing for a volume whose OCR is gone', () {
      Directory volume = Directory.systemTemp.createTempSync('volume');
      addTearDown(() => volume.deleteSync(recursive: true));

      expect(ReaderMokuroSource.imagePathOfPage(volume, 0), isNull);
    });
  });
}
