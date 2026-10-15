import 'package:collection/collection.dart';
import 'package:yuuna/dictionary.dart';

/// A word: a term and its reading, shared by every dictionary that has
/// something to say about it. Built fully loaded by `loadHeadings`.
class DictionaryHeading {
  /// Create a heading. [id] is null for a stand-in that is not in the
  /// database.
  DictionaryHeading({
    required this.term,
    this.reading = '',
    this.id,
  });

  /// The database id; null for a stand-in.
  final int? id;

  /// The word as written.
  final String term;

  /// The word's reading; empty for kanji entries and words given no reading.
  final String reading;

  /// Entries for this word, one or more per dictionary defining it.
  final List<DictionaryEntry> entries = [];

  /// Pitch accents of this word.
  final List<DictionaryPitch> pitches = [];

  /// Frequencies of this word.
  final List<DictionaryFrequency> frequencies = [];

  /// Tags on this word as a whole.
  final List<DictionaryTag> tags = [];

  /// Frequencies that frequency dictionaries give for [term] without a
  /// reading. Empty when [reading] is empty: those are [frequencies].
  final List<DictionaryFrequency> noReadingFrequencies = [];

  /// The sum of the popularity of this word's entries.
  double get popularitySum {
    return entries.map((entry) => entry.popularity).sum;
  }

  @override
  bool operator ==(Object other) =>
      other is DictionaryHeading &&
      term == other.term &&
      reading == other.reading;

  @override
  int get hashCode => term.hashCode * reading.hashCode;
}
