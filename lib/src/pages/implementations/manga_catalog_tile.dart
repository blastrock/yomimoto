import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:yuuna/media.dart';

/// A cover in a catalog's grids, styled like the library's tiles: the cover
/// downloaded when the tile is first built and kept in the image cache, its
/// title at the bottom, a [badge] at the top left, a check at the bottom
/// right when [inLibrary], and a frame when [selected].
class MangaCatalogTile extends StatelessWidget {
  /// Create a tile.
  const MangaCatalogTile({
    required this.coverUrl,
    required this.title,
    required this.onTap,
    this.onLongPress,
    this.badge,
    this.inLibrary = false,
    this.selected = false,
    super.key,
  });

  /// Where the cover image is.
  final String coverUrl;

  /// The text at the bottom of the cover.
  final String title;

  /// Called when the tile is tapped.
  final VoidCallback onTap;

  /// Called when the tile is long-pressed.
  final VoidCallback? onLongPress;

  /// A short text shown at the top left, such as an edition's tag.
  final String? badge;

  /// Whether the volume is already in the library.
  final bool inLibrary;

  /// Whether the tile is selected.
  final bool selected;

  @override
  Widget build(BuildContext context) {
    ThemeData theme = Theme.of(context);
    TextStyle style = theme.textTheme.bodySmall!;
    double aspectRatio = ReaderMokuroSource.instance.aspectRatio;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: selected
              ? BoxDecoration(
                  border:
                      Border.all(color: theme.colorScheme.primary, width: 3))
              : const BoxDecoration(),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: LayoutBuilder(builder: (context, constraints) {
              double stripHeight = constraints.maxHeight * 0.25;
              return Stack(
                children: [
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.grey.shade800.withValues(alpha: 0.3),
                      child: FadeInImage(
                        placeholder: MemoryImage(kTransparentImage),
                        imageErrorBuilder: (_, _, _) =>
                            const SizedBox.shrink(),
                        image: CachedNetworkImageProvider(coverUrl),
                        alignment: Alignment.topCenter,
                        fit: BoxFit.fitHeight,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    height: stripHeight,
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.fromLTRB(2, 2, 2, 4),
                      color: Colors.black.withValues(alpha: 0.6),
                      child: Text(
                        title,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        style: style.copyWith(
                            color: Colors.white,
                            fontSize: style.fontSize! * 0.9),
                      ),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 4,
                      left: 4,
                      right: 4,
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          color: Colors.red.shade800,
                          child: Text(
                            badge!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: style.copyWith(
                                color: Colors.white,
                                fontSize: style.fontSize! * 0.8),
                          ),
                        ),
                      ),
                    ),
                  if (inLibrary)
                    Positioned(
                      right: 4,
                      bottom: stripHeight + 4,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check,
                            size: 14, color: Colors.white),
                      ),
                    ),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
