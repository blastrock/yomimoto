import 'dart:ui';

/// A label a dictionary defines, on its entries or on headings.
class DictionaryTag {
  /// Create a tag of the dictionary [dictionaryId].
  DictionaryTag({
    required this.id,
    required this.dictionaryId,
    required this.name,
    required this.category,
    required this.sortingOrder,
    required this.notes,
    required this.popularity,
  });

  /// The database id.
  final int id;

  /// The dictionary defining the tag.
  final int dictionaryId;

  /// The short label, such as `v1` or `P`.
  final String name;

  /// The kind of tag; picks its colour.
  final String category;

  /// Display order among tags.
  final int sortingOrder;

  /// What the label means.
  final String notes;

  /// The dictionary's score for the tag.
  final double popularity;

  /// Get the color for this tag based on its category.
  Color get color {
    switch (category) {
      case 'name':
        return const Color(0xffd46a6a);
      case 'expression':
        return const Color(0xffff4d4d);
      case 'popular':
        return const Color(0xff550000);
      case 'partOfSpeech':
        return const Color(0xff565656);
      case 'archaism':
        return const Color(0xFF616161);
      case 'dictionary':
        return const Color(0xffa15151);
      case 'frequency':
        return const Color(0xffd46a6a);
      case 'frequent':
        return const Color(0xff801515);
    }

    return const Color(0xFF616161);
  }

  @override
  bool operator ==(Object other) => other is DictionaryTag && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
