import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';

/// Media type for prose read through the embedded ッツ ebook reader.
class NovelMediaType extends ReaderMediaType {
  /// Initialise this media type.
  NovelMediaType._privateConstructor()
      : super(
          uniqueKey: 'novel_media_type',
          icon: Icons.library_books,
          outlinedIcon: Icons.library_books_outlined,
        );

  /// Get the singleton instance of this media type.
  static NovelMediaType get instance => _instance;

  static final NovelMediaType _instance = NovelMediaType._privateConstructor();

  @override
  Widget get home => const HomeNovelPage();

  @override
  ReaderMediaSource get source => ReaderTtuSource.instance;
}
