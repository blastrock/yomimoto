import 'dart:async';
import 'dart:convert';

import 'package:document_file_save_plus/document_file_save_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:local_assets_server/local_assets_server.dart';
import 'package:share_plus/share_plus.dart';
import 'package:spaces/spaces.dart';
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
    super.key,
  });

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
                buildBody(),
                buildDictionary(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildBody() {
    AsyncValue<LocalAssetsServer> server =
        ref.watch(ttuServerProvider);

    return server.when(
      data: buildReaderArea,
      loading: buildLoading,
      error: (error, stack) => buildError(
        error: error,
        stack: stack,
        refresh: () {
          ref.invalidate(ttuServerProvider);
        },
      ),
    );
  }

  CacheMode get cacheMode {
    if (mediaSource.currentTtuInternalVersion ==
        ReaderTtuSource.ttuInternalVersion) {
      return CacheMode.LOAD_CACHE_ELSE_NETWORK;
    } else {
      mediaSource.setTtuInternalVersion();
      return CacheMode.LOAD_NO_CACHE;
    }
  }

  createFileFromBase64(String base64Content) async {
    var bytes = base64Decode(base64Content.replaceAll('\n', ''));
    DocumentFileSavePlus().saveFile(
      bytes.buffer.asUint8List(),
      _suggestedFilename,
      _mimeType,
    );
    Fluttertoast.showToast(msg: t.file_downloaded(name: _suggestedFilename));
  }

  Widget buildReaderArea(LocalAssetsServer server) {
    return InAppWebView(
      initialUrlRequest: URLRequest(
        url: WebUri(
          widget.item?.mediaIdentifier ??
              'http://localhost:${server.boundPort}/manage.html',
        ),
      ),
      onPermissionRequest: (controller, origin) async {
        return PermissionResponse(
          action: PermissionResponseAction.GRANT,
        );
      },
      initialSettings: InAppWebViewSettings(
        allowFileAccessFromFileURLs: true,
        allowUniversalAccessFromFileURLs: true,
        mediaPlaybackRequiresUserGesture: false,
        verticalScrollBarEnabled: false,
        horizontalScrollBarEnabled: false,
        javaScriptCanOpenWindowsAutomatically: true,
        useOnDownloadStart: true,
        verticalScrollbarThumbColor: Colors.transparent,
        verticalScrollbarTrackColor: Colors.transparent,
        horizontalScrollbarThumbColor: Colors.transparent,
        horizontalScrollbarTrackColor: Colors.transparent,
        scrollbarFadingEnabled: false,
        appCachePath: appModel.browserDirectory.path,
        cacheMode: cacheMode,
        supportMultipleWindows: true,
      ),
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

        controller.addJavaScriptHandler(
          handlerName: 'blobToBase64Handler',
          callback: (data) async {
            if (data.isNotEmpty) {
              final String base64Content = data[0];
              createFileFromBase64(base64Content);
            }
          },
        );
      },
      onCreateWindow: (controller, createWindowRequest) async {
        showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              insetPadding: Spacing.of(context).insets.all.big,
              contentPadding: EdgeInsets.zero,
              content: SizedBox(
                width: MediaQuery.of(context).size.width,
                height: MediaQuery.of(context).size.height * (3 / 4),
                child: InAppWebView(
                  initialSettings: InAppWebViewSettings(
                    supportZoom: false,
                    disableContextMenu: true,
                    allowFileAccessFromFileURLs: true,
                    allowUniversalAccessFromFileURLs: true,
                    mediaPlaybackRequiresUserGesture: false,
                    verticalScrollBarEnabled: false,
                    horizontalScrollBarEnabled: false,
                    javaScriptCanOpenWindowsAutomatically: true,
                    userAgent: 'random',
                    useOnDownloadStart: true,
                    verticalScrollbarThumbColor: Colors.transparent,
                    verticalScrollbarTrackColor: Colors.transparent,
                    horizontalScrollbarThumbColor: Colors.transparent,
                    horizontalScrollbarTrackColor: Colors.transparent,
                    scrollbarFadingEnabled: false,
                    appCachePath: appModel.browserDirectory.path,
                    cacheMode: cacheMode,
                    supportMultipleWindows: true,
                  ),
                  windowId: createWindowRequest.windowId,
                  onDownloadStartRequest: onDownloadStartRequest,
                  onCloseWindow: (controller) {
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                ),
              ),
            );
          },
        );
        return true;
      },
      onReceivedServerTrustAuthRequest: (controller, challenge) async {
        return ServerTrustAuthResponse(
          action: ServerTrustAuthResponseAction.PROCEED,
        );
      },
      onLoadStop: (controller, uri) async {
        Future.delayed(const Duration(seconds: 1), _focusNode.requestFocus);
      },
      onDownloadStartRequest: onDownloadStartRequest,
    );
  }

  String _suggestedFilename = '';
  String _mimeType = '';

  void onDownloadStartRequest(
      InAppWebViewController controller, DownloadStartRequest request) async {
    _mimeType = request.mimeType ?? _mimeType;

    _suggestedFilename = request.suggestedFilename ?? _suggestedFilename;

    await controller.evaluateJavascript(
        source: downloadFileJs.replaceAll(
            'blobUrlPlaceholder', request.url.toString()));
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

      mediaSource.setCurrentSentence(selection: selection);
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
          stashMenuItem(),
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

  ContextMenuItem stashMenuItem() {
    return ContextMenuItem(
      id: 2,
      title: t.stash,
      action: stashMenuAction,
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

  void stashMenuAction() async {
    String searchTerm = await getSelectedText();
    appModel.addToStash(terms: [searchTerm]);
    await unselectWebViewTextSelection(_controller);
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

  String downloadFileJs = '''
var xhr = new XMLHttpRequest();
var blobUrl = "blobUrlPlaceholder";
console.log(blobUrl);
xhr.open('GET', blobUrl, true);
xhr.responseType = 'blob';
xhr.onload = function(e) {
  if (this.status == 200) {
    var blob = this.response;
    var reader = new FileReader();
    reader.readAsDataURL(blob);
    reader.onloadend = function() {
      var base64data = reader.result;
      var base64ContentArray = base64data.split(",")     ;
      var mimeType = base64ContentArray[0].match(/[^:\\s*]\\w+\\/[\\w-+\\d.]+(?=[;| ])/)[0];
      var decodedFile = base64ContentArray[1];
      console.log(mimeType);
      window.flutter_inappwebview.callHandler('blobToBase64Handler', decodedFile, mimeType);
    };
  };
};
xhr.send();
''';
}
