import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';

/// Home tab for prose read through the embedded ッツ ebook reader.
class NovelTab extends ReaderTab {
  /// Initialise this home tab.
  NovelTab._privateConstructor()
      : super(
          uniqueKey: 'novel_media_type',
          icon: Icons.library_books,
          outlinedIcon: Icons.library_books_outlined,
        );

  /// Get the singleton instance of this home tab.
  static NovelTab get instance => _instance;

  static final NovelTab _instance = NovelTab._privateConstructor();

  @override
  Widget get home => const HomeNovelPage();

  @override
  ReaderMediaSource get source => ReaderTtuSource.instance;
}
