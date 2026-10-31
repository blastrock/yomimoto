import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';

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
  });

  @override
  double get aspectRatio => 176 / 250;

  /// Open [item] at [position], in the source's own units, to see a stashed
  /// word in context, leaving the item's reading position untouched.
  Future<void> peek({
    required WidgetRef ref,
    required AppModel appModel,
    required MediaItem item,
    required int position,
  });
}
