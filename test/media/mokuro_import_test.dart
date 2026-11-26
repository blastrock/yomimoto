import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yuuna/media.dart';

void main() {
  late Directory root;
  late Directory sources;
  late Directory volumes;

  setUp(() {
    root = Directory.systemTemp.createTempSync('mokuro_import_test');
    sources = Directory(p.join(root.path, 'sources'))..createSync();
    volumes = Directory(p.join(root.path, 'volumes'))..createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  /// The contents of a `.mokuro` file with pages at [imgPaths].
  String ocr(List<String> imgPaths,
      {String title = 'series',
      String volume = 'vol1',
      String uuid = 'uuid-1'}) {
    return jsonEncode({
      'version': '0.2.5',
      'title': title,
      'title_uuid': 'title-uuid',
      'volume': volume,
      'volume_uuid': uuid,
      'pages': [
        for (String imgPath in imgPaths)
          {
            'img_path': imgPath,
            'img_width': 10,
            'img_height': 20,
            'blocks': <Object>[],
          },
      ],
    });
  }

  /// Write an archive named [name] holding [files] (name to contents).
  String archive(String name, Map<String, String> files) {
    Archive zip = Archive();
    for (MapEntry<String, String> file in files.entries) {
      zip.addFile(ArchiveFile.bytes(file.key, utf8.encode(file.value)));
    }
    String path = p.join(sources.path, name);
    File(path).writeAsBytesSync(ZipEncoder().encodeBytes(zip));
    return path;
  }

  /// Write [contents] as the `.mokuro` file [name], beside the archives
  /// unless [directory] is given, and return its path.
  String ocrFile(String name, String contents, {Directory? directory}) {
    String path = p.join((directory ?? sources).path, name);
    File(path).writeAsStringSync(contents);
    return path;
  }

  MokuroImportResult import(String archivePath, {String? ocrPath}) {
    return importMokuroVolume(MokuroImportParams(
      archivePath: archivePath,
      ocrPath: ocrPath,
      volumesDirectory: volumes.path,
    ));
  }

  Matcher failsWith(MokuroImportError error) => throwsA(
      isA<MokuroImportException>().having((e) => e.error, 'error', error));

  group('importMokuroVolume', () {
    test('imports the mokuro tool layout, OCR given', () {
      String path = archive('vol1.cbz', {
        'vol1/000a.jpg': 'a',
        'vol1/000b.jpg': 'b',
      });
      String source = ocr(['000a.jpg', '000b.jpg']);
      String ocrPath = ocrFile('vol1.mokuro', source);

      MokuroImportResult result = import(path, ocrPath: ocrPath);

      expect(result.volumeUuid, 'uuid-1');
      expect(result.title, 'series vol1');
      expect(result.pageCount, 2);
      expect(result.missingPages, 0);
      expect(result.directory, p.join(volumes.path, 'uuid-1'));
      expect(File(p.join(result.directory, 'images', '000a.jpg'))
          .readAsStringSync(), 'a');
      expect(File(p.join(result.directory, 'images', '000b.jpg'))
          .readAsStringSync(), 'b');
      expect(File(p.join(result.directory, 'volume.mokuro'))
          .readAsStringSync(), source);
      expect(result.coverPath,
          p.join(result.directory, 'images', '000a.jpg'));
    });

    test('imports the mokuro-bunko layout, folder in img_path', () {
      String path = archive('【推しの子】 01.cbz', {
        '【推しの子】 01/00001.webp': '1',
      });
      String ocrPath =
          ocrFile('【推しの子】 01.mokuro', ocr(['【推しの子】 01/00001.webp']));

      MokuroImportResult result = import(path, ocrPath: ocrPath);

      expect(File(p.join(
              result.directory, 'images', '【推しの子】 01', '00001.webp'))
          .readAsStringSync(), '1');
      expect(result.missingPages, 0);
    });

    test('imports an archive with its OCR inside', () {
      String path = archive('v.zip', {
        'v.mokuro': ocr(['001.jpg']),
        '001.jpg': 'x',
      });

      MokuroImportResult result = import(path);

      expect(result.pageCount, 1);
      expect(File(p.join(result.directory, 'images', '001.jpg'))
          .readAsStringSync(), 'x');
    });

    test('prefers the given OCR to the one inside', () {
      String path = archive('v.cbz', {
        'v.mokuro': ocr(['001.jpg'], title: 'inside'),
        '001.jpg': 'x',
      });
      String ocrPath = ocrFile('v.mokuro', ocr(['001.jpg'], title: 'given'));

      expect(import(path, ocrPath: ocrPath).title, 'given vol1');
    });

    test('reads the given OCR from another directory', () {
      String path = archive('vol1.cbz', {'001.jpg': 'x'});
      Directory elsewhere = Directory(p.join(root.path, 'elsewhere'))
        ..createSync();
      String ocrPath =
          ocrFile('picked.mokuro', ocr(['001.jpg']), directory: elsewhere);

      expect(import(path, ocrPath: ocrPath).missingPages, 0);
    });

    test('ignores a .mokuro beside the archive when none is given', () {
      String path = archive('vol1.cbz', {'001.jpg': 'x'});
      ocrFile('vol1.mokuro', ocr(['001.jpg']));

      expect(() => import(path), failsWith(MokuroImportError.noOcr));
    });

    test('refuses an archive with no OCR', () {
      String path = archive('v.cbz', {'001.jpg': 'x'});

      expect(() => import(path), failsWith(MokuroImportError.noOcr));
      expect(volumes.listSync(), isEmpty);
    });

    test('refuses an archive with several OCR files and none given', () {
      String path = archive('v.cbz', {
        'a.mokuro': ocr(['001.jpg']),
        'b.mokuro': ocr(['001.jpg']),
        '001.jpg': 'x',
      });

      expect(() => import(path), failsWith(MokuroImportError.severalOcr));
      expect(volumes.listSync(), isEmpty);
    });

    test('refuses a file that is not an archive', () {
      String path = p.join(sources.path, 'x.cbz');
      File(path).writeAsStringSync('not a zip');

      expect(() => import(path), failsWith(MokuroImportError.notAnArchive));
      expect(volumes.listSync(), isEmpty);
    });

    test('refuses OCR that is not a volume', () {
      String path = archive('v.cbz', {'001.jpg': 'x'});
      String ocrPath = ocrFile('v.mokuro', '{"title": ');

      expect(() => import(path, ocrPath: ocrPath),
          failsWith(MokuroImportError.invalidOcr));
      expect(volumes.listSync(), isEmpty);
    });

    test('imports a volume with missing pages and counts them', () {
      String path = archive('v.cbz', {'001.jpg': 'x'});
      String ocrPath = ocrFile('v.mokuro', ocr(['000.jpg', '001.jpg']));

      MokuroImportResult result = import(path, ocrPath: ocrPath);

      expect(result.pageCount, 2);
      expect(result.missingPages, 1);
      expect(result.coverPath, isNull);
    });

    test('replaces the files of a volume imported before', () {
      String path = archive('v.cbz', {'001.jpg': 'new'});
      String ocrPath = ocrFile('v.mokuro', ocr(['001.jpg']));
      File stray = File(p.join(volumes.path, 'uuid-1', 'images', 'old.jpg'))
        ..createSync(recursive: true);

      MokuroImportResult result = import(path, ocrPath: ocrPath);

      expect(stray.existsSync(), isFalse);
      expect(File(p.join(result.directory, 'images', '001.jpg'))
          .readAsStringSync(), 'new');
    });

    test('never writes outside the volume directory', () {
      String path = archive('v.cbz', {'evil.jpg': 'x', '001.jpg': 'y'});
      String ocrPath = ocrFile('v.mokuro', ocr(['../evil.jpg', '001.jpg']));

      MokuroImportResult result = import(path, ocrPath: ocrPath);

      expect(result.missingPages, 1);
      expect(File(p.join(result.directory, 'evil.jpg')).existsSync(),
          isFalse);
      expect(File(p.join(volumes.path, 'evil.jpg')).existsSync(), isFalse);
    });
  });

  group('importMokuroVolume, archives as people zip them', () {
    test('imports OCR at the root beside the image folder', () {
      String path = archive('vol1.zip', {
        'vol1.mokuro': ocr(['000a.jpg']),
        'vol1/000a.jpg': 'a',
      });

      MokuroImportResult result = import(path);

      expect(result.missingPages, 0);
      expect(File(p.join(result.directory, 'images', '000a.jpg'))
          .readAsStringSync(), 'a');
    });

    test('ignores the metadata macOS adds to archives', () {
      String path = archive('vol1.zip', {
        'vol1.mokuro': ocr(['000a.jpg']),
        'vol1/000a.jpg': 'a',
        '__MACOSX/._vol1.mokuro': 'resource fork',
        '__MACOSX/vol1/._000a.jpg': 'resource fork',
      });

      MokuroImportResult result = import(path);

      expect(result.missingPages, 0);
      expect(result.title, 'series vol1');
    });
  });

  group('resolveImageEntry', () {
    test('finds the image at the root of the archive', () {
      expect(resolveImageEntry('a.jpg', {'a.jpg'}), 'a.jpg');
    });

    test('finds the image in the single top-level folder', () {
      expect(resolveImageEntry('a.jpg', {'vol/a.jpg', 'vol/b.jpg'}),
          'vol/a.jpg');
    });

    test('looks in the only folder when files sit beside it', () {
      expect(resolveImageEntry('a.jpg', {'v.mokuro', 'vol/a.jpg'}),
          'vol/a.jpg');
    });

    test('does not guess between several top-level folders', () {
      expect(resolveImageEntry('a.jpg', {'x/a.jpg', 'y/b.jpg'}), isNull);
    });

    test('rejects paths leaving the image root', () {
      expect(resolveImageEntry('../a.jpg', {'a.jpg'}), isNull);
      expect(resolveImageEntry('/a.jpg', {'a.jpg'}), isNull);
    });
  });

  test('a byte-for-byte copy keeps binary images intact', () {
    Uint8List bytes = Uint8List.fromList(List.generate(256, (i) => i));
    Archive zip = Archive()..addFile(ArchiveFile.bytes('001.png', bytes));
    String path = p.join(sources.path, 'v.cbz');
    File(path).writeAsBytesSync(ZipEncoder().encodeBytes(zip));
    String ocrPath = ocrFile('v.mokuro', ocr(['001.png']));

    MokuroImportResult result = import(path, ocrPath: ocrPath);

    expect(File(p.join(result.directory, 'images', '001.png'))
        .readAsBytesSync(), bytes);
  });
}
