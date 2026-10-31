import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/utils.dart';

/// The dialog shown while catalog volumes download: which volume of how
/// many, the bytes downloaded over the whole batch, and a Cancel button
/// that always stays available. The caller closes it when the batch ends.
class MangaDownloadDialog extends StatefulWidget {
  /// Create the dialog for a batch reporting to [progress], stopped through
  /// [cancel].
  const MangaDownloadDialog({
    required this.progress,
    required this.cancel,
    super.key,
  });

  /// The batch's progress, null before the first report.
  final ValueListenable<CatalogDownloadProgress?> progress;

  /// Stops the batch.
  final CatalogCancelToken cancel;

  @override
  State<MangaDownloadDialog> createState() => _MangaDownloadDialogState();
}

class _MangaDownloadDialogState extends State<MangaDownloadDialog> {
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(t.manga_download_title),
        content: ValueListenableBuilder<CatalogDownloadProgress?>(
          valueListenable: widget.progress,
          builder: (context, progress, _) => buildProgress(progress),
        ),
        actions: [
          TextButton(
            onPressed: () => setState(widget.cancel.cancel),
            child: Text(widget.cancel.isCancelled
                ? t.manga_download_cancelling
                : t.dialog_cancel),
          ),
        ],
      ),
    );
  }

  /// The volume, a bar and the bytes downloaded.
  Widget buildProgress(CatalogDownloadProgress? progress) {
    bool importing = progress?.importing ?? false;
    double? value = progress == null || importing || progress.totalBytes == 0
        ? null
        : (progress.receivedBytes / progress.totalBytes).clamp(0, 1);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (progress != null)
          Text(t.manga_download_volume(
              i: progress.volumeIndex + 1, n: progress.volumeCount)),
        const SizedBox(height: 16),
        LinearProgressIndicator(value: value),
        const SizedBox(height: 8),
        if (progress != null)
          Text(importing
              ? t.manga_download_importing
              : t.manga_download_bytes(
                  received: formatCatalogSize(progress.receivedBytes),
                  total: formatCatalogSize(progress.totalBytes),
                )),
      ],
    );
  }
}
