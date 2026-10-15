import 'package:yuuna/dictionary.dart';

/// One dictionary's definitions of a [DictionaryHeading].
class DictionaryEntry {
  /// Create an entry of [dictionary]. The loader sets [heading].
  DictionaryEntry({
    required this.id,
    required this.definitions,
    required this.popularity,
    required this.dictionary,
  });

  /// The database id.
  final int id;

  /// The definitions: plain text, or a structured content JSON document.
  final List<String> definitions;

  /// The dictionary's popularity score for this entry; higher is commoner.
  final double popularity;

  /// The dictionary giving the definitions.
  final Dictionary dictionary;

  /// The heading this entry defines.
  late final DictionaryHeading heading;

  /// Tags on this entry.
  final List<DictionaryTag> tags = [];

  /// The definitions as one text: bulleted lines when there are several.
  String get compactDefinitions {
    if (definitions.length > 1) {
      return definitions
          .map((definition) => '• ${definition.trim()}')
          .join('\n');
    }

    return definitions.join().trim();
  }

  @override
  bool operator ==(Object other) => other is DictionaryEntry && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
