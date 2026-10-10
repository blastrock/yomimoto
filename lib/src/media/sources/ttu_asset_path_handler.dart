import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mime/mime.dart';

/// Serves the ebook-reader-lite build from Flutter assets at the root of the
/// WebView asset loader's origin.
class TtuAssetPathHandler extends CustomPathHandler {
  /// Create the handler.
  TtuAssetPathHandler() : super(path: '/');

  static const String _root = 'assets/ttu-ebook-reader';

  @override
  Future<WebResourceResponse?> handle(String path) async {
    String clean = path.split('?').first.split('#').first;
    List<String> candidates = clean.isEmpty
        ? ['index.html']
        : [clean, '$clean.html', '$clean/index.html'];

    for (String candidate in candidates) {
      try {
        ByteData data = await rootBundle.load('$_root/$candidate');
        return WebResourceResponse(
          contentType: lookupMimeType(candidate) ?? 'application/octet-stream',
          data: data.buffer.asUint8List(),
        );
      } catch (_) {
        continue;
      }
    }

    return null;
  }
}
