import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;
import 'package:yuuna/media.dart';

/// What [importMokuroVolume] imports and where it puts it. Plain strings, so
/// that it can be sent to an isolate.
class MokuroImportParams {
  /// Describe an import.
  const MokuroImportParams({
    required this.archivePath,
    required this.volumesDirectory,
  });

  /// The `.cbz` or `.zip` holding the volume's images.
  final String archivePath;

  /// Where volumes are stored, one directory per volume.
  final String volumesDirectory;
}

/// A volume [importMokuroVolume] imported.
class MokuroImportResult {
  /// Describe an imported volume.
  const MokuroImportResult({
    required this.volumeUuid,
    required this.title,
    required this.pageCount,
    required this.missingPages,
    required this.directory,
    required this.coverPath,
  });

  /// The volume's identity, from its `.mokuro` file.
  final String volumeUuid;

  /// The name to show for the volume ([MokuroVolume.displayTitle]).
  final String title;

  /// How many pages the volume has.
  final int pageCount;

  /// How many of those pages have no image in the archive.
  final int missingPages;

  /// The volume's directory: `volume.mokuro` and `images/<img_path>`.
  final String directory;

  /// The first page's image, or null when it is missing.
  final String? coverPath;
}

/// Why a volume could not be imported.
enum MokuroImportError {
  /// The picked file is not a zip archive.
  notAnArchive,

  /// There is no `.mokuro` beside the archive or inside it.
  noOcr,

  /// There is no `.mokuro` beside the archive and several inside it.
  severalOcr,

  /// The `.mokuro` file is not a volume.
  invalidOcr,
}

/// A volume could not be imported.
class MokuroImportException implements Exception {
  /// Create the exception.
  MokuroImportException(this.error, [this.detail]);

  /// Why the import failed.
  final MokuroImportError error;

  /// What went wrong, for logs.
  final String? detail;

  @override
  String toString() => 'MokuroImportException($error, $detail)';
}

/// Top-level function for use in compute. Copies the volume in
/// [MokuroImportParams.archivePath] into its own directory under
/// [MokuroImportParams.volumesDirectory], replacing any earlier import of
/// the same volume. Its OCR is the `.mokuro` file beside the archive with
/// the archive's name, else the only `.mokuro` file inside it. Only the
/// images the OCR names are copied. Throws a [MokuroImportException] when
/// the volume cannot be imported, leaving nothing behind.
MokuroImportResult importMokuroVolume(MokuroImportParams params) {
  if (!_isZip(params.archivePath)) {
    throw MokuroImportException(MokuroImportError.notAnArchive);
  }

  InputFileStream input = InputFileStream(params.archivePath);
  try {
    Archive archive;
    try {
      archive = ZipDecoder().decodeStream(input);
    } catch (error) {
      throw MokuroImportException(
          MokuroImportError.notAnArchive, error.toString());
    }

    Map<String, ArchiveFile> files = {
      for (ArchiveFile file in archive.files)
        if (file.isFile) file.name: file,
    };

    String source = _readOcr(params.archivePath, files);
    MokuroVolume volume;
    try {
      volume = MokuroVolume.parse(source);
    } on FormatException catch (error) {
      throw MokuroImportException(
          MokuroImportError.invalidOcr, error.toString());
    }

    Directory target =
        Directory(p.join(params.volumesDirectory, volume.volumeUuid));
    Directory staging = Directory('${target.path}.importing');
    if (staging.existsSync()) {
      staging.deleteSync(recursive: true);
    }

    try {
      Set<String> entries = files.keys.toSet();
      int missingPages = 0;
      bool hasCover = false;
      for (int i = 0; i < volume.pages.length; i++) {
        String imgPath = volume.pages[i].imgPath;
        String? entry = resolveImageEntry(imgPath, entries);
        if (entry == null) {
          missingPages++;
          continue;
        }

        File image = File(p.join(staging.path, 'images', imgPath))
          ..parent.createSync(recursive: true);
        OutputFileStream output = OutputFileStream(image.path);
        try {
          files[entry]!.writeContent(output);
        } finally {
          output.closeSync();
        }
        hasCover = hasCover || i == 0;
      }

      File(p.join(staging.path, 'volume.mokuro'))
        ..parent.createSync(recursive: true)
        ..writeAsStringSync(source);

      if (target.existsSync()) {
        target.deleteSync(recursive: true);
      }
      staging.renameSync(target.path);

      return MokuroImportResult(
        volumeUuid: volume.volumeUuid,
        title: volume.displayTitle,
        pageCount: volume.pages.length,
        missingPages: missingPages,
        directory: target.path,
        coverPath: hasCover
            ? p.join(target.path, 'images', volume.pages.first.imgPath)
            : null,
      );
    } catch (_) {
      if (staging.existsSync()) {
        staging.deleteSync(recursive: true);
      }
      rethrow;
    }
  } finally {
    input.closeSync();
  }
}

/// Whether the file at [path] starts like a zip archive: the decoder reads
/// anything else as an empty archive instead of failing.
bool _isZip(String path) {
  RandomAccessFile file = File(path).openSync();
  try {
    List<int> magic = file.readSync(4);
    return magic.length == 4 &&
        magic[0] == 0x50 &&
        magic[1] == 0x4b &&
        ((magic[2] == 3 && magic[3] == 4) || (magic[2] == 5 && magic[3] == 6));
  } finally {
    file.closeSync();
  }
}

/// The text of the volume's OCR: the `.mokuro` beside [archivePath] with its
/// name, else the only `.mokuro` among [files].
String _readOcr(String archivePath, Map<String, ArchiveFile> files) {
  File beside = File(p.setExtension(archivePath, '.mokuro'));
  if (beside.existsSync()) {
    return beside.readAsStringSync();
  }

  List<ArchiveFile> inside = files.values
      .where((file) => file.name.toLowerCase().endsWith('.mokuro'))
      .toList();
  if (inside.isEmpty) {
    throw MokuroImportException(MokuroImportError.noOcr);
  }
  if (inside.length > 1) {
    throw MokuroImportException(MokuroImportError.severalOcr);
  }

  try {
    return utf8.decode(inside.single.readBytes() ?? []);
  } on FormatException catch (error) {
    throw MokuroImportException(
        MokuroImportError.invalidOcr, error.toString());
  }
}

/// The archive entry holding the image a page names with [imgPath], among
/// the archive's [fileEntries], or null. Producers do not agree on what
/// `img_path` is relative to: mokuro-bunko names the archive's folder in it,
/// the mokuro tool does not. So [imgPath] is looked up at the archive's root,
/// then in its single top-level folder when every entry is in one. A path
/// that is absolute or leaves the image root names nothing.
String? resolveImageEntry(String imgPath, Set<String> fileEntries) {
  String normalised = p.posix.normalize(imgPath);
  if (p.posix.isAbsolute(normalised) ||
      p.posix.split(normalised).contains('..')) {
    return null;
  }

  if (fileEntries.contains(normalised)) {
    return normalised;
  }

  Set<String> topFolders = {
    for (String entry in fileEntries)
      if (entry.contains('/')) entry.split('/').first else '',
  };
  if (topFolders.length != 1 || topFolders.single.isEmpty) {
    return null;
  }

  String nested = '${topFolders.single}/$normalised';
  return fileEntries.contains(nested) ? nested : null;
}
