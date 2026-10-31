import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mime/mime.dart';

/// Serves the manga reader page from Flutter assets at `<origin>/manga/`.
class MokuroAssetPathHandler extends CustomPathHandler {
  /// Create the handler.
  MokuroAssetPathHandler() : super(path: '/manga/');

  static const String _root = 'assets/manga-reader';

  @override
  Future<WebResourceResponse?> handle(String path) async {
    String clean = path.split('?').first.split('#').first;
    if (clean.isEmpty || clean.contains('..')) {
      return null;
    }

    try {
      ByteData data = await rootBundle.load('$_root/$clean');
      return WebResourceResponse(
        contentType: lookupMimeType(clean) ?? 'application/octet-stream',
        data: data.buffer.asUint8List(),
      );
    } catch (_) {
      return null;
    }
  }
}
