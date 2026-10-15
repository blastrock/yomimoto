import 'package:yuuna/dictionary.dart';

/// A frequency rank of a heading, from a frequency dictionary.
class DictionaryFrequency {
  /// Create a frequency from [dictionary].
  DictionaryFrequency({
    required this.id,
    required this.value,
    required this.displayValue,
    required this.dictionary,
  });

  /// The database id.
  final int id;

  /// The rank, for sorting; lower is more frequent.
  final double value;

  /// The rank as the dictionary displays it.
  final String displayValue;

  /// The frequency dictionary it comes from.
  final Dictionary dictionary;

  @override
  bool operator ==(Object other) =>
      other is DictionaryFrequency && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
