import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_floating_search_bar_2/material_floating_search_bar_2.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';
import 'package:yuuna/pages.dart';
import 'package:yuuna/utils.dart';

/// A global [Provider] for getting ッツ Ebook Reader books from IndexedDB.
final ttuBooksProvider = FutureProvider<List<MediaItem>>((ref) {
  return ReaderTtuSource.instance.getBooksHistory(
    appModel: ref.watch(appProvider),
  );
});

/// A media source that allows the user to read from ッツ Ebook Reader.
class ReaderTtuSource extends ReaderMediaSource {
  /// Define this media source.
  ReaderTtuSource._privateConstructor()
      : super(
          uniqueKey: 'reader_ttu',
          sourceName: 'ッツ Ebook Reader',
          description: 'Read EPUBs and mine sentences via an embedded web'
              ' reader.',
          icon: Icons.library_books,
          outlinedIcon: Icons.library_books_outlined,
          implementsSearch: false,
          implementsHistory: false,
        );

  /// Get the singleton instance of this home tab.
  static ReaderTtuSource get instance => _instance;

  static final ReaderTtuSource _instance =
      ReaderTtuSource._privateConstructor();

  @override
  Widget get home => const HomeNovelPage();

  @override
  Future<void> onSourceExit({
    required AppModel appModel,
    required WidgetRef ref,
  }) async {
    ref.invalidate(ttuBooksProvider);
  }

  /// Origin the reader is served from: [TtuAssetPathHandler] answers it
  /// through the WebView asset loader. IndexedDB is tied to it, so it must
  /// never change between releases.
  static const String origin = 'https://appassets.androidplatform.net';

  /// Absolute URL of a reader page, e.g. `url('b.html?id=3')`.
  String url(String path) => '$origin/$path';

  /// Settings shared by every WebView that loads the reader.
  InAppWebViewSettings get webViewSettings => InAppWebViewSettings(
        webViewAssetLoader: WebViewAssetLoader(
          pathHandlers: [TtuAssetPathHandler()],
        ),
      );

  @override
  BaseSourcePage buildLaunchPage({
    MediaItem? item,
  }) {
    return ReaderTtuSourcePage(item: item);
  }

  @override
  List<Widget> getActions({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
  }) {
    return [
      buildSettingsButton(
        context: context,
        ref: ref,
        appModel: appModel,
      ),
      buildLaunchButton(
        context: context,
        ref: ref,
        appModel: appModel,
      ),
    ];
  }

  /// Allows user to close the floating search bar of a home tab page
  /// when open.
  Widget buildLaunchButton({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
  }) {
    return FloatingSearchBarAction(
      showIfOpened: true,
      child: JidoujishoIconButton(
        size: Theme.of(context).textTheme.titleLarge?.fontSize,
        tooltip: t.manager,
        icon: Icons.local_library_outlined,
        onTap: () {
          appModel.openMedia(
            ref: ref,
            mediaSource: this,
          );
        },
      ),
    );
  }

  /// Allows user to close the floating search bar of a home tab page
  /// when open.
  Widget buildSettingsButton({
    required BuildContext context,
    required WidgetRef ref,
    required AppModel appModel,
  }) {
    return FloatingSearchBarAction(
      showIfOpened: true,
      child: JidoujishoIconButton(
        size: Theme.of(context).textTheme.titleLarge?.fontSize,
        tooltip: t.settings,
        icon: Icons.settings,
        onTap: () {
          appModel.openMedia(
            ref: ref,
            mediaSource: this,
            item: MediaItem(
              mediaIdentifier: url('settings.html'),
              title: '',
              mediaSourceIdentifier: ReaderTtuSource.instance.uniqueKey,
              position: 0,
              duration: 1,
              canDelete: false,
              canEdit: true,
            ),
          );
        },
      ),
    );
  }

  @override
  BasePage buildHistoryPage({MediaItem? item}) {
    return const ReaderTtuSourceHistoryPage();
  }

  /// Fetch JSON for all books in IndexedDB.
  Future<List<MediaItem>> getBooksHistory({
    required AppModel appModel,
    bool recursive = false,
  }) async {
    List<MediaItem>? items;

    HeadlessInAppWebView webView = HeadlessInAppWebView(
      initialSettings: webViewSettings,
      initialUrlRequest: URLRequest(
        url: WebUri(url('')),
      ),
      onLoadStop: (controller, url) async {
        controller.evaluateJavascript(source: getHistoryJs);
      },
      onConsoleMessage: (controller, message) async {
        try {
          Map<String, dynamic> messageJson = jsonDecode(message.message);

          if (messageJson['messageType'] != null) {
            switch (messageJson['messageType']) {
              case 'history':
                try {
                  items = getItemsFromJson(messageJson);
                } catch (error, stack) {
                  items = [];
                  debugPrint('$error');
                  debugPrint('$stack');
                }
                break;
              case 'empty':
                items = [];
                break;
              case 'error':
                items = [];
                break;
            }
          }
        } on FormatException catch (_) {}
      },
    );

    try {
      await webView.run();
      while (items == null) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } finally {
      await webView.dispose();
    }

    return items!;
  }

  /// Fetch the list of history items given JSON from IndexedDB.
  List<MediaItem> getItemsFromJson(Map<String, dynamic> json) {
    List<Map<String, dynamic>> bookmarks =
        List<Map<String, dynamic>>.from(jsonDecode(json['bookmark']));
    List<Map<String, dynamic>> datas =
        List<Map<String, dynamic>>.from(jsonDecode(json['data']));
    Map<int, Map<String, dynamic>> bookmarksById =
        Map<int, Map<String, dynamic>>.fromEntries(
            bookmarks.map((e) => MapEntry(e['dataId'] as int, e)));

    List<MapEntry<int, MediaItem>> itemsById = datas.mapIndexed((index, data) {
      int position = 0;
      int duration = 1;

      Map<String, dynamic>? bookmark = bookmarksById[data['id']];

      if (bookmark != null) {
        position = bookmark['exploredCharCount'] as int;
        double progress = double.parse(bookmark['progress'].toString());
        if (progress == 0) {
          duration = 1;
        } else {
          duration = position ~/ progress;
        }
      }

      String id = data['id'].toString();
      String title = data['title'] as String? ?? ' ';
      String? base64Image;
      try {
        Uri.parse(data['coverImage']);
        base64Image = data['coverImage'];
      } catch (e) {
        base64Image = null;
      }

      return MapEntry(
        index,
        MediaItem(
          mediaIdentifier: url('b.html?id=$id&?title=$title'),
          title: title,
          base64Image: base64Image,
          mediaSourceIdentifier: ReaderTtuSource.instance.uniqueKey,
          position: position,
          duration: duration,
          canDelete: false,
          canEdit: true,
        ),
      );
    }).toList();

    List<int> lastOpens = datas.mapIndexed((index, data) {
      return data['lastBookOpen'] as int? ?? 0;
    }).toList();

    itemsById.sort((a, b) => lastOpens[b.key].compareTo(lastOpens[a.key]));
    List<MediaItem> itemsByLastOpened = itemsById.map((e) => e.value).toList();

    return itemsByLastOpened;
  }

  /// Whether or not using the volume buttons in the Reader should turn the
  /// page.
  bool get volumePageTurningEnabled {
    return getPreference<bool>(
        key: 'volume_page_turning_enabled', defaultValue: true);
  }

  /// Toggles the volume page turning option.
  void toggleVolumePageTurningEnabled() async {
    await setPreference<bool>(
      key: 'volume_page_turning_enabled',
      value: !volumePageTurningEnabled,
    );
  }

  /// Controls which direction is up or down for volume button page turning.
  bool get volumePageTurningInverted {
    return getPreference<bool>(
        key: 'volume_page_turning_inverted', defaultValue: false);
  }

  /// Inverts the current volume button page turning direction preference.
  void toggleVolumePageTurningInverted() async {
    await setPreference<bool>(
      key: 'volume_page_turning_inverted',
      value: !volumePageTurningInverted,
    );
  }

  /// Whether or not to add to extend the webpage beyond the navigation bar.
  /// This may be helpful for devices that don't have difficulty accessing the
  /// top bar (i.e. don't have a teardrop notch).
  bool get extendPageBeyondNavigationBar {
    return getPreference<bool>(
        key: 'extend_page_beyond_navbar', defaultValue: false);
  }

  /// Toggles the extend navbar option.
  void toggleExtendPageBeyondNavigationBar() async {
    await setPreference<bool>(
      key: 'extend_page_beyond_navbar',
      value: !extendPageBeyondNavigationBar,
    );
  }

  /// Whether or not the dictionary popup should adapt to the reader's theme.
  bool get adaptTtuTheme {
    return getPreference<bool>(key: 'adapt_ttu_theme', defaultValue: true);
  }

  /// Toggles whether dictionary popup should adapt to the reader's theme.
  void toggleAdaptTtuTheme() async {
    await setPreference<bool>(
      key: 'adapt_ttu_theme',
      value: !adaptTtuTheme,
    );
  }

  /// Whether the reader will highlight words on tap.
  bool get highlightOnTap {
    return getPreference<bool>(
      key: 'highlight_on_tap',
      defaultValue: true,
    );
  }

  /// Toggles whether the reader will highlight words on tap.
  void toggleHighlightOnTap() async {
    await setPreference<bool>(
      key: 'highlight_on_tap',
      value: !highlightOnTap,
    );
  }

  /// Used to fetch JSON for all books in IndexedDB.
  static const String getHistoryJs = '''
indexedDB.databases().then((databases) => {
  if (databases.length > 0) {
    var bookmarkJson = JSON.stringify([]);
    var dataJson = JSON.stringify([]);
    var lastItemJson = JSON.stringify([]);

    var blobToBase64 = function(blob) {
      return new Promise(resolve => {
        let reader = new FileReader();
        reader.onload = function() {
          let dataUrl = reader.result;
          resolve(dataUrl);
        };
        reader.readAsDataURL(blob);
      });
    }

    function getAllFromIDBStore(storeName) {
      return new Promise(
        function(resolve, reject) {
          var dbRequest = indexedDB.open("books");

          dbRequest.onerror = function(event) {
            reject(Error("Error opening DB"));
          };

          dbRequest.onupgradeneeded = function(event) {
            reject(Error('Not found'));
          };

          dbRequest.onsuccess = function(event) {
            var database = event.target.result;

            try {
              var transaction = database.transaction([storeName], 'readwrite');
              var objectStore;
              try {
                objectStore = transaction.objectStore(storeName);
              } catch (e) {
                reject(Error('Error getting objects'));
              }

              var objectRequest = objectStore.getAll();

              objectRequest.onerror = function(event) {
                reject(Error('Error getting objects'));
              };

              objectRequest.onsuccess = function(event) {
                if (objectRequest.result) resolve(objectRequest.result);
                else reject(Error('Objects not found'));
              }; 
            } catch (e) {
              console.log(JSON.stringify({messageType: "error", error: e.name}));
              reject(Error('Error getting objects'));
            }
          };
        }
      );
    }

    async function getTtuData() {
      try {
        items = await getAllFromIDBStore("data");
        await Promise.all(items.map(async (item) => {
          try {
            item["coverImage"] = await blobToBase64(item["coverImage"]);
          } catch (e) {}
        }));
        
        dataJson = JSON.stringify(items);
      } catch (e) {
        dataJson = JSON.stringify([]);
      }

      try {
        bookmarkJson = JSON.stringify(await getAllFromIDBStore("bookmark"));
      } catch (e) {
        bookmarkJson = JSON.stringify([]);
      }
      
      try {
        lastItemJson = JSON.stringify(await getAllFromIDBStore("lastItem"));
      } catch (e) {
        lastItemJson = JSON.stringify([]);
      }

      console.log(JSON.stringify({messageType: "history", lastItem: lastItemJson, bookmark: bookmarkJson, data: dataJson}));
    }

    try {
      getTtuData();
    } catch (e) {
      console.log(JSON.stringify({messageType: "history", lastItem: lastItemJson, bookmark: bookmarkJson, data: dataJson}));
    }
  } else {
  
    console.log(JSON.stringify({messageType: "empty"}));
    
  }
});
''';
}
