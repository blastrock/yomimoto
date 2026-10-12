import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive/hive.dart';
import 'package:network_to_file_image/network_to_file_image.dart';
import 'package:transparent_image/transparent_image.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';
import 'package:path/path.dart' as path;

/// A [HomeTab] backed by a library of media items. Handles sourcing and
/// delivery of arguments such that the media it holds is able to execute and
/// launch with the proper arguments.
abstract class MediaSource extends HomeTab {
  /// Initialise a media source.
  MediaSource({
    required super.uniqueKey,
    required this.sourceName,
    required this.description,
    required super.icon,
    required super.outlinedIcon,
    required this.implementsSearch,
    required this.implementsHistory,
    this.overridesAutoImage = false,
  });

  /// Name of the source that very shortly describes what it does.
  final String sourceName;

  /// A longer description of what the source can do, or details left by or
  /// regarding the developer.
  final String description;

  /// Whether or not this media source has a search function. If false, this
  /// media source will have an action executed by [onSearchBarTap].
  final bool implementsSearch;

  /// Whether or not this media source allows adding items to media history.
  /// Note that some media sources produce a history of media items but do
  /// not require this to be set true. For example, the reader fetches its
  /// history from a source other than the actual internal media history
  /// system provided by the media source framework. In such cases, this
  /// should be set as false. Setting this as true results to a media item
  /// being added to history when media is opened.
  final bool implementsHistory;

  /// Whether or not a media source overrides the auto image enhancement.
  /// See [generateImages].
  final bool overridesAutoImage;

  /// Used for accessing persistent key-value data specific to this source.
  /// See [initialise].
  late final Box _preferences;

  /// Whether or not [initialise] has been called for this source.
  bool _initialised = false;

  /// This function is run at startup. It is not called again if already run.
  Future<void> initialise() async {
    if (_initialised) {
      return;
    } else {
      _preferences = await Hive.openBox(uniqueKey);

      await prepareResources();
      _initialised = true;
    }
  }

  /// Get the preference value for a certain parameter [key] for this source.
  T getPreference<T>({required String key, required T defaultValue}) {
    return _preferences.get(key, defaultValue: defaultValue) as T;
  }

  /// Set the preference [value] for a certain parameter [key] for this source.
  Future<void> setPreference<T>({required String key, required T value}) async {
    await _preferences.put(key, value);
  }

  /// Set the preference for a certain parameter [key] for this source.
  Future<void> deletePreference({required String key}) async {
    await _preferences.delete(key);
  }

  /// If a media source requires resources to function, they can be prepared
  /// here and this function will be run once only at runtime during the
  /// initialisation step.
  Future<void> prepareResources() async {}

  /// Executed when this media source is closed. Perform this step to clean up
  /// resources or refresh media history.
  Future<void> onSourceExit({
    required AppModel appModel,
    required WidgetRef ref,
  }) async {}

  /// Get the floating search bar actions of this source when it is the active
  /// source being displayed on its respective home tab.
  List<Widget> getActions({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
  }) {
    return [];
  }

  /// The widget to show when this source is launched. An optional [MediaItem]
  /// can be supplied as a launch parameter.
  BaseSourcePage buildLaunchPage({MediaItem? item});

  /// If this is not null, this action is executed when the user taps on the
  /// search bar. Sources that do not have a search action should have this
  /// defined.
  Future<void> onSearchBarTap({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
  }) async {
    appModel.openMedia(
      ref: ref,
      mediaSource: this,
    );
  }

  /// This function can be used to clean up resources associated with a
  /// media item upon clearing it.
  Future<void> onMediaItemClear(MediaItem item) async {}

  /// Supplies a sentence that can be used for the sentence field when making
  /// a card while this source is active. Can be set with [setCurrentSentence]
  /// and [clearCurrentSentence] in a source page.
  JidoujishoTextSelection get currentSentence => _currentSentence;
  JidoujishoTextSelection _currentSentence = JidoujishoTextSelection(
    text: '',
  );

  /// Position of the word behind [currentSentence] in the media, in the
  /// source's own units (characters for novels), or -1 when unknown.
  int get currentPosition => _currentPosition;
  int _currentPosition = -1;

  /// Update the current sentence and the position of its word.
  void setCurrentSentence({
    required JidoujishoTextSelection selection,
    int position = -1,
  }) {
    _currentSentence = selection;
    _currentPosition = position;
  }

  /// Clear the current sentence.
  void clearCurrentSentence() {
    _currentSentence = JidoujishoTextSelection(
      text: '',
    );
    _currentPosition = -1;
  }

  /// This is used to hold data for generating images and audio.
  String? get currentExtraData => _currentExtraData;
  String? _currentExtraData;

  /// Set extra export data. This should be simplified in the future and be
  /// used as the main way of communicating parameters to the creator for
  /// creating override images/audio information. There should not be media
  /// source specific parameters for general functions like generating images
  /// or audio.
  void setExtraData(String? value) {
    _currentExtraData = value;
  }

  /// Clear extra export data.
  void clearExtraData() {
    _currentExtraData = null;
  }

  /// The body widget to show in the tab when this source's home tab and this
  /// source is selected.
  BasePage buildHistoryPage();

  /// Given a [MediaItem], return its title. Some media items may allow
  /// overriding of values for display purposes. If a source does this,
  /// override this function.
  String getDisplayTitleFromMediaItem(MediaItem item) {
    String? overrideTitle = getOverrideTitleFromMediaItem(item);
    if (overrideTitle != null) {
      return overrideTitle;
    }

    return item.title;
  }

  /// Given a [MediaItem], return its thumbnail. Some media items may allow
  /// overriding of values for display purposes.
  ImageProvider<Object> getDisplayThumbnailFromMediaItem({
    required AppModel appModel,
    required MediaItem item,
    String? fallbackUrl,
    bool noOverride = false,
  }) {
    ImageProvider<Object>? overrideThumbnail =
        getOverrideThumbnailFromMediaItem(
      appModel: appModel,
      item: item,
    );

    if (!noOverride && overrideThumbnail != null) {
      return overrideThumbnail;
    }

    if (item.imageUrl != null) {
      if (item.imageUrl!.startsWith('file://')) {
        return FileImage(File(item.imageUrl!.replaceFirst('file://', '')));
      } else {
        return CachedNetworkImageProvider(
          fallbackUrl ?? item.imageUrl!,
          cacheKey: item.uniqueKey,
        );
      }
    }

    if (item.base64Image == null) {
      return MemoryImage(kTransparentImage);
    }

    UriData? data = Uri.parse(item.base64Image!).data;
    if (data != null) {
      /// A cached version of [MemoryImage] so that the image does not reload
      /// on every revisit
      return CacheImageProvider(item.uniqueKey, data.contentAsBytes());
    } else {
      return MemoryImage(kTransparentImage);
    }
  }

  /// The map key used to store the override title of an item.
  String getOverrideTitleKey(MediaItem item) {
    return 'override_title://${item.mediaSourceIdentifier}/${item.uniqueKey}';
  }

  /// The map value used to store the override thumbnail of an item.
  String getOverrideThumbnailFilename({
    required AppModel appModel,
    required MediaItem item,
  }) {
    String key =
        '${item.mediaIdentifier}/${item.mediaSourceIdentifier}/override_thumbnail';
    String basename = key.hashCode.toString();
    String filename = path.join(appModel.thumbnailsDirectory.path, basename);

    return filename;
  }

  /// Given a [MediaItem], return its override display title.
  String? getOverrideTitleFromMediaItem(MediaItem item) {
    if (!item.canEdit) {
      return null;
    }

    String key = getOverrideTitleKey(item);
    String? overrideTitle =
        getPreference<String?>(key: key, defaultValue: null);
    return overrideTitle;
  }

  /// Given a [MediaItem], return its override display thumbnail.
  ImageProvider<Object>? getOverrideThumbnailFromMediaItem({
    required AppModel appModel,
    required MediaItem item,
  }) {
    String filename = getOverrideThumbnailFilename(
      appModel: appModel,
      item: item,
    );

    File file = File(filename);
    if (!file.existsSync()) {
      return null;
    }

    return FileImage(file);
  }

  /// Given a [MediaItem], set its override display title. If the title is
  /// blank, the override title is cleared.
  Future<void> setOverrideTitleFromMediaItem({
    required MediaItem item,
    required String? title,
  }) async {
    String key = getOverrideTitleKey(item);
    String? value;
    if (title != null) {
      String trimmedTitle = title.trim();
      if (trimmedTitle.isNotEmpty) {
        value = trimmedTitle;
      }
    }

    await setPreference<String?>(key: key, value: value);
  }

  /// Given a [MediaItem], set its override display thumbnail. If null, this
  /// deletes the override thumbnail.
  Future<void> setOverrideThumbnailFromMediaItem({
    required AppModel appModel,
    required MediaItem item,
    required File? file,
    required bool clearOverrideImage,
  }) async {
    String filename = getOverrideThumbnailFilename(
      appModel: appModel,
      item: item,
    );

    File thumbnailFile = File(filename);
    thumbnailFile.createSync(recursive: true);
    if (clearOverrideImage) {
      thumbnailFile.deleteSync();
    } else if (file != null) {
      file.copySync(filename);
    }
  }

  /// Used to clear override values of a [MediaItem] upon deletion.
  Future<void> clearOverrideValues({
    required AppModel appModel,
    required MediaItem item,
  }) async {
    await deletePreference(key: getOverrideTitleKey(item));
    await setOverrideThumbnailFromMediaItem(
      appModel: appModel,
      item: item,
      file: null,
      clearOverrideImage: true,
    );
  }

  /// If this source is non-null, this will be used as the initial function
  /// for the image field over the auto enhancement. Extra durations can be
  /// invoked and defined when initially opening the creator, to call attention
  /// to multiple durations to be used for image generation.
  Future<List<NetworkToFileImage>> generateImages({
    required AppModel appModel,
    required MediaItem item,
    String? data,
  }) {
    throw UnimplementedError();
  }

  /// Aspect ratio of media items.
  double get aspectRatio;
}
