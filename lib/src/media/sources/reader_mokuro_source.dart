import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:path/path.dart' as path;
import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/preferences.dart';
import 'package:yuuna/utils.dart';

/// A media source that allows the user to read manga processed by Mokuro.
///
/// Its library is the volumes imported from `.cbz` and `.zip` archives, each
/// a [MediaItem] whose `mediaIdentifier` is the volume's `volume_uuid` and
/// whose files are in [volumeDirectory].
class ReaderMokuroSource extends ReaderMediaSource {
  /// Define this media source.
  ReaderMokuroSource._privateConstructor()
      : super(
          uniqueKey: 'reader_mokuro',
          sourceName: 'Mokuro',
          description: 'Read manga volumes processed by mokuro.',
          icon: Icons.photo_album,
          outlinedIcon: Icons.photo_album_outlined,
          implementsSearch: false,
          implementsHistory: false,
          overridesAutoImage: true,
        );

  /// Get the singleton instance of this home tab.
  static ReaderMokuroSource get instance => _instance;

  static final ReaderMokuroSource _instance =
      ReaderMokuroSource._privateConstructor();

  @override
  ExplanationKind get explanationKind => ExplanationKind.manga;

  // This source's preferences, prefixed with its uniqueKey.
  static const Preference<bool> _volumePageTurningEnabled =
      Preference('reader_mokuro/volume_page_turning_enabled',
          defaultValue: true);

  static const Preference<bool> _volumePageTurningInverted =
      Preference('reader_mokuro/volume_page_turning_inverted',
          defaultValue: false);

  static const Preference<bool> _highlightOnTap =
      Preference('reader_mokuro/highlight_on_tap', defaultValue: true);

  static const StringListPreference _catalogs =
      StringListPreference('reader_mokuro/catalogs', defaultValue: []);

  /// The base URLs of the mokuro-bunko catalogs the user added, in the order
  /// they were added.
  List<String> get catalogs => List.of(preferences.get(_catalogs));

  /// Add the catalog at [url], a normalised base URL; nothing happens when
  /// it is already there.
  Future<void> addCatalog(String url) async {
    List<String> urls = catalogs;
    if (!urls.contains(url)) {
      await preferences.set(_catalogs, [...urls, url]);
    }
  }

  /// Remove the catalog at [url]. The volumes downloaded from it stay.
  Future<void> removeCatalog(String url) =>
      preferences.set(_catalogs, catalogs..remove(url));

  @override
  Widget get home => const HomeMangaPage();

  @override
  double get aspectRatio => 257 / 364;

  /// Where imported volumes are stored, one directory per volume.
  Directory volumesDirectory(AppModel appModel) =>
      Directory(path.join(appModel.appDirectory.path, 'mangaVolumes'));

  /// The directory of [item]'s volume: `volume.mokuro` and
  /// `images/<img_path>`.
  Directory volumeDirectory(AppModel appModel, MediaItem item) => Directory(
      path.join(volumesDirectory(appModel).path, item.mediaIdentifier));

  /// The image of page [page] of the volume in [volume], as its OCR names it
  /// (relative to the volume's `images/`), or null when there is no such
  /// page or the OCR cannot be read.
  static String? imagePathOfPage(Directory volume, int page) {
    try {
      List<MokuroPage> pages = MokuroVolume.parse(
              File(path.join(volume.path, 'volume.mokuro'))
                  .readAsStringSync())
          .pages;
      return page >= 0 && page < pages.length ? pages[page].imgPath : null;
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  /// A word stashed from a volume gets the image of its page.
  @override
  String? imageDataFor({
    required AppModel appModel,
    required MediaItem item,
    required int position,
  }) =>
      imagePathOfPage(volumeDirectory(appModel, item), position);

  /// The page whose image path [data] is, from the volume's files: the
  /// reader sets it for the page of the word looked up, and [imageDataFor]
  /// for a stashed word.
  @override
  Future<List<NetworkToFileImage>> generateImages({
    required AppModel appModel,
    required MediaItem item,
    String? data,
  }) async {
    if (data == null) {
      return [];
    }
    File page = File(
        path.join(volumeDirectory(appModel, item).path, 'images', data));
    if (!page.existsSync()) {
      return [];
    }

    Directory previews = Directory(
        path.join(appModel.temporaryDirectory.path, 'mokuroImagePreview'));
    if (previews.existsSync()) {
      previews.deleteSync(recursive: true);
    }
    // A new directory each time, so that no cached image is shown instead.
    Directory directory = Directory(path.join(
        previews.path, '${DateTime.now().millisecondsSinceEpoch}'))
      ..createSync(recursive: true);
    File file = appModel.getPreviewImageFile(directory, 0);
    page.copySync(file.path);

    return [NetworkToFileImage(file: file)];
  }

  /// A volume's `duration` for [pageCount] pages: the last page's index,
  /// since its `position` is the index of the highest page shown, so that
  /// reaching the last page reads as finished in the library.
  static int progressLength(int pageCount) =>
      pageCount > 1 ? pageCount - 1 : 1;

  /// The library entry for an imported volume. A volume imported again
  /// keeps the [existing] entry's row, so its stash, its reading position
  /// and the title the user gave it.
  static MediaItem volumeItem({
    required MokuroImportResult result,
    MediaItem? existing,
  }) {
    String? coverPath = result.coverPath;
    return MediaItem(
      id: existing?.id,
      mediaIdentifier: result.volumeUuid,
      title: result.title,
      mediaSourceIdentifier: instance.uniqueKey,
      imageUrl: coverPath == null ? null : 'file://$coverPath',
      position: existing?.position ?? 0,
      duration: progressLength(result.pageCount),
      canDelete: false,
      canEdit: true,
      overrideTitle: existing?.overrideTitle,
    );
  }

  /// Let the user pick a volume's archive, with its `.mokuro` file unless
  /// the archive holds it, import the volume and add it to the library.
  Future<void> importVolume({
    required BuildContext context,
    required AppModel appModel,
  }) async {
    List<PlatformFile> picked = await FilePicker.pickFiles();
    if (picked.isEmpty) {
      return;
    }

    try {
      MokuroPick? pick = mokuroPickOf([
        for (PlatformFile file in picked) (name: file.name, path: file.path),
      ]);
      if (pick == null) {
        if (context.mounted) {
          await showImportError(context: context, message: t.manga_import_pick);
        }
        return;
      }
      if (!context.mounted) {
        return;
      }

      MokuroImportError? error = await runWithProgress<MokuroImportError?>(
        context: context,
        message: t.manga_importing,
        task: () async {
          try {
            await importArchive(
              appModel: appModel,
              archivePath: pick.archivePath,
              ocrPath: pick.ocrPath,
            );
            return null;
          } on MokuroImportException catch (error) {
            debugPrint('manga import: $error');
            return error.error;
          }
        },
      );
      if (error != null && context.mounted) {
        await showImportError(
            context: context, message: importErrorMessage(error));
      }
    } finally {
      await FilePicker.clearTemporaryFiles();
    }
  }

  /// Tell the user why a volume could not be imported.
  Future<void> showImportError({
    required BuildContext context,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t.manga_import_failed),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(t.dialog_close),
          ),
        ],
      ),
    );
  }

  /// Import the volume in the archive at [archivePath], its OCR being the
  /// file at [ocrPath] or else inside the archive, and add it to the
  /// library, keeping the entry of a volume imported before. Throws a
  /// [MokuroImportException] when the volume cannot be imported.
  Future<MokuroImportResult> importArchive({
    required AppModel appModel,
    required String archivePath,
    String? ocrPath,
  }) async {
    MokuroImportResult result = await compute(
      importMokuroVolume,
      MokuroImportParams(
        archivePath: archivePath,
        ocrPath: ocrPath,
        volumesDirectory: volumesDirectory(appModel).path,
      ),
    );

    MediaItem? existing = appModel
        .getMediaSourceHistory(mediaSource: this)
        .firstWhereOrNull((item) => item.mediaIdentifier == result.volumeUuid);
    await appModel.putMediaItem(volumeItem(result: result, existing: existing));
    if (result.missingPages > 0) {
      showToast(msg: t.manga_import_missing_pages(n: result.missingPages));
    }
    refreshTab();
    return result;
  }

  /// The message telling the user why an import failed with [error].
  String importErrorMessage(MokuroImportError error) {
    switch (error) {
      case MokuroImportError.notAnArchive:
        return t.manga_import_not_archive;
      case MokuroImportError.noOcr:
        return t.manga_import_no_ocr;
      case MokuroImportError.severalOcr:
        return t.manga_import_several_ocr;
      case MokuroImportError.invalidOcr:
        return t.manga_import_invalid_ocr;
    }
  }

  /// Ask for confirmation, then delete [item]'s volume, its files and its
  /// stash. Returns whether it was deleted.
  Future<bool> deleteVolume({
    required BuildContext context,
    required AppModel appModel,
    required MediaItem item,
  }) async {
    bool confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(getDisplayTitleFromMediaItem(item)),
            content: Text(t.manga_delete_volume_confirm),
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

    bool deleted = await runWithProgress(
          context: context,
          message: t.manga_deleting,
          task: () async {
            await appModel.deleteMediaItem(item);
            Directory directory = volumeDirectory(appModel, item);
            if (directory.existsSync()) {
              await directory.delete(recursive: true);
            }
            return true;
          },
        ) ??
        false;
    refreshTab();
    return deleted;
  }

  /// Settings for the WebView showing the volume in [volume]: the reader
  /// page and the volume's files are served on the asset loader's origin.
  /// Zoom is the WebView's own pinch-zoom, which the defaults enable.
  InAppWebViewSettings webViewSettings(Directory volume) =>
      InAppWebViewSettings(
        webViewAssetLoader: WebViewAssetLoader(
          pathHandlers: [
            MokuroAssetPathHandler(),
            MokuroVolumePathHandler(volume),
          ],
        ),
      );

  int? _peekPage;

  /// Open [item] at page [position] to see a word in context. The volume's
  /// reading position is left untouched for the whole session.
  @override
  Future<void> peek({
    required WidgetRef ref,
    required AppModel appModel,
    required MediaItem item,
    required int position,
  }) async {
    _peekPage = position;
    try {
      await appModel.openMedia(ref: ref, mediaSource: this, item: item);
    } finally {
      _peekPage = null;
    }
  }

  @override
  BaseSourcePage buildLaunchPage({
    MediaItem? item,
  }) {
    return ReaderMokuroSourcePage(item: item!, peekPage: _peekPage);
  }

  @override
  BasePage buildHistoryPage({MediaItem? item}) {
    return const ReaderMokuroHistoryPage();
  }

  @override
  List<Widget> getActions({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
  }) {
    return [
      FloatingSearchBarAction(
        showIfOpened: true,
        child: JidoujishoIconButton(
          size: Theme.of(context).textTheme.titleLarge?.fontSize,
          tooltip: t.manga_add_volume,
          icon: Icons.add,
          onTap: () => showDialog<void>(
            context: context,
            builder: (_) => const MangaAddVolumeDialogPage(),
          ),
        ),
      ),
    ];
  }

  /// Whether or not using the volume buttons in the Reader should turn the
  /// page.
  bool get volumePageTurningEnabled =>
      preferences.get(_volumePageTurningEnabled);

  /// Toggles the volume page turning option.
  Future<void> toggleVolumePageTurningEnabled() =>
      preferences.toggle(_volumePageTurningEnabled);

  /// Controls which direction is up or down for volume button page turning.
  bool get volumePageTurningInverted =>
      preferences.get(_volumePageTurningInverted);

  /// Inverts the current volume button page turning direction preference.
  Future<void> toggleVolumePageTurningInverted() =>
      preferences.toggle(_volumePageTurningInverted);

  /// Whether the reader will highlight words on tap.
  bool get highlightOnTap => preferences.get(_highlightOnTap);

  /// Toggles whether the reader will highlight words on tap.
  Future<void> toggleHighlightOnTap() =>
      preferences.toggle(_highlightOnTap);
}
