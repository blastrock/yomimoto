import 'package:yuuna/dictionary.dart';
import 'package:isar_community/isar.dart';

part 'dictionary.g.dart';

/// A dictionary that can be imported into the application, encapsulating its
/// metadata and current preferences.
@Collection()
class Dictionary {
  /// Initialise a dictionary with details determined from import.
  Dictionary({
    required this.id,
    required this.name,
    required this.formatKey,
    required this.order,
    this.isHidden = false,
    this.isCollapsed = false,
  });

  /// Identifier for database purposes.
  final Id id;

  /// The name of the dictionary. For example, this could be 'Merriam-Webster
  /// Dictionary' or '大辞林' or 'JMdict'.
  ///
  /// Dictionary names are meant to be unique, meaning two dictionaries of the
  /// same name should not be allowed to be added in the database.
  @Index(unique: true, replace: true)
  final String name;

  /// The unique key for the format that the dictionary was sourced from.
  final String formatKey;

  /// The order of this dictionary in terms of user sorting, relative to other
  /// dictionaries.
  @Index()
  int order;

  /// A dictionary may have multiple entries.
  @Backlink(to: 'dictionary')
  final IsarLinks<DictionaryEntry> entries = IsarLinks<DictionaryEntry>();

  /// A dictionary may have multiple tags.
  @Backlink(to: 'dictionary')
  final IsarLinks<DictionaryTag> tags = IsarLinks<DictionaryTag>();

  /// A dictionary may have multiple pitch entries.
  @Backlink(to: 'dictionary')
  final IsarLinks<DictionaryPitch> pitches = IsarLinks<DictionaryPitch>();

  /// A dictionary may have multiple frequency entries.
  @Backlink(to: 'dictionary')
  final IsarLinks<DictionaryFrequency> frequencies =
      IsarLinks<DictionaryFrequency>();

  /// Whether this dictionary's results are hidden from search results.
  bool isHidden;

  /// Whether this dictionary's results are collapsed by default in search
  /// results.
  bool isCollapsed;

  @override
  bool operator ==(Object other) => other is Dictionary && name == other.name;

  @override
  int get hashCode => Object.hash(id, name);

  @override
  toString() {
    return 'Dictionary(name: $name, format: $formatKey)';
  }
}
