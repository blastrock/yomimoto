import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:path/path.dart' as p;
import 'package:yuuna/media.dart';

void main() {
  late Directory root;
  late Directory temporary;
  late CatalogCancelToken cancel;
  late List<Uri> requested;
  late List<CatalogDownloadProgress> progress;

  setUp(() {
    root = Directory.systemTemp.createTempSync('catalog_download_test');
    temporary = Directory(p.join(root.path, 'catalogDownloads'));
    cancel = CatalogCancelToken();
    requested = [];
    progress = [];
  });

  tearDown(() => root.deleteSync(recursive: true));

  List<int> bytes(int n, int value) => List.filled(n, value);

  /// A client serving [routes] by URL, as streams; anything else is a 404.
  http.Client serve(Map<String, Stream<List<int>> Function()> routes) {
    return MockClient.streaming((request, _) async {
      requested.add(request.url);
      Stream<List<int>> Function()? route =
          routes[Uri.decodeFull('${request.url}')];
      if (route == null) {
        return http.StreamedResponse(Stream.value(utf8.encode('no')), 404);
      }
      return http.StreamedResponse(route(), 200);
    });
  }

  CatalogDownload download(String name, int archiveSize, int ocrSize) {
    return CatalogDownload(
      volumeName: name,
      manifest: CatalogManifest(
        archiveUrl: Uri.parse('https://c/$name.cbz'),
        archiveSize: archiveSize,
        ocrUrl: Uri.parse('https://c/$name.mokuro'),
        ocrSize: ocrSize,
      ),
    );
  }

  /// Routes serving [name]'s archive as [archive] and its OCR as [ocr].
  Map<String, Stream<List<int>> Function()> volume(
      String name, List<int> archive, List<int> ocr) {
    return {
      'https://c/$name.cbz': () => Stream.value(archive),
      'https://c/$name.mokuro': () => Stream.value(ocr),
    };
  }

  Future<int> run(
    http.Client client,
    List<CatalogDownload> downloads,
    Future<void> Function(String archivePath) importArchive,
  ) {
    return downloadCatalogVolumes(
      client: client,
      downloads: downloads,
      temporaryDirectory: temporary,
      cancel: cancel,
      importArchive: importArchive,
      onProgress: progress.add,
    );
  }

  Matcher failsFor(String volumeName, Matcher error) {
    return throwsA(isA<CatalogDownloadException>()
        .having((e) => e.volumeName, 'volumeName', volumeName)
        .having((e) => e.error, 'error', error));
  }

  test('downloads each volume beside its OCR and imports it', () async {
    List<String> archives = [];
    List<List<int>> ocrs = [];
    int imported = await run(
      serve({
        ...volume('vol 01', bytes(10, 1), bytes(3, 2)),
        ...volume('vol 02', bytes(20, 3), bytes(4, 4)),
      }),
      [download('vol 01', 10, 3), download('vol 02', 20, 4)],
      (path) async {
        archives.add(path);
        expect(File(path).readAsBytesSync(),
            archives.length == 1 ? bytes(10, 1) : bytes(20, 3));
        ocrs.add(File(p.setExtension(path, '.mokuro')).readAsBytesSync());
      },
    );

    expect(imported, 2);
    expect(archives.map(p.basename), ['volume.cbz', 'volume.cbz']);
    expect(ocrs, [bytes(3, 2), bytes(4, 4)]);
    expect(temporary.listSync(), isEmpty);
  });

  test('reports bytes over the whole batch', () async {
    await run(
      serve({
        ...volume('vol 01', bytes(10, 1), bytes(3, 2)),
        ...volume('vol 02', bytes(20, 3), bytes(4, 4)),
      }),
      [download('vol 01', 10, 3), download('vol 02', 20, 4)],
      (_) async {},
    );

    expect(progress.last.receivedBytes, 37);
    expect(progress.last.totalBytes, 37);
    expect(progress.last.volumeCount, 2);
    expect(progress.last.volumeIndex, 1);
    expect(progress.where((p) => p.importing).map((p) => p.volumeIndex),
        containsAll([0, 1]));
  });

  test('a real archive goes through importMokuroVolume', () async {
    Directory volumes = Directory(p.join(root.path, 'volumes'))..createSync();
    Archive zip = Archive()
      ..addFile(ArchiveFile.bytes('a.jpg', bytes(5, 9)));
    String ocr = jsonEncode({
      'version': '0.2.5',
      'title': 'series',
      'title_uuid': 'title-uuid',
      'volume': 'vol1',
      'volume_uuid': 'uuid-1',
      'pages': [
        {
          'img_path': 'a.jpg',
          'img_width': 10,
          'img_height': 20,
          'blocks': <Object>[],
        },
      ],
    });
    List<int> archive = ZipEncoder().encodeBytes(zip);

    int imported = await run(
      serve(volume('vol 01', archive, utf8.encode(ocr))),
      [download('vol 01', archive.length, utf8.encode(ocr).length)],
      (path) async => importMokuroVolume(MokuroImportParams(
          archivePath: path, volumesDirectory: volumes.path)),
    );

    expect(imported, 1);
    expect(File(p.join(volumes.path, 'uuid-1', 'volume.mokuro')).existsSync(),
        isTrue);
    expect(File(p.join(volumes.path, 'uuid-1', 'images', 'a.jpg'))
        .readAsBytesSync(), bytes(5, 9));
  });

  test('a dropped connection stops the batch and names the volume', () async {
    int imports = 0;
    Future<int> batch = run(
      serve({
        ...volume('vol 01', bytes(10, 1), bytes(3, 2)),
        'https://c/vol 02.cbz': () async* {
          yield bytes(5, 3);
          throw http.ClientException('connection reset');
        },
        'https://c/vol 02.mokuro': () => Stream.value(bytes(4, 4)),
        ...volume('vol 03', bytes(1, 1), bytes(1, 1)),
      }),
      [
        download('vol 01', 10, 3),
        download('vol 02', 20, 4),
        download('vol 03', 1, 1),
      ],
      (_) async => imports++,
    );

    await expectLater(
        batch,
        failsFor(
            'vol 02',
            isA<CatalogException>()
                .having((e) => e.failure, 'failure', CatalogFailure.network)));
    expect(imports, 1);
    expect(temporary.listSync(), isEmpty);
    expect(requested, isNot(contains(Uri.parse('https://c/vol 03.cbz'))));
  });

  test('an HTTP error is a failure of that volume', () async {
    await expectLater(
        run(serve({}), [download('vol 01', 10, 3)], (_) async {}),
        failsFor(
            'vol 01',
            isA<CatalogException>()
                .having((e) => e.failure, 'failure', CatalogFailure.http)));
    expect(temporary.listSync(), isEmpty);
  });

  test('an import error is a failure of that volume', () async {
    await expectLater(
        run(
          serve(volume('vol 01', bytes(10, 1), bytes(3, 2))),
          [download('vol 01', 10, 3)],
          (_) async => throw MokuroImportException(MokuroImportError.noOcr),
        ),
        failsFor(
            'vol 01',
            isA<MokuroImportException>()
                .having((e) => e.error, 'error', MokuroImportError.noOcr)));
    expect(temporary.listSync(), isEmpty);
  });

  test('cancel during a download keeps earlier volumes and deletes the '
      'partial one', () async {
    int imports = 0;
    int imported = await run(
      serve({
        ...volume('vol 01', bytes(10, 1), bytes(3, 2)),
        'https://c/vol 02.cbz': () async* {
          yield bytes(5, 3);
          cancel.cancel();
          yield bytes(5, 3);
          yield bytes(5, 3);
        },
        'https://c/vol 02.mokuro': () => Stream.value(bytes(4, 4)),
      }),
      [download('vol 01', 10, 3), download('vol 02', 15, 4)],
      (_) async => imports++,
    );

    expect(imported, 1);
    expect(imports, 1);
    expect(temporary.listSync(), isEmpty);
    expect(requested, isNot(contains(Uri.parse('https://c/vol 02.mokuro'))));
  });

  test('cancel during an import finishes it and starts nothing else',
      () async {
    List<String> finished = [];
    int imported = await run(
      serve({
        ...volume('vol 01', bytes(10, 1), bytes(3, 2)),
        ...volume('vol 02', bytes(20, 3), bytes(4, 4)),
      }),
      [download('vol 01', 10, 3), download('vol 02', 20, 4)],
      (path) async {
        cancel.cancel();
        await Future<void>.delayed(Duration.zero);
        finished.add(path);
      },
    );

    expect(imported, 1);
    expect(finished, hasLength(1));
    expect(
        requested,
        isNot(anyOf(contains(Uri.parse('https://c/vol 02.cbz')),
            contains(Uri.parse('https://c/vol 02.mokuro')))));
    expect(temporary.listSync(), isEmpty);
  });
}
