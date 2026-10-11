import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Sent once per page load when the ebook-reader-lite host bridge is up.
class TtuReadyEvent {
  /// Create the event from its wire form.
  TtuReadyEvent.fromJson(Map<String, dynamic> json)
      : protocolVersion = json['protocolVersion'] as int,
        route = json['route'] as String? ?? '';

  /// Protocol version spoken by the web side.
  final int protocolVersion;

  /// Path of the page that loaded.
  final String route;

  /// Whether the web side speaks the same protocol as [TtuBridge].
  bool get isCompatible => protocolVersion == TtuBridge.protocolVersion;
}

/// A tap on book content.
class TtuTapEvent {
  /// Create the event from its wire form.
  TtuTapEvent.fromJson(Map<String, dynamic> json)
      : text = json['text'] as String? ?? '',
        offset = json['offset'] as int? ?? -1,
        position = json['position'] as int? ?? -1,
        x = (json['x'] as num).round(),
        y = (json['y'] as num).round();

  /// The tapped paragraph with furigana removed.
  final String text;

  /// UTF-16 index of the tapped character in [text], or -1.
  final int offset;

  /// The tapped character's position in the book, in ttu bookmark units
  /// (Japanese characters from the start), or -1.
  final int position;

  /// Tap position in logical pixels from the left of the WebView.
  final int x;

  /// Tap position in logical pixels from the top of the WebView.
  final int y;

  /// Whether the tap hit no character and should close the popup.
  bool get isDismiss => offset < 0 || text.isEmpty;
}

/// The reader's current theme colours.
class TtuThemeEvent {
  /// Create the event from its wire form.
  TtuThemeEvent.fromJson(Map<String, dynamic> json)
      : backgroundColor = _colour(json['backgroundColor']),
        fontColor = _colour(json['fontColor']);

  /// Page background colour.
  final Color backgroundColor;

  /// Text colour.
  final Color fontColor;

  static Color _colour(dynamic json) {
    Map<String, dynamic> rgba = Map<String, dynamic>.from(json as Map);
    return Color.fromRGBO(
      (rgba['r'] as num).round(),
      (rgba['g'] as num).round(),
      (rgba['b'] as num).round(),
      (rgba['a'] as num? ?? 1).toDouble(),
    );
  }
}

/// A book in ttu's IndexedDB.
class TtuBook {
  /// Create the book from its wire form.
  TtuBook.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        title = json['title'] as String? ?? '';

  /// ttu's id for the book (IndexedDB key of the `data` store).
  final int id;

  /// The book's title.
  final String title;
}

/// A bridge command failed on the web side or timed out.
class TtuBridgeException implements Exception {
  /// Create the exception.
  TtuBridgeException(this.command, this.message);

  /// The command that failed.
  final String command;

  /// The JavaScript error or a description of the failure.
  final String message;

  @override
  String toString() => 'TtuBridgeException($command): $message';
}

/// Typed access to the host bridge of ebook-reader-lite running in a WebView.
///
/// Events arrive through the `ttuHost` JavaScript handler; commands are
/// methods on `window.ttuHost`, called with
/// [InAppWebViewController.callAsyncJavaScript].
class TtuBridge {
  /// Attach a bridge to [controller]. Call from `onWebViewCreated`, before
  /// the page loads, so that no event is missed.
  TtuBridge({
    required this.controller,
    this.onReady,
    this.onTap,
    this.onTheme,
    this.onExit,
  }) {
    controller.addJavaScriptHandler(
      handlerName: 'ttuHost',
      callback: _dispatch,
    );
  }

  /// Must equal `PROTOCOL_VERSION` in ebook-reader-lite's `host-bridge.ts`.
  static const int protocolVersion = 3;

  /// Timeout applied to every command.
  static const Duration commandTimeout = Duration(seconds: 10);

  /// The WebView this bridge talks to.
  final InAppWebViewController controller;

  /// Called when a page with the bridge has loaded.
  final void Function(TtuReadyEvent)? onReady;

  /// Called when book content is tapped.
  final void Function(TtuTapEvent)? onTap;

  /// Called with the current theme on load and on every theme change.
  final void Function(TtuThemeEvent)? onTheme;

  /// Called when the reader's Exit entry is chosen.
  final void Function()? onExit;

  void _dispatch(List<dynamic> arguments) {
    if (arguments.isEmpty || arguments.first is! Map) {
      return;
    }

    Map<String, dynamic> message =
        Map<String, dynamic>.from(arguments.first as Map);

    switch (message['type']) {
      case 'ready':
        onReady?.call(TtuReadyEvent.fromJson(message));
        break;
      case 'tap':
        onTap?.call(TtuTapEvent.fromJson(message));
        break;
      case 'theme':
        onTheme?.call(TtuThemeEvent.fromJson(message));
        break;
      case 'exit':
        onExit?.call();
        break;
      default:
        debugPrint('ttuHost: unknown event ${message['type']}');
    }
  }

  Future<dynamic> _call(
    String command, {
    Map<String, dynamic> args = const {},
    Duration timeout = commandTimeout,
  }) async {
    CallAsyncJavaScriptResult? result;
    try {
      result = await controller.callAsyncJavaScript(
        functionBody: 'return await window.ttuHost[command](args);',
        arguments: {'command': command, 'args': args},
      ).timeout(timeout);
    } on TimeoutException {
      throw TtuBridgeException(command, 'timed out');
    }

    if (result == null) {
      throw TtuBridgeException(command, 'no result');
    }
    if (result.error != null) {
      // JavaScript errors arrive as `Error: <message>`.
      throw TtuBridgeException(
        command,
        result.error!.replaceFirst(RegExp('^Error: '), ''),
      );
    }

    return result.value;
  }

  /// Turn to the next page (paginated) or scroll one screen (continuous).
  Future<void> nextPage() => _call('nextPage');

  /// Turn to the previous page.
  Future<void> prevPage() => _call('prevPage');

  /// Select [length] characters from [start] in the last tapped paragraph.
  Future<void> highlight({required int start, required int length}) =>
      _call('highlight', args: {'start': start, 'length': length});

  /// Remove any selection in the reader.
  Future<void> clearSelection() => _call('clearSelection');

  /// The current selection with furigana removed, trimmed.
  Future<String> getSelectedText() async =>
      (await _call('getSelectedText') as String?) ?? '';

  /// Every book in ttu's library.
  Future<List<TtuBook>> listBooks() async {
    List<dynamic> raw = (await _call('listBooks') as List<dynamic>?) ?? [];
    return raw
        .map((e) => TtuBook.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// The cover of book [id] as a data URL, or null if it has none.
  Future<String?> getCover(int id) async =>
      await _call('getCover', args: {'id': id}) as String?;

  /// Import the files at [urls] (served to the WebView) with ttu's importer.
  Future<void> importBooks(List<String> urls, {required Duration timeout}) =>
      _call('importBooks', args: {'urls': urls}, timeout: timeout);

  /// Delete book [id] and its bookmark from ttu's library.
  Future<void> deleteBook(int id) => _call('deleteBook', args: {'id': id});
}
