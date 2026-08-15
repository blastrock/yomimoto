import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// A template for a single home tab's history body content in the main menu
/// given a selected media source.
abstract class BaseHistoryPage extends BasePage {
  /// Create an instance of this tab page.
  const BaseHistoryPage({
    super.key,
  });

  @override
  BaseHistoryPageState<BaseHistoryPage> createState();
}

/// A base class for providing all tabs in the main menu. In large part, this
/// was implemented to define shortcuts for common lengthy methods across UI
/// code.
abstract class BaseHistoryPageState<T extends BaseHistoryPage>
    extends BasePageState<T> {
  /// Each tab in the home page is a [HomeTab].
  HomeTab get homeTab;

  /// Get the media source for the current home tab.
  MediaSource get mediaSource;

  /// This variable is true when the [buildPlaceholder] should be shown.
  /// For example, if a certain home tab does not have any media items to
  /// show in its history.
  bool get shouldPlaceholderBeShown => true;

  /// Whether or not to allow edit and delete.
  bool get isHistory => true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context);

  /// This is shown as the body when [shouldPlaceholderBeShown] is true.
  Widget buildPlaceholder() {
    return Center(
      child: JidoujishoPlaceholderMessage(
        icon: homeTab.outlinedIcon,
        message: t.info_empty_home_tab,
      ),
    );
  }

  /// This is shown as the body when [shouldPlaceholderBeShown] is false.
  Widget buildHistory(List<MediaItem> items) {
    return Container();
  }

  /// Wraps the [MediaItem] and adds interaction functionality for tapping
  /// and long pressing.
  Widget buildMediaItem(MediaItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          MediaSource mediaSource = item.getMediaSource(appModel: appModel);

          await appModel.openMedia(
            ref: ref,
            mediaSource: mediaSource,
            item: item,
          );
        },
        onLongPress: () async {
          await showDialog(
            context: context,
            builder: (context) => MediaItemDialogPage(
              item: item,
              isHistory: isHistory,
              extraActions: extraActions,
            ),
          );
          if (isHistory) {
            setState(() {});
          }
        },
        child: buildMediaItemContent(item),
      ),
    );
  }

  /// Extra actions to supply to a history page.
  List<Widget> extraActions(MediaItem item) {
    return [];
  }

  /// Build the widget visually representing the [MediaItem]'s history tile.
  Widget buildMediaItemContent(MediaItem item);
}
