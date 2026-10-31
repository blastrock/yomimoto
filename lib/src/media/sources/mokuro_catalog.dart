import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

/// The canonical form of a catalog address the user typed: `https://` in
/// front when no scheme is given, without query, fragment or trailing `/`.
/// Null when [input] is not an `http` or `https` address with a host.
String? normaliseCatalogUrl(String input) {
  String trimmed = input.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  if (!trimmed.contains('://')) {
    trimmed = 'https://$trimmed';
  }

  Uri? uri = Uri.tryParse(trimmed);
  if (uri == null ||
      (uri.scheme != 'http' && uri.scheme != 'https') ||
      uri.host.isEmpty) {
    return null;
  }

  String path = uri.path;
  while (path.endsWith('/')) {
    path = path.substring(0, path.length - 1);
  }
  return Uri(
    scheme: uri.scheme,
    userInfo: uri.userInfo,
    host: uri.host,
    port: uri.hasPort ? uri.port : null,
    path: path,
  ).toString();
}

/// The name a catalog is shown by: its address's host.
String catalogHost(String url) => Uri.parse(url).host;

/// A download size for the user, in megabytes (10⁶ bytes), never below 1
/// unless nothing at all.
String formatCatalogSize(int bytes) {
  int megabytes = (bytes / 1000000).round();
  return '${megabytes < 1 && bytes > 0 ? 1 : megabytes} MB';
}

/// Why a catalog request failed.
enum CatalogFailure {
  /// The server could not be reached, or the connection dropped.
  network,

  /// The server answered with an HTTP error.
  http,

  /// The answer is not what a mokuro-bunko server sends.
  unparseable,

  /// The manifest is of a version this app does not know.
  unsupported,

  /// The volume has no OCR yet, so it cannot be read.
  noOcr,
}

/// A catalog request failed.
class CatalogException implements Exception {
  /// Create the exception.
  CatalogException(this.failure, [this.detail]);

  /// Why the request failed.
  final CatalogFailure failure;

  /// What went wrong, for logs.
  final String? detail;

  @override
  String toString() => 'CatalogException($failure, $detail)';
}

/// A series in a catalog's library.
class CatalogSeries {
  /// Describe a series.
  const CatalogSeries({
    required this.name,
    required this.cover,
    this.native,
    this.romaji,
    this.english,
    this.tag,
  });

  /// The server's name for the series, its folder name: the key for the
  /// series' other requests.
  final String name;

  /// The cover's path, for [MokuroCatalogClient.coverUri].
  final String cover;

  /// The title in Japanese.
  final String? native;

  /// The title in romaji. Searched, never shown.
  final String? romaji;

  /// The English title.
  final String? english;

  /// What sets this edition apart, such as `Upscaled` or `HD Scan`.
  final String? tag;

  /// The title to show: the native one, else the server's name.
  String get displayTitle => native ?? name;

  /// Whether the series' titles or name contain [query], ignoring case. An
  /// empty query matches every series.
  bool matches(String query) {
    String needle = query.trim().toLowerCase();
    if (needle.isEmpty) {
      return true;
    }
    return [native, romaji, english, name]
        .any((text) => text != null && text.toLowerCase().contains(needle));
  }
}

/// A volume of a series in a catalog.
class CatalogVolume {
  /// Describe a volume.
  const CatalogVolume({
    required this.name,
    required this.cover,
    required this.ocrPending,
  });

  /// The server's name for the volume.
  final String name;

  /// The cover's path, for [MokuroCatalogClient.coverUri].
  final String cover;

  /// Whether the volume is still waiting for its OCR.
  final bool ocrPending;
}

/// The files of a volume to download.
class CatalogManifest {
  /// Describe a volume's files.
  const CatalogManifest({
    required this.archiveUrl,
    required this.archiveSize,
    required this.ocrUrl,
    required this.ocrSize,
  });

  /// The volume's `.cbz`.
  final Uri archiveUrl;

  /// The `.cbz`'s size in bytes.
  final int archiveSize;

  /// The volume's `.mokuro`.
  final Uri ocrUrl;

  /// The `.mokuro`'s size in bytes.
  final int ocrSize;

  /// How many bytes downloading the volume takes.
  int get totalSize => archiveSize + ocrSize;
}

/// Reads the catalog API of a mokuro-bunko server at a base URL. Every
/// `fetch` method throws only [CatalogException].
class MokuroCatalogClient {
  /// A client for the catalog at [baseUrl]. [client] is for tests and for
  /// sharing one connection; without one, the catalog client creates its own
  /// and [close] closes it.
  MokuroCatalogClient(
    String baseUrl, {
    http.Client? client,
    this.timeout = const Duration(seconds: 30),
  })  : _base = Uri.parse(baseUrl),
        _ownsClient = client == null,
        httpClient = client ?? http.Client();

  final Uri _base;
  final bool _ownsClient;

  /// The client requests go through, also used for downloads.
  final http.Client httpClient;

  /// How long a request may take.
  final Duration timeout;

  /// Close the HTTP client if this catalog client created it.
  void close() {
    if (_ownsClient) {
      httpClient.close();
    }
  }

  Uri _endpoint(List<String> segments, [Map<String, String>? query]) {
    return _base.replace(
      pathSegments: [
        ..._base.pathSegments.where((segment) => segment.isNotEmpty),
        ...segments,
      ],
      queryParameters: query,
    );
  }

  /// The address of the cover at [coverPath].
  Uri coverUri(String coverPath) =>
      _endpoint(['catalog', 'api', 'cover'], {'path': coverPath});

  /// Every series of the catalog, in the server's order.
  Future<List<CatalogSeries>> fetchLibrary() async {
    Object? json = await _getJson(_endpoint(['catalog', 'api', 'library']));
    return _parse(() {
      List<Object?> series = (json! as Map<String, dynamic>)['series'] as List;
      return [
        for (Map<String, dynamic> item in series.cast<Map<String, dynamic>>())
          _parseSeries(item),
      ];
    });
  }

  /// The volumes of the series named [seriesName], in the server's order.
  Future<List<CatalogVolume>> fetchVolumes(String seriesName) async {
    Object? json = await _getJson(
        _endpoint(['catalog', 'api', 'series'], {'name': seriesName}));
    return _parse(() {
      List<Object?> volumes =
          (json! as Map<String, dynamic>)['volumes'] as List;
      return [
        for (Map<String, dynamic> item in volumes.cast<Map<String, dynamic>>())
          CatalogVolume(
            name: item['name'] as String,
            cover: item['cover'] as String,
            ocrPending: item['ocr_pending'] as bool? ?? false,
          ),
      ];
    });
  }

  /// The `volume_uuid` of each volume of the series named [seriesName], by
  /// volume name, from the series' `series.json`.
  Future<Map<String, String>> fetchVolumeUuids(String seriesName) async {
    Object? json = await _getJson(
        _endpoint(['mokuro-reader', seriesName, 'series.json']));
    return _parse(() {
      List<Object?> volumes =
          (json! as Map<String, dynamic>)['volumes'] as List;
      return {
        for (Map<String, dynamic> item in volumes.cast<Map<String, dynamic>>())
          item['volume_title'] as String:
              item['volume_uuid'] as String,
      };
    });
  }

  /// The files of the volume named [volumeName] in the series named
  /// [seriesName].
  Future<CatalogManifest> fetchManifest(
      String seriesName, String volumeName) async {
    Object? json = await _getJson(_endpoint(['catalog', 'api', 'manifest'],
        {'series': seriesName, 'volume': volumeName}));
    return _parse(() {
      Map<String, dynamic> manifest = json! as Map<String, dynamic>;
      Object? version = manifest['version'];
      if (version != 1) {
        throw CatalogException(
            CatalogFailure.unsupported, 'manifest version $version');
      }

      Map<String, dynamic> archive =
          manifest['archive'] as Map<String, dynamic>;
      Map<String, dynamic>? ocr = manifest['ocr'] as Map<String, dynamic>?;
      if (ocr == null) {
        throw CatalogException(CatalogFailure.noOcr);
      }
      return CatalogManifest(
        archiveUrl: _base.resolve(archive['url'] as String),
        archiveSize: archive['size'] as int,
        ocrUrl: _base.resolve(ocr['url'] as String),
        ocrSize: ocr['size'] as int,
      );
    });
  }

  CatalogSeries _parseSeries(Map<String, dynamic> json) {
    Map<String, dynamic>? titles = json['titles'] as Map<String, dynamic>?;
    return CatalogSeries(
      name: json['name'] as String,
      cover: json['cover'] as String,
      native: titles?['native'] as String?,
      romaji: titles?['romaji'] as String?,
      english: titles?['english'] as String?,
      tag: json['tag'] as String?,
    );
  }

  /// Run [read] over decoded JSON, turning a wrong shape into a
  /// [CatalogFailure.unparseable].
  T _parse<T>(T Function() read) {
    try {
      return read();
    } on TypeError catch (error) {
      throw CatalogException(CatalogFailure.unparseable, '$error');
    }
  }

  Future<Object?> _getJson(Uri uri) async {
    http.Response response;
    try {
      response = await httpClient.get(uri).timeout(timeout);
    } on TimeoutException {
      throw CatalogException(CatalogFailure.network, 'timeout');
    } on http.ClientException catch (error) {
      throw CatalogException(CatalogFailure.network, error.message);
    } on IOException catch (error) {
      throw CatalogException(CatalogFailure.network, '$error');
    }

    if (response.statusCode != 200) {
      throw CatalogException(CatalogFailure.http, '${response.statusCode}');
    }
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException catch (error) {
      throw CatalogException(CatalogFailure.unparseable, error.message);
    }
  }
}
