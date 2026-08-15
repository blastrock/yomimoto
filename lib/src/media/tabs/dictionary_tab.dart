import 'package:flutter/material.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/pages.dart';

/// Home tab that encapsulates dictionary search results.
class DictionaryTab extends HomeTab {
  /// Initialise this home tab.
  DictionaryTab._privateConstructor()
      : super(
          uniqueKey: 'dictionary',
          icon: Icons.auto_stories_rounded,
          outlinedIcon: Icons.auto_stories_outlined,
        );

  /// Get the singleton instance of this home tab.
  static DictionaryTab get instance => _instance;

  static final DictionaryTab _instance =
      DictionaryTab._privateConstructor();

  @override
  Widget get home => const HomeDictionaryPage();
}
