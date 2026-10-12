import 'package:flutter/material.dart';
import 'package:spaces/spaces.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';

/// The shared body content for a [ReaderMediaSource]'s tab in the main menu.
/// Each reader source subclasses this to supply its own history.
abstract class HistoryReaderPage extends BaseHistoryPage {
  /// Create an instance of this tab page.
  const HistoryReaderPage({
    super.key,
  });
}

/// A base class for providing all tabs in the main menu. In large part, this
/// was implemented to define shortcuts for common lengthy methods across UI
/// code.
abstract class HistoryReaderPageState<T extends HistoryReaderPage>
    extends BaseHistoryPageState {
  /// Whether tiles show a reading-progress bar.
  bool get showProgress => true;

  /// This is shown as the body when [shouldPlaceholderBeShown] is false.
  @override
  Widget buildHistory(List<MediaItem> items) {
    return RawScrollbar(
      thumbVisibility: true,
      thickness: 3,
      controller: mediaSource.scrollController,
      child: GridView.builder(
        padding: const EdgeInsets.only(top: 48),
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 150,
          childAspectRatio: mediaSource.aspectRatio,
        ),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        controller: mediaSource.scrollController,
        itemCount: items.length,
        itemBuilder: (context, index) => buildMediaItem(items[index]),
      ),
    );
  }

  /// Build the widget visually representing the [MediaItem]'s history tile.
  @override
  Widget buildMediaItemContent(MediaItem item) {
    return Container(
      padding: Spacing.of(context).insets.all.normal,
      child: Stack(
        alignment: Alignment.bottomLeft,
        children: [
          ColoredBox(
            color: Colors.grey.shade800.withValues(alpha: 0.3),
            child: AspectRatio(
              aspectRatio: mediaSource.aspectRatio,
              child: FadeInImage(
                key: UniqueKey(),
                imageErrorBuilder: (_, _, _) => const SizedBox.shrink(),
                placeholder: MemoryImage(kTransparentImage),
                image: mediaSource.getDisplayThumbnailFromMediaItem(
                  appModel: appModel,
                  item: item,
                ),
                alignment: Alignment.topCenter,
                fit: BoxFit.fitHeight,
              ),
            ),
          ),
          LayoutBuilder(builder: (context, constraints) {
            return Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 4),
              height: constraints.maxHeight * 0.25,
              width: double.maxFinite,
              color: Colors.black.withValues(alpha: 0.6),
              child: Text(
                mediaSource.getDisplayTitleFromMediaItem(item),
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                textAlign: TextAlign.center,
                softWrap: true,
                style: textTheme.bodySmall!.copyWith(
                    color: Colors.white,
                    fontSize: textTheme.bodySmall!.fontSize! * 0.9),
              ),
            );
          }),
          if (showProgress)
            LinearProgressIndicator(
              value: (item.position / item.duration).isNaN ||
                      (item.position / item.duration) == double.infinity ||
                      (item.position == 0 && item.duration == 0)
                  ? 0
                  : ((item.position / item.duration) > 0.97)
                      ? 1
                      : (item.position / item.duration),
              backgroundColor: Colors.white.withValues(alpha: 0.6),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
              minHeight: 2,
            ),
        ],
      ),
    );
  }
}
