import 'package:yuuna/media.dart';

/// Media type that encapsulates text-based media, like books or manga. Each
/// concrete reader media type is backed by exactly one [ReaderMediaSource] and
/// gets its own home tab.
abstract class ReaderMediaType extends MediaType {
  /// Initialise this media type.
  ReaderMediaType({
    required super.uniqueKey,
    required super.icon,
    required super.outlinedIcon,
  });

  @override
  ReaderMediaSource get source;
}
