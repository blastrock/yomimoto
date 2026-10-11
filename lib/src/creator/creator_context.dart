import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';
import 'package:yuuna/utils.dart';

/// Where the word of a card was met: the sentence around it and the media it
/// was read in. Fields read this instead of the reader's live state, so that
/// a card can also be made long after the reader was closed.
class CreatorContext {
  /// Create a context from known values.
  CreatorContext({
    required this.sentence,
    this.mediaItem,
  });

  /// The context of whatever is open in the app right now.
  factory CreatorContext.current(AppModel appModel) {
    return CreatorContext(
      sentence: appModel.getCurrentSentence(),
      mediaItem: appModel.currentMediaItem,
    );
  }

  /// The sentence containing the word, with the word as its range.
  final JidoujishoTextSelection sentence;

  /// The media the sentence was read in, if any.
  final MediaItem? mediaItem;
}
