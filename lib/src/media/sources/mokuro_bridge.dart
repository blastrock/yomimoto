import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Sent once the manga reader page has read its volume.
class MokuroReadyEvent {
  /// Create the event from its wire form.
  MokuroReadyEvent.fromJson(Map<String, dynamic> json)
      : protocolVersion = json['protocolVersion'] as int;

  /// Protocol version spoken by the page.
  final int protocolVersion;

  /// Whether the page speaks the same protocol as [MokuroBridge].
  bool get isCompatible => protocolVersion == MokuroBridge.protocolVersion;
}

/// A tap on the text of an OCR block, or a tap that dismisses the shown one.
class MokuroTapEvent {
  /// Create the event from its wire form.
  MokuroTapEvent.fromJson(Map<String, dynamic> json)
      : text = json['text'] as String? ?? '',
        offset = json['offset'] as int? ?? -1,
        page = json['page'] as int? ?? -1,
        x = (json['x'] as num).round(),
        y = (json['y'] as num).round();

  /// The block's lines, joined, as rendered.
  final String text;

  /// UTF-16 index of the tapped character in [text], or -1.
  final int offset;

  /// The index of the block's page, or -1.
  final int page;

  /// Tap position in logical pixels from the left of the WebView.
  final int x;

  /// Tap position in logical pixels from the top of the WebView.
  final int y;

  /// Whether the tap hit no character and should close the popup.
  bool get isDismiss => offset < 0 || text.isEmpty;
}

/// The pages now shown: one, or two side by side.
class MokuroPageEvent {
  /// Create the event from its wire form.
  MokuroPageEvent.fromJson(Map<String, dynamic> json)
      : pages = (json['pages'] as List<dynamic>).cast<int>(),
        count = json['count'] as int;

  /// The indices of the pages shown, in ascending order.
  final List<int> pages;

  /// How many pages the volume has.
  final int count;

  /// The lowest page shown.
  int get first => pages.first;

  /// The highest page shown: the reading position.
  int get last => pages.last;
}

/// A bridge command failed on the web side or timed out.
class MokuroBridgeException implements Exception {
  /// Create the exception.
  MokuroBridgeException(this.command, this.message);

  /// The command that failed.
  final String command;

  /// The JavaScript error or a description of the failure.
  final String message;

  @override
  String toString() => 'MokuroBridgeException($command): $message';
}

/// Typed access to the manga reader page (`assets/manga-reader/`) running in
/// a WebView.
///
/// Events arrive through the `mokuroHost` JavaScript handler; commands are
/// methods on `window.mokuroHost`, called with
/// [InAppWebViewController.callAsyncJavaScript].
class MokuroBridge {
  /// Attach a bridge to [controller]. Call from `onWebViewCreated`, before
  /// the page loads, so that no event is missed.
  MokuroBridge({
    required this.controller,
    this.onReady,
    this.onTap,
    this.onPage,
    this.onMenu,
    this.onTurn,
  }) {
    controller.addJavaScriptHandler(
      handlerName: 'mokuroHost',
      callback: _dispatch,
    );
  }

  /// Must equal `PROTOCOL_VERSION` in `assets/manga-reader/reader.js`.
  static const int protocolVersion = 2;

  /// Timeout applied to every command.
  static const Duration commandTimeout = Duration(seconds: 10);

  /// The WebView this bridge talks to.
  final InAppWebViewController controller;

  /// Called when the page has read its volume.
  final void Function(MokuroReadyEvent)? onReady;

  /// Called when OCR text is tapped, or a tap dismisses it.
  final void Function(MokuroTapEvent)? onTap;

  /// Called whenever the pages shown change, the first ones included.
  final void Function(MokuroPageEvent)? onPage;

  /// Called when the middle of the screen is tapped away from any text.
  final void Function()? onMenu;

  /// Called before the page draws a different spread. The page waits until
  /// the returned future completes.
  final Future<void> Function()? onTurn;

  /// The handler's result goes back to the page: `turn` waits on it.
  Future<void>? _dispatch(List<dynamic> arguments) {
    if (arguments.isEmpty || arguments.first is! Map) {
      return null;
    }

    Map<String, dynamic> message =
        Map<String, dynamic>.from(arguments.first as Map);

    switch (message['type']) {
      case 'ready':
        onReady?.call(MokuroReadyEvent.fromJson(message));
      case 'tap':
        onTap?.call(MokuroTapEvent.fromJson(message));
      case 'page':
        onPage?.call(MokuroPageEvent.fromJson(message));
      case 'menu':
        onMenu?.call();
      case 'turn':
        return onTurn?.call();
      default:
        debugPrint('mokuroHost: unknown event ${message['type']}');
    }
    return null;
  }

  Future<dynamic> _call(
    String command, {
    Map<String, dynamic> args = const {},
  }) async {
    CallAsyncJavaScriptResult? result;
    try {
      result = await controller.callAsyncJavaScript(
        functionBody: 'return await window.mokuroHost[command](args);',
        arguments: {'command': command, 'args': args},
      ).timeout(commandTimeout);
    } on TimeoutException {
      throw MokuroBridgeException(command, 'timed out');
    }

    if (result == null) {
      throw MokuroBridgeException(command, 'no result');
    }
    if (result.error != null) {
      // JavaScript errors arrive as `Error: <message>`.
      throw MokuroBridgeException(
        command,
        result.error!.replaceFirst(RegExp('^Error: '), ''),
      );
    }

    return result.value;
  }

  /// Show the next pages in reading order.
  Future<void> nextPage() => _call('nextPage');

  /// Show the previous pages in reading order.
  Future<void> prevPage() => _call('prevPage');

  /// Show the spread holding [page].
  Future<void> goToPage(int page) => _call('goToPage', args: {'page': page});

  /// Select [length] characters from [start] in the shown block's text.
  Future<void> highlight({required int start, required int length}) =>
      _call('highlight', args: {'start': start, 'length': length});

  /// Remove any selection, leaving the shown block shown.
  Future<void> clearSelection() => _call('clearSelection');

  /// Hide the shown block and remove any selection.
  Future<void> clearOverlay() => _call('clearOverlay');

  /// The current selection without line breaks, trimmed.
  Future<String> getSelectedText() async =>
      (await _call('getSelectedText') as String?) ?? '';
}
