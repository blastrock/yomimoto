import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:yuuna/creator.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// Returns the widget for a [DictionarySearchResult] which returns a
/// scrollable list of each [DictionaryEntry] in its mappings.
class DictionaryResultPage extends BasePage {
  /// Create the widget of a [DictionarySearchResult].
  const DictionaryResultPage({
    required this.result,
    required this.onSearch,
    required this.onShare,
    this.scrollController,
    this.opacity = 1,
    this.updateHistory = true,
    this.spaceBeforeFirstResult = true,
    this.footerWidget,
    this.onClosePopup,
    super.key,
  });

  /// The result made from a dictionary database search.
  final DictionarySearchResult result;

  /// Action to be done upon selecting the search option.
  final Function(String) onSearch;

  /// Action to be done upon selecting the share option.
  final Function(String) onShare;

  /// Whether or not to update dictionary history upon viewing this result.
  final bool updateHistory;

  /// Whether or not to put a space before the first result.
  final bool spaceBeforeFirstResult;

  /// Opacity for entries.
  final double opacity;

  /// Allows controlling the scroll position of the page.
  final ScrollController? scrollController;

  /// Optional footer for use for showing more.
  final Widget? footerWidget;

  /// Closes the dictionary popup the result is shown in, after an action that
  /// [QuickAction.closesPopup]. Null when the result is not in a popup.
  final VoidCallback? onClosePopup;

  @override
  BasePageState<DictionaryResultPage> createState() =>
      _DictionaryResultPageState();
}

class _DictionaryResultPageState extends BasePageState<DictionaryResultPage> {
  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
  }

  late ScrollController _scrollController;

  Map<DictionaryHeading, Map<Dictionary, ExpandableController>>
      expandableControllersByHeading = {};

  @override
  Widget build(BuildContext context) {
    AnkiMapping lastSelectedMapping = appModel.lastSelectedMapping;

    List<DictionaryHeading> headings = widget.result.headings;

    List<Dictionary> dictionaries = appModel.dictionaries;
    Map<String, bool> dictionaryNamesByHidden = Map<String, bool>.fromEntries(
        dictionaries
            .map((e) => MapEntry(e.name, e.isHidden)));
    Map<String, bool> dictionaryNamesByCollapsed =
        Map<String, bool>.fromEntries(dictionaries.map(
            (e) => MapEntry(e.name, e.isCollapsed)));
    Map<String, int> dictionaryNamesByOrder = Map<String, int>.fromEntries(
        dictionaries.map((e) => MapEntry(e.name, e.order)));

    for (DictionaryHeading heading in headings) {
      expandableControllersByHeading.putIfAbsent(heading, () => {});
      for (DictionaryEntry entry in heading.entries) {
        Dictionary dictionary = entry.dictionary;
        expandableControllersByHeading[heading]?.putIfAbsent(
          dictionary,
          () => ExpandableController(
            initialExpanded: !dictionaryNamesByCollapsed[dictionary.name]!,
          ),
        );
      }
    }

    return MediaQuery(
      data: MediaQuery.of(context).removePadding(
        removeTop: true,
        removeBottom: true,
        removeLeft: true,
        removeRight: true,
      ),
      child: CustomScrollView(
        scrollCacheExtent: const ScrollCacheExtent.pixels(999999999999999),
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPadding(
              padding: widget.spaceBeforeFirstResult
                  ? const EdgeInsets.only(top: Spacing.normal)
                  : EdgeInsets.zero),
          ...headings
              .map((heading) => DictionaryTermPage(
                    lastSelectedMapping: lastSelectedMapping,
                    opacity: widget.opacity,
                    heading: heading,
                    onSearch: widget.onSearch,
                    onShare: widget.onShare,
                    expandableControllers:
                        expandableControllersByHeading[heading]!,
                    dictionaryNamesByHidden: dictionaryNamesByHidden,
                    dictionaryNamesByOrder: dictionaryNamesByOrder,
                    onClosePopup: widget.onClosePopup,
                  )),
          if (widget.footerWidget != null) widget.footerWidget!,
        ],
      ),
    );
  }
}
