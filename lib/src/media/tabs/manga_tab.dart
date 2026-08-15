import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';

/// Home tab for manga volumes read through the mokuro reader.
class MangaTab extends ReaderTab {
  /// Initialise this home tab.
  MangaTab._privateConstructor()
      : super(
          uniqueKey: 'manga_media_type',
          icon: Icons.photo_album,
          outlinedIcon: Icons.photo_album_outlined,
        );

  /// Get the singleton instance of this home tab.
  static MangaTab get instance => _instance;

  static final MangaTab _instance = MangaTab._privateConstructor();

  @override
  Widget get home => const HomeMangaPage();

  @override
  ReaderMediaSource get source => ReaderMokuroSource.instance;
}
