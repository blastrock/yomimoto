import 'package:yuuna/dictionary.dart';

/// The headings found for a search term, best first.
class DictionarySearchResult {
  /// Create a result. Empty [headings] mean nothing was found.
  DictionarySearchResult({
    required this.searchTerm,
    this.bestLength = 0,
    this.headings = const [],
  });

  /// The term searched.
  final String searchTerm;

  /// How many leading characters of [searchTerm] matched, for highlighting
  /// the selected word.
  final int bestLength;

  /// The headings found, fully loaded, best first.
  final List<DictionaryHeading> headings;
}
