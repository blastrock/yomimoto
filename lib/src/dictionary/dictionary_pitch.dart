import 'package:yuuna/dictionary.dart';

/// A pitch accent of a heading, from a pitch dictionary.
class DictionaryPitch {
  /// Create a pitch accent from [dictionary].
  DictionaryPitch({
    required this.id,
    required this.downstep,
    required this.dictionary,
  });

  /// The database id.
  final int id;

  /// The mora after which the pitch drops; 0 for a flat pattern.
  final int downstep;

  /// The pitch dictionary it comes from.
  final Dictionary dictionary;

  @override
  bool operator ==(Object other) => other is DictionaryPitch && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
