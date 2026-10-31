import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// The volumes of a series in a mokuro-bunko catalog that can be read (not
/// waiting for OCR), as a grid of covers. Volumes already in the library
/// have a check. A tap downloads a volume, a long-press starts selecting
/// several.
class MangaSeriesPage extends BasePage {
  /// Create the page for [series] in the catalog at [catalogUrl].
  const MangaSeriesPage({
    required this.catalogUrl,
    required this.series,
    super.key,
  });

  /// The catalog's base URL.
  final String catalogUrl;

  /// The series whose volumes are shown.
  final CatalogSeries series;

  @override
  BasePageState<MangaSeriesPage> createState() => _MangaSeriesPageState();
}

class _MangaSeriesPageState extends BasePageState<MangaSeriesPage> {
  late final MokuroCatalogClient _client =
      MokuroCatalogClient(widget.catalogUrl);

  List<CatalogVolume>? _volumes;
  Map<String, String> _uuids = {};
  Set<String> _library = {};
  CatalogFailure? _failure;
  final Set<String> _selected = {};

  bool get _isSelecting => _selected.isNotEmpty;

  ReaderMokuroSource get _source => ReaderMokuroSource.instance;

  @override
  void initState() {
    super.initState();
    _readLibrary();
    _load();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  void _readLibrary() {
    _library = {
      for (MediaItem item
          in appModelNoUpdate.getMediaSourceHistory(mediaSource: _source))
        item.mediaIdentifier,
    };
  }

  Future<void> _load() async {
    setState(() {
      _volumes = null;
      _failure = null;
    });

    Future<Map<String, String>> uuids = _client
        .fetchVolumeUuids(widget.series.name)
        .catchError((Object error) {
      debugPrint('catalog series.json: $error');
      return <String, String>{};
    }, test: (error) => error is CatalogException);
    try {
      List<CatalogVolume> volumes =
          await _client.fetchVolumes(widget.series.name);
      Map<String, String> found = await uuids;
      if (mounted) {
        setState(() {
          _volumes = volumes.where((volume) => !volume.ocrPending).toList();
          _uuids = found;
        });
      }
    } on CatalogException catch (error) {
      debugPrint('catalog series: $error');
      unawaited(uuids);
      if (mounted) {
        setState(() => _failure = error.failure);
      }
    }
  }

  bool _inLibrary(CatalogVolume volume) =>
      _library.contains(_uuids[volume.name]);

  void _toggle(CatalogVolume volume) {
    setState(() {
      if (!_selected.remove(volume.name)) {
        _selected.add(volume.name);
      }
    });
  }

  String _failureMessage(String volumeName, Object error) {
    String reason = switch (error) {
      CatalogException(:CatalogFailure failure) =>
        catalogFailureMessage(failure),
      MokuroImportException(:MokuroImportError error) =>
        _source.importErrorMessage(error),
      _ => '$error',
    };
    return t.manga_download_failed(name: volumeName, reason: reason);
  }

  /// The manifests of [volumes], or null when one could not be fetched,
  /// which the user is told.
  Future<List<CatalogDownload>?> _fetchManifests(
      List<CatalogVolume> volumes) {
    return runWithProgress<List<CatalogDownload>?>(
      context: context,
      message: t.manga_download_preparing,
      task: () async {
        List<CatalogDownload> downloads = [];
        for (CatalogVolume volume in volumes) {
          try {
            downloads.add(CatalogDownload(
              volumeName: volume.name,
              manifest: await _client.fetchManifest(
                  widget.series.name, volume.name),
            ));
          } on CatalogException catch (error) {
            debugPrint('catalog manifest: $error');
            showToast(msg: _failureMessage(volume.name, error));
            return null;
          }
        }
        return downloads;
      },
    );
  }

  Future<bool> _confirm(List<CatalogVolume> volumes,
      List<CatalogDownload> downloads) async {
    String size = formatCatalogSize(downloads.fold(
        0, (total, download) => total + download.manifest.totalSize));
    String title;
    String content;
    if (volumes.length == 1) {
      CatalogVolume volume = volumes.single;
      title = _inLibrary(volume)
          ? t.manga_download_again(name: volume.name)
          : t.manga_download_one(name: volume.name);
      content = t.manga_download_size(size: size);
    } else {
      title = t.manga_download_many(n: volumes.length);
      content = t.manga_download_total(size: size);
    }

    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(content),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.dialog_cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(t.dialog_download),
              ),
            ],
          ),
        ) ??
        false;
  }

  /// Ask, then download [volumes] into the library.
  Future<void> _download(List<CatalogVolume> volumes) async {
    List<CatalogDownload>? downloads = await _fetchManifests(volumes);
    if (downloads == null || !mounted) {
      return;
    }
    if (!await _confirm(volumes, downloads) || !mounted) {
      return;
    }

    NavigatorState navigator = Navigator.of(context);
    ValueNotifier<CatalogDownloadProgress?> progress = ValueNotifier(null);
    CatalogCancelToken cancel = CatalogCancelToken();
    unawaited(showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => MangaDownloadDialog(progress: progress, cancel: cancel),
    ));

    try {
      await downloadCatalogVolumes(
        client: _client.httpClient,
        downloads: downloads,
        temporaryDirectory: Directory(p.join(
            appModelNoUpdate.temporaryDirectory.path, 'catalogDownloads')),
        cancel: cancel,
        importArchive: (path) => _source.importArchive(
            appModel: appModelNoUpdate, archivePath: path),
        onProgress: (value) => progress.value = value,
      );
    } on CatalogDownloadException catch (error) {
      debugPrint('catalog download: $error');
      showToast(msg: _failureMessage(error.volumeName, error.error));
    } finally {
      navigator.pop();
      progress.dispose();
      if (mounted) {
        setState(() {
          _selected.clear();
          _readLibrary();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          setState(_selected.clear);
        }
      },
      child: Scaffold(
        appBar: _isSelecting ? buildSelectionAppBar() : buildAppBar(),
        body: SafeArea(child: buildBody()),
      ),
    );
  }

  /// The app bar showing the series' title.
  PreferredSizeWidget buildAppBar() {
    return AppBar(
      titleSpacing: 8,
      title: Text(widget.series.displayTitle),
    );
  }

  /// The app bar in selection mode.
  PreferredSizeWidget buildSelectionAppBar() {
    return AppBar(
      titleSpacing: 8,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: t.dialog_cancel,
        onPressed: () => setState(_selected.clear),
      ),
      title: Text(t.manga_selected(n: _selected.length)),
      actions: [
        IconButton(
          icon: const Icon(Icons.download),
          tooltip: t.dialog_download,
          onPressed: () => _download(_volumes!
              .where((volume) => _selected.contains(volume.name))
              .toList()),
        ),
      ],
    );
  }

  /// A spinner, the failure with a retry button, or the volumes.
  Widget buildBody() {
    CatalogFailure? failure = _failure;
    if (failure != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(catalogFailureMessage(failure)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _load,
              child: Text(t.dialog_retry),
            ),
          ],
        ),
      );
    }
    List<CatalogVolume>? volumes = _volumes;
    if (volumes == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 150,
        childAspectRatio: _source.aspectRatio,
      ),
      itemCount: volumes.length,
      itemBuilder: (context, index) => buildVolume(volumes[index]),
    );
  }

  /// One volume's cover.
  Widget buildVolume(CatalogVolume volume) {
    return MangaCatalogTile(
      coverUrl: _client.coverUri(volume.cover).toString(),
      title: volume.name,
      inLibrary: _inLibrary(volume),
      selected: _selected.contains(volume.name),
      onTap: _isSelecting ? () => _toggle(volume) : () => _download([volume]),
      onLongPress: () => _toggle(volume),
    );
  }
}
