import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:yuuna/media.dart';

void main() {
  // Trimmed from mokuro.moe's responses on 2026-10-31.
  String library = jsonEncode({
    'series': [
      {
        'name': '#Zombie Sagashitemasu',
        'path': '#Zombie Sagashitemasu',
        'cover': '#Zombie Sagashitemasu/-Zombie-Sagashitemasu-01.webp',
        'volume_count': 1,
        'titles': {
          'native': '#ゾンビさがしてます',
          'romaji': '#Zombie Sagashitemasu',
          'english': '#ImLookingForZombies',
        },
        'community': {'score': 64.0},
      },
      {
        'name': '20 Seiki Shounen (Upscaled)',
        'cover': '20 Seiki Shounen (Upscaled)/[浦沢直樹] 20世紀少年 01.webp',
        'titles': {
          'native': '20世紀少年',
          'romaji': '20 Seiki Shounen',
          'english': '20th Century Boys',
        },
        'tag': 'Upscaled',
      },
      {
        'name': 'Candy Samurai Wars',
        'cover': 'Candy Samurai Wars/01.webp',
      },
    ],
  });

  String volumes = jsonEncode({
    'name': '#Zombie Sagashitemasu',
    'cover': '#Zombie Sagashitemasu/-Zombie-Sagashitemasu-01.webp',
    'volumes': [
      {
        'name': '-Zombie-Sagashitemasu-01',
        'cover': '#Zombie Sagashitemasu/-Zombie-Sagashitemasu-01.webp',
        'ocr_pending': false,
        'ocr_active': false,
        'page_count': 173,
      },
      {
        'name': '-Zombie-Sagashitemasu-02',
        'cover': '#Zombie Sagashitemasu/-Zombie-Sagashitemasu-02.webp',
        'ocr_pending': true,
      },
    ],
  });

  String seriesFile = jsonEncode({
    'version': 2,
    'series_title': '#Zombie Sagashitemasu',
    'volumes': [
      {
        'volume_uuid': '882d0326-606e-4b84-a496-90dcb68708ce',
        'volume_title': '-Zombie-Sagashitemasu-01',
        'page_count': 173,
      },
    ],
  });

  Map<String, Object?> manifestJson() => {
        'version': 1,
        'series': '#Zombie Sagashitemasu',
        'volume': '-Zombie-Sagashitemasu-01',
        'archive': {
          'url': '/mokuro-reader/%23Zombie%20Sagashitemasu/'
              '-Zombie-Sagashitemasu-01.cbz',
          'size': 55846180,
        },
        'ocr': {
          'url': '/mokuro-reader/%23Zombie%20Sagashitemasu/'
              '-Zombie-Sagashitemasu-01.mokuro',
          'size': 398114,
          'sha256': '7c3b',
        },
        'layers': <Object>[],
        'series_file': {
          'url': '/mokuro-reader/%23Zombie%20Sagashitemasu/series.json',
        },
      };

  /// A client for mokuro.moe answering every request with [body] and
  /// [status], recording the requests in [requests].
  MokuroCatalogClient clientFor(String body,
      {int status = 200, List<http.Request>? requests}) {
    return MokuroCatalogClient(
      'https://mokuro.moe',
      client: MockClient((request) async {
        requests?.add(request);
        return http.Response.bytes(utf8.encode(body), status);
      }),
    );
  }

  Matcher failsWith(CatalogFailure failure) => throwsA(isA<CatalogException>()
      .having((e) => e.failure, 'failure', failure));

  group('normaliseCatalogUrl', () {
    test('adds https and drops trailing slashes, query and fragment', () {
      expect(normaliseCatalogUrl('  mokuro.moe/ '), 'https://mokuro.moe');
      expect(normaliseCatalogUrl('https://mokuro.moe/?a=1#x'),
          'https://mokuro.moe');
      expect(normaliseCatalogUrl('http://host:8080/sub/'),
          'http://host:8080/sub');
    });

    test('refuses empty input and other schemes', () {
      expect(normaliseCatalogUrl('   '), isNull);
      expect(normaliseCatalogUrl('ftp://mokuro.moe'), isNull);
    });
  });

  test('catalogHost names the server', () {
    expect(catalogHost('https://mokuro.moe'), 'mokuro.moe');
  });

  test('formatCatalogSize', () {
    expect(formatCatalogSize(98000000), '98 MB');
    expect(formatCatalogSize(55846180 + 398114), '56 MB');
    expect(formatCatalogSize(1000), '1 MB');
  });

  group('MokuroCatalogClient', () {
    test('fetchLibrary reads titles, tags and series with no titles',
        () async {
      List<http.Request> requests = [];
      List<CatalogSeries> series =
          await clientFor(library, requests: requests).fetchLibrary();

      expect(requests.single.url,
          Uri.parse('https://mokuro.moe/catalog/api/library'));
      expect(series, hasLength(3));
      expect(series[0].name, '#Zombie Sagashitemasu');
      expect(series[0].cover,
          '#Zombie Sagashitemasu/-Zombie-Sagashitemasu-01.webp');
      expect(series[0].displayTitle, '#ゾンビさがしてます');
      expect(series[0].tag, isNull);
      expect(series[1].tag, 'Upscaled');
      expect(series[2].native, isNull);
      expect(series[2].displayTitle, 'Candy Samurai Wars');
    });

    test('matches searches native, romaji, English and name, ignoring case',
        () async {
      CatalogSeries s = (await clientFor(library).fetchLibrary()).first;

      expect(s.matches('ゾンビ'), isTrue);
      expect(s.matches('zombie sagashi'), isTrue);
      expect(s.matches('LOOKINGFOR'), isTrue);
      expect(s.matches(''), isTrue);
      expect(s.matches('  '), isTrue);
      expect(s.matches('berserk'), isFalse);
    });

    test('fetchVolumes encodes the series name and keeps ocr_pending',
        () async {
      List<http.Request> requests = [];
      List<CatalogVolume> result = await clientFor(volumes, requests: requests)
          .fetchVolumes('#Zombie Sagashitemasu');

      expect(requests.single.url.path, '/catalog/api/series');
      expect(requests.single.url.queryParameters,
          {'name': '#Zombie Sagashitemasu'});
      expect(result, hasLength(2));
      expect(result[0].name, '-Zombie-Sagashitemasu-01');
      expect(result[0].cover,
          '#Zombie Sagashitemasu/-Zombie-Sagashitemasu-01.webp');
      expect(result[0].ocrPending, isFalse);
      expect(result[1].ocrPending, isTrue);
    });

    test('fetchVolumeUuids reads series.json beside the volumes', () async {
      List<http.Request> requests = [];
      Map<String, String> uuids =
          await clientFor(seriesFile, requests: requests)
              .fetchVolumeUuids('#Zombie Sagashitemasu');

      expect(requests.single.url.host, 'mokuro.moe');
      expect(requests.single.url.pathSegments,
          ['mokuro-reader', '#Zombie Sagashitemasu', 'series.json']);
      expect(uuids,
          {'-Zombie-Sagashitemasu-01': '882d0326-606e-4b84-a496-90dcb68708ce'});
    });

    test('fetchManifest resolves URLs without encoding them again', () async {
      List<http.Request> requests = [];
      CatalogManifest manifest =
          await clientFor(jsonEncode(manifestJson()), requests: requests)
              .fetchManifest(
                  '20 Seiki Shounen (Upscaled)', '[浦沢直樹] 20世紀少年 01');

      expect(requests.single.url.path, '/catalog/api/manifest');
      expect(requests.single.url.queryParameters, {
        'series': '20 Seiki Shounen (Upscaled)',
        'volume': '[浦沢直樹] 20世紀少年 01',
      });
      expect(
          manifest.archiveUrl.toString(),
          'https://mokuro.moe/mokuro-reader/%23Zombie%20Sagashitemasu/'
          '-Zombie-Sagashitemasu-01.cbz');
      expect(
          manifest.ocrUrl.toString(),
          'https://mokuro.moe/mokuro-reader/%23Zombie%20Sagashitemasu/'
          '-Zombie-Sagashitemasu-01.mokuro');
      expect(manifest.archiveSize, 55846180);
      expect(manifest.ocrSize, 398114);
      expect(manifest.totalSize, 55846180 + 398114);
    });

    test('fetchManifest refuses another manifest version', () {
      Map<String, Object?> json = manifestJson()..['version'] = 2;
      expect(clientFor(jsonEncode(json)).fetchManifest('s', 'v'),
          failsWith(CatalogFailure.unsupported));
    });

    test('fetchManifest refuses a manifest with no OCR', () {
      Map<String, Object?> json = manifestJson()..['ocr'] = null;
      expect(clientFor(jsonEncode(json)).fetchManifest('s', 'v'),
          failsWith(CatalogFailure.noOcr));
    });

    test('an HTML page served with 200 is unparseable', () {
      expect(clientFor('<html><body>Hello</body></html>').fetchLibrary(),
          failsWith(CatalogFailure.unparseable));
    });

    test('a missing series key is unparseable', () {
      expect(clientFor(jsonEncode({'x': <Object>[]})).fetchLibrary(),
          failsWith(CatalogFailure.unparseable));
    });

    test('a wrongly typed field is unparseable', () {
      expect(
          clientFor(jsonEncode({
            'series': [
              {'name': 3, 'cover': 'c'},
            ],
          })).fetchLibrary(),
          failsWith(CatalogFailure.unparseable));
    });

    test('a 404 is an http failure', () {
      expect(clientFor('not found', status: 404).fetchLibrary(),
          failsWith(CatalogFailure.http));
    });

    test('a client exception is a network failure', () {
      MokuroCatalogClient client = MokuroCatalogClient(
        'https://mokuro.moe',
        client: MockClient((_) async => throw http.ClientException('down')),
      );
      expect(client.fetchLibrary(), failsWith(CatalogFailure.network));
    });

    test('coverUri encodes the path', () {
      Uri uri = clientFor('').coverUri(
          '#Zombie Sagashitemasu/-Zombie-Sagashitemasu-01.webp');

      expect(uri.host, 'mokuro.moe');
      expect(uri.path, '/catalog/api/cover');
      expect(uri.queryParameters,
          {'path': '#Zombie Sagashitemasu/-Zombie-Sagashitemasu-01.webp'});
    });

    test('a catalog under a sub-path keeps it in its requests', () async {
      List<http.Request> requests = [];
      await MokuroCatalogClient(
        'https://host/sub',
        client: MockClient((request) async {
          requests.add(request);
          return http.Response.bytes(utf8.encode(library), 200);
        }),
      ).fetchLibrary();

      expect(requests.single.url,
          Uri.parse('https://host/sub/catalog/api/library'));
    });
  });
}
