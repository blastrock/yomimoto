import 'package:yuuna/media.dart';

/// A source for a [ReaderTab], which handles primarily text-based media.
abstract class ReaderMediaSource extends MediaSource {
  /// Initialise a media source.
  ReaderMediaSource({
    required super.uniqueKey,
    required super.sourceName,
    required super.description,
    required ReaderTab super.homeTab,
    required super.icon,
    required super.implementsSearch,
    required super.implementsHistory,
    super.overridesAutoImage = false,
    super.overridesAutoAudio = false,
  });

  @override
  double get aspectRatio => 176 / 250;
}
