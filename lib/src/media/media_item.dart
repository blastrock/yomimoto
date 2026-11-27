import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';

/// An item representable in media history from which a media source may
/// start playback with. This entity does not have any progress information,
/// such as duration or number of chapters and individual progress of those
/// items. That extra information is handled as extra arguments used alongside
/// the [MediaItem], and not included within it. This design is done to reduce
/// the number and complexity of CRUD operations, as including all data in this
/// entity is impractical to include when persisting a progress update.
class MediaItem {
  /// Initialise a media item with certain details.
  MediaItem({
    required this.mediaIdentifier,
    required this.title,
    required this.mediaSourceIdentifier,
    required this.position,
    required this.duration,
    required this.canDelete,
    required this.canEdit,
    this.id,
    this.imageUrl,
    this.sourceMetadata,
    this.lastOpenedAt,
    this.overrideTitle,
  });

  /// A unique identifier for the purposes of database storage. Null until
  /// the item is saved.
  int? id;

  /// Identifies the item across sources: its source and media identifier.
  String get uniqueKey => '$mediaSourceIdentifier/$mediaIdentifier';

  /// The media identifier of this item. Using this variable alone, a media
  /// source must be able to functionally process how to display the media.
  /// If the same item exists in history, then the item is replaced with a
  /// newer item in the addition operation. This key is also used to identify
  /// resources such as thumbnails in the cache.
  String mediaIdentifier;

  /// The name of this item. Typically, this is the name of a book or a manga
  /// volume.
  String title;

  /// The media source, and so the home tab, where this item is from.
  String mediaSourceIdentifier;

  /// The preview image, if any.
  String? imageUrl;

  /// This field may be used to store additional details that the source may
  /// require to get more details on this item.
  String? sourceMetadata;

  /// The current progress of the media in the time this context was made.
  /// This could be the page number of a book or comic.
  int position;

  /// The media's full duration, used to be able to tell the completion of
  /// this media context relative to the position.
  int duration;

  /// Whether or not this [MediaItem] can be deleted.
  final bool canDelete;

  /// Whether or not this [MediaItem] allows overriding the display title and
  /// thumbnail.
  final bool canEdit;

  /// When the item was last opened, set when it is saved through
  /// `AppStore.putMediaItem` or `AppStore.addMediaItem`. Null until then.
  DateTime? lastOpenedAt;

  /// The title the user gave this item, if any, shown instead of [title].
  /// Loaded with the item; set through `AppStore.setMediaItemOverrideTitle`.
  String? overrideTitle;

  @override
  bool operator ==(Object other) =>
      other is MediaItem && other.uniqueKey == uniqueKey;

  @override
  int get hashCode => uniqueKey.hashCode;

  @override
  String toString() => 'MediaItem($uniqueKey)';

  /// Get the [MediaSource] from a [MediaItem] from its serialised identifier.
  MediaSource getMediaSource({required AppModel appModel}) {
    return appModel.tabs[mediaSourceIdentifier]! as MediaSource;
  }

  /// Creates a deep copy of this mapping but with the given variables replaced
  /// with the new values.
  MediaItem copyWith({
    int? id,
    String? mediaIdentifier,
    String? title,
    String? mediaSourceIdentifier,
    String? imageUrl,
    String? sourceMetadata,
    int? position,
    int? duration,
    bool? canDelete,
    bool? canEdit,
    DateTime? lastOpenedAt,
    String? overrideTitle,
  }) {
    return MediaItem(
      id: id ?? this.id,
      mediaIdentifier: mediaIdentifier ?? this.mediaIdentifier,
      title: title ?? this.title,
      mediaSourceIdentifier:
          mediaSourceIdentifier ?? this.mediaSourceIdentifier,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceMetadata: sourceMetadata ?? this.sourceMetadata,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      canDelete: canDelete ?? this.canDelete,
      canEdit: canEdit ?? this.canEdit,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
      overrideTitle: overrideTitle ?? this.overrideTitle,
    );
  }
}
