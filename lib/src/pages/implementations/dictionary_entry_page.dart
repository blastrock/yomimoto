import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spaces/spaces.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/models.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// Returns the widget for a [DictionaryEntry] making up a collection of
/// meanings.
class DictionaryEntryPage extends ConsumerStatefulWidget {
  /// Create the widget for a dictionary entry.
  const DictionaryEntryPage({
    required this.entry,
    required this.onSearch,
    required this.onShare,
    required this.expandableController,
    super.key,
  });

  /// The entry particular to this
  final DictionaryEntry entry;

  /// Action to be done upon selecting the search option.
  final Function(String) onSearch;

  /// Action to be done upon selecting the share option.
  final Function(String) onShare;

  /// Controller specific to a dictionary name.
  final ExpandableController expandableController;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DictionaryEntryPageState();
}

class _DictionaryEntryPageState extends ConsumerState<DictionaryEntryPage> {
  String selectedText = '';

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: Spacing.of(context).spaces.extraSmall,
        bottom: Spacing.of(context).spaces.normal,
      ),
      child: ExpandablePanel(
        theme: ExpandableThemeData(
          hasIcon: false,
        ),
        controller: widget.expandableController,
        header: _DictionaryEntryHeader(entry: widget.entry),
        collapsed: const SizedBox.shrink(),
        expanded: Padding(
          padding: EdgeInsets.only(
            top: Spacing.of(context).spaces.small,
            left: Spacing.of(context).spaces.normal,
          ),
          child: SelectionArea(
            onSelectionChanged: (selection) {
              if (selection?.plainText != null && selection?.plainText != '_') {
                selectedText = selection?.plainText ?? '';
              }
            },
            contextMenuBuilder: (context, state) {
              return AdaptiveTextSelectionToolbar.buttonItems(
                anchors: TextSelectionToolbarAnchors(
                  primaryAnchor: state.contextMenuAnchors.primaryAnchor,
                ),
                buttonItems: <ContextMenuButtonItem>[
                  ContextMenuButtonItem(
                    onPressed: () {
                      widget.onSearch(selectedText);
                      state.hideToolbar();
                    },
                    label: t.search,
                  ),
                  ...AdaptiveTextSelectionToolbar.selectableRegion(
                              selectableRegionState: state)
                          .buttonItems
                          ?.where(
                              (e) => e.type == ContextMenuButtonType.copy) ??
                      [],
                  ...AdaptiveTextSelectionToolbar.selectableRegion(
                              selectableRegionState: state)
                          .buttonItems
                          ?.where((e) =>
                              e.type == ContextMenuButtonType.selectAll) ??
                      [],
                  ContextMenuButtonItem(
                    onPressed: () {
                      widget.onShare(selectedText);
                      state.hideToolbar();
                    },
                    label: t.share,
                  ),
                ],
              );
            },
            child: DictionaryHtmlWidget(
              entry: widget.entry,
              onSearch: widget.onSearch,
            ),
          ),
        ),
      ),
    );
  }
}

class _DictionaryEntryHeader extends ConsumerWidget {
  const _DictionaryEntryHeader({
    required this.entry,
  });

  final DictionaryEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppModel appModel = ref.read(appProvider);
    Dictionary dictionary = entry.dictionary;
    List<Widget> children = [
      JidoujishoTag(
        text: dictionary.name,
        backgroundColor: Colors.red.shade900,
      ),
      ...entry.tags.map((tag) {
        return JidoujishoTag(
          text: tag.name,
          message: tag.notes,
          backgroundColor: tag.color,
        );
      })
    ];

    Widget last = children.removeLast();

    /// The panel's own icon would sit right of the buttons; it never rotates,
    /// so a plain icon after the tags looks the same.
    children.add(
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(child: last),
          Icon(
            Icons.arrow_drop_down,
            size: Theme.of(context).textTheme.titleLarge?.fontSize,
            color: Theme.of(context).unselectedWidgetColor,
          ),
        ],
      ),
    );

    return Row(
      children: [
        Expanded(
          child: Wrap(
            children: children,
          ),
        ),
        DictionaryQuickActionsRow(
          heading: entry.heading,
          actions: appModel.entryQuickActions,
          selectedEntry: entry,
        ),
      ],
    );
  }
}
