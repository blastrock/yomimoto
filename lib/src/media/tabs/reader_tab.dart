import 'package:yuuna/media.dart';

/// Home tab that encapsulates text-based media, like books or manga. Each
/// concrete reader tab is backed by exactly one [ReaderMediaSource].
abstract class ReaderTab extends HomeTab {
  /// Initialise this home tab.
  ReaderTab({
    required super.uniqueKey,
    required super.icon,
    required super.outlinedIcon,
  });

  @override
  ReaderMediaSource get source;
}
