import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;
import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// A media source that allows the user to read from ッツ Ebook Reader.
class ReaderTtuSource extends ReaderMediaSource {
  /// Define this media source.
  ReaderTtuSource._privateConstructor()
      : super(
          uniqueKey: 'reader_ttu',
          sourceName: 'ッツ Ebook Reader',
          description: 'Read EPUBs and mine sentences via an embedded web'
              ' reader.',
          icon: Icons.library_books,
          outlinedIcon: Icons.library_books_outlined,
          implementsSearch: false,
          implementsHistory: false,
        );

  /// Get the singleton instance of this home tab.
  static ReaderTtuSource get instance => _instance;

  static final ReaderTtuSource _instance =
      ReaderTtuSource._privateConstructor();

  @override
  Widget get home => const HomeNovelPage();

  /// Origin the reader is served from: [TtuAssetPathHandler] answers it
  /// through the WebView asset loader. IndexedDB is tied to it, so it must
  /// never change between releases.
  static const String origin = 'https://appassets.androidplatform.net';

  /// Absolute URL of a reader page, e.g. `url('b.html?id=3')`.
  String url(String path) => '$origin/$path';

  /// Settings shared by every WebView that loads the reader.
  InAppWebViewSettings get webViewSettings => InAppWebViewSettings(
        webViewAssetLoader: WebViewAssetLoader(
          pathHandlers: [TtuAssetPathHandler()],
        ),
      );

  static const String _bookPathPrefix = 'b.html?id=';

  /// The library entry for ttu book [id].
  MediaItem bookItem({
    required int id,
    required String title,
    String? coverPath,
  }) {
    return MediaItem(
      mediaIdentifier: '$_bookPathPrefix$id',
      title: title,
      imageUrl: coverPath == null ? null : 'file://$coverPath',
      mediaSourceIdentifier: uniqueKey,
      position: 0,
      duration: 1,
      canDelete: false,
      canEdit: true,
    );
  }

  /// ttu's id for a library entry, or null if [item] is not a book (e.g.
  /// the settings page).
  int? bookIdOf(MediaItem item) {
    if (!item.mediaIdentifier.startsWith(_bookPathPrefix)) {
      return null;
    }
    return int.tryParse(
        item.mediaIdentifier.substring(_bookPathPrefix.length));
  }

  /// Where library covers are stored, one file per book id.
  Directory coversDirectory(AppModel appModel) =>
      Directory(path.join(appModel.appDirectory.path, 'ttuCovers'));

  /// Make the Isar library match ttu's IndexedDB: add missing books (with
  /// their covers) and drop entries whose book is gone.
  Future<void> syncLibrary({
    required AppModel appModel,
    required TtuBridge bridge,
  }) async {
    List<TtuBook> books = await bridge.listBooks();
    Map<int, MediaItem> mirrored = {};
    for (MediaItem item in appModel.getMediaSourceHistory(mediaSource: this)) {
      int? id = bookIdOf(item);
      if (id != null) {
        mirrored[id] = item;
      }
    }
    Directory covers = coversDirectory(appModel)..createSync(recursive: true);

    for (TtuBook book in books) {
      if (mirrored.containsKey(book.id)) {
        continue;
      }
      String? coverPath;
      String? dataUrl = await bridge.getCover(book.id);
      UriData? data = dataUrl == null ? null : Uri.parse(dataUrl).data;
      if (data != null) {
        String extension = extensionFromMime(data.mimeType) ?? 'img';
        File file = File(path.join(covers.path, '${book.id}.$extension'));
        file.writeAsBytesSync(data.contentAsBytes());
        coverPath = file.path;
      }
      appModel.putMediaItem(
        bookItem(id: book.id, title: book.title, coverPath: coverPath),
      );
    }

    Set<int> ids = books.map((book) => book.id).toSet();
    for (MapEntry<int, MediaItem> entry in mirrored.entries) {
      if (ids.contains(entry.key)) {
        continue;
      }
      for (FileSystemEntity file in covers.listSync()) {
        if (path.basenameWithoutExtension(file.path) == '${entry.key}') {
          file.deleteSync();
        }
      }
      appModel.deleteStashForMedia(entry.value);
      await appModel.deleteMediaItem(entry.value);
    }

    refreshTab();
  }

  /// Run [task] behind a blocking progress dialog; on failure show the error
  /// and return null.
  Future<T?> runWithProgress<T>({
    required BuildContext context,
    required String message,
    required Future<T> Function() task,
  }) async {
    NavigatorState navigator = Navigator.of(context);
    bool progressShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ).then((_) => progressShown = false);

    try {
      return await task();
    } catch (error) {
      if (progressShown) {
        progressShown = false;
        navigator.pop();
      }
      await showDialog(
        context: navigator.context,
        builder: (context) => AlertDialog(
          title: Text(t.ttu_operation_failed),
          content: Text(error is TtuBridgeException ? error.message : '$error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.dialog_close),
            ),
          ],
        ),
      );
      return null;
    } finally {
      if (progressShown) {
        progressShown = false;
        navigator.pop();
      }
    }
  }

  /// Reconcile the library with ttu's IndexedDB.
  Future<void> refreshLibrary({
    required BuildContext context,
    required AppModel appModel,
  }) async {
    await runWithProgress(
      context: context,
      message: t.ttu_refreshing,
      task: () => TtuHostOperations.run(
        (bridge) => syncLibrary(appModel: appModel, bridge: bridge),
      ),
    );
  }

  static const List<String> _importExtensions = ['epub', 'htmlz', 'txt'];

  /// Let the user pick book files, import them with ttu's importer and add
  /// them to the library.
  Future<void> importBooks({
    required BuildContext context,
    required AppModel appModel,
  }) async {
    List<PlatformFile> picked = await FilePicker.pickFiles();
    if (picked.isEmpty || !context.mounted) {
      return;
    }

    List<PlatformFile> books = picked
        .where((file) => _importExtensions.contains(
            path.extension(file.name).replaceFirst('.', '').toLowerCase()))
        .toList();
    if (books.length != picked.length) {
      Fluttertoast.showToast(msg: t.ttu_unsupported_files);
    }
    if (books.isEmpty) {
      return;
    }

    Directory staging =
        Directory(path.join(appModel.temporaryDirectory.path, 'ttu-import'));
    if (staging.existsSync()) {
      staging.deleteSync(recursive: true);
    }
    staging.createSync(recursive: true);

    try {
      int totalBytes = 0;
      List<String> urls = [];
      for (int i = 0; i < books.length; i++) {
        // One directory per file keeps original names (ttu takes TXT titles
        // and the format from them) even when two picked files share a name.
        Directory slot = Directory(path.join(staging.path, '$i'))
          ..createSync();
        String name = books[i].name;
        File staged =
            File(books[i].path!).copySync(path.join(slot.path, name));
        totalBytes += staged.lengthSync();
        urls.add(url('import/$i/${Uri.encodeComponent(name)}'));
      }

      if (!context.mounted) {
        return;
      }
      await runWithProgress(
        context: context,
        message: t.ttu_importing,
        task: () => TtuHostOperations.run(
          (bridge) async {
            await bridge.importBooks(
              urls,
              timeout: Duration(seconds: 60 + totalBytes ~/ (256 * 1024)),
            );
            await syncLibrary(appModel: appModel, bridge: bridge);
          },
          importDirectory: staging,
        ),
      );
    } finally {
      staging.deleteSync(recursive: true);
      await FilePicker.clearTemporaryFiles();
    }
  }

  /// Ask for confirmation, then delete [item]'s book from ttu and the
  /// library. Returns whether it was deleted.
  Future<bool> deleteBook({
    required BuildContext context,
    required AppModel appModel,
    required MediaItem item,
  }) async {
    int? id = bookIdOf(item);
    if (id == null) {
      return false;
    }

    bool confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(item.title),
            content: Text(t.ttu_delete_book_confirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  t.dialog_delete,
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.dialog_cancel),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return false;
    }

    return await runWithProgress(
          context: context,
          message: t.ttu_deleting,
          task: () => TtuHostOperations.run((bridge) async {
            await bridge.deleteBook(id);
            await syncLibrary(appModel: appModel, bridge: bridge);
            return true;
          }),
        ) ??
        false;
  }

  /// Picks book files and imports them into the library.
  Widget buildImportButton({
    required BuildContext context,
    required AppModel appModel,
  }) {
    return FloatingSearchBarAction(
      showIfOpened: true,
      child: JidoujishoIconButton(
        size: Theme.of(context).textTheme.titleLarge?.fontSize,
        tooltip: t.ttu_import_books,
        icon: Icons.add,
        onTap: () => importBooks(context: context, appModel: appModel),
      ),
    );
  }

  /// Reconciles the library with ttu's IndexedDB.
  Widget buildRefreshButton({
    required BuildContext context,
    required AppModel appModel,
  }) {
    return FloatingSearchBarAction(
      showIfOpened: true,
      child: JidoujishoIconButton(
        size: Theme.of(context).textTheme.titleLarge?.fontSize,
        tooltip: t.ttu_refresh_library,
        icon: Icons.refresh,
        onTap: () => refreshLibrary(context: context, appModel: appModel),
      ),
    );
  }

  @override
  BaseSourcePage buildLaunchPage({
    MediaItem? item,
  }) {
    return ReaderTtuSourcePage(item: item);
  }

  @override
  List<Widget> getActions({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
  }) {
    return [
      buildImportButton(
        context: context,
        appModel: appModel,
      ),
      buildRefreshButton(
        context: context,
        appModel: appModel,
      ),
      buildSettingsButton(
        context: context,
        ref: ref,
        appModel: appModel,
      ),
    ];
  }

  /// Allows user to close the floating search bar of a home tab page
  /// when open.
  Widget buildSettingsButton({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
  }) {
    return FloatingSearchBarAction(
      showIfOpened: true,
      child: JidoujishoIconButton(
        size: Theme.of(context).textTheme.titleLarge?.fontSize,
        tooltip: t.settings,
        icon: Icons.settings,
        onTap: () {
          appModel.openMedia(
            ref: ref,
            mediaSource: this,
            item: MediaItem(
              mediaIdentifier: 'settings.html',
              title: '',
              mediaSourceIdentifier: ReaderTtuSource.instance.uniqueKey,
              position: 0,
              duration: 1,
              canDelete: false,
              canEdit: true,
            ),
          );
        },
      ),
    );
  }

  @override
  BasePage buildHistoryPage({MediaItem? item}) {
    return const ReaderTtuSourceHistoryPage();
  }

  /// Whether or not using the volume buttons in the Reader should turn the
  /// page.
  bool get volumePageTurningEnabled {
    return getPreference<bool>(
        key: 'volume_page_turning_enabled', defaultValue: true);
  }

  /// Toggles the volume page turning option.
  void toggleVolumePageTurningEnabled() async {
    await setPreference<bool>(
      key: 'volume_page_turning_enabled',
      value: !volumePageTurningEnabled,
    );
  }

  /// Controls which direction is up or down for volume button page turning.
  bool get volumePageTurningInverted {
    return getPreference<bool>(
        key: 'volume_page_turning_inverted', defaultValue: false);
  }

  /// Inverts the current volume button page turning direction preference.
  void toggleVolumePageTurningInverted() async {
    await setPreference<bool>(
      key: 'volume_page_turning_inverted',
      value: !volumePageTurningInverted,
    );
  }

  /// Whether or not to add to extend the webpage beyond the navigation bar.
  /// This may be helpful for devices that don't have difficulty accessing the
  /// top bar (i.e. don't have a teardrop notch).
  bool get extendPageBeyondNavigationBar {
    return getPreference<bool>(
        key: 'extend_page_beyond_navbar', defaultValue: false);
  }

  /// Toggles the extend navbar option.
  void toggleExtendPageBeyondNavigationBar() async {
    await setPreference<bool>(
      key: 'extend_page_beyond_navbar',
      value: !extendPageBeyondNavigationBar,
    );
  }

  /// Whether or not the dictionary popup should adapt to the reader's theme.
  bool get adaptTtuTheme {
    return getPreference<bool>(key: 'adapt_ttu_theme', defaultValue: true);
  }

  /// Toggles whether dictionary popup should adapt to the reader's theme.
  void toggleAdaptTtuTheme() async {
    await setPreference<bool>(
      key: 'adapt_ttu_theme',
      value: !adaptTtuTheme,
    );
  }

  /// Whether the reader will highlight words on tap.
  bool get highlightOnTap {
    return getPreference<bool>(
      key: 'highlight_on_tap',
      defaultValue: true,
    );
  }

  /// Toggles whether the reader will highlight words on tap.
  void toggleHighlightOnTap() async {
    await setPreference<bool>(
      key: 'highlight_on_tap',
      value: !highlightOnTap,
    );
  }
}
