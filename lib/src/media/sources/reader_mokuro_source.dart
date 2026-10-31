import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:filesystem_picker/filesystem_picker.dart';
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
      duration: result.pageCount,
      canDelete: false,
      canEdit: true,
      overrideTitle: existing?.overrideTitle,
    );
  }

  /// Let the user pick an archive, import its volume and add it to the
  /// library.
  Future<void> importVolume({
    required BuildContext context,
    required AppModel appModel,
  }) async {
    List<Directory> rootDirectories =
        await appModel.getFilePickerDirectoriesForMediaSource(this);
    if (!context.mounted) {
      return;
    }

    Iterable<String>? picked = await FilesystemPicker.open(
      allowedExtensions: ['.cbz', '.zip'],
      context: context,
      rootDirectories: rootDirectories,
      fsType: FilesystemType.file,
      title: '',
      pickText: t.dialog_select,
      cancelText: t.dialog_cancel,
      themeData: Theme.of(context),
      folderIconColor: Theme.of(context).colorScheme.primary,
    );
    if (picked == null || picked.isEmpty || !context.mounted) {
      return;
    }

    String archivePath = picked.first;
    appModel.setLastPickedDirectory(
      mediaSource: this,
      directory: Directory(path.dirname(archivePath)),
    );

    MokuroImportResult? result = await runWithProgress<MokuroImportResult?>(
      context: context,
      message: t.manga_importing,
      task: () async {
        try {
          return await compute(
            importMokuroVolume,
            MokuroImportParams(
              archivePath: archivePath,
              volumesDirectory: volumesDirectory(appModel).path,
            ),
          );
        } on MokuroImportException catch (error) {
          debugPrint('manga import: $error');
          showToast(msg: _importErrorMessage(error.error));
          return null;
        }
      },
    );
    if (result == null) {
      return;
    }

    MediaItem? existing = appModel
        .getMediaSourceHistory(mediaSource: this)
        .firstWhereOrNull((item) => item.mediaIdentifier == result.volumeUuid);
    await appModel.putMediaItem(volumeItem(result: result, existing: existing));
    if (result.missingPages > 0) {
      showToast(msg: t.manga_import_missing_pages(n: result.missingPages));
    }
    refreshTab();
  }

  String _importErrorMessage(MokuroImportError error) {
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
          tooltip: t.manga_import_volume,
          icon: Icons.add,
          onTap: () => importVolume(context: context, appModel: appModel),
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
