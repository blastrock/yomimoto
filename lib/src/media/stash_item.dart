import 'package:flutter/services.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/utils.dart';

/// A word saved from a book while reading, with the sentence it was found
/// in, so that a card can be made from it later.
class StashItem {
  /// Create a stash item for the book [mediaItemId].
  StashItem({
    required this.mediaItemId,
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

  /// Database id. Null until the item is saved.
  int? id;

  /// Database id of the book the word was saved from.
  int mediaItemId;

  /// The word as written.
  String term;

  /// The word's reading.
  String reading;

  /// The dictionary of the entry picked when saving; null when the whole
  /// heading was saved.
  String? dictionaryName;

  /// The definitions shown when saving, as plain text.
  List<String> definitions;

  /// The sentence the word was found in.
  String sentence;

  /// Where the word starts in [sentence].
  int wordStart;

  /// How long the word is in [sentence].
  int wordLength;

  /// Where the word is in the book, in ttu bookmark units.
  int position;

  /// When the word was saved.
  DateTime dateAdded;

  /// The word selected in its sentence.
  JidoujishoTextSelection getSelection() {
    return JidoujishoTextSelection(
      text: sentence,
      range: TextRange(start: wordStart, end: wordStart + wordLength),
    );
  }
}

/// A stash item's word found in the dictionaries: `heading` is a stand-in
/// with no entries when the word is gone; `entry` is null when the stashed
/// entry's dictionary is gone or the whole heading was stashed; `found` tells
/// whether the stashed entry could be found.
typedef ResolvedStashItem = ({
  DictionaryHeading heading,
  DictionaryEntry? entry,
  bool found,
});
