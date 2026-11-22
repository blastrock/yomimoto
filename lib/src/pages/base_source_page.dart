import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_value_listenable_builder/multi_value_listenable_builder.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/preferences.dart';
import 'package:yuuna/utils.dart';

/// A page template which assumes use of [BaseSourcePageState] by which all
/// pages in the app that are used for when using a certain source will
/// conveniently share base functionality.f
abstract class BaseSourcePage extends BasePage {
  /// Create an instance of this tab page.
  const BaseSourcePage({
    required this.item,
    super.key,
  });

  /// The media item pertaining to this usage instance of the source.
  final MediaItem? item;

  @override
  BaseSourcePageState<BaseSourcePage> createState();
}

/// A base class for providing all pages used for media in the app with a
/// collection of shared functions and variables. In large part, this was
/// implemented to define shortcuts for common lengthy methods across UI code.
class BaseSourcePageState<T extends BaseSourcePage> extends BasePageState<T> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _creatorActiveStreamSubscription = appModel.creatorActiveStream.listen(
        (creatorActive) {
          if (creatorActive) {
            onCreatorOpen();
          } else {
            onCreatorClose();
          }
        },
      );
    });
  }

  @override
  void dispose() {
    _creatorActiveStreamSubscription?.cancel();
    super.dispose();
  }

  /// Used for listening to when the Card Creator is opened and closed.
  StreamSubscription<bool>? _creatorActiveStreamSubscription;

  /// Allows customisation of opacity of dictionary entries.
  double get dictionaryEntryOpacity => 1;

  /// The result from the last dictionary search performed with
  /// [searchDictionaryResult].
  final ValueNotifier<DictionarySearchResult?> _dictionaryResultNotifier =
      ValueNotifier<DictionarySearchResult?>(null);

  String? _lastSearchTerm;

  /// Notifies the progress bar whether or not to refresh.
  final ValueNotifier<bool> _isSearchingNotifier = ValueNotifier<bool>(false);

  /// Whether or not there is a present dictionary result.
  bool get isDictionaryShown => _dictionaryResultNotifier.value != null;

  /// The popup position for the [buildDictionary] widget.
  final _popupPositionNotifier =
      ValueNotifier<JidoujishoPopupPosition?>(JidoujishoPopupPosition.topHalf);

  /// Close the media being used by this source page. All sources should call
  /// this before popping and wrap their [build] function with a [PopScope].
  Future<void> closeSource() async {
    await onSourcePagePop();
    await appModel.closeMedia(
      ref: ref,
      mediaSource: appModel.currentMediaSource!,
      item: widget.item,
    );
  }

  bool _showMore = false;

  /// Action to perform within the source page upon closing the media.
  Future<void> onSourcePagePop() async {}

  /// Perform a search with a given query and update the dictionary search
  /// result. The [position] parameter determines where the pop-up will
  /// be shown on the screen.
  Future<void> searchDictionaryResult({
    required String searchTerm,
    required JidoujishoPopupPosition position,
    int? overrideMaximumTerms,
  }) async {
    if (_lastSearchTerm == searchTerm && overrideMaximumTerms == null) {
      return;
    } else {
      _lastSearchTerm = searchTerm;
    }

    bool notShowMore = overrideMaximumTerms == null;

    overrideMaximumTerms ??=
        appModel.preferences.get<int>(Preferences.maximumTerms);

    late DictionarySearchResult dictionaryResult;
    _popupPositionNotifier.value = position;

    try {
      _isSearchingNotifier.value = true;

      dictionaryResult = await appModel.searchDictionary(
        searchTerm: searchTerm,
        searchWithWildcards: false,
        overrideMaximumTerms: overrideMaximumTerms,
      );
      if (notShowMore && resultScrollController.hasClients) {
        resultScrollController
            .jumpTo(resultScrollController.initialScrollOffset);
      }

      _lastSearchTerm = searchTerm;

      _showMore = dictionaryResult.headings.length < overrideMaximumTerms;
      _dictionaryResultNotifier.value = dictionaryResult;
      await appModel.addToDictionaryHistory(
        result: dictionaryResult,
        searchWithWildcards: false,
      );
    } finally {
      _isSearchingNotifier.value = false;
    }
  }

  /// Hide the dictionary and dispose of the current result.
  void clearDictionaryResult() {
    _dictionaryResultNotifier.value = null;
    _popupPositionNotifier.value = null;
    _lastSearchTerm = null;
    _showMore = false;
    appModel.currentMediaSource?.clearCurrentSentence();
    appModel.currentMediaSource?.clearExtraData();
  }

  /// Build a dictionary showing the result with positioning.
  /// If the result is null, show nothing.
  Widget buildDictionary() {
    return MultiValueListenableBuilder(
      valueListenables: [
        _popupPositionNotifier,
      ],
      builder: (context, result, _) {
        if (!_isSearchingNotifier.value &&
            _dictionaryResultNotifier.value == null) {
          return const SizedBox.shrink();
        }

        switch (_popupPositionNotifier.value) {
          case null:
            return const SizedBox.shrink();
          case JidoujishoPopupPosition.topHalf:
            return buildTopHalfDictionary();

          case JidoujishoPopupPosition.bottomHalf:
            return buildBottomHalfDictionary();

          case JidoujishoPopupPosition.leftHalf:
            return buildLeftHalfDictionary();

          case JidoujishoPopupPosition.rightHalf:
            return buildRightHalfDictionary();

          case JidoujishoPopupPosition.topThreeFourths:
            return buildTopThreeFourths();
        }
      },
    );
  }

  /// The dictionary in the case of [JidoujishoPopupPosition.topHalf].
  Widget buildTopHalfDictionary() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: buildDictionaryResult(),
        ),
        const SizedBox(height: Spacing.semiBig),
        const Flexible(
          child: SizedBox.shrink(),
        ),
      ],
    );
  }

  /// The dictionary in the case of [JidoujishoPopupPosition.bottomHalf].
  Widget buildBottomHalfDictionary() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: SizedBox.shrink(),
        ),
        const SizedBox(height: Spacing.semiBig),
        Flexible(
          child: buildDictionaryResult(),
        ),
      ],
    );
  }

  /// The dictionary in the case of [JidoujishoPopupPosition.leftHalf].
  Widget buildLeftHalfDictionary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: buildDictionaryResult(),
        ),
        const SizedBox(width: Spacing.semiBig),
        const Flexible(
          child: SizedBox.shrink(),
        ),
      ],
    );
  }

  /// The dictionary in the case of [JidoujishoPopupPosition.rightHalf].
  Widget buildRightHalfDictionary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Flexible(
          child: SizedBox.shrink(),
        ),
        const SizedBox(width: Spacing.semiBig),
        Flexible(
          child: buildDictionaryResult(),
        ),
      ],
    );
  }

  /// The dictionary in the case of [JidoujishoPopupPosition.topThreeFourths].
  Widget buildTopThreeFourths() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 3,
          child: buildDictionaryResult(),
        ),
        const SizedBox(height: Spacing.semiBig),
        const Flexible(
          child: SizedBox.shrink(),
        ),
      ],
    );
  }

  /// Used to check if the pop-up is open.
  bool get dictionaryPopupShown => _popupPositionNotifier.value != null;

  /// The dictionary result unpositioned. See [buildDictionary] for the
  /// positioned version.
  Widget buildDictionaryResult() {
    return Dismissible(
      key: ValueKey(_dictionaryResultNotifier.value),
      onDismissed: (dismissDirection) {},
      onUpdate: (details) {
        if (details.reached) {
          onDictionaryDismiss();
        }
      },
      dismissThresholds: const {DismissDirection.horizontal: 0.05},
      movementDuration: const Duration(milliseconds: 20),
      child: Container(
        padding: const EdgeInsets.all(Spacing.semiSmall),
        margin: const EdgeInsets.all(Spacing.normal),
        decoration: BoxDecoration(
          color: theme.appColors.dictionaryPopup
              .withValues(alpha: theme.appStyle.dictionaryPopupOpacity),
          border: Border.fromBorderSide(theme.appStyle.border),
        ),
        child: Stack(
          children: [
            buildSearchResult(),
            buildDictionaryLoading(),
          ],
        ),
      ),
    );
  }

  /// Executed on dictionary dismiss.
  void onDictionaryDismiss() {
    clearDictionaryResult();
  }

  /// In progress indicator for dictionary searching.
  Widget buildDictionaryLoading() {
    return ValueListenableBuilder<bool>(
      valueListenable: _isSearchingNotifier,
      builder: (context, value, child) {
        return Visibility(
          visible: value,
          child: SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Card(
              color: Colors.transparent,
              elevation: 0,
              shape: const RoundedRectangleBorder(),
              child: Column(
                children: [
                  const LinearProgressIndicator(
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    minHeight: 2.75,
                  ),
                  Expanded(child: Container())
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Scroll controller for the search result.
  final ScrollController resultScrollController = ScrollController();

  /// Displays the dictionary entries.
  Widget buildSearchResult() {
    return ValueListenableBuilder(
      valueListenable: _dictionaryResultNotifier,
      builder: (_, _, _) {
        if (_dictionaryResultNotifier.value == null) {
          return SizedBox(
            height: double.infinity,
            width: double.infinity,
            child: Card(
              color: Theme.of(context)
                  .appColors
                  .dictionaryCard
                  .withValues(alpha: dictionaryEntryOpacity),
              elevation: 0,
              shape: const RoundedRectangleBorder(),
              child: Column(
                children: [Container()],
              ),
            ),
          );
        }

        if (_dictionaryResultNotifier.value!.headings.isEmpty) {
          return buildNoSearchResultsPlaceholderMessage();
        }

        return DictionaryResultPage(
          scrollController: resultScrollController,
          opacity: dictionaryEntryOpacity,
          onSearch: onSearch,
          onShare: onShare,
          result: _dictionaryResultNotifier.value!,
          spaceBeforeFirstResult: false,
          footerWidget: footerWidget,
          onClosePopup: clearDictionaryResult,
        );
      },
    );
  }

  /// Show more widget.
  Widget? get footerWidget {
    if (_showMore) {
      return null;
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(Spacing.small),
        child: Tooltip(
          message: t.show_more,
          child: InkWell(
            onTap: _isSearchingNotifier.value
                ? null
                : () async {
                    await searchDictionaryResult(
                      searchTerm: _lastSearchTerm!,
                      position: _popupPositionNotifier.value!,
                      overrideMaximumTerms:
                          _dictionaryResultNotifier.value!.headings.length +
                              appModel.preferences
                                  .get(Preferences.maximumTerms),
                    );
                  },
            child: Container(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.05),
              width: double.maxFinite,
              child: Padding(
                padding: const EdgeInsets.all(Spacing.normal),
                child: Text(
                  t.show_more,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: (textTheme.labelMedium?.fontSize)! * 0.9,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Placeholder when there are no search results.
  Widget buildNoSearchResultsPlaceholderMessage() {
    return Center(
      child: JidoujishoPlaceholderMessage(
        icon: Icons.search_off,
        message: t.no_search_results,
      ),
    );
  }

  /// Get the result returned from the last search.
  DictionarySearchResult? get currentResult => _dictionaryResultNotifier.value;

  /// Action upon selecting the Search option.
  @override
  Future<void> onSearch(String searchTerm, {String? sentence = ''}) async {
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
  }

  /// Performs an action before opening the Card Creator.
  void onCreatorOpen() {}

  /// Performs an action after closing the Card Creator.
  void onCreatorClose() {}
}
