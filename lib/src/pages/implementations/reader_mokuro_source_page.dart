import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:yuuna/creator.dart';
import 'package:yuuna/language.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// The media page used for the [ReaderMokuroSource]: the manga reader page
/// (`assets/manga-reader/`) showing one volume, with the bar over it.
class ReaderMokuroSourcePage extends BaseSourcePage {
  /// Create an instance of this page.
  const ReaderMokuroSourcePage({
    required MediaItem super.item,
    this.peekPage,
    super.key,
  });

  /// If set, open the volume at this page without saving the position.
  final int? peekPage;

  @override
  BaseSourcePageState createState() => _ReaderMokuroSourcePageState();
}

class _ReaderMokuroSourcePageState
    extends BaseSourcePageState<ReaderMokuroSourcePage>
    with WidgetsBindingObserver {
  /// The media source pertaining to this page.
  ReaderMokuroSource get mediaSource => ReaderMokuroSource.instance;
  bool _controllerInitialised = false;
  late InAppWebViewController _controller;
  MokuroBridge? _bridge;

  late final Directory _volumeDirectory =
      mediaSource.volumeDirectory(appModelNoUpdate, widget.item!);
  late final MokuroVolume _volume = MokuroVolume.parse(
      File(path.join(_volumeDirectory.path, 'volume.mokuro'))
          .readAsStringSync());

  Orientation? lastOrientation;

  final FocusNode _focusNode = FocusNode();
  bool _isRecursiveSearching = false;

  /// The pages shown, from the last page event.
  MokuroPageEvent? _shown;

  /// Whether the bar is shown.
  bool _barShown = false;

  /// The WebView's zoom scale, 1 when the page fits the screen.
  double _zoomScale = 1;

  /// How long the white of the E-ink flash stays up before the page draws
  /// under it: long enough for the panel to show it.
  static const Duration _flashDuration = Duration(milliseconds: 300);

  /// How long the flash may wait for the new spread before it goes anyway:
  /// a turn can end on the pages already shown.
  static const Duration _flashTimeout = Duration(seconds: 1);

  /// Whether the E-ink flash covers the screen.
  bool _flashShown = false;

  /// Hides the flash if no new spread is shown in time.
  Timer? _flashTimer;

  bool get _isPeeking => widget.peekPage != null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (!_isPeeking) {
      unawaited(appModelNoUpdate.putMediaItem(widget.item!));
    }
  }

  @override
  void dispose() {
    _flashTimer?.cancel();
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
  Future<void> onSearch(String searchTerm, {String? sentence = ''}) async {
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

  /// Hide the dictionary, dispose of the current result and hide the shown
  /// block.
  @override
  void clearDictionaryResult() {
    super.clearDictionaryResult();
    unawaited(_bridge?.clearOverlay());
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
      onKeyEvent: (node, event) {
        if (!(ModalRoute.of(context)?.isCurrent ?? false) ||
            !mediaSource.volumePageTurningEnabled) {
          return KeyEventResult.ignored;
        }

        if (isDictionaryShown) {
          clearDictionaryResult();
          mediaSource.clearCurrentSentence();

          return KeyEventResult.handled;
        }

        // Key-down and repeats turn pages, so holding a key keeps turning;
        // key-ups pass through.
        final bool isPress = event is KeyDownEvent || event is KeyRepeatEvent;

        if (isPress && event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
          _turnPage(forward: !mediaSource.volumePageTurningInverted);
          return KeyEventResult.handled;
        }
        if (isPress &&
            event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
          _turnPage(forward: mediaSource.volumePageTurningInverted);
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: PopScope(
        // PopScope inverts WillPopScope: refuse the pop up front, close the
        // media, and pop by hand once that is done.
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) {
            return;
          }
          await closeSource();
          if (context.mounted) {
            Navigator.of(context).pop(result);
          }
        },
        child: Scaffold(
          backgroundColor: theme.colorScheme.surface,
          resizeToAvoidBottomInset: false,
          body: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: <Widget>[
              buildReaderArea(),
              if (_barShown) buildBar(),
              buildDictionary(),
              if (_flashShown)
                const IgnorePointer(child: ColoredBox(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildBar() {
    MokuroPageEvent? shown = _shown;
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: MokuroReaderBar(
        firstShown: shown?.first ?? 0,
        lastShown: shown?.last ?? 0,
        count: shown?.count ?? _volume.pages.length,
        // Through the pop, so leaving asks the same confirmation as Back.
        onExit: () => unawaited(Navigator.maybePop(context)),
        onHide: () => setState(() => _barShown = false),
        onNext: () => _turnPage(forward: true),
        onPrevious: () => _turnPage(forward: false),
        onGoTo: (page) => unawaited(_bridge?.goToPage(page)),
      ),
    );
  }

  /// The reader page to load: the volume at its position, or the peeked
  /// page.
  String get initialUrl {
    int page = widget.peekPage ?? widget.item!.position;
    String themeName =
        theme.brightness == Brightness.dark ? 'dark' : 'light';
    return '${ReaderTtuSource.origin}/manga/index.html'
        '?page=$page&theme=$themeName';
  }

  Widget buildReaderArea() {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
      initialSettings: mediaSource.webViewSettings(_volumeDirectory)
        ..mediaPlaybackRequiresUserGesture = false
        ..verticalScrollBarEnabled = false
        ..horizontalScrollBarEnabled = false,
      contextMenu: contextMenu,
      onConsoleMessage: onConsoleMessage,
      onWebViewCreated: (controller) {
        _controller = controller;
        _controllerInitialised = true;
        _bridge = MokuroBridge(
          controller: controller,
          onReady: _onBridgeReady,
          onTap: _onTap,
          onPage: _onPage,
          onTurn: _onTurn,
          onMenu: _onMenu,
        );
      },
      onZoomScaleChanged: (controller, oldScale, newScale) {
        _zoomScale = newScale;
      },
      onLoadStop: (controller, uri) {
        Future.delayed(const Duration(seconds: 1), _focusNode.requestFocus);
      },
    );
  }

  void onConsoleMessage(
    InAppWebViewController controller,
    ConsoleMessage message,
  ) {
    debugPrint('manga reader: ${message.message}');
  }

  void _onBridgeReady(MokuroReadyEvent event) {
    if (event.isCompatible) {
      return;
    }

    debugPrint('mokuroHost: protocol ${event.protocolVersion}, app expects '
        '${MokuroBridge.protocolVersion}.');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.ttu_bridge_mismatch)),
      );
    }
  }

  void _onPage(MokuroPageEvent event) {
    if (isDictionaryShown) {
      clearDictionaryResult();
      mediaSource.clearCurrentSentence();
    }
    // The card image is the page of the last lookup: not one turned away
    // from.
    mediaSource.clearExtraData();
    _hideFlash();
    setState(() => _shown = event);

    if (_zoomScale > 1.01) {
      // Android clamps the factor to the page's minimum scale: back to fit.
      // The plugin asserts a factor above 0.01, and 0.02 undoes even the
      // page's maximum scale of 5.
      unawaited(_controller.zoomBy(zoomFactor: 0.02));
    }

    if (_isPeeking) {
      return;
    }
    MediaItem item = widget.item!;
    item.position = event.last;
    item.duration = ReaderMokuroSource.progressLength(event.count);
    unawaited(appModel.updateMediaItem(item));
  }

  /// Ready an e-ink panel for the spread the page is about to draw, so that
  /// it drops the ghost of the previous one: the panel's own full refresh
  /// where it has one, otherwise a white flash the page then draws under.
  Future<void> _onTurn() async {
    if (appModel.themeMode != AppThemeMode.eink) {
      return;
    }

    if (await EinkRefresh.instance.isAvailable) {
      try {
        await EinkRefresh.instance.refreshNextFrame();
        return;
      } on PlatformException catch (e) {
        debugPrint('E-ink refresh failed, flashing instead: $e');
      }
    }

    if (!mounted) {
      return;
    }
    setState(() => _flashShown = true);
    await Future.delayed(_flashDuration);
    if (!mounted) {
      return;
    }
    _flashTimer?.cancel();
    _flashTimer = Timer(_flashTimeout, _hideFlash);
  }

  /// Uncover the screen after a flash.
  void _hideFlash() {
    _flashTimer?.cancel();
    _flashTimer = null;
    if (mounted && _flashShown) {
      setState(() => _flashShown = false);
    }
  }

  void _onMenu() {
    setState(() => _barShown = !_barShown);
  }

  Future<void> _onTap(MokuroTapEvent event) async {
    FocusScope.of(context).unfocus();
    _focusNode.requestFocus();
    unawaited(
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky));

    if (event.isDismiss) {
      clearDictionaryResult();
      mediaSource.clearCurrentSentence();
      mediaSource.clearExtraData();
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
          await _bridge?.clearSelection();
        }
      }

      // A bubble is the sentence: manga has no paragraphs to cut it from.
      mediaSource.setCurrentSentence(
        selection: JidoujishoTextSelection(
          text: text,
          range: TextRange(start: start, end: start + length),
        ),
        position: event.page,
      );
      mediaSource.setExtraData(_volume.pages[event.page].imgPath);
    } catch (e) {
      clearDictionaryResult();
    }
  }

  /// Select text without the native selection menu flashing up.
  Future<void> _highlight({required int start, required int length}) async {
    MokuroBridge? bridge = _bridge;
    if (bridge == null) {
      return;
    }

    await _controller.setContextMenu(emptyContextMenu);
    await bridge.highlight(start: start, length: length);
    await _controller.setContextMenu(contextMenu);
  }

  /// Volume up is "next page" unless inverted, as in the novel reader.
  Future<void> _turnPage({required bool forward}) async {
    MokuroBridge? bridge = _bridge;
    if (bridge == null) {
      return;
    }

    if (forward) {
      await bridge.nextPage();
    } else {
      await bridge.prevPage();
    }
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

  Future<void> searchMenuAction() async {
    String searchTerm = await getSelectedText();
    _isRecursiveSearching = true;

    await _bridge?.clearSelection();
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

  Future<void> creatorMenuAction() async {
    String text = await getSelectedText();

    await _bridge?.clearSelection();
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

  Future<void> copyMenuAction() async {
    String text = await getSelectedText();
    await Clipboard.setData(ClipboardData(text: text));
    await _bridge?.clearSelection();
  }

  Future<void> shareMenuAction() async {
    String text = await getSelectedText();
    unawaited(SharePlus.instance.share(ShareParams(text: text)));
    await _bridge?.clearSelection();
  }

  Future<String> getSelectedText() async {
    return await _bridge?.getSelectedText() ?? '';
  }
}
