import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// A page for [ReaderTtuSource]'s tab body content when selected as a source
/// in the main menu: the library, read from its Isar mirror.
class ReaderTtuSourceHistoryPage extends HistoryReaderPage {
  /// Create an instance of this tab page.
  const ReaderTtuSourceHistoryPage({
    super.key,
  });

  @override
  BaseHistoryPageState<BaseHistoryPage> createState() =>
      _ReaderTtuSourceHistoryPageState();
}

class _ReaderTtuSourceHistoryPageState<T extends HistoryReaderPage>
    extends HistoryReaderPageState {
  @override
  ReaderTtuSource get mediaSource => ReaderTtuSource.instance;

  @override
  bool get showProgress => false;

  @override
  void initState() {
    super.initState();
    mediaSource.tabRefreshNotifier.addListener(refresh);
  }

  @override
  void dispose() {
    mediaSource.tabRefreshNotifier.removeListener(refresh);
    super.dispose();
  }

  /// Refresh the page and respond to library changes.
  void refresh() {
    setState(() {});
  }

  @override
  List<Widget> extraActions(MediaItem item) {
    return [
      TextButton(
        onPressed: () async {
          NavigatorState navigator = Navigator.of(context);
          navigator.pop();
          await navigator.push(
            MaterialPageRoute(
              builder: (context) => StashPage(item: item),
            ),
          );
        },
        child: Text(t.stash.toUpperCase()),
      ),
      TextButton(
        onPressed: () async {
          NavigatorState navigator = Navigator.of(context);
          bool deleted = await mediaSource.deleteBook(
            context: context,
            appModel: appModel,
            item: item,
          );
          if (deleted) {
            navigator.pop();
          }
        },
        child: Text(
          t.dialog_delete,
          style: TextStyle(color: theme.colorScheme.primary),
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    List<MediaItem> items = appModel
        .getMediaSourceHistory(mediaSource: mediaSource)
        .reversed
        .toList();

    return items.isEmpty ? buildPlaceholder() : buildHistory(items);
  }

  /// This is shown as the body when [shouldPlaceholderBeShown] is true.
  @override
  Widget buildPlaceholder() {
    return Center(
      child: JidoujishoPlaceholderMessage(
        icon: mediaSource.icon,
        message: t.ttu_no_books_added,
      ),
    );
  }
}
