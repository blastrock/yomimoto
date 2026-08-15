import 'package:yuuna/media.dart';

/// A media source that handles primarily text-based media, read rather than
/// watched or listened to. Being one is what makes a media item's launch
/// action read as "read".
abstract class ReaderMediaSource extends MediaSource {
  /// Initialise a media source.
  ReaderMediaSource({
    required super.uniqueKey,
    required super.sourceName,
    required super.description,
    required super.icon,
    required super.outlinedIcon,
    required super.implementsSearch,
    required super.implementsHistory,
    super.overridesAutoImage = false,
    super.overridesAutoAudio = false,
  });

  @override
  double get aspectRatio => 176 / 250;
}
