import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/preferences.dart';
import 'package:yuuna/utils.dart';

/// A media source that allows the user to read manga processed by Mokuro.
class ReaderMokuroSource extends ReaderMediaSource {
  /// Define this media source.
  ReaderMokuroSource._privateConstructor()
      : super(
          uniqueKey: 'reader_mokuro',
          sourceName: 'Mokuro',
          description: 'Read manga volumes processed by mokuro.',
          icon: Icons.photo_album,
          outlinedIcon: Icons.photo_album_outlined,
          implementsSearch: false,
          implementsHistory: false,
          overridesAutoImage: true,
        );

  /// Get the singleton instance of this home tab.
  static ReaderMokuroSource get instance => _instance;

  static final ReaderMokuroSource _instance =
      ReaderMokuroSource._privateConstructor();

  @override
  ExplanationKind get explanationKind => ExplanationKind.manga;

  // This source's preferences, prefixed with its uniqueKey.
  static const Preference<bool> _volumePageTurningEnabled =
      Preference('reader_mokuro/volume_page_turning_enabled',
          defaultValue: true);

  static const Preference<bool> _volumePageTurningInverted =
      Preference('reader_mokuro/volume_page_turning_inverted',
          defaultValue: false);

  static const Preference<bool> _highlightOnTap =
      Preference('reader_mokuro/highlight_on_tap', defaultValue: true);

  @override
  Widget get home => const HomeMangaPage();

  @override
  double get aspectRatio => 257 / 364;

  @override
  BaseSourcePage buildLaunchPage({
    MediaItem? item,
  }) {
    throw UnimplementedError('The manga reader is not built yet');
  }

  @override
  BasePage buildHistoryPage({MediaItem? item}) {
    return const ReaderMokuroHistoryPage();
  }

  @override
  List<Widget> getActions({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
  }) {
    return [];
  }

  /// Whether or not using the volume buttons in the Reader should turn the
  /// page.
  bool get volumePageTurningEnabled =>
      preferences.get(_volumePageTurningEnabled);

  /// Toggles the volume page turning option.
  Future<void> toggleVolumePageTurningEnabled() =>
      preferences.toggle(_volumePageTurningEnabled);

  /// Controls which direction is up or down for volume button page turning.
  bool get volumePageTurningInverted =>
      preferences.get(_volumePageTurningInverted);

  /// Inverts the current volume button page turning direction preference.
  Future<void> toggleVolumePageTurningInverted() =>
      preferences.toggle(_volumePageTurningInverted);

  /// Whether the reader will highlight words on tap.
  bool get highlightOnTap => preferences.get(_highlightOnTap);

  /// Toggles whether the reader will highlight words on tap.
  Future<void> toggleHighlightOnTap() =>
      preferences.toggle(_highlightOnTap);
}
