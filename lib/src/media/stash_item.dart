import 'package:flutter/services.dart';
import 'package:isar_community/isar.dart';
import 'package:yuuna/utils.dart';

part 'stash_item.g.dart';

/// A word saved while reading a book, holding what is needed to make a card
/// from it later. A book has at most one item per word: see [stashKey].
@Collection()
class StashItem {
  /// Create a stash item.
  StashItem({
    required this.mediaSourceIdentifier,
    required this.mediaIdentifier,
    required this.term,
    required this.reading,
    required this.dictionaryName,
    required this.definitions,
    required this.sentence,
    required this.wordStart,
    required this.wordLength,
    required this.position,
    required this.dateAdded,
    this.id,
  });

  /// A unique identifier for the purposes of database storage.
  Id? id;

  /// One item per word (term and reading) per book.
  @Index(unique: true)
  String get stashKey =>
      '$mediaSourceIdentifier/$mediaIdentifier/$term/$reading';

  /// The media source of the book, e.g. the ttu reader.
  String mediaSourceIdentifier;

  /// The book, as the `mediaIdentifier` of its library `MediaItem`.
  String mediaIdentifier;

  /// The word's dictionary form.
  String term;

  /// The reading of [term]. With it, identifies the dictionary heading.
  String reading;

  /// The dictionary of the entry the word was stashed from, or null when it
  /// was stashed from the whole heading.
  String? dictionaryName;

  /// The definitions shown when the word was stashed, as plain text. Used for
  /// display, and still there if the dictionary is removed.
  List<String> definitions;

  /// The full sentence the word was met in.
  String sentence;

  /// UTF-16 offset of the word in [sentence].
  int wordStart;

  /// UTF-16 length of the word in [sentence].
  int wordLength;

  /// Where the word is in the book, in the media source's units: characters
  /// from the start for novels.
  int position;

  /// When the word was stashed.
  DateTime dateAdded;

  /// [sentence] with the word selected, as used by the sentence and cloze
  /// fields.
  JidoujishoTextSelection getSelection() {
    return JidoujishoTextSelection(
      text: sentence,
      range: TextRange(start: wordStart, end: wordStart + wordLength),
    );
  }
}
