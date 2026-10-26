import 'package:expandable/expandable.dart';
import 'package:float_column/float_column.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sliver_tools/sliver_tools.dart';
import 'package:spaces/spaces.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:yuuna/creator.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/language.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/src/models/app_model.dart';
import 'package:yuuna/src/models/creator_model.dart';
import 'package:yuuna/utils.dart';
import 'package:collection/collection.dart';

/// Returns the widget for a list of [DictionaryEntry] making up a term.
class DictionaryTermPage extends ConsumerWidget {
  /// Create the widget for a dictionary word.
  const DictionaryTermPage({
    required this.heading,
    required this.onSearch,
    required this.onShare,
    required this.expandableControllers,
    required this.dictionaryNamesByHidden,
    required this.dictionaryNamesByOrder,
    required this.lastSelectedMapping,
    this.opacity = 1,
    this.footerWidget,
    this.onClosePopup,
    super.key,
  });

  /// The result made from a dictionary database search.
  final DictionaryHeading heading;

  /// Action to be done upon selecting the search option.
  final Function(String) onSearch;

  /// Action to be done upon selecting the share option.
  final Function(String) onShare;

  /// Controls expandables by dictionary name.
  final Map<Dictionary, ExpandableController> expandableControllers;

  /// Lists whether a dictionary is hidden.
  final Map<String, bool> dictionaryNamesByHidden;

  /// Lists the order of dictionaries.
  final Map<String, int> dictionaryNamesByOrder;

  /// Optional footer foor use in [DictionaryHistoryPage].
  final Widget? footerWidget;

  /// Closes the dictionary popup the result is shown in, after an action that
  /// [QuickAction.closesPopup]. Null when the result is not in a popup.
  final VoidCallback? onClosePopup;

  /// Opacity for entries.
  final double opacity;

  /// Last selected mapping for optimisation purposes. Not including this
  /// before caused rendering jank as database queries were performed multiple
  /// times for getting this value.
  final AnkiMapping lastSelectedMapping;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<DictionaryEntry> entries = heading.entries
        .where(
            (entry) => !dictionaryNamesByHidden[entry.dictionary.name]!)
        .toList();

    entries.sort((a, b) => dictionaryNamesByOrder[a.dictionary.name]!
        .compareTo(dictionaryNamesByOrder[b.dictionary.name]!));

    if (entries.isEmpty) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    return SliverStack(
      children: [
        SliverPositioned.fill(
          child: Card(
            color: Theme.of(context)
                .appColors
                .dictionaryCard
                .withValues(alpha: opacity),
            elevation: 0,
            shape: const RoundedRectangleBorder(),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.only(
            left: Spacing.of(context).spaces.semiBig,
            top: Spacing.of(context).spaces.normal,
            right: Spacing.of(context).spaces.normal,
            bottom: Spacing.of(context).spaces.normal,
          ),
          sliver: MultiSliver(
            children: [
              SliverList(
                delegate: SliverChildListDelegate(
                  [
                    _DictionaryTermTopRow(
                      heading: heading,
                      onSearch: onSearch,
                      onClosePopup: onClosePopup,
                    ),
                    if (heading.tags.isNotEmpty) const Space.normal(),
                    if (heading.tags.isNotEmpty)
                      _DictionaryTermTagsWrap(heading: heading),
                    const Space.normal(),
                    _DictionaryTermFreqList(
                      heading: heading,
                      dictionaryNamesByHidden: dictionaryNamesByHidden,
                    ),
                  ],
                ),
              ),
              SliverPadding(
                padding: Spacing.of(context).insets.onlyBottom.normal,
                sliver: _DictionaryTermPitchList(heading: heading),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: footerWidget != null
                      ? entries.length + 1
                      : entries.length,
                  (context, index) {
                    if (index == entries.length && footerWidget != null) {
                      return footerWidget;
                    }

                    DictionaryEntry entry = entries[index];

                    return DictionaryEntryPage(
                      entry: entry,
                      onSearch: onSearch,
                      onShare: onShare,
                      expandableController:
                          expandableControllers[entry.dictionary]!,
                      onClosePopup: onClosePopup,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A row of quick action buttons on a dictionary result: the heading's, or
/// those of one of its definitions.
class DictionaryQuickActionsRow extends ConsumerStatefulWidget {
  /// Create the row of [actions] for [heading], acting on [selectedEntry]
  /// when given.
  const DictionaryQuickActionsRow({
    required this.heading,
    required this.actions,
    this.selectedEntry,
    this.onClosePopup,
    super.key,
  });

  /// The result made from a dictionary database search.
  final DictionaryHeading heading;

  /// The actions to show, left to right.
  final List<QuickAction> actions;

  /// The definition the actions act on, or null for the whole [heading].
  final DictionaryEntry? selectedEntry;

  /// Closes the dictionary popup the result is shown in, after an action that
  /// [QuickAction.closesPopup]. Null when the result is not in a popup.
  final VoidCallback? onClosePopup;

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _DictionaryQuickActionsRowState();
}

class _DictionaryQuickActionsRowState
    extends ConsumerState<DictionaryQuickActionsRow> {
  VisibilityInfo? visibilityInfo;

  @override
  Widget build(BuildContext context) {
    AppModel appModel = ref.read(appProvider);
    CreatorModel creatorModel = ref.read(creatorProvider);
    bool visibleOnce = ref.watch(visibleOnceProvider(widget.heading));

    Map<String, Color?> defaultColors = Map<String, Color?>.fromEntries(
        appModel.quickActions.values.map((e) => MapEntry(e.uniqueKey, null)));

    if (!visibleOnce) {
      return VisibilityDetector(
        key: UniqueKey(),
        onVisibilityChanged: (info) {
          visibilityInfo = info;
          if (info.visibleFraction > 0) {
            ref.watch(visibleOnceProvider(widget.heading).notifier).state =
                true;
          }
        },
        child: buildRow(
          context: context,
          appModel: appModel,
          creatorModel: creatorModel,
          ref: ref,
          colors: defaultColors,
        ),
      );
    }

    AsyncValue<Map<String, Color?>> colors =
        ref.watch(quickActionColorProvider(widget.heading));

    return colors.when(
      data: (colors) {
        return buildRow(
          context: context,
          appModel: appModel,
          creatorModel: creatorModel,
          ref: ref,
          colors: colors,
        );
      },
      loading: () => buildRow(
        context: context,
        appModel: appModel,
        creatorModel: creatorModel,
        ref: ref,
        colors: defaultColors,
      ),
      error: (_, _) => buildRow(
        context: context,
        appModel: appModel,
        creatorModel: creatorModel,
        ref: ref,
        colors: defaultColors,
      ),
    );
  }

  Widget buildRow({
    required BuildContext context,
    required AppModel appModel,
    required CreatorModel creatorModel,
    required WidgetRef ref,
    required Map<String, Color?> colors,
  }) {
    List<Widget> buttons = [];
    for (QuickAction quickAction in widget.actions) {
      Color defaultColor = Theme.of(context).colorScheme.onSurface;
      Color enabledColor = colors[quickAction.uniqueKey] ?? defaultColor;
      buttons.add(
        Padding(
          padding: Spacing.of(context).insets.onlyLeft.semiSmall,
          child: JidoujishoIconButton(
            busy: true,
            enabledColor: enabledColor,
            disabledColor: enabledColor.withValues(alpha: 0.5),
            shapeBorder: const RoundedRectangleBorder(),
            backgroundColor: Theme.of(context)
                .colorScheme
                .onSurface
                .withValues(alpha: 0.05),
            size: Spacing.of(context).spaces.semiBig,
            tooltip: quickAction.label,
            icon: quickAction.icon,
            onTap: () async {
              await quickAction.executeAction(
                context: context,
                ref: ref,
                appModel: appModel,
                creatorModel: creatorModel,
                heading: widget.heading,
                selectedEntry: widget.selectedEntry,
              );

              ref.invalidate(quickActionColorProvider(widget.heading));
              if (quickAction.closesPopup && mounted) {
                widget.onClosePopup?.call();
              }
            },
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: buttons,
    );
  }
}

class _DictionaryTermPitchList extends ConsumerWidget {
  const _DictionaryTermPitchList({
    required this.heading,
  });

  /// The result made from a dictionary database search.
  final DictionaryHeading heading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppModel appModel = ref.watch(appProvider);

    List<DictionaryPitch> pitches = heading.pitches
        .where((pitch) =>
            !pitch.dictionary.isHidden)
        .toList();
    if (pitches.isEmpty) {
      return const SliverPadding(padding: EdgeInsets.zero);
    }

    pitches.sort((a, b) =>
        a.dictionary.order.compareTo(b.dictionary.order));

    Map<Dictionary, List<DictionaryPitch>> pitchesByDictionary =
        groupBy<DictionaryPitch, Dictionary>(
            pitches, (pitch) => pitch.dictionary);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
          childCount: pitchesByDictionary.length, (context, index) {
        MapEntry<Dictionary, List<DictionaryPitch>> pitchesForDictionary =
            pitchesByDictionary.entries.elementAt(index);
        Dictionary dictionary = pitchesForDictionary.key;
        List<DictionaryPitch> pitches = pitchesForDictionary.value;

        if (pitches.length > 1) {
          List<Widget> pitchWidgets = pitches
              .map(
                (pitch) => Padding(
                  padding: Spacing.of(context).insets.onlyLeft.normal,
                  child: JapaneseLanguage.instance.getPitchWidget(
                    appModel: appModel,
                    context: context,
                    reading: heading.reading,
                    downstep: pitch.downstep,
                  ),
                ),
              )
              .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: Spacing.of(context).insets.onlyBottom.semiSmall,
                child: JidoujishoTag(
                  text: dictionary.name,
                  backgroundColor: Colors.red.shade900,
                ),
              ),
              ...pitchWidgets,
            ],
          );
        } else {
          List<Widget> pitchWidgets = pitches
              .map(
                (pitch) => Padding(
                  padding: Spacing.of(context).insets.onlyLeft.small,
                  child: JapaneseLanguage.instance.getPitchWidget(
                    appModel: appModel,
                    context: context,
                    reading: heading.reading,
                    downstep: pitch.downstep,
                  ),
                ),
              )
              .toList();

          return Wrap(
            children: [
              JidoujishoTag(
                text: dictionary.name,
                backgroundColor: Colors.red.shade900,
              ),
              ...pitchWidgets,
            ],
          );
        }
      }),
    );
  }
}

class _DictionaryTermFreqList extends ConsumerWidget {
  const _DictionaryTermFreqList({
    required this.heading,
    required this.dictionaryNamesByHidden,
  });

  /// The result made from a dictionary database search.
  final DictionaryHeading heading;

  /// Lists whether a dictionary is hidden.
  final Map<String, bool> dictionaryNamesByHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<DictionaryFrequency> frequencies = heading.frequencies
        .where((frequency) =>
            !dictionaryNamesByHidden[frequency.dictionary.name]!)
        .toList();

    frequencies += heading.noReadingFrequencies
        .where((frequency) =>
            !dictionaryNamesByHidden[frequency.dictionary.name]!)
        .toList();

    if (frequencies.isEmpty) {
      return const SizedBox.shrink();
    }

    List<MapEntry<Dictionary, List<DictionaryFrequency>>>
        frequenciesByDictionary = groupBy<DictionaryFrequency, Dictionary>(
                frequencies, (frequency) => frequency.dictionary)
            .entries
            .toList();

    frequenciesByDictionary.sort((a, b) => a.key.order.compareTo(b.key.order));
    for (MapEntry<Dictionary, List<DictionaryFrequency>> entries
        in frequenciesByDictionary) {
      entries.value.sort((a, b) => a.value.compareTo(b.value));
    }

    List<Widget> children =
        frequenciesByDictionary.map((frequenciesForDictionary) {
      return Padding(
        padding: Spacing.of(context).insets.onlyBottom.normal,
        child: JidoujishoTag(
          text: frequenciesForDictionary.key.name,
          trailingText: frequenciesForDictionary.value
              .map((e) => e.displayValue)
              .join(', '),
          backgroundColor: Colors.red.shade900,
        ),
      );
    }).toList();

    return Wrap(children: children);
  }
}

class _DictionaryTermTagsWrap extends ConsumerWidget {
  const _DictionaryTermTagsWrap({
    required this.heading,
  });

  /// The result made from a dictionary database search.
  final DictionaryHeading heading;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    List<Widget> children = heading.tags.map((tag) {
      return JidoujishoTag(
        text: tag.name,
        message: tag.notes,
        backgroundColor: tag.color,
      );
    }).toList();

    return Wrap(children: children);
  }
}

class _DictionaryTermTopRow extends ConsumerWidget {
  const _DictionaryTermTopRow({
    required this.heading,
    required this.onSearch,
    required this.onClosePopup,
  });

  /// The result made from a dictionary database search.
  final DictionaryHeading heading;

  /// Action to be done upon selecting the search option.
  final Function(String) onSearch;

  /// See [DictionaryQuickActionsRow.onClosePopup].
  final VoidCallback? onClosePopup;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    AppModel appModel = ref.watch(appProvider);
    return FloatColumn(
      children: [
        Floatable(
          float: FCFloat.end,
          padding: EdgeInsets.only(
            top: Spacing.of(context).spaces.small,
            right: Spacing.of(context).spaces.small,
            bottom: Spacing.of(context).spaces.small,
          ),
          child: DictionaryQuickActionsRow(
            heading: heading,
            actions: appModel.headingQuickActions,
            onClosePopup: onClosePopup,
          ),
        ),
        Floatable(
          float: FCFloat.start,
          child: GestureDetector(
            child: JapaneseLanguage.instance.getTermReadingWidget(
              context: context,
              appModel: appModel,
              heading: heading,
              onSearch: onSearch,
            ),
          ),
        ),
      ],
    );
  }
}
