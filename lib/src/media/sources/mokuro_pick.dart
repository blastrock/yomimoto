import 'package:path/path.dart' as p;

/// The files of one volume, as picked for an import.
class MokuroPick {
  /// Describe a picked volume.
  const MokuroPick({required this.archivePath, this.ocrPath});

  /// The `.cbz` or `.zip` holding the volume's images.
  final String archivePath;

  /// The volume's `.mokuro` file, or null when it is inside the archive.
  final String? ocrPath;
}

/// [files] (each file's original name and its local copy's path) as one
/// volume: one archive (`.cbz`, `.zip`) alone, or with one `.mokuro`, in
/// any order and whatever their names. Null for anything else, or when a
/// file has no local path.
MokuroPick? mokuroPickOf(List<({String name, String? path})> files) {
  List<String> archives = [];
  List<String> ocrs = [];
  for (({String name, String? path}) file in files) {
    String? path = file.path;
    if (path == null) {
      return null;
    }

    switch (p.extension(file.name).toLowerCase()) {
      case '.cbz':
      case '.zip':
        archives.add(path);
      case '.mokuro':
        ocrs.add(path);
      default:
        return null;
    }
  }

  if (archives.length != 1 || ocrs.length > 1) {
    return null;
  }
  return MokuroPick(archivePath: archives.single, ocrPath: ocrs.firstOrNull);
}
