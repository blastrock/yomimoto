import 'dart:convert';

/// A manga volume as described by its `.mokuro` file: the OCR of every page,
/// written by the mokuro tool or by mokuro-bunko. Only what the app needs is
/// read here; the reader page reads the text blocks itself.
class MokuroVolume {
  MokuroVolume._({
    required this.title,
    required this.volume,
    required this.volumeUuid,
    required this.pages,
  });

  /// Read the contents of a `.mokuro` file. Throws a [FormatException] if
  /// it is not one. Keys this class does not use are ignored.
  factory MokuroVolume.parse(String source) {
    Object? json = jsonDecode(source);
    if (json is! Map<String, dynamic>) {
      throw const FormatException('A .mokuro file is a JSON object');
    }

    String volumeUuid = _string(json, 'volume_uuid');
    if (!_uuidPattern.hasMatch(volumeUuid)) {
      throw FormatException('Unusable volume_uuid', volumeUuid);
    }

    Object? pages = json['pages'];
    if (pages is! List || pages.isEmpty) {
      throw const FormatException('A volume has at least one page');
    }

    return MokuroVolume._(
      title: _string(json, 'title'),
      volume: _string(json, 'volume'),
      volumeUuid: volumeUuid,
      pages: pages.map(MokuroPage._fromJson).toList(),
    );
  }

  /// The volume's identity, also used as a directory name: letters, digits
  /// and dashes only.
  static final RegExp _uuidPattern = RegExp(r'^[A-Za-z0-9-]+$');

  /// The series name.
  final String title;

  /// The volume name. The mokuro tool takes it from the file name, so it may
  /// be as short as `vol1`.
  final String volume;

  /// The volume's identity, stable across runs of the mokuro tool.
  final String volumeUuid;

  /// The pages, in reading order.
  final List<MokuroPage> pages;

  /// The name to show for the volume: [volume] when it already names the
  /// series, else the series name followed by [volume].
  String get displayTitle =>
      volume.contains(title) ? volume : '$title $volume';
}

/// One page of a [MokuroVolume].
class MokuroPage {
  MokuroPage._({
    required this.imgPath,
    required this.width,
    required this.height,
  });

  factory MokuroPage._fromJson(Object? json) {
    if (json is! Map<String, dynamic>) {
      throw const FormatException('A page is a JSON object');
    }

    return MokuroPage._(
      imgPath: _string(json, 'img_path'),
      width: _int(json, 'img_width'),
      height: _int(json, 'img_height'),
    );
  }

  /// The page's image, relative to the volume's images.
  final String imgPath;

  /// The image's width in pixels.
  final int width;

  /// The image's height in pixels.
  final int height;
}

String _string(Map<String, dynamic> json, String key) {
  Object? value = json[key];
  if (value is! String) {
    throw FormatException('$key is not a string', value);
  }
  return value;
}

int _int(Map<String, dynamic> json, String key) {
  Object? value = json[key];
  if (value is! int) {
    throw FormatException('$key is not an integer', value);
  }
  return value;
}
