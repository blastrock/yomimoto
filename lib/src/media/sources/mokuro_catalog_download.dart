import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:yuuna/media.dart';

/// Lets the user stop a batch of catalog downloads.
class CatalogCancelToken {
  final Completer<void> _cancelled = Completer<void>();

  /// Ask the batch to stop: a download stops at once, an import finishes
  /// first.
  void cancel() {
    if (!_cancelled.isCompleted) {
      _cancelled.complete();
    }
  }

  /// Whether [cancel] was called.
  bool get isCancelled => _cancelled.isCompleted;

  /// Completes when [cancel] is called.
  Future<void> get whenCancelled => _cancelled.future;
}

/// A volume to download: its name, for messages, and its files.
class CatalogDownload {
  /// Describe a volume to download.
  const CatalogDownload({
    required this.volumeName,
    required this.manifest,
  });

  /// The server's name for the volume.
  final String volumeName;

  /// The volume's files.
  final CatalogManifest manifest;
}

/// Where a batch of downloads is.
class CatalogDownloadProgress {
  /// Describe a batch's progress.
  const CatalogDownloadProgress({
    required this.volumeIndex,
    required this.volumeCount,
    required this.receivedBytes,
    required this.totalBytes,
    required this.importing,
  });

  /// The volume being downloaded or imported, from 0.
  final int volumeIndex;

  /// How many volumes the batch has.
  final int volumeCount;

  /// How many bytes the batch has downloaded so far.
  final int receivedBytes;

  /// How many bytes the whole batch is, from the manifests.
  final int totalBytes;

  /// Whether the volume is being imported rather than downloaded.
  final bool importing;
}

/// A volume of a batch could not be downloaded or imported.
class CatalogDownloadException implements Exception {
  /// Create the exception.
  CatalogDownloadException(this.volumeName, this.error);

  /// The server's name for the volume that failed.
  final String volumeName;

  /// What failed: a [CatalogException] or a [MokuroImportException].
  final Object error;

  @override
  String toString() => 'CatalogDownloadException($volumeName, $error)';
}

/// Download [downloads] one at a time and hand each to [importArchive]:
/// a `volume.cbz` with its `volume.mokuro` beside it, in a fresh directory
/// under [temporaryDirectory] deleted afterwards. Returns how many volumes
/// were imported, fewer than [downloads] only when [cancel] stopped the
/// batch: a cancel during a download drops that volume, a cancel during an
/// import keeps it. Throws a [CatalogDownloadException] on the first volume
/// that fails; the volumes imported before it stay.
Future<int> downloadCatalogVolumes({
  required http.Client client,
  required List<CatalogDownload> downloads,
  required Directory temporaryDirectory,
  required CatalogCancelToken cancel,
  required Future<void> Function(String archivePath) importArchive,
  required void Function(CatalogDownloadProgress) onProgress,
  Duration timeout = const Duration(seconds: 30),
}) async {
  int totalBytes = downloads.fold(
      0, (total, download) => total + download.manifest.totalSize);
  int receivedBytes = 0;
  int imported = 0;
  temporaryDirectory.createSync(recursive: true);

  for (int i = 0; i < downloads.length; i++) {
    if (cancel.isCancelled) {
      break;
    }

    void report({required bool importing}) {
      onProgress(CatalogDownloadProgress(
        volumeIndex: i,
        volumeCount: downloads.length,
        receivedBytes: receivedBytes,
        totalBytes: totalBytes,
        importing: importing,
      ));
    }

    void received(int bytes) {
      receivedBytes += bytes;
      report(importing: false);
    }

    CatalogDownload download = downloads[i];
    Directory directory = temporaryDirectory.createTempSync('volume');
    String archivePath = p.join(directory.path, 'volume.cbz');
    try {
      report(importing: false);
      bool complete = await _downloadFile(
            client: client,
            url: download.manifest.archiveUrl,
            file: File(archivePath),
            cancel: cancel,
            timeout: timeout,
            onBytes: received,
          ) &&
          await _downloadFile(
            client: client,
            url: download.manifest.ocrUrl,
            file: File(p.join(directory.path, 'volume.mokuro')),
            cancel: cancel,
            timeout: timeout,
            onBytes: received,
          );
      if (!complete) {
        break;
      }

      report(importing: true);
      await importArchive(archivePath);
      imported++;
    } on CatalogException catch (error) {
      throw CatalogDownloadException(download.volumeName, error);
    } on MokuroImportException catch (error) {
      throw CatalogDownloadException(download.volumeName, error);
    } finally {
      if (directory.existsSync()) {
        directory.deleteSync(recursive: true);
      }
    }
  }

  return imported;
}

/// Download [url] into [file], calling [onBytes] with each chunk's size.
/// Returns false when [cancel] stopped it. Throws [CatalogException].
Future<bool> _downloadFile({
  required http.Client client,
  required Uri url,
  required File file,
  required CatalogCancelToken cancel,
  required Duration timeout,
  required void Function(int bytes) onBytes,
}) async {
  if (cancel.isCancelled) {
    return false;
  }

  IOSink? sink;
  try {
    http.StreamedResponse response = await client
        .send(http.AbortableRequest('GET', url,
            abortTrigger: cancel.whenCancelled))
        .timeout(timeout);
    if (response.statusCode != 200) {
      unawaited(response.stream.listen(null).cancel());
      throw CatalogException(CatalogFailure.http, '${response.statusCode}');
    }

    sink = file.openWrite();
    await for (List<int> chunk in response.stream.timeout(timeout)) {
      sink.add(chunk);
      onBytes(chunk.length);
      if (cancel.isCancelled) {
        return false;
      }
    }
    return !cancel.isCancelled;
  } on TimeoutException {
    if (cancel.isCancelled) {
      return false;
    }
    throw CatalogException(CatalogFailure.network, 'timeout');
  } on http.ClientException catch (error) {
    if (cancel.isCancelled) {
      return false;
    }
    throw CatalogException(CatalogFailure.network, error.message);
  } on IOException catch (error) {
    if (cancel.isCancelled) {
      return false;
    }
    throw CatalogException(CatalogFailure.network, '$error');
  } finally {
    await sink?.close();
  }
}
