import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as intl;
import 'package:spaces/spaces.dart';
import 'package:yuuna/creator.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// Everything stored for one stashed word, with the actions to see it in the
/// book and to make a card from it.
class StashItemPage extends BasePage {
  /// Create the page for [item], stashed from [mediaItem].
  const StashItemPage({
    required this.item,
    required this.mediaItem,
    super.key,
  });

  /// The stashed word.
  final StashItem item;

  /// The book the word was stashed from.
  final MediaItem mediaItem;

  @override
  BasePageState<StashItemPage> createState() => _StashItemPageState();
}

class _StashItemPageState extends BasePageState<StashItemPage> {
  StashItem get item => widget.item;

  late ({DictionaryHeading heading, DictionaryEntry? entry, bool found})
      _resolved;
  late Future<Color?> _duplicateColour;

  InstantExportAction get _instantExport =>
      appModelNoUpdate.quickActions[InstantExportAction.key]!
          as InstantExportAction;

  CardCreatorAction get _cardCreator =>
      appModelNoUpdate.quickActions[CardCreatorAction.key]!
          as CardCreatorAction;

  CreatorContext get _creatorContext => CreatorContext(
        sentence: item.getSelection(),
        mediaItem: widget.mediaItem,
      );

  @override
  void initState() {
    super.initState();
    _resolved = appModelNoUpdate.resolveStashItem(item);
    _duplicateColour = _instantExport.getIconColor(
      appModel: appModelNoUpdate,
      heading: _resolved.heading,
    );
  }

  Future<void> _jump() async {
    await ReaderTtuSource.instance.peekBook(
      ref: ref,
      appModel: appModelNoUpdate,
      item: widget.mediaItem,
      position: item.position,
    );
  }

  Future<void> _export() async {
    await _instantExport.exportCard(
      context: context,
      ref: ref,
      appModel: appModelNoUpdate,
      heading: _resolved.heading,
      selectedEntry: _resolved.entry,
      creatorContext: _creatorContext,
    );
    _refreshDuplicateColour();
  }

  Future<void> _openCreator() async {
    await _cardCreator.openCreatorFor(
      context: context,
      ref: ref,
      appModel: appModelNoUpdate,
      creatorModel: creatorModelNoUpdate,
      heading: _resolved.heading,
      selectedEntry: _resolved.entry,
      creatorContext: _creatorContext,
    );
    _refreshDuplicateColour();
  }

  void _refreshDuplicateColour() {
    if (!mounted) {
      return;
    }
    setState(() {
      _duplicateColour = _instantExport.getIconColor(
        appModel: appModelNoUpdate,
        heading: _resolved.heading,
      );
    });
  }

  Future<void> _delete() async {
    bool confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            content: Text(t.stash_delete_one),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  t.dialog_delete,
                  style: TextStyle(color: theme.colorScheme.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.dialog_cancel),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) {
      return;
    }

    appModelNoUpdate.deleteStashItems([item.id!]);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 8,
        title: Text(item.term),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: t.dialog_delete,
            onPressed: _delete,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: buildDetails()),
            buildActions(),
          ],
        ),
      ),
    );
  }

  /// The stored data of the word.
  Widget buildDetails() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        SelectableText(item.term, style: textTheme.headlineMedium),
        if (item.reading.isNotEmpty && item.reading != item.term)
          SelectableText(item.reading, style: textTheme.titleMedium),
        const Space.normal(),
        buildSentence(),
        const Space.semiBig(),
        Text(
          item.dictionaryName ?? t.stash_all_dictionaries,
          style: textTheme.labelLarge?.copyWith(
            color: theme.unselectedWidgetColor,
          ),
        ),
        const Space.small(),
        for (String definition in item.definitions)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: SelectableText('• $definition'),
          ),
        if (!_resolved.found) ...[
          const Space.normal(),
          Row(
            children: [
              Icon(Icons.info_outline, color: theme.unselectedWidgetColor),
              const Space.small(),
              Expanded(
                child: Text(
                  t.stash_entry_missing,
                  style: TextStyle(color: theme.unselectedWidgetColor),
                ),
              ),
            ],
          ),
        ],
        const Space.normal(),
        Text(
          intl.DateFormat.yMMMd().add_Hm().format(item.dateAdded),
          style: textTheme.bodySmall?.copyWith(
            color: theme.unselectedWidgetColor,
          ),
        ),
      ],
    );
  }

  /// The sentence with the word highlighted.
  Widget buildSentence() {
    JidoujishoTextSelection selection = item.getSelection();
    if (selection.textInside.isEmpty) {
      return SelectableText(item.sentence, style: textTheme.bodyLarge);
    }

    return SelectableText.rich(
      TextSpan(
        style: textTheme.bodyLarge,
        children: [
          TextSpan(text: selection.textBefore),
          TextSpan(
            text: selection.textInside,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          TextSpan(text: selection.textAfter),
        ],
      ),
    );
  }

  /// Jump, Instant Export and Card Creator.
  Widget buildActions() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton.icon(
            icon: const Icon(Icons.menu_book),
            label: Text(t.stash_jump),
            onPressed: _jump,
          ),
          FutureBuilder<Color?>(
            future: _duplicateColour,
            builder: (context, snapshot) => IconButton(
              icon: Icon(_instantExport.icon, color: snapshot.data),
              tooltip: _instantExport.label,
              onPressed: _export,
            ),
          ),
          FutureBuilder<Color?>(
            future: _duplicateColour,
            builder: (context, snapshot) => IconButton(
              icon: Icon(_cardCreator.icon, color: snapshot.data),
              tooltip: _cardCreator.label,
              onPressed: _openCreator,
            ),
          ),
        ],
      ),
    );
  }
}
