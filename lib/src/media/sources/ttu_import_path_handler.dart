import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

/// Serves files staged for import from [directory] at
/// `<origin>/import/<index>/<name>`, so that ttu's importer can `fetch` them
/// under their original file names.
class TtuImportPathHandler extends CustomPathHandler {
  /// Create the handler.
  TtuImportPathHandler(this.directory) : super(path: '/import/');

  /// Directory holding the staged files, one numbered subdirectory per file.
  final Directory directory;

  /// The file in [directory] that [path], relative to `/import/`, names, or
  /// null if it names none.
  ///
  /// The asset loader passes the URL's path already decoded and without its
  /// query, so [path] holds the file name as is: decoding it again fails on
  /// any non-ASCII character or `%`.
  static File? stagedFile(Directory directory, String path) {
    List<String> segments = path.split('/');
    if (segments.length != 2 || int.tryParse(segments[0]) == null) {
      return null;
    }
    String name = segments[1];
    if (name.isEmpty || name.contains('/') || name == '..' || name == '.') {
      return null;
    }

    return File(p.join(directory.path, segments[0], name));
  }

  // Returning null would send the request on to the network, where the
  // origin does not exist, and ttu would only see a `TypeError` from
  // `fetch`. Every path under /import/ is answered here instead.
  @override
  Future<WebResourceResponse?> handle(String path) async {
    try {
      File? file = stagedFile(directory, path);
      if (file == null || !file.existsSync()) {
        debugPrint('ttu import: no staged file for $path');
        return _error(404, 'Not Found');
      }

      return WebResourceResponse(
        contentType: lookupMimeType(file.path) ?? 'application/octet-stream',
        data: await file.readAsBytes(),
      );
    } catch (error) {
      debugPrint('ttu import: cannot serve $path: $error');
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
