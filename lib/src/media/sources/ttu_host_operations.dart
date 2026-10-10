import 'dart:async';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:yuuna/media.dart';

/// Runs ebook-reader-lite library commands in a short-lived headless
/// WebView on the reader's origin, so they share its IndexedDB.
class TtuHostOperations {
  TtuHostOperations._();

  /// How long the host page may take to load.
  static const Duration loadTimeout = Duration(seconds: 30);

  /// Start a headless WebView on `host.html`, wait for its bridge, run
  /// [action], and dispose of the WebView whatever happens. Files in
  /// [importDirectory] are served at `<origin>/import/<index>/<name>`.
  static Future<T> run<T>(
    Future<T> Function(TtuBridge bridge) action, {
    Directory? importDirectory,
  }) async {
    ReaderTtuSource source = ReaderTtuSource.instance;
    Completer<TtuBridge> ready = Completer<TtuBridge>();
    TtuBridge? bridge;

    InAppWebViewSettings settings = source.webViewSettings;
    if (importDirectory != null) {
      settings.webViewAssetLoader = WebViewAssetLoader(
        pathHandlers: [
          TtuImportPathHandler(importDirectory),
          TtuAssetPathHandler(),
        ],
      );
    }

    HeadlessInAppWebView webView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(source.url('host.html'))),
      initialSettings: settings,
      onWebViewCreated: (controller) {
        bridge = TtuBridge(
          controller: controller,
          onReady: (event) {
            if (ready.isCompleted) {
              return;
            }
            if (event.isCompatible) {
              ready.complete(bridge);
            } else {
              ready.completeError(TtuBridgeException(
                'ready',
                'protocol ${event.protocolVersion}, app expects '
                    '${TtuBridge.protocolVersion}',
              ));
            }
          },
        );
      },
    );

    try {
      await webView.run();
      TtuBridge readyBridge;
      try {
        readyBridge = await ready.future.timeout(loadTimeout);
      } on TimeoutException {
        throw TtuBridgeException('ready', 'host page did not load');
      }
      return await action(readyBridge);
    } finally {
      await webView.dispose();
    }
  }
}
