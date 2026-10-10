import 'dart:io';

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

  @override
  Future<WebResourceResponse?> handle(String path) async {
    List<String> segments = path.split('?').first.split('/');
    if (segments.length != 2 || int.tryParse(segments[0]) == null) {
      return null;
    }
    String name = Uri.decodeComponent(segments[1]);
    if (name.isEmpty || name.contains('/') || name == '..' || name == '.') {
      return null;
    }

    File file = File(p.join(directory.path, segments[0], name));
    if (!file.existsSync()) {
      return null;
    }

    return WebResourceResponse(
      contentType: lookupMimeType(name) ?? 'application/octet-stream',
      data: await file.readAsBytes(),
    );
  }
}
