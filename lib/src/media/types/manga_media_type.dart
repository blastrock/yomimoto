import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';

/// Media type for manga volumes read through the mokuro reader.
class MangaMediaType extends ReaderMediaType {
  /// Initialise this media type.
  MangaMediaType._privateConstructor()
      : super(
          uniqueKey: 'manga_media_type',
          icon: Icons.photo_album,
          outlinedIcon: Icons.photo_album_outlined,
        );

  /// Get the singleton instance of this media type.
  static MangaMediaType get instance => _instance;

  static final MangaMediaType _instance = MangaMediaType._privateConstructor();

  @override
  Widget get home => const HomeMangaPage();

  @override
  ReaderMediaSource get source => ReaderMokuroSource.instance;
}
