import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:cancelable_compute/cancelable_compute.dart' as cancelable;
import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_exit_app/flutter_exit_app.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart' as intl;
import 'package:path/path.dart' as path;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:remove_emoji/remove_emoji.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:yuuna/creator.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/language.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/preferences.dart';
import 'package:yuuna/utils.dart';

/// A list of fields that the app will support at runtime.
final List<Field> globalFields = List<Field>.unmodifiable(
  [
    SentenceField.instance,
    TermField.instance,
    ReadingField.instance,
    MeaningField.instance,
    NotesField.instance,
    ImageField.instance,
    AudioField.instance,
    AudioSentenceField.instance,
    PitchAccentField.instance,
    FuriganaField.instance,
    FrequencyField.instance,
    ContextField.instance,
    ClozeBeforeField.instance,
    ClozeInsideField.instance,
    ClozeAfterField.instance,
    ExpandedMeaningField.instance,
    CollapsedMeaningField.instance,
    HiddenMeaningField.instance,
    TagsField.instance,
  ],
);

/// A list of home tabs that the app will support at runtime.
final Map<String, Field> fieldsByKey = Map.unmodifiable(
  Map<String, Field>.fromEntries(
    globalFields.map(
      (field) => MapEntry(field.uniqueKey, field),
    ),
  ),
);

/// A global [Provider] for app-wide configuration and state management.
final appProvider = ChangeNotifierProvider<AppModel>((ref) {
  return AppModel();
});

/// Provides color for all quick actions.
final quickActionColorProvider =
    FutureProvider.family<Map<String, Color?>, DictionaryHeading>(
        (ref, heading) async {
  AppModel appModel = ref.watch(appProvider);
  List<Future<Color?>> futures = appModel.quickActions.values.map((e) {
    return e.getIconColor(
      appModel: appModel,
      heading: heading,
    );
  }).toList();

  List<Color?> colors = await Future.wait(futures);
  return Map<String, Color?>.fromEntries(
      appModel.quickActions.values.mapIndexed((i, action) {
    return MapEntry(action.uniqueKey, colors[i]);
  }));
});

/// A global [Provider] for maintaining visible once state.
final visibleOnceProvider =
    StateProvider.family<bool, DictionaryHeading>((ref, heading) => false);

/// A global [Provider] for listening to search term changes in PIP mode.
final pipSearchTermProvider = StateProvider<String>((ref) => '');

/// A global [Provider] for listening to search term position changes in PIP mode.
final pipSearchPositionProvider = StateProvider<int>((ref) => 0);

/// A scoped model for parameters that affect the entire application.
/// RiverPod is used for global state management across multiple layers,
/// especially for preferences that persist across application restarts.
class AppModel with ChangeNotifier {
  /// Used for showing dialogs without needing to pass around a [BuildContext].
  GlobalKey<NavigatorState> get navigatorKey => _navigatorKey;
  late final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();

  /// The SQLite database. See [initialise].
  late final AppDatabase _db;

  /// Synchronous reads and Drift writes over [_db]. See [initialise].
  late final AppStore _store;

  /// The app's settings, stored in [_db]. See [initialise].
  PreferenceStore get preferences => _preferences;
  late final PreferenceStore _preferences;

  /// Used to get the versioning metadata of the app. See [initialise].
  PackageInfo get packageInfo => _packageInfo;
  late final PackageInfo _packageInfo;

  /// Used to get information on the Android version of the device.
  AndroidDeviceInfo get androidDeviceInfo => _androidDeviceInfo;
  late final AndroidDeviceInfo _androidDeviceInfo;

  /// Used to notify dictionary widgets to dictionary history additions.
  final ChangeNotifier dictionaryEntriesNotifier = ChangeNotifier();

  /// Used to notify dictionary widgets to dictionary import additions.
  final ChangeNotifier dictionarySearchAgainNotifier = ChangeNotifier();

  /// Used to notify dictionary widgets to dictionary menu changes.
  final ChangeNotifier dictionaryMenuNotifier = ChangeNotifier();

  /// For refreshing on dictionary result additions.
  void refreshDictionaryHistory() {
    dictionaryMenuNotifier.notifyListeners();
  }

  /// Used to strip emoji from search terms.
  final _removeEmoji = RemoveEmoji();

  /// Used to notify toggling incognito. Updates the app logo to and from
  /// grayscale.
  final ChangeNotifier incognitoNotifier = ChangeNotifier();

  /// Notifies app to stop showing any screens.
  final ChangeNotifier databaseCloseNotifier = ChangeNotifier();

  /// These directories are prepared at startup in order to reduce redundancy
  /// in actual runtime.
  /// Directory where data that may be dumped is stored.
  Directory get temporaryDirectory => _temporaryDirectory;
  late final Directory _temporaryDirectory;

  /// Directory where data may be persisted.
  Directory get appDirectory => _appDirectory;
  late final Directory _appDirectory;

  /// Directory where database data is persisted.
  Directory get databaseDirectory => _databaseDirectory;
  late final Directory _databaseDirectory;

  /// Path of the SQLite database file.
  String get databasePath =>
      path.join(_databaseDirectory.path, databaseFileName);

  /// Directory where database data is persisted.
  Directory get dictionaryResourceDirectory => _dictionaryResourceDirectory;
  late final Directory _dictionaryResourceDirectory;

  /// Directory where media source thumbnails may be persisted.
  Directory get thumbnailsDirectory => _thumbnailsDirectory;
  late final Directory _thumbnailsDirectory;


  /// Directory where media for export is stored for communication with
  /// third-party APIs.
  Directory get exportDirectory => _exportDirectory;
  late final Directory _exportDirectory;

  /// Directory where media for export is stored for communication with
  /// third-party APIs. Fallback for failure.
  Directory get alternateExportDirectory => _alternateExportDirectory;
  late final Directory _alternateExportDirectory;

  /// Directory used as a working directory for dictionary imports.
  Directory get dictionaryImportWorkingDirectory =>
      _dictionaryImportWorkingDirectory;
  late final Directory _dictionaryImportWorkingDirectory;

  /// Used to fetch a dictionary format by its unique key with constant time
  /// performance. Initialised with [populateDictionaryFormats] at startup.
  late final Map<String, DictionaryFormat> dictionaryFormats;

  /// Used to fetch a home tab by its unique key with constant time
  /// performance. Initialised with [populateTabs] at startup.
  late final Map<String, HomeTab> tabs;

  /// Used to fetch initialised enhancements by their unique key with constant
  /// time performance. Initialised with [populateEnhancements] at startup.
  late final Map<Field, Map<String, Enhancement>> enhancements;

  /// Used to fetch initialised actions by their unique key with constant
  /// time performance. Initialised with [populateQuickActions] at startup.
  late final Map<String, QuickAction> quickActions;

  /// The actions shown on a dictionary result's heading, left to right. They
  /// apply to the whole term. Initialised with [populateQuickActions].
  late final List<QuickAction> headingQuickActions;

  /// The actions shown on each definition of a dictionary result, left to
  /// right. They apply to that definition only. Initialised with
  /// [populateQuickActions].
  late final List<QuickAction> entryQuickActions;

  /// Maximum number of manual enhancements in a field.
  final int maximumFieldEnhancements = 5;

  /// Maximum number of search history items.
  final int maximumSearchHistoryItems = 60;

  /// Maximum number of media history items.
  final int maximumMediaHistoryItems = 100;

  /// Maximum number of dictionary history items.
  final int maximumDictionaryHistoryItems = 10;

  /// Maximum number of dictionary search results stored in the database.
  final int maximumDictionarySearchResults = 200;

  /// Used to check if the dictionary tab should be refreshed on switching tabs.
  bool shouldRefreshTabs = false;

  /// Returns all dictionaries imported into the database. Sorted by the
  /// user-defined order in the dictionary menu.
  List<Dictionary> get dictionaries => _store.dictionaries();

  /// Returns all export profiles.
  List<AnkiMapping> get mappings => _store.mappings();

  /// The searches whose results the Dictionary tab shows. Oldest is first.
  List<DictionaryHistoryItem> get dictionaryHistory =>
      _store.dictionaryHistory();

  /// For listening to searches made inside the Card Creator.
  Stream<void> get cardCreatorRecursiveSearchStream =>
      _cardCreatorRecursiveSearchStreamController.stream;
  final StreamController<void> _cardCreatorRecursiveSearchStreamController =
      StreamController.broadcast();

  /// Broadcast that a search was made in the Card Creator
  void notifyRecursiveSearch() {
    _cardCreatorRecursiveSearchStreamController.add(null);
  }

  /// For listening to changes for whether or not the Card Creator is open.
  Stream<bool> get creatorActiveStream => _creatorActiveController.stream;
  final StreamController<bool> _creatorActiveController =
      StreamController.broadcast();

  /// Used to check whether or not the creator is currently in the navigation
  /// stack.
  bool get isCreatorOpen => _isCreatorOpen;
  bool _isCreatorOpen = false;

  /// Used to check whether or not the app is currently using a media source.
  bool get isMediaOpen => _currentMediaSource != null;

  /// Current active media source.
  MediaSource? get currentMediaSource => _currentMediaSource;
  MediaSource? _currentMediaSource;

  /// Current active media item.
  MediaItem? get currentMediaItem => _currentMediaItem;
  MediaItem? _currentMediaItem;

  /// Blocks creator from processing initial media while the source is not
  /// ready.
  bool blockCreatorInitialMedia = false;

  /// Get the app-wide text style.
  TextStyle get textStyle => TextStyle(
        fontFamily: JapaneseLanguage.fontFamily,
        fontFeatures: const [FontFeature('liga', 0)],
        locale: JapaneseLanguage.locale,
        textBaseline: JapaneseLanguage.textBaseline,
      );

  /// This override is a workaround required to theme the app-wide [TextTheme]
  /// based on the [Locale] and [TextBaseline] of the active target language.
  TextTheme get textTheme => TextTheme(
        displayLarge: textStyle,
        displayMedium: textStyle,
        displaySmall: textStyle,
        headlineLarge: textStyle,
        headlineMedium: textStyle,
        headlineSmall: textStyle,
        titleLarge: textStyle,
        titleMedium: textStyle,
        titleSmall: textStyle,
        bodyLarge: textStyle,
        bodyMedium: textStyle,
        bodySmall: textStyle,
        labelLarge: textStyle,
        labelMedium: textStyle,
        labelSmall: textStyle,
      );

  /// Shows when the current mode is a light theme.
  ThemeData get theme => ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.white,
        unselectedWidgetColor: Colors.black54,
        textTheme: textTheme,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
        ),
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateColor.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.red
                : Colors.white;
          }),
          trackColor: WidgetStateColor.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.grey;
          }),
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: textTheme.labelSmall,
          unselectedLabelStyle: textTheme.labelSmall,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          backgroundColor: Colors.white,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Colors.white,
          shape: RoundedRectangleBorder(),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(),
        ),
        cardColor: Colors.white,
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.black,
          ),
        ),
        listTileTheme: ListTileThemeData(
          dense: true,
          selectedTileColor: Colors.grey.shade300,
          selectedColor: Colors.black,
          horizontalTitleGap: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.black54,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thickness: WidgetStateProperty.all(3),
          thumbVisibility: WidgetStateProperty.all(true),
        ),
        sliderTheme: const SliderThemeData(
          thumbColor: Colors.red,
          activeTrackColor: Colors.red,
          inactiveTrackColor: Colors.grey,
          trackShape: RectangularSliderTrackShape(),
          trackHeight: 2,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        ),
        colorScheme: ColorScheme.fromSwatch()
            .copyWith(
              primary: Colors.red,
              secondary: Colors.red,
              brightness: Brightness.light,
            )
            .copyWith(surface: Colors.white),
        extensions: const [AppColors.light],
      );

  /// Shows when the current mode is a dark theme.
  ThemeData get darkTheme => ThemeData(
        useMaterial3: false,
        scaffoldBackgroundColor: Colors.black,
        textTheme: textTheme,
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateColor.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.red
                : Colors.grey;
          }),
          trackColor: WidgetStateColor.resolveWith((states) {
            return states.contains(WidgetState.selected)
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.grey;
          }),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: textTheme.labelSmall,
          unselectedLabelStyle: textTheme.labelSmall,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          backgroundColor: Colors.black,
        ),
        popupMenuTheme: const PopupMenuThemeData(
          color: Color.fromARGB(255, 30, 30, 30),
          shape: RoundedRectangleBorder(),
        ),
        dialogTheme: const DialogThemeData(
          backgroundColor: Color.fromARGB(255, 30, 30, 30),
          shape: RoundedRectangleBorder(),
        ),
        cardColor: const Color.fromARGB(255, 30, 30, 30),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
          ),
        ),
        listTileTheme: ListTileThemeData(
          dense: true,
          selectedTileColor: Colors.grey.shade600,
          selectedColor: Colors.white,
          horizontalTitleGap: 0,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: Colors.white70,
            ),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.red),
          ),
        ),
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(true),
        ),
        sliderTheme: const SliderThemeData(
          thumbColor: Colors.red,
          activeTrackColor: Colors.red,
          inactiveTrackColor: Colors.grey,
          trackShape: RectangularSliderTrackShape(),
          trackHeight: 2,
          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
        ),
        colorScheme: ColorScheme.fromSwatch(brightness: Brightness.dark)
            .copyWith(
              primary: Colors.red,
              secondary: Colors.red,
              onSecondary: Colors.white,
              onError: Colors.white,
            )
            .copyWith(surface: Colors.black),
        extensions: const [AppColors.dark],
      );

  /// Get the sentence to be used by the [SentenceField] upon card creation.
  JidoujishoTextSelection getCurrentSentence() {
    if (isMediaOpen) {
      return _currentMediaSource!.currentSentence;
    } else {
      HomeTab homeTab = tabs.values
          .toList()[_preferences.get(Preferences.currentHomeTabIndex)];
      MediaSource? mediaSource = _currentMediaSource ??
          (homeTab is MediaSource ? homeTab : null);

      return mediaSource?.currentSentence ?? JidoujishoTextSelection(text: '');
    }
  }

  /// This should all be refactored as part of [MediaItem] if possible. No
  /// reason to expose it here if not for card export functions. This is super
  /// cursed. Need to extract this to its own Provider at some point.

  /// Get the current media item for use in tracking history and generating
  /// media for card creation based on media progress.
  MediaItem? getCurrentMediaItem() {
    if (_currentMediaSource == null) {
      return null;
    } else {
      return _currentMediaItem;
    }
  }

  /// Manually flag that the app is now using a media item. Prefer [openMedia]
  /// instead of this.
  void setCurrentMediaItem(MediaItem mediaItem) {
    _currentMediaItem = mediaItem;
    _currentMediaSource = mediaItem.getMediaSource(appModel: this);
  }

  /// Get a mapping with a given mapping name.
  AnkiMapping? getMappingFromLabel(String label) =>
      _store.mappingByLabel(label);

  /// Change this once a field hide/show system is in place.
  List<Field> get activeFields => [
        ...lastSelectedMapping.getCreatorFields(),
        ...lastSelectedMapping.getCreatorCollapsedFields()
      ];

  /// Update the user-defined order of a given dictionary in the database.
  /// See the dictionary dialog's [ReorderableListView] for usage.
  Future<void> updateDictionaryOrder(List<Dictionary> newDictionaries) =>
      _store.reorderDictionaries(newDictionaries);

  /// Update the user-defined order of a given dictionary in the database.
  /// See the dictionary dialog's [ReorderableListView] for usage.
  Future<void> updateMappingsOrder(List<AnkiMapping> newMappings) =>
      _store.replaceMappings(newMappings);

  /// Populate maps for home tabs at startup to optimise performance.
  void populateTabs() {
    /// A list of home tabs that the app will support at runtime.
    final List<HomeTab> availableTabs = List<HomeTab>.unmodifiable(
      [
        ReaderTtuSource.instance,
        ReaderMokuroSource.instance,
        DictionaryTab.instance,
      ],
    );

    tabs = Map<String, HomeTab>.unmodifiable(
      Map<String, HomeTab>.fromEntries(
        availableTabs.map(
          (homeTab) => MapEntry(homeTab.uniqueKey, homeTab),
        ),
      ),
    );
  }

  /// Populate maps for dictionary formats at startup to optimise performance.
  void populateDictionaryFormats() {
    /// A list of dictionary formats that the app will support at runtime.
    final List<DictionaryFormat> availableDictionaryFormats =
        List<DictionaryFormat>.unmodifiable(
      [
        YomichanFormat.instance,
        MigakuFormat.instance,
      ],
    );

    dictionaryFormats = Map<String, DictionaryFormat>.unmodifiable(
      Map<String, DictionaryFormat>.fromEntries(
        availableDictionaryFormats.map(
          (dictionaryFormat) => MapEntry(
            dictionaryFormat.uniqueKey,
            dictionaryFormat,
          ),
        ),
      ),
    );
  }

  /// Populate maps for enhancements at startup to optimise performance.
  void populateEnhancements() {
    /// A list of enhancements that the app will support at runtime.
    final Map<Field, List<Enhancement>> availableEnhancements = {
      AudioField.instance: [
        ClearFieldEnhancement(field: AudioField.instance),
        JapanesePod101AudioEnhancement(),
        ForvoAudioEnhancement(),
        PickAudioEnhancement(field: AudioField.instance),
        AudioRecorderEnhancement(field: AudioField.instance),
      ],
      AudioSentenceField.instance: [
        ClearFieldEnhancement(field: AudioSentenceField.instance),
        PickAudioEnhancement(field: AudioSentenceField.instance),
        AudioRecorderEnhancement(field: AudioSentenceField.instance),
      ],
      NotesField.instance: [
        ClearFieldEnhancement(field: NotesField.instance),
        TextSegmentationEnhancement(field: NotesField.instance),
      ],
      ImageField.instance: [
        ClearFieldEnhancement(field: ImageField.instance),
        BingImagesSearchEnhancement(),
        CropImageEnhancement(),
        PickImageEnhancement(),
        CameraEnhancement(),
      ],
      MeaningField.instance: [
        ClearFieldEnhancement(field: MeaningField.instance),
        SentencePickerEnhancement(field: MeaningField.instance),
        TextSegmentationEnhancement(field: MeaningField.instance),
      ],
      ReadingField.instance: [
        ClearFieldEnhancement(field: ReadingField.instance),
      ],
      SentenceField.instance: [
        ClearFieldEnhancement(field: SentenceField.instance),
        TextSegmentationEnhancement(field: SentenceField.instance),
        SentencePickerEnhancement(field: SentenceField.instance),
      ],
      TermField.instance: [
        ClearFieldEnhancement(field: TermField.instance),
        SearchDictionaryEnhancement(),
        MassifExampleSentencesEnhancement(),
        TatoebaExampleSentencesEnhancement(),
        ImmersionKitEnhancement(),
      ],
      ContextField.instance: [
        ClearFieldEnhancement(field: ContextField.instance),
      ],
      PitchAccentField.instance: [
        ClearFieldEnhancement(field: PitchAccentField.instance),
      ],
      FuriganaField.instance: [
        ClearFieldEnhancement(field: FuriganaField.instance),
      ],
      FrequencyField.instance: [
        ClearFieldEnhancement(field: FrequencyField.instance),
      ],
      CollapsedMeaningField.instance: [
        ClearFieldEnhancement(field: CollapsedMeaningField.instance),
        SentencePickerEnhancement(field: CollapsedMeaningField.instance),
        TextSegmentationEnhancement(field: CollapsedMeaningField.instance),
      ],
      ExpandedMeaningField.instance: [
        ClearFieldEnhancement(field: ExpandedMeaningField.instance),
        SentencePickerEnhancement(field: ExpandedMeaningField.instance),
        TextSegmentationEnhancement(field: ExpandedMeaningField.instance),
      ],
      HiddenMeaningField.instance: [
        ClearFieldEnhancement(field: HiddenMeaningField.instance),
        SentencePickerEnhancement(field: HiddenMeaningField.instance),
        TextSegmentationEnhancement(field: HiddenMeaningField.instance),
      ],
      TagsField.instance: [
        ClearFieldEnhancement(field: TagsField.instance),
        SaveTagsEnhancement(),
      ],
      ClozeBeforeField.instance: [
        ClearFieldEnhancement(field: ClozeBeforeField.instance),
      ],
      ClozeAfterField.instance: [
        ClearFieldEnhancement(field: ClozeAfterField.instance),
      ],
      ClozeInsideField.instance: [
        ClearFieldEnhancement(field: ClozeInsideField.instance),
      ],
    };

    enhancements = Map<Field, Map<String, Enhancement>>.unmodifiable(
      availableEnhancements.map(
        (field, enhancements) => MapEntry(
          field,
          Map<String, Enhancement>.unmodifiable(
            Map<String, Enhancement>.fromEntries(
              enhancements.map(
                (enhancement) => MapEntry(enhancement.uniqueKey, enhancement),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Populate maps for actions at startup to optimise performance.
  void populateQuickActions() {
    headingQuickActions = List<QuickAction>.unmodifiable([
      CopyToClipboardAction(),
      PlayAudioAction(),
      ExplainSentenceAction(),
    ]);
    entryQuickActions = List<QuickAction>.unmodifiable([
      ShareAction(),
      CardCreatorAction(),
      InstantExportAction(),
      AddToStashAction(),
    ]);

    quickActions = Map<String, QuickAction>.unmodifiable(
      Map<String, QuickAction>.fromEntries(
        [...headingQuickActions, ...entryQuickActions].map(
          (quickAction) => MapEntry(quickAction.uniqueKey, quickAction),
        ),
      ),
    );
  }

  /// Return the app external directory found in the public DCIM directory.
  /// This path also initialises the folder if it does not exist, and includes
  /// a .nomedia file within the folder.
  Future<Directory> prepareJidoujishoDirectory() async {
    String publicDirectory =
        await ExternalPath.getExternalStoragePublicDirectory(
            ExternalPath.DIRECTORY_DCIM);
    try {
      String directoryPath = path.join(publicDirectory, 'yomimoto');
      String noMediaFilePath =
          path.join(publicDirectory, 'yomimoto', '.nomedia');

      Directory jidoujishoDirectory = Directory(directoryPath);
      File noMediaFile = File(noMediaFilePath);

      if (!jidoujishoDirectory.existsSync()) {
        jidoujishoDirectory.createSync(recursive: true);
      }
      if (!noMediaFile.existsSync()) {
        noMediaFile.createSync();
      }

      return jidoujishoDirectory;
    } catch (e) {
      debugPrint('Failed to create directory in DCIM.');
      return prepareFallbackJidoujishoDirectory();
    }
  }

  /// Return the app external directory found in the internal app directory.
  /// This path also initialises the folder if it does not exist, and includes
  /// a .nomedia file within the folder.
  Future<Directory> prepareFallbackJidoujishoDirectory() async {
    String directoryPath = path.join(appDirectory.path, 'yomimotoExport');
    String noMediaFilePath =
        path.join(appDirectory.path, 'yomimotoExport', '.nomedia');

    Directory jidoujishoDirectory = Directory(directoryPath);
    File noMediaFile = File(noMediaFilePath);

    if (!jidoujishoDirectory.existsSync()) {
      jidoujishoDirectory.createSync(recursive: true);
    }
    if (!noMediaFile.existsSync()) {
      noMediaFile.createSync();
    }

    return jidoujishoDirectory;
  }

  /// Injects licenses to be displayed in the licenses page that aren't
  /// pre-included by Flutter upon compilation but are included as assets.
  Future<void> injectAssetLicenses() async {
    final packageNames = [
      'ebook-reader',
      'ipadic',
      've',
    ];

    for (String packageName in packageNames) {
      String licenseText =
          await rootBundle.loadString('assets/licenses/$packageName.txt');
      LicenseRegistry.addLicense(
        () => Stream<LicenseEntry>.value(
          LicenseEntryWithLineBreaks(<String>[packageName], licenseText),
        ),
      );
    }
  }

  /// Prepare application data and state to be ready of use upon starting up
  /// the application. [AppModel] is initialised in the main function before
  /// [runApp] is executed.
  Future<void> initialise() async {
    /// Prepare entities that may be repeatedly used at runtime.
    _packageInfo = await PackageInfo.fromPlatform();
    _androidDeviceInfo = await DeviceInfoPlugin().androidInfo;

    /// Open the SQLite database before anything reads a preference. The
    /// first query creates the schema on a fresh install.
    _databaseDirectory = await getApplicationSupportDirectory();
    Database raw = openRawDatabase(databasePath);
    _db = AppDatabase.fromRaw(raw);
    await _db.customSelect('SELECT 1').get();
    _store = AppStore(db: _db, raw: raw);
    _preferences = PreferenceStore(db: _db, raw: raw);

    /// Perform startup activities unnecessary to further initialisation here.
    await requestExternalStoragePermissions();
    await requestAnkidroidPermissions();

    /// These directories will commonly be accessed.
    _temporaryDirectory = await getTemporaryDirectory();
    _appDirectory = await getApplicationDocumentsDirectory();
    _thumbnailsDirectory =
        Directory(path.join(appDirectory.path, 'thumbnails'));

    _dictionaryResourceDirectory =
        Directory(path.join(appDirectory.path, 'dictionaryResources'));

    _dictionaryImportWorkingDirectory = Directory(
        path.join(appDirectory.path, 'dictionaryImportWorkingDirectory'));
    _exportDirectory = await prepareJidoujishoDirectory();
    _alternateExportDirectory = await prepareFallbackJidoujishoDirectory();

    thumbnailsDirectory.createSync();
    dictionaryImportWorkingDirectory.createSync();
    dictionaryResourceDirectory.createSync();

    /// Inject open source licenses for non-Flutter dependencies that are
    /// included as assets.
    await injectAssetLicenses();

    /// Populate entities with key-value maps for constant time performance.
    /// This is not the initialisation step, which occurs below.
    populateTabs();
    populateDictionaryFormats();
    populateEnhancements();
    populateQuickActions();

    /// Prepare the Japanese text segmentation resources for use.
    await JapaneseLanguage.instance.initialise();

    /// Ready all enhancements sources for use.
    for (Field field in globalFields) {
      for (Enhancement enhancement in enhancements[field]!.values) {
        await enhancement.initialise();
      }
    }

    /// Ready all quick actions for use.
    for (QuickAction action in quickActions.values) {
      await action.initialise();
    }

    /// Ready all media sources for use.
    for (MediaSource source in tabs.values.whereType<MediaSource>()) {
      await source.initialise(_preferences);
    }

    /// Preloads the search database in memory.
    unawaited(searchDictionary(
      searchTerm: JapaneseLanguage.helloWorld,
      searchWithWildcards: false,
      useCache: false,
    ).then((_) {
      /// Preloads for wildcard searches.
      searchDictionary(
        searchTerm: '${JapaneseLanguage.helloWorld.substring(0, 1)}?',
        searchWithWildcards: true,
        useCache: false,
      ).then((_) {
        searchDictionary(
          searchTerm: '${JapaneseLanguage.helloWorld.substring(0, 1)}*',
          searchWithWildcards: true,
          useCache: false,
        );
      });
    }));
  }

  /// Whether the app is light, dark or follows the system.
  ThemeMode get themeMode => _preferences.get(Preferences.themeMode);

  /// Switch the app to [mode]; the app recolours without a restart.
  Future<void> setThemeMode(ThemeMode mode) async {
    await _preferences.set(Preferences.themeMode, mode);
    notifyListeners();
  }

  /// The format dictionaries are imported as, last picked in the dictionary
  /// menu.
  DictionaryFormat get lastSelectedDictionaryFormat => dictionaryFormats[
      _preferences.get(Preferences.lastSelectedDictionaryFormat)]!;

  /// The AnkiDroid note type last picked for a new profile, if any.
  String? get lastSelectedModel =>
      _preferences.get(Preferences.lastSelectedModel);

  /// The card creation profile in use. Deleting it selects the standard
  /// profile, which cannot be deleted, so it always exists.
  AnkiMapping get lastSelectedMapping => _store
      .mappingById(_preferences.get(Preferences.selectedMappingId))!;

  /// Persist a new last selected dictionary format. This is called when the
  /// user changes the import format in the dictionary menu.
  Future<void> setLastSelectedDictionaryFormat(
      DictionaryFormat dictionaryFormat) async {
    await _preferences.set(
        Preferences.lastSelectedDictionaryFormat, dictionaryFormat.uniqueKey);
  }

  /// Persist a new last selected model name. This is called when the user
  /// changes the selected model to map in the profiles menu.
  Future<void> setLastSelectedModelName(String modelName) async {
    await _preferences.set(Preferences.lastSelectedModel, modelName);
    notifyListeners();
  }

  /// Persist a new last selected model name. This is called when the user
  /// changes the selected model to map in the profiles menu.
  Future<void> setLastSelectedMapping(AnkiMapping mapping,
      {bool notify = true}) async {
    await _preferences.set(Preferences.selectedMappingId, mapping.id!);
    if (notify) {
      notifyListeners();
    }
  }

  /// Show the dictionary menu. This should be callable from many parts of the
  /// app, so it is appropriately handled by the model.
  Future<void> showDictionaryMenu() async {
    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => const DictionaryDialogPage(),
    );

    notifyListeners();
    dictionaryMenuNotifier.notifyListeners();
  }

  /// Show the language menu. This should be callable from many parts of the
  /// app, so it is appropriately handled by the model.
  Future<void> showProfilesMenu() async {
    List<String> models = await getModelList();
    String initialModel = lastSelectedModel ?? models.first;

    await showDialog(
      context: navigatorKey.currentContext!,
      builder: (context) => ProfilesDialogPage(
        models: models,
        initialModel: initialModel,
      ),
    );

    notifyListeners();
  }

  /// Start the process of importing a dictionary. This is called from the
  /// dictionary menu, and starts the process of importing for the
  /// [lastSelectedDictionaryFormat].
  Future<void> importDictionary({
    required File file,
    required ValueNotifier<String> progressNotifier,
    required ValueNotifier<double?> fractionNotifier,
    required Function() onImportSuccess,
  }) async {
    /// New results may be wrong after dictionary is added so this has to be
    /// done.
    clearDictionaryResultsCache();

    DictionaryFormat dictionaryFormat = lastSelectedDictionaryFormat;

    /// Each dictionary starts without a known fraction.
    fractionNotifier.value = null;

    /// Importing makes heavy use of isolates as it is very performance
    /// intensive to work with files. In order to ensure the UI isolate isn't
    /// blocked, a [ReceivePort] is necessary to receive UI updates.
    ReceivePort receivePort = ReceivePort();
    receivePort.listen((message) {
      if (message is double) {
        /// The bar is only repainted when its percentage changes, which
        /// matters on e-ink; the end is always delivered.
        double? last = fractionNotifier.value;
        if (message >= 1.0 ||
            last == null ||
            (message * 100).floor() != (last * 100).floor()) {
          fractionNotifier.value = message;
        }
      } else {
        progressNotifier.value = '$message';
      }
    });

    /// Used to show an [AlertDialog] if critical information needs to be
    /// given to a user regarding the dictionary they are importing.
    ReceivePort alertReceivePort = ReceivePort();
    alertReceivePort.listen((message) {
      showToast(
        msg: message.toString(),
        toastLength: Toast.LENGTH_LONG,
      );
    });

    /// If any [Exception] occurs, the process is aborted with a message as
    /// shown below. A dialog is shown to show the progress of the dictionary
    /// file import, with messages pertaining to the above [ValueNotifier].
    Directory stagingDirectory =
        Directory(path.join(dictionaryResourceDirectory.path, 'importing'));
    try {
      if (stagingDirectory.existsSync()) {
        stagingDirectory.deleteSync(recursive: true);
      }
      stagingDirectory.createSync(recursive: true);

      PrepareDirectoryParams prepareDirectoryParams = PrepareDirectoryParams(
        file: file,
        databasePath: databasePath,
        resourceDirectory: stagingDirectory,
        dictionaryFormat: dictionaryFormat,
        sendPort: receivePort.sendPort,
      );

      String name = await dictionaryFormat.prepareName(prepareDirectoryParams);
      progressNotifier.value = t.import_name(name: name);

      if (dictionaries.any((dictionary) => dictionary.name == name)) {
        throw Exception(t.import_duplicate(name: name));
      }

      progressNotifier.value = t.import_extract;
      await dictionaryFormat.prepareDirectory(prepareDirectoryParams);
      progressNotifier.value = t.import_name(name: name);

      PrepareDictionaryParams prepareDictionaryParams = PrepareDictionaryParams(
        dictionaryName: name,
        dictionaryFormat: dictionaryFormat,
        file: file,
        resourceDirectory: stagingDirectory,
        databasePath: databasePath,
        sendPort: receivePort.sendPort,
        alertSendPort: alertReceivePort.sendPort,
      );

      int id =
          await compute(depositDictionaryDataHelper, prepareDictionaryParams);

      Directory resourceDirectory =
          Directory(path.join(dictionaryResourceDirectory.path, '$id'));
      if (resourceDirectory.existsSync()) {
        resourceDirectory.deleteSync(recursive: true);
      }
      stagingDirectory.renameSync(resourceDirectory.path);

      progressNotifier.value = t.import_complete;
      onImportSuccess();
      await Future.delayed(const Duration(seconds: 1), () {});
    } catch (e) {
      if (stagingDirectory.existsSync()) {
        stagingDirectory.deleteSync(recursive: true);
      }
      progressNotifier.value = '$e';
      await Future.delayed(const Duration(seconds: 3), () {});
      progressNotifier.value = t.import_failed;
      await Future.delayed(const Duration(seconds: 1), () {});
    } finally {
      receivePort.close();
    }
  }

  /// Toggle a dictionary's between collapsed and expanded state. This will
  /// affect how a dictionary's search results are shown by default.
  Future<void> toggleDictionaryCollapsed(Dictionary dictionary) async {
    dictionary.isCollapsed = !dictionary.isCollapsed;
    await _store.updateDictionaryFlags(dictionary);
  }

  /// Toggle a dictionary's between hidden and shown state. This will
  /// affect how a dictionary's search results are shown by default.
  Future<void> toggleDictionaryHidden(Dictionary dictionary) async {
    dictionary.isHidden = !dictionary.isHidden;
    await _store.updateDictionaryFlags(dictionary);
  }

  /// Delete all dictionary data from the database.
  Future<void> deleteDictionaries() async {
    /// New results may be wrong after dictionary is added so this has to be
    /// done.
    clearDictionaryResultsCache();

    ReceivePort receivePort = ReceivePort();
    DeleteDictionaryParams params = DeleteDictionaryParams(
      databasePath: databasePath,
      sendPort: receivePort.sendPort,
    );

    await compute(deleteDictionariesHelper, params);
    await _store.clearDictionaryHistory();

    if (dictionaryResourceDirectory.existsSync()) {
      dictionaryResourceDirectory.deleteSync(recursive: true);
    }

    dictionarySearchAgainNotifier.notifyListeners();
  }

  /// Delete all dictionary data from the database.
  Future<void> deleteDictionary(Dictionary dictionary) async {
    /// New results may be wrong after dictionary is added so this has to be
    /// done.
    clearDictionaryResultsCache();

    ReceivePort receivePort = ReceivePort();
    DeleteDictionaryParams params = DeleteDictionaryParams(
      dictionaryId: dictionary.id,
      databasePath: databasePath,
      sendPort: receivePort.sendPort,
    );

    await compute(deleteDictionaryHelper, params);
    await _store.clearDictionaryHistory();

    final directory = Directory(
        path.join(dictionaryResourceDirectory.path, dictionary.id.toString()));

    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }

    dictionarySearchAgainNotifier.notifyListeners();
  }

  /// Delete a selected mapping from the database. The standard profile is
  /// never deleted: the selected profile falls back to it.
  Future<void> deleteMapping(AnkiMapping mapping) async {
    if (mapping.id == AnkiMapping.standardProfileId) {
      return;
    }

    await _store.deleteMapping(mapping.id!);

    if (mapping.id == _preferences.get(Preferences.selectedMappingId)) {
      await selectStandardProfile();
    }
  }

  /// Add a selected mapping to the database.
  Future<void> addMapping(AnkiMapping mapping) => _store.putMapping(mapping);

  /// Used for caching search results. Cleared when a dictionary is added or
  /// deleted.
  final Map<String, DictionarySearchResult> _dictionarySearchCache = {};

  /// Used when a dictionary is added or removed as those results may now be
  /// wrong.
  void clearDictionaryResultsCache() {
    _dictionarySearchCache.clear();
  }

  /// Whether or not the app is currently searching.
  cancelable.ComputeOperation<DictionarySearchResult?>? _searchOperation;

  /// Gets the raw unprocessed entries straight from a dictionary database
  /// given a search term. This will be processed later for user viewing.
  Future<DictionarySearchResult> searchDictionary({
    required String searchTerm,
    required bool searchWithWildcards,
    int? overrideMaximumTerms,
    bool useCache = true,
  }) async {
    String term = searchTerm.replaceAll('\n', ' ');
    term = _removeEmoji.clean(term, ' ', false);

    /// Strip lone surrogates that may crash the search.
    RegExp loneSurrogate = RegExp(
      '[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF]',
    );
    term = term.replaceAll(loneSurrogate, ' ');

    String cacheKey = '$term/$searchWithWildcards/$overrideMaximumTerms';
    DictionarySearchResult? cachedResult = _dictionarySearchCache[cacheKey];
    if (cachedResult != null && useCache) {
      return cachedResult;
    }

    ReceivePort receivePort = ReceivePort();
    receivePort.listen((message) {
      debugPrint(message.toString());
    });

    DictionarySearchParams params = DictionarySearchParams(
      searchTerm: term,
      databasePath: databasePath,
      maximumDictionarySearchResults: maximumDictionarySearchResults,
      maximumDictionaryTermsInResult: overrideMaximumTerms ??
          _preferences.get(Preferences.maximumTerms),
      searchWithWildcards: searchWithWildcards,
      enabledDictionaryIds: [],
      sendPort: receivePort.sendPort,
    );

    if (params.searchTerm.trim().isEmpty) {
      return DictionarySearchResult(searchTerm: term);
    }

    _searchOperation =
        cancelable.compute(prepareSearchResultsJapaneseLanguage, params);
    DictionarySearchResult? result = await _searchOperation?.value;

    if (result == null || result.headings.isEmpty) {
      return DictionarySearchResult(searchTerm: term);
    }

    _dictionarySearchCache[cacheKey] = result;
    return result;
  }

  /// Check if a mapping with a certain name with a different order already
  /// exists.
  bool mappingNameHasDuplicate(AnkiMapping mapping) =>
      _store.mappingLabelTaken(mapping);

  /// Get the newest available order for a new mapping.
  int get nextMappingOrder => _store.nextMappingOrder();

  /// Requests for full external storage permissions. Required to browse for
  /// media anywhere on the device.
  Future<void> requestExternalStoragePermissions() async {
    if (_preferences.get(Preferences.firstTimeSetup)) {
      showToast(
        msg: t.storage_permissions,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }

    final cameraGranted = await Permission.camera.isGranted;
    if (!cameraGranted) {
      await Permission.camera.request();
    }

    final storageGranted = await Permission.storage.isGranted;
    if (!storageGranted) {
      await Permission.storage.request();
    }

    if (_androidDeviceInfo.version.sdkInt >= 30) {
      final manageStorageGranted =
          await Permission.manageExternalStorage.isGranted;
      if (!manageStorageGranted) {
        await Permission.manageExternalStorage.request();
      }
    }
  }

  /// Used to communicate back and forth with Dart and native code.
  static const MethodChannel methodChannel =
      MethodChannel('app.arianneorpilla.yuuna/anki');

  /// Shows the AnkiDroid API message. Called when an Anki-related API get call
  /// fails.
  Future<void> showAnkidroidApiMessage() async {
    await requestAnkidroidPermissions();

    await showDialog(
      context: _navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text(t.error_ankidroid_api),
        content: Text(
          t.error_ankidroid_api_content,
        ),
        actions: [
          TextButton(
            child: Text(t.dialog_launch_ankidroid),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await LaunchApp.openApp(
                androidPackageName: 'com.ichi2.anki',
                openStore: true,
              );
              navigator.pop();
            },
          ),
          TextButton(
            child: Text(t.dialog_close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  /// Used to ask for AnkiDroid database permissions. Should be called at
  /// startup.
  Future<void> requestAnkidroidPermissions() async {
    await methodChannel.invokeMethod('requestAnkidroidPermissions');
  }

  /// Adds the default 'Yomimoto' model to the list of Anki card types.
  Future<void> addDefaultModelIfMissing() async {
    List<String> models = await getModelList();
    if (!models.contains(AnkiMapping.standardModelName)) {
      await methodChannel.invokeMethod('addDefaultModel');

      await showDialog(
        context: _navigatorKey.currentContext!,
        builder: (context) => AlertDialog(
          title: Text(t.info_standard_model),
          content: Text(
            t.info_standard_model_content,
          ),
          actions: [
            TextButton(
              child: Text(t.dialog_close),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  /// Get the file to be written to for image export.
  File getImageExportFile({bool fallback = false}) {
    String imagePath = path.join(
        (fallback ? alternateExportDirectory : exportDirectory).path,
        'exportImage.jpg');
    return File(imagePath);
  }

  /// Get the placeholder file to compress for image export.
  File getImageCompressedFile({bool fallback = false}) {
    String imagePath = path.join(
        (fallback ? alternateExportDirectory : exportDirectory).path,
        'compressedImage.jpg');
    return File(imagePath);
  }

  /// Get the file to be written to for audio export.
  File getAudioExportFile({bool fallback = false}) {
    String audioPath = path.join(
        (fallback ? alternateExportDirectory : exportDirectory).path,
        'exportAudio.mp3');
    return File(audioPath);
  }

  /// Get the file to be written to for image export.
  File getPreviewImageFile(Directory directory, int index) {
    String imagePath = path.join(directory.path, 'previewImage$index.jpg');
    return File(imagePath);
  }

  /// Get a list of decks from the Anki background service that can be used
  /// for export.
  Future<List<String>> getDecks() async {
    try {
      Map<dynamic, dynamic> result =
          await methodChannel.invokeMethod('getDecks');
      List<String> decks = result.values.toList().cast<String>();

      decks.sort((a, b) => a.compareTo(b));
      return decks;
    } catch (e) {
      await showAnkidroidApiMessage();
      rethrow;
    }
  }

  /// Get a list of models from the Anki background service that can be used
  /// for export.
  Future<List<String>> getModelList() async {
    try {
      Map<dynamic, dynamic> result =
          await methodChannel.invokeMethod('getModelList');
      List<String> models = result.values.toList().cast<String>();

      models.sort((a, b) => a.compareTo(b));
      return models;
    } catch (e) {
      await showAnkidroidApiMessage();
      rethrow;
    }
  }

  /// Get the target language from persisted preferences.
  DictionaryFormat getDictionaryFormat(Dictionary dictionary) {
    return dictionaryFormats[dictionary.formatKey]!;
  }

  /// Get a list of field names for a given [model] name in Anki. This function
  /// assumes that the model name can be found in [getDecks] and is valid.
  Future<List<String>> getFieldList(String model) async {
    try {
      List<String> fields = List<String>.from(
        await methodChannel.invokeMethod(
          'getFieldList',
          <String, dynamic>{
            'model': model,
          },
        ),
      );

      return fields;
    } catch (e) {
      unawaited(showAnkidroidApiMessage());
      rethrow;
    }
  }

  /// Given a value and a model name, checks if there are cards that have a
  /// first field with a matching value.
  Future<bool> checkForDuplicates(String key) async {
    try {
      final result = await methodChannel.invokeMethod(
        'checkForDuplicates',
        <String, dynamic>{
          'models': _preferences.get(Preferences.duplicateCheckModels),
          'key': key,
        },
      );
      return result;
    } catch (e) {
      return false;
    }
  }

  /// Add a note with certain [creatorFieldValues] and a [mapping] of fields to
  /// a model to a given [deck].
  Future<void> addNote({
    required CreatorFieldValues creatorFieldValues,
    required AnkiMapping mapping,
    required String deck,
    required Function() onSuccess,
  }) async {
    if (mapping.isExportFieldsEmpty) {
      showToast(
        msg: t.export_profile_empty,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    Map<Field, String> exportedImages = {};
    Map<Field, String> exportedAudio = {};

    for (MapEntry<Field, File> entry
        in creatorFieldValues.imagesToExport.entries) {
      Field field = entry.key;
      File exportFile = entry.value;

      String timestamp =
          intl.DateFormat('yyyyMMddTkkmmss').format(DateTime.now());
      String preferredName = 'yomimoto-$timestamp';

      String? imageFileName;
      if (exportFile.existsSync()) {
        imageFileName = await addFileToMedia(
          exportFile: exportFile,
          preferredName: preferredName,
          mimeType: 'image',
        );

        exportedImages[field] = imageFileName;
      }
    }

    for (MapEntry<Field, File> entry
        in creatorFieldValues.audioToExport.entries) {
      Field field = entry.key;
      File exportFile = entry.value;

      String timestamp =
          intl.DateFormat('yyyyMMddTkkmmss').format(DateTime.now());
      String preferredName = 'yomimoto-$timestamp';

      String? audioFileName;
      if (exportFile.existsSync()) {
        audioFileName = await addFileToMedia(
          exportFile: exportFile,
          preferredName: preferredName,
          mimeType: 'audio',
        );

        exportedAudio[field] = audioFileName;
      }
    }

    String model = mapping.model;
    List<String> fields = getCardFields(
      creatorFieldValues: creatorFieldValues,
      mapping: mapping,
      exportedImages: exportedImages,
      exportedAudio: exportedAudio,
    );

    List<String> tags =
        creatorFieldValues.textValues[TagsField.instance]?.split(' ') ?? [];

    try {
      await methodChannel.invokeMethod(
        'addNote',
        <String, dynamic>{
          'deck': deck,
          'model': model,
          'fields': fields,
          'tags': tags,
        },
      );

      showToast(
        msg: t.card_exported(deck: deck),
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      onSuccess.call();
    } on PlatformException {
      debugPrint('Failed to add note');

      showToast(
        msg: t.error_add_note,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );

      rethrow;
    } finally {
      debugPrint('Added note to Anki media');
    }
  }

  /// Add a file to Anki media. [mimeType] can be 'image' or 'audio'.
  /// [preferredName] is used as a prefix to the file when exported to the
  /// media store. Returns the name of the file once successfully added to
  /// Anki media.
  Future<String> addFileToMedia({
    required File exportFile,
    required String preferredName,
    required String mimeType,
    bool fallback = false,
  }) async {
    late File destinationFile;
    if (mimeType == 'image') {
      destinationFile = getImageExportFile(fallback: fallback);
    } else if (mimeType == 'audio') {
      destinationFile = getAudioExportFile(fallback: fallback);
    } else {
      throw Exception('Invalid mime type, must be image or audio');
    }

    if (destinationFile.existsSync()) {
      destinationFile.deleteSync();
    }

    String destinationPath = destinationFile.path;
    if (mimeType == 'image') {
      File compressedFile = getImageCompressedFile(fallback: fallback);
      if (compressedFile.existsSync()) {
        compressedFile.deleteSync();
      }
      await FlutterImageCompress.compressAndGetFile(
        exportFile.path,
        compressedFile.path,
        quality: 70,
        keepExif: true,
      );

      debugPrint('Original image size: ${exportFile.lengthSync()} bytes');
      debugPrint('Compressed image size: ${compressedFile.lengthSync()} bytes');

      compressedFile.copySync(destinationPath);
    } else {
      exportFile.copySync(destinationPath);
    }

    try {
      String response = await methodChannel.invokeMethod(
        'addFileToMedia',
        <String, String>{
          'filename': destinationPath,
          'preferredName': preferredName,
          'mimeType': mimeType,
        },
      );
      debugPrint('Added $mimeType for [$preferredName] to Anki media');
      if (destinationFile.existsSync()) {
        destinationFile.deleteSync();
      }

      return response;
    } on PlatformException {
      if (fallback) {
        showToast(
          msg: t.error_export_media_ankidroid,
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );

        rethrow;
      } else {
        return addFileToMedia(
          exportFile: exportFile,
          preferredName: preferredName,
          mimeType: mimeType,
          fallback: true,
        );
      }
    }
  }

  /// Returns the list that will be passed to the Anki card creation API to
  /// fill a card's fields. The contents of the list will correspond to the
  /// order of the [mapping] provided, with each field in the list replaced
  /// with the corresponding [creatorFieldValues] or in the case of the image
  /// and audio fields, the file names.
  static List<String> getCardFields({
    required CreatorFieldValues creatorFieldValues,
    required AnkiMapping mapping,
    required Map<Field, String> exportedImages,
    required Map<Field, String> exportedAudio,
  }) {
    List<String> fields = mapping.getExportFields().map<String>((field) {
      if (field == null) {
        return '';
      } else {
        if (field is ImageExportField) {
          if (exportedImages[field] == null) {
            return '';
          } else {
            String text = exportedImages[field]!;
            if (mapping.exportMediaTags ?? false) {
              return '<img src="$text">';
            } else {
              return text;
            }
          }
        } else if (field is AudioExportField) {
          if (exportedAudio[field] == null) {
            return '';
          } else {
            String text = exportedAudio[field]!;
            if (mapping.exportMediaTags ?? false) {
              return '[sound:$text]';
            } else {
              return text;
            }
          }
        } else {
          String text = creatorFieldValues.textValues[field] ?? '';
          if (mapping.useBrTags ?? false) {
            text = text.replaceAll('\n', '<br>');
          }

          return text;
        }
      }
    }).toList();

    return fields;
  }

  /// Returns whether or not a given [AnkiMapping] has the same amount of
  /// fields as the model it uses.
  Future<bool> profileFieldMatchesCardTypeCount(AnkiMapping mapping) async {
    List<String> fields = await getFieldList(mapping.model);
    return mapping.exportFieldKeys.length == fields.length;
  }

  /// Returns whether or not a given [AnkiMapping]'s model exists in Anki.
  Future<bool> profileModelExists(AnkiMapping mapping) async {
    List<String> models = await getModelList();
    return models.contains(mapping.model);
  }

  /// Persist the standard profile as the last selected mapping.
  Future<void> selectStandardProfile() async {
    await _preferences.set(
        Preferences.selectedMappingId, AnkiMapping.standardProfileId);
    notifyListeners();
  }

  /// Refresh all screens and have them respond to new variables.
  Future<void> refresh() async {
    notifyListeners();
  }

  /// Resets a profile's fields such that it will have the model's number of
  /// fields, all empty.
  Future<void> resetProfileFields(AnkiMapping mapping) async {
    List<String> fields = await getFieldList(mapping.model);
    List<String?> exportFieldKeys =
        List.generate(fields.length, (index) => null);

    AnkiMapping resetMapping =
        mapping.copyWith(exportFieldKeys: exportFieldKeys);
    await _store.putMapping(resetMapping);
  }

  /// Check for errors relating to the current selected export profile.
  Future<void> validateSelectedMapping({
    required BuildContext context,
    required AnkiMapping mapping,
  }) async {
    final navigator = Navigator.of(context);

    /// Ensure that the following case never happens to the default profile.
    await addDefaultModelIfMissing();

    bool newMappingModelExists = await profileModelExists(mapping);

    if (!newMappingModelExists) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(t.error_model_missing),
            content: Text(
              t.error_model_missing_content,
            ),
            actions: [
              TextButton(
                onPressed: navigator.pop,
                child: Text(t.dialog_close),
              ),
            ],
          ),
        );
      }

      await selectStandardProfile();
      await deleteMapping(mapping);
      return;
    }

    bool newMappingModelLengthMatches =
        await profileFieldMatchesCardTypeCount(mapping);

    if (!newMappingModelLengthMatches) {
      if (context.mounted) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(t.error_model_changed),
            content: Text(
              t.error_model_changed_content,
            ),
            actions: [
              TextButton(
                onPressed: navigator.pop,
                child: Text(t.dialog_close),
              ),
            ],
          ),
        );
      }

      await resetProfileFields(mapping);
    }
  }

  /// A helper function for opening the creator from any page in the
  /// application for card export purposes. Normally, the fields are provided
  /// by values in the app state. For example, the sentence field provides its
  /// value upon opening the creator from current media, which if null is
  /// empty.
  Future<void> openCreator({
    required WidgetRef ref,
    required bool killOnPop,
    CreatorFieldValues? creatorFieldValues,
    CreatorContext? creatorContext,
  }) async {

    List<String> decks = await getDecks();

    CreatorModel creatorModel = ref.watch(creatorProvider);
    creatorModel.clearAll(
      overrideLocks: true,
      savedTags: _preferences.get(Preferences.savedTags),
    );
    if (creatorFieldValues != null) {
      creatorModel.copyContext(creatorFieldValues);
    }

    _isCreatorOpen = true;
    _creatorActiveController.add(true);

    await Navigator.push(
      _navigatorKey.currentContext!,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation1, animation2) => CreatorPage(
          decks: decks,
          editEnhancements: false,
          editFields: false,
          killOnPop: killOnPop,
          creatorContext: creatorContext,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        settings: RouteSettings(name: (CreatorPage).toString()),
      ),
    );

    _isCreatorOpen = false;
    _creatorActiveController.add(false);
  }

  /// Whether or not the media item should be killed upon exit.
  bool _shouldKillMediaOnPop = false;

  /// A helper function for launching a media source.
  Future<void> openMedia({
    required WidgetRef ref,
    required MediaSource mediaSource,
    bool killOnPop = false,
    bool pushReplacement = false,
    MediaItem? item,
  }) async {
    if (killOnPop) {
      _shouldKillMediaOnPop = true;
    }

    mediaSource.clearCurrentSentence();
    mediaSource.clearExtraData();

    _currentMediaSource = mediaSource;
    if (item != null) {
      _currentMediaItem = item;
    }

    await WakelockPlus.enable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (item != null && mediaSource.implementsHistory) {
      await addMediaItem(item);
    }

    if (pushReplacement) {
      await Navigator.pushReplacement(
        _navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => mediaSource.buildLaunchPage(item: item),
        ),
      );
    } else {
      await Navigator.push(
        _navigatorKey.currentContext!,
        MaterialPageRoute(
          builder: (context) => mediaSource.buildLaunchPage(item: item),
        ),
      );
    }
  }

  /// Ends a media session and ensures that values are reset.
  Future<void> closeMedia({
    required WidgetRef ref,
    required MediaSource mediaSource,
    MediaItem? item,
  }) async {
    mediaSource.clearCurrentSentence();
    mediaSource.clearExtraData();
    _currentMediaSource = null;
    _currentMediaItem = null;
    blockCreatorInitialMedia = false;
    await WakelockPlus.disable();
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await mediaSource.onSourceExit(
      appModel: this,
      ref: ref,
    );

    mediaSource.refreshTab();
    DictionaryTab.instance.refreshTab();

    if (_shouldKillMediaOnPop) {
      await shutdown();
    }
  }

  /// A helper function for opening the creator from any page in the
  /// application for editing enhancements.
  Future<void> openCreatorEnhancementsEditor() async {
    List<String> decks = await getDecks();

    await Navigator.push(
      _navigatorKey.currentContext!,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => CreatorPage(
          decks: decks,
          editEnhancements: true,
          editFields: false,
          killOnPop: false,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  // A helper function for opening the creator from any page in the
  /// application for editing fields.
  Future<void> openCreatorFieldsEditor() async {
    List<String> decks = await getDecks();

    await Navigator.push(
      _navigatorKey.currentContext!,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) => CreatorPage(
          decks: decks,
          editEnhancements: false,
          editFields: true,
          killOnPop: false,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  /// A helper function for doing a recursive dictionary search.
  Future<void> openRecursiveDictionarySearch({
    required String searchTerm,
    required bool killOnPop,
    Function(String)? onUpdateQuery,
  }) async {

    if (searchTerm.trim().isEmpty) {
      return;
    }

    await Navigator.push(
      _navigatorKey.currentContext!,
      PageRouteBuilder(
        pageBuilder: (context, animation1, animation2) =>
            RecursiveDictionaryPage(
          searchTerm: searchTerm,
          killOnPop: killOnPop,
          onUpdateQuery: onUpdateQuery,
        ),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
    refreshDictionaryHistory();
  }

  /// A helper function for showing a result already in dictionary history.
  Future<void> openResultFromHistory({
    required DictionarySearchResult result,
  }) async {
    await Navigator.push(
      _navigatorKey.currentContext!,
      MaterialPageRoute(
        builder: (context) => RecursiveDictionaryHistoryPage(
          result: result,
        ),
      ),
    );
  }

  /// A helper function for opening a text segmentation dialog.
  Future<void> openTextSegmentationDialog({
    required String sourceText,
    List<String>? segmentedText,
    Function(JidoujishoTextSelection)? onSelect,
    Function(JidoujishoTextSelection)? onSearch,
  }) async {
    if (sourceText.trim().isEmpty) {
      return;
    }

    segmentedText ??= JapaneseLanguage.instance.textToWords(sourceText);

    await showDialog(
      context: _navigatorKey.currentContext!,
      builder: (context) => TextSegmentationDialogPage(
        sourceText: sourceText,
        segmentedText: segmentedText!,
        onSelect: onSelect,
        onSearch: onSearch,
      ),
    );
  }

  /// A helper function for opening an example sentence dialog.
  Future<void> openExampleSentenceDialog({
    required List<String> exampleSentences,
    required Function(List<String>) onSelect,
    Function(List<String>)? onAppend,
  }) async {
    await showDialog(
      context: _navigatorKey.currentContext!,
      builder: (context) => ExampleSentencesDialogPage(
        exampleSentences: exampleSentences,
        onSelect: onSelect,
        onAppend: onAppend,
      ),
    );
  }

  /// A helper function for opening an example sentence dialog for sentences
  /// returned from Massif.
  Future<void> openMassifSentenceDialog({
    required List<MassifResult> exampleSentences,
    required Function(List<MassifResult>) onSelect,
    required Function(List<MassifResult>) onAppend,
  }) async {
    await showDialog(
      context: _navigatorKey.currentContext!,
      builder: (context) => MassifSentencesDialogPage(
        exampleSentences: exampleSentences,
        onSelect: onSelect,
        onAppend: onAppend,
      ),
    );
  }

  /// A helper function for opening an example sentence dialog for sentences
  /// returned from ImmersionKitEnhancement.
  Future<void> openImmersionKitSentenceDialog({
    required List<ImmersionKitResult> exampleSentences,
    required Function(List<ImmersionKitResult>) onSelect,
    required Function(List<ImmersionKitResult>) onAppend,
  }) async {
    await showDialog(
      context: _navigatorKey.currentContext!,
      builder: (context) => ImmersionKitSentencesDialogPage(
        exampleSentences: exampleSentences,
        onSelect: onSelect,
        onAppend: onAppend,
      ),
    );
  }

  /// Updates a given [mapping]'s persisted enhancement for a given [field]
  /// and [slotNumber].
  Future<void> setFieldEnhancement({
    required AnkiMapping mapping,
    required Field field,
    required int slotNumber,
    required Enhancement enhancement,
  }) async {
    mapping.enhancements![field.uniqueKey] ??= {};
    mapping.enhancements![field.uniqueKey]![slotNumber] = enhancement.uniqueKey;

    await _store.putMapping(mapping);
  }

  /// Updates a given [mapping] to remove a [Field].
  Future<void> removeField({
    required AnkiMapping mapping,
    required Field field,
    required bool isCollapsed,
  }) async {
    if (isCollapsed) {
      mapping.creatorCollapsedFieldKeys = [
        ...mapping.creatorCollapsedFieldKeys
            .whereNot((key) => key == field.uniqueKey)
      ];
    } else {
      mapping.creatorFieldKeys = [
        ...mapping.creatorFieldKeys.whereNot((key) => key == field.uniqueKey)
      ];
    }

    await _store.putMapping(mapping);
  }

  /// Updates a given [mapping] to include a [Field].
  Future<void> setField({
    required AnkiMapping mapping,
    required Field field,
    required bool isCollapsed,
  }) async {
    if (isCollapsed) {
      mapping.creatorCollapsedFieldKeys = [
        ...mapping.creatorCollapsedFieldKeys,
        field.uniqueKey,
      ];
    } else {
      mapping.creatorFieldKeys = [
        ...mapping.creatorFieldKeys,
        field.uniqueKey,
      ];
    }

    await _store.putMapping(mapping);
  }

  /// Removes a given [mapping]'s persisted enhancement for a given [field]
  /// and [slotNumber].
  Future<void> removeFieldEnhancement({
    required AnkiMapping mapping,
    required Field field,
    required int slotNumber,
  }) async {
    mapping.enhancements![field.uniqueKey]!.remove(slotNumber);

    await _store.putMapping(mapping);
  }

  /// Removes a given [mapping]'s persisted auto enhancement for a given
  /// [field].
  Future<void> removeAutoFieldEnhancement({
    required AnkiMapping mapping,
    required Field field,
  }) async {
    /// -1 is reserved for the auto enhancement.
    mapping.enhancements![field.uniqueKey]!
        .remove(AnkiMapping.autoModeSlotNumber);

    await _store.putMapping(mapping);
  }

  /// Add [searchTerm] to the search history. If there are already a maximum
  /// number of items in history, the oldest are discarded.
  Future<void> addToSearchHistory({required String searchTerm}) async {
    if (searchTerm.trim().isEmpty) {
      return;
    }

    await _store.addToSearchHistory(searchTerm,
        maximum: maximumSearchHistoryItems);
  }

  /// Remove [searchTerm] from the search history.
  Future<void> removeFromSearchHistory({required String searchTerm}) =>
      _store.removeFromSearchHistory(searchTerm);

  /// Clear the search history.
  Future<void> clearSearchHistory() => _store.clearSearchHistory();

  /// Get the search history, oldest first.
  List<String> getSearchHistory() => _store.searchHistory();

  /// Shown when a query fails to be made to an online service. For example,
  /// when there is no internet connection.
  void showFailedToCommunicateMessage() {
    showToast(
      msg: t.failed_online_service,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  /// Clear the entire dictionary history. This must be performed when a
  /// dictionary is deleted, otherwise history data cannot be viewed without
  /// the necessary dictionary metadata.
  Future<void> clearDictionaryHistory() async {
    await _store.clearDictionaryHistory();

    dictionaryEntriesNotifier.notifyListeners();
  }

  /// Insert or replace [item] as the most recent entry of its source's
  /// history, without the history size limit of [addMediaItem]. For
  /// sources whose history is a library that must not lose entries. Sets
  /// the item's id.
  Future<void> putMediaItem(MediaItem item) => _store.putMediaItem(item);

  /// Add a [MediaItem] to history. This should be called at startup
  /// when the media item is launched.
  Future<void> addMediaItem(MediaItem item) =>
      _store.addMediaItem(item, maximum: maximumMediaHistoryItems);

  /// Update a media item, without performing any deletion or mutation
  /// operations. This is useful when updating constantly, for example,
  /// when a reading position needs to be persisted as the user reads.
  Future<void> updateMediaItem(MediaItem item) => _store.updateMediaItem(item);

  /// Set the title the user gave [item], or clear it with null.
  Future<void> setMediaItemOverrideTitle(MediaItem item, String? title) async {
    await _store.setMediaItemOverrideTitle(item.id!, title);
    item.overrideTitle = title;
  }

  /// Deletes a [MediaItem] from history, with its stash, and also rids of
  /// override values.
  Future<void> deleteMediaItem(MediaItem item) async {
    MediaSource mediaSource = item.getMediaSource(appModel: this);
    await mediaSource.clearOverrideValues(appModel: this, item: item);
    await mediaSource.onMediaItemClear(item);

    await _store.deleteMediaItem(item);
  }

  /// Save [item] to its book's stash. Returns false, saving nothing, if the
  /// book already has this word.
  Future<bool> putStashItem(StashItem item) => _store.putStashItem(item);

  /// The stash of [mediaItem], in reading order.
  List<StashItem> getStashItems(MediaItem mediaItem) =>
      _store.stashItems(mediaItem.id!);

  /// Delete the stash items with these [ids].
  Future<void> deleteStashItems(List<int> ids) => _store.deleteStashItems(ids);

  /// Find [item]'s word in the dictionaries for making a card. When the
  /// heading is gone, `heading` is a stand-in with no entries; when the
  /// stashed entry's dictionary is gone, `entry` is null (whole heading).
  /// `found` tells whether the stashed entry could be found.
  Future<ResolvedStashItem> resolveStashItem(StashItem item) async {
    HeadingRow? row = await _db
        .headingByTermAndReading(term: item.term, reading: item.reading)
        .getSingleOrNull();
    if (row == null) {
      return (
        heading: DictionaryHeading(term: item.term, reading: item.reading),
        entry: null,
        found: false,
      );
    }

    DictionaryHeading heading = (await loadHeadings(_db, [row.id])).single;
    DictionaryEntry? entry = item.dictionaryName == null
        ? null
        : heading.entries.firstWhereOrNull(
            (entry) => entry.dictionary.name == item.dictionaryName);

    return (
      heading: heading,
      entry: entry,
      found: heading.entries.isNotEmpty &&
          (item.dictionaryName == null || entry != null),
    );
  }

  /// Copies a [term] to clipboard and shows an appropriate toast.
  void copyToClipboard(String term) {
    Clipboard.setData(ClipboardData(text: term));

    /// Redundant to do this with the share notification on Android
    if (_androidDeviceInfo.version.sdkInt < 33) {
      showToast(
        msg: t.copied_to_clipboard,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  /// Get the history of [MediaItem] for a particular [MediaSource], least
  /// recently opened first.
  List<MediaItem> getMediaSourceHistory({required MediaSource mediaSource}) {
    return _store.mediaItems(mediaSource.uniqueKey);
  }

  /// Returns the last navigated directory the user used for picking a file for a
  /// certain media source.
  Directory? getLastPickedDirectory(MediaSource mediaSource) {
    String? path = _preferences
        .get(Preferences.lastPickedDirectory(mediaSource.uniqueKey));
    if (path == null) {
      return null;
    }

    Directory directory = Directory(path);
    if (!directory.existsSync()) {
      return null;
    }
    return directory;
  }

  /// Returns the last navigated directory the user used for picking a file for a
  /// certain media source.
  void setLastPickedDirectory({
    required MediaSource mediaSource,
    required Directory directory,
  }) {
    unawaited(_preferences.set(
        Preferences.lastPickedDirectory(mediaSource.uniqueKey),
        directory.path));
  }

  /// Returns valid file picker directories. If there is a last picked directory for
  /// a media source, this will be included as first on the list. Otherwise,
  /// external root directories will be included.
  Future<List<Directory>> getFilePickerDirectoriesForMediaSource(
      MediaSource mediaSource) async {
    List<Directory> directories = [];
    Directory? lastPickedDirectory = getLastPickedDirectory(mediaSource);
    if (lastPickedDirectory != null) {
      directories.add(lastPickedDirectory);
    }

    // external_path 3 made this nullable.
    List<String> paths =
        await ExternalPath.getExternalStorageDirectories() ?? <String>[];
    for (String path in paths) {
      Directory directory = Directory(path);
      if (!directories.contains(directory)) {
        directories.add(directory);
      }
    }

    return directories;
  }

  /// Adds a [DictionarySearchResult] to dictionary history.
  /// [searchWithWildcards] is how [result] was searched, so that the history
  /// searches it again the same way.
  Future<void> addToDictionaryHistory({
    required DictionarySearchResult result,
    required bool searchWithWildcards,
  }) async {
    HomeTab homeTab = tabs.values
        .toList()[_preferences.get(Preferences.currentHomeTabIndex)];
    if (homeTab != DictionaryTab.instance) {
      shouldRefreshTabs = true;
      ScrollController scrollController =
          DictionaryTab.instance.scrollController;
      if (scrollController.hasClients) {
        scrollController.jumpTo(0);
      }
    }

    if (result.headings.isEmpty || result.searchTerm.isEmpty) {
      return;
    }

    await _store.addToDictionaryHistory(
      result.searchTerm,
      searchWithWildcards: searchWithWildcards,
      maximum: maximumDictionaryHistoryItems,
    );
  }

  /// Check if the database is still open or has the app been flagged to be
  /// shutdown.
  bool get isDatabaseOpen => _isDatabaseOpen;
  bool _isDatabaseOpen = true;

  /// Safely shutdown and stop database operations.
  Future<void> shutdown() async {
    databaseCloseNotifier.notifyListeners();
    _isDatabaseOpen = false;
    await _db.close();
    await FlutterExitApp.exitApp();
  }
}
