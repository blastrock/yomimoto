import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:yuuna/creator.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';
import 'package:yuuna/utils.dart';

/// Saves the word to the stash of the book being read, with its sentence and
/// position, to make a card from later.
class AddToStashAction extends QuickAction {
  /// Initialise this action with the hardset parameters.
  AddToStashAction()
      : super(
          uniqueKey: key,
          label: 'Add to Stash',
          description: 'Save the word, its sentence and its place in the book'
              ' to make a card later.',
          icon: Icons.bookmark_add_outlined,
          showInSingleDictionary: true,
        );

  /// Used to identify this action and to allow a constant value for the
  /// default mappings value of [AnkiMapping].
  static const String key = 'add_to_stash';

  @override
  Future<void> executeAction({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
    required CreatorModel creatorModel,
    required DictionaryHeading heading,
    required DictionaryEntry? selectedEntry,
  }) async {
    MediaItem? mediaItem = appModel.getCurrentMediaItem();
    MediaSource? mediaSource = mediaItem?.getMediaSource(appModel: appModel);
    if (mediaItem == null ||
        mediaSource == null ||
        mediaSource.currentPosition < 0) {
      showToast(t.stash_unavailable);
      return;
    }

    JidoujishoTextSelection sentence = mediaSource.currentSentence;
    TextRange range = sentence.range;
    bool hasWord = range.isValid && range != TextRange.empty;

    bool added = appModel.putStashItem(
      StashItem(
        mediaSourceIdentifier: mediaItem.mediaSourceIdentifier,
        mediaIdentifier: mediaItem.mediaIdentifier,
        term: heading.term,
        reading: heading.reading,
        dictionaryName: selectedEntry?.dictionary.value?.name,
        definitions: getDefinitions(
          appModel: appModel,
          heading: heading,
          selectedEntry: selectedEntry,
        ),
        sentence: sentence.text,
        wordStart: hasWord ? range.start : 0,
        wordLength: hasWord ? range.end - range.start : 0,
        position: mediaSource.currentPosition,
        dateAdded: DateTime.now(),
      ),
    );

    showToast(added ? t.stash_added : t.stash_already);
  }

  /// The definitions to snapshot as plain text: [selectedEntry]'s, or those
  /// of every visible entry of [heading], in dictionary order.
  List<String> getDefinitions({
    required AppModel appModel,
    required DictionaryHeading heading,
    required DictionaryEntry? selectedEntry,
  }) {
    Map<String, Dictionary> dictionariesByName = {
      for (Dictionary dictionary in appModel.dictionaries)
        dictionary.name: dictionary,
    };

    List<DictionaryEntry> entries = selectedEntry != null
        ? [selectedEntry]
        : heading.entries
            .where((entry) =>
                !(dictionariesByName[entry.dictionary.value!.name]?.isHidden ??
                    true))
            .toList();
    entries.sort((a, b) => dictionariesByName[a.dictionary.value!.name]!.order
        .compareTo(dictionariesByName[b.dictionary.value!.name]!.order));

    List<String> definitions = [];
    for (DictionaryEntry entry in entries) {
      DictionaryFormat format =
          appModel.getDictionaryFormat(entry.dictionary.value!);
      for (String definition in entry.definitions) {
        if (format.shouldUseCustomDefinitionWidget(definition)) {
          definition = format.getCustomDefinitionText(definition);
        }
        definitions.add(definition.trim());
      }
    }

    return definitions;
  }

  /// Show a short message at the bottom of the screen.
  void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }
}
