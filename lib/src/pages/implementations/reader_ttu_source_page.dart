import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:share_plus/share_plus.dart';
import 'package:yuuna/creator.dart';
import 'package:yuuna/language.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// The media page used for the [ReaderTtuSource].
class ReaderTtuSourcePage extends BaseSourcePage {
  /// Create an instance of this page.
  const ReaderTtuSourcePage({
    super.item,
    this.peekPosition,
    super.key,
  });

  /// If set, open the book at this position without saving its bookmark.
  final int? peekPosition;

  @override
  BaseSourcePageState createState() => _ReaderTtuSourcePageState();
}

class _ReaderTtuSourcePageState extends BaseSourcePageState<ReaderTtuSourcePage>
    with WidgetsBindingObserver {
  /// The media source pertaining to this page.
  ReaderTtuSource get mediaSource => ReaderTtuSource.instance;
  bool _controllerInitialised = false;
  late InAppWebViewController _controller;
  TtuBridge? _bridge;

  Orientation? lastOrientation;

  final FocusNode _focusNode = FocusNode();
  bool _isRecursiveSearching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    MediaItem? item = widget.item;
    if (item != null && mediaSource.bookIdOf(item) != null) {
      appModelNoUpdate.putMediaItem(item);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      FocusScope.of(context).unfocus();
      _focusNode.requestFocus();
    }
  }

  @override
  void onSearch(String searchTerm, {String? sentence = ''}) async {
    _isRecursiveSearching = true;
    if (appModel.isMediaOpen) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await Future.delayed(const Duration(milliseconds: 5), () {});
    }
    await appModel.openRecursiveDictionarySearch(
      searchTerm: searchTerm,
      killOnPop: false,
    );
    if (appModel.isMediaOpen) {
      await Future.delayed(const Duration(milliseconds: 5), () {});
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    _isRecursiveSearching = false;

    _focusNode.requestFocus();
  }

  /// Hide the dictionary and dispose of the current result.
  @override
  void clearDictionaryResult() async {
    super.clearDictionaryResult();
    unselectWebViewTextSelection(_controller);
  }

  @override
  void onCreatorClose() {
    _focusNode.unfocus();
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    Orientation orientation = MediaQuery.of(context).orientation;
    if (orientation != lastOrientation) {
      if (_controllerInitialised) {
        clearDictionaryResult();
      }
      lastOrientation = orientation;
    }

    return Focus(
      autofocus: true,
      focusNode: _focusNode,
      onFocusChange: (value) {
        if (mediaSource.volumePageTurningEnabled &&
            !(ModalRoute.of(context)?.isCurrent ?? false) &&
            !appModel.isCreatorOpen &&
            !_isRecursiveSearching) {
          _focusNode.requestFocus();
        }
      },
      canRequestFocus: true,
      onKeyEvent: (FocusNode node, KeyEvent event) {
        if (ModalRoute.of(context)?.isCurrent ?? false) {
          if (mediaSource.volumePageTurningEnabled) {
            if (isDictionaryShown) {
              clearDictionaryResult();
              unselectWebViewTextSelection(_controller);
              mediaSource.clearCurrentSentence();

              return KeyEventResult.handled;
            }

            // RawKeyEvent.isKeyPressed was true on key-down and while the key
            // was held, and false on key-up. KeyDownEvent + KeyRepeatEvent is
            // that same set, so page turning still auto-repeats and the key-up
            // is still passed through.
            final bool isPress =
                event is KeyDownEvent || event is KeyRepeatEvent;

            if (isPress && event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
              _turnPage(forward: !mediaSource.volumePageTurningInverted);
              return KeyEventResult.handled;
            }
            if (isPress &&
                event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
              _turnPage(forward: mediaSource.volumePageTurningInverted);
              return KeyEventResult.handled;
            }
          }

          return KeyEventResult.ignored;
        } else {
          return KeyEventResult.ignored;
        }
      },
      child: PopScope(
        // PopScope inverts WillPopScope: refuse the pop up front, run the
        // same confirmation, and pop by hand if it is accepted.
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) async {
          if (didPop) {
            return;
          }
          if (await onWillPop() && context.mounted) {
            Navigator.of(context).pop(result);
          }
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          resizeToAvoidBottomInset: false,
          body: SafeArea(
            top: !mediaSource.extendPageBeyondNavigationBar,
            bottom: false,
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: <Widget>[
                buildReaderArea(),
                buildDictionary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The reader page to load: the book, at the peek position if any.
  String get initialPath {
    MediaItem? item = widget.item;
    if (item == null) {
      return 'manage.html';
    }

    int? peekPosition = widget.peekPosition;
    return peekPosition == null
        ? item.mediaIdentifier
        : '${item.mediaIdentifier}&peek=$peekPosition';
  }

  Widget buildReaderArea() {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(
          mediaSource.url(initialPath),
        ),
      ),
      onPermissionRequest: (controller, origin) async {
        return PermissionResponse(
          action: PermissionResponseAction.GRANT,
        );
      },
      initialSettings: mediaSource.webViewSettings
        ..allowFileAccessFromFileURLs = true
        ..allowUniversalAccessFromFileURLs = true
        ..mediaPlaybackRequiresUserGesture = false
        ..verticalScrollBarEnabled = false
        ..horizontalScrollBarEnabled = false
        ..verticalScrollbarThumbColor = Colors.transparent
        ..verticalScrollbarTrackColor = Colors.transparent
        ..horizontalScrollbarThumbColor = Colors.transparent
        ..horizontalScrollbarTrackColor = Colors.transparent
        ..scrollbarFadingEnabled = false,
      contextMenu: contextMenu,
      onConsoleMessage: onConsoleMessage,
      onWebViewCreated: (controller) {
        _controller = controller;
        _controllerInitialised = true;
        _bridge = TtuBridge(
          controller: controller,
          onReady: _onBridgeReady,
          onTap: _onTap,
          onTheme: _onTheme,
          onExit: _onBridgeExit,
        );
      },
      onLoadStop: (controller, uri) async {
        Future.delayed(const Duration(seconds: 1), _focusNode.requestFocus);
      },
    );
  }

  void onConsoleMessage(
    InAppWebViewController controller,
    ConsoleMessage message,
  ) {
    debugPrint('ttu: ${message.message}');
  }

  Future<void> _onTap(TtuTapEvent event) async {
    FocusScope.of(context).unfocus();
    _focusNode.requestFocus();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (event.isDismiss) {
      clearDictionaryResult();
      mediaSource.clearCurrentSentence();
      return;
    }

    late JidoujishoPopupPosition position;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      position = event.y < MediaQuery.of(context).size.height / 2
          ? JidoujishoPopupPosition.bottomHalf
          : JidoujishoPopupPosition.topHalf;
    } else {
      position = event.x < MediaQuery.of(context).size.width / 2
          ? JidoujishoPopupPosition.rightHalf
          : JidoujishoPopupPosition.leftHalf;
    }

    String text = event.text;
    int index = event.offset;

    try {
      /// If we cut off at a lone surrogate, offset the index back by 1. The
      /// selection meant to select the index before.
      RegExp loneSurrogate = RegExp(
        '[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF]',
      );
      if (index != 0 && text.substring(index).startsWith(loneSurrogate)) {
        index = index - 1;
      }

      String searchTerm = text.substring(index);
      int whitespaceOffset = searchTerm.length - searchTerm.trimLeft().length;
      int start = index + whitespaceOffset;

      int length = JapaneseLanguage.instance.getGuessHighlightLength(
        searchTerm: searchTerm,
      );

      if (mediaSource.highlightOnTap) {
        await _highlight(start: start, length: length);
      }

      await searchDictionaryResult(
        searchTerm: searchTerm,
        position: position,
      );

      length = JapaneseLanguage.instance.getFinalHighlightLength(
        result: currentResult,
      );

      if (mediaSource.highlightOnTap) {
        await _highlight(start: start, length: length);

        if (!dictionaryPopupShown) {
          await unselectWebViewTextSelection(_controller);
        }
      }

      JidoujishoTextSelection selection =
          JapaneseLanguage.instance.getSentenceFromParagraph(
        paragraph: text,
        index: index,
        startOffset: start,
        endOffset: start + length,
      );

      mediaSource.setCurrentSentence(
        selection: selection,
        position: event.position,
      );
    } catch (e) {
      clearDictionaryResult();
    }
  }

  /// Select text without the native selection menu flashing up.
  Future<void> _highlight({required int start, required int length}) async {
    TtuBridge? bridge = _bridge;
    if (bridge == null) {
      return;
    }

    await _controller.setContextMenu(emptyContextMenu);
    await bridge.highlight(start: start, length: length);
    await _controller.setContextMenu(contextMenu);
  }

  /// Match the dictionary popup to the reader's page colour.
  void _onTheme(TtuThemeEvent event) {
    if (!mediaSource.adaptTtuTheme) {
      return;
    }

    Color background = event.backgroundColor;
    bool isDark = background.computeLuminance() < 0.5;

    appModel.setOverrideDictionaryTheme(
      isDark ? appModel.darkTheme : appModel.theme,
    );
    appModel.setOverrideDictionaryColor(
      Color.fromRGBO(
        (background.r * 255).round(),
        (background.g * 255).round(),
        (background.b * 255).round(),
        dictionaryEntryOpacity,
      ),
    );

    if (mounted) {
      clearDictionaryResult();
      setState(() {});
    }
  }

  void _onBridgeReady(TtuReadyEvent event) {
    if (event.isCompatible) {
      return;
    }

    debugPrint(
      'ttuHost: protocol ${event.protocolVersion}, app expects '
      '${TtuBridge.protocolVersion}. Run tool/fetch_ttu.sh.',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.ttu_bridge_mismatch)),
      );
    }
  }

  /// Exit goes through [PopScope], so the exit confirmation and
  /// [MediaSource.onSourceExit] run exactly as for the back button.
  void _onBridgeExit() {
    if (mounted) {
      Navigator.maybePop(context);
    }
  }

  /// Volume up is "next page" unless inverted, as with the old wheel-event
  /// implementation (a positive wheel delta flipped forward).
  Future<void> _turnPage({required bool forward}) async {
    TtuBridge? bridge = _bridge;
    if (bridge == null) {
      return;
    }

    await unselectWebViewTextSelection(_controller);
    if (forward) {
      await bridge.nextPage();
    } else {
      await bridge.prevPage();
    }
  }

  Future<void> unselectWebViewTextSelection(
      InAppWebViewController webViewController) async {
    await _bridge?.clearSelection();
  }

  /// Get the default context menu for sources that make use of embedded web
  /// views.
  ContextMenu get contextMenu => ContextMenu(
        settings: ContextMenuSettings(
          hideDefaultSystemContextMenuItems: true,
        ),
        menuItems: [
          searchMenuItem(),
          copyMenuItem(),
          shareMenuItem(),
          creatorMenuItem(),
        ],
      );

  /// Get the default context menu for sources that make use of embedded web
  /// views.
  ContextMenu get emptyContextMenu => ContextMenu(
        settings: ContextMenuSettings(
          hideDefaultSystemContextMenuItems: true,
        ),
        menuItems: [],
      );

  ContextMenuItem searchMenuItem() {
    return ContextMenuItem(
      id: 1,
      title: t.search,
      action: searchMenuAction,
    );
  }

  ContextMenuItem copyMenuItem() {
    return ContextMenuItem(
      id: 3,
      title: t.copy,
      action: copyMenuAction,
    );
  }

  ContextMenuItem shareMenuItem() {
    return ContextMenuItem(
      id: 4,
      title: t.share,
      action: shareMenuAction,
    );
  }

  ContextMenuItem creatorMenuItem() {
    return ContextMenuItem(
      id: 5,
      title: t.creator,
      action: creatorMenuAction,
    );
  }

  void searchMenuAction() async {
    String searchTerm = await getSelectedText();
    _isRecursiveSearching = true;

    await unselectWebViewTextSelection(_controller);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await Future.delayed(const Duration(milliseconds: 5), () {});
    await appModel.openRecursiveDictionarySearch(
      searchTerm: searchTerm,
      killOnPop: false,
    );
    await Future.delayed(const Duration(milliseconds: 5), () {});
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _isRecursiveSearching = false;
    _focusNode.requestFocus();
  }

  void creatorMenuAction() async {
    String text = await getSelectedText();

    await unselectWebViewTextSelection(_controller);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await Future.delayed(const Duration(milliseconds: 5), () {});

    await appModel.openCreator(
      ref: ref,
      killOnPop: false,
      creatorFieldValues: CreatorFieldValues(
        textValues: {
          SentenceField.instance: text,
          TermField.instance: '',
          ClozeBeforeField.instance: '',
          ClozeInsideField.instance: '',
          ClozeAfterField.instance: '',
        },
      ),
    );

    await Future.delayed(const Duration(milliseconds: 5), () {});
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    _focusNode.requestFocus();
  }

  void copyMenuAction() async {
    String searchTerm = await getSelectedText();
    Clipboard.setData(ClipboardData(text: searchTerm));
    await unselectWebViewTextSelection(_controller);
  }

  void shareMenuAction() async {
    String searchTerm = await getSelectedText();
    SharePlus.instance.share(ShareParams(text: searchTerm));
    await unselectWebViewTextSelection(_controller);
  }

  Future<String> getSelectedText() async {
    return await _bridge?.getSelectedText() ?? '';
  }

}
