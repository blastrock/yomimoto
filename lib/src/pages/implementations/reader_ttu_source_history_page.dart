import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// A page for [ReaderTtuSource]'s tab body content when selected as a source
/// in the main menu.
class ReaderTtuSourceHistoryPage extends HistoryReaderPage {
  /// Create an instance of this tab page.
  const ReaderTtuSourceHistoryPage({
    super.key,
  });

  @override
  BaseHistoryPageState<BaseHistoryPage> createState() =>
      _ReaderTtuSourceHistoryPageState();
}

/// A base class for providing all tabs in the main menu. In large part, this
/// was implemented to define shortcuts for common lengthy methods across UI
/// code.
class _ReaderTtuSourceHistoryPageState<T extends HistoryReaderPage>
    extends HistoryReaderPageState {
  @override
  ReaderTtuSource get mediaSource => ReaderTtuSource.instance;

  @override
  Widget build(BuildContext context) {
    AsyncValue<List<MediaItem>> books =
        ref.watch(ttuBooksProvider);

    return books.when(
      data: buildBody,
      error: (error, stack) => buildError(
        error: error,
        stack: stack,
        refresh: () {
          ref.invalidate(ttuBooksProvider);
        },
      ),
      loading: buildLoading,
    );
  }

  Widget buildBody(List<MediaItem> books) {
    if (books.isEmpty) {
      return buildPlaceholder();
    } else {
      return buildHistory(books);
    }
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
