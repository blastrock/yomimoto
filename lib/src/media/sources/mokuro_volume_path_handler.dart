import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Serves the files of the open manga volume from [directory] at
/// `<origin>/volume/`: `volume.mokuro` and `images/<img_path>`.
class MokuroVolumePathHandler extends CustomPathHandler {
  /// Create the handler.
  MokuroVolumePathHandler(this.directory) : super(path: '/volume/');

  /// The volume's directory.
  final Directory directory;

  /// The file in [directory] that [path], relative to `/volume/`, names, or
  /// null if it names none or leaves [directory].
  ///
  /// The asset loader passes the URL's path already decoded and without its
  /// query, so [path] holds the file name as is: decoding it again fails on
  /// any non-ASCII character or `%`.
  static File? volumeFile(Directory directory, String path) {
    if (path.isEmpty || path.endsWith('/') || p.posix.isAbsolute(path)) {
      return null;
    }
    List<String> segments = path.split('/');
    if (segments.any((segment) => segment.isEmpty || segment == '..')) {
      return null;
    }

    return File(p.joinAll([directory.path, ...segments]));
  }

  // Returning null would send the request on to the network, where the
  // origin does not exist. Every path under /volume/ is answered here.
  @override
  Future<WebResourceResponse?> handle(String path) async {
    try {
      File? file = volumeFile(directory, path);
      if (file == null || !file.existsSync()) {
        debugPrint('manga reader: no volume file for $path');
        return _error(404, 'Not Found');
      }

      return WebResourceResponse(
        contentType: lookupMimeType(file.path) ?? 'application/octet-stream',
        data: await file.readAsBytes(),
      );
    } catch (error) {
      debugPrint('manga reader: cannot serve $path: $error');
      return _error(500, 'Internal Server Error');
    }
  }

  WebResourceResponse _error(int statusCode, String reasonPhrase) =>
      WebResourceResponse(
        contentType: 'text/plain',
        statusCode: statusCode,
        reasonPhrase: reasonPhrase,
        data: Uint8List(0),
      );
}
