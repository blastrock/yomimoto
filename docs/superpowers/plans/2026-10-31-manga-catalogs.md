# Manga Catalogs Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Browse mokuro-bunko servers (mokuro.moe) from the Manga tab and download volumes straight into the library through the existing import.

**Architecture:** A pure-Dart API client (`MokuroCatalogClient`) and a pure-Dart batch downloader (`downloadCatalogVolumes`) beside `mokuro_import.dart`, both taking an injected `http.Client` so they are unit-tested with `MockClient`. The downloader writes `volume.cbz` + `volume.mokuro` into a temporary directory and hands the archive to an injected importer, which in the app is the existing `importMokuroVolume` isolate plus `putMediaItem`, factored out of `ReaderMokuroSource.importVolume`. Four new pages: the Add volume popup, the Add catalog popup, the series page and the volume page, plus a progress dialog. Catalogs are a `StringListPreference`; no schema change.

**Tech Stack:** Flutter/Dart, `http` 1.6 (`AbortableRequest`, `MockClient`), `cached_network_image` (already a dependency), slang.

**Spec:** `docs/superpowers/specs/2026-10-31-manga-catalogs-design.md`

## Global Constraints

- Follow `CLAUDE.md`: barrel imports only (`package:yuuna/<barrel>.dart`), every new file gets an `export` line in its barrel (`lib/media.dart` for `lib/src/media/sources/`, `lib/pages.dart` for pages); `///` docs on every public member; British spelling; format new code by hand to match surrounding files (never `dart format` an existing file); `unawaited(...)` for fire-and-forget; toasts through `showToast`.
- `flutter analyze` reports no issues (infos included) and `flutter test` passes after every task.
- `ReaderMokuroSource.uniqueKey` stays `reader_mokuro`; the new preference key is `reader_mokuro/catalogs`. Schema stays at version 2.
- Romaji is never shown, only searched. The one exception: a series with no `titles` shows its `name`.
- Only mokuro-bunko servers. Read only the API fields listed in the spec's "The API" table; ignore all others. A manifest whose `version` is not `1` is refused.
- Downloads go through the existing `importMokuroVolume` unchanged.
- No new dependencies. The `http` constraint is raised to `^1.5.0` (for `AbortableRequest`); the lock already has 1.6.0.
- No animations added.
- Each task ends with a jj commit: `jj describe -m "<message>"` then `jj new`, the message ending with:
  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01HHbqLK6JMXgShtdobG7J26
  ```
  Never move bookmarks; the user pushes.
- Android builds need `ANDROID_HOME=/home/blastrock/android/android-sdk-linux`; the emulator is `emulator-5554`.

## Review Focus

1. **Names that must be URL-encoded.** Real series and volume names contain `#`, spaces, brackets, `&` and CJK (`#Zombie Sagashitemasu`, `[浦沢直樹] 20世紀少年 01`). Every request must encode them as query parameters or path segments, and manifest URLs, which arrive already percent-encoded, must not be encoded again. Pinned by the exact-URI tests in Task 1.
2. **The network drops mid-download.** The batch stops, the toast names the volume, its temporary files are gone, and volumes imported before it stay. Pinned by the failure test in Task 2.
3. **Cancel pressed during an import.** The import finishes and its volume is kept; no further download starts. Pinned by the cancel-during-import test in Task 2.
4. **A response that is not the expected JSON** (an HTML error page served with 200, a missing `series` key, a wrong type). The page shows its error and Retry; nothing crashes. Pinned by the unparseable tests in Task 1.
5. **A catalog URL typed loosely** (spaces around it, no scheme, a trailing slash, the same server twice). It normalises to one canonical form and is stored once. Pinned by the normalisation tests in Task 1 and the duplicate check in Task 3.

---

### Task 1: The catalog API client

**Files:**
- Create: `lib/src/media/sources/mokuro_catalog.dart`
- Modify: `lib/media.dart` (export), `pubspec.yaml` (`http: ^1.5.0`, with a comment: `AbortableRequest` for cancelling catalog downloads)
- Test: `test/media/mokuro_catalog_test.dart`

**Interfaces:**
- Produces:
  - `String? normaliseCatalogUrl(String input)`: trims; empty → `null`; prepends `https://` when there is no `://`; parses; `null` unless the scheme is `http`/`https` and the host is non-empty; drops the query, fragment and trailing `/`s; returns the string.
  - `String catalogHost(String url)`: `Uri.parse(url).host`.
  - `String formatCatalogSize(int bytes)`: megabytes (10⁶ bytes), rounded, `'98 MB'`; below 1 MB, `'1 MB'`.
  - `enum CatalogFailure { network, http, unparseable, unsupported, noOcr }`; `class CatalogException implements Exception { CatalogException(this.failure, [this.detail]); final CatalogFailure failure; final String? detail; }`.
  - `class CatalogSeries { name, cover (String), native, romaji, english, tag (String?) ; String get displayTitle /* native ?? name */; bool matches(String query) }`. `matches`: query trimmed and lower-cased; empty matches all; else a substring of any of `native`, `romaji`, `english`, `name`, lower-cased.
  - `class CatalogVolume { name, cover (String); bool ocrPending }`.
  - `class CatalogManifest { Uri archiveUrl; int archiveSize; Uri ocrUrl; int ocrSize; int get totalSize }` (URLs resolved against the base).
  - `class MokuroCatalogClient { MokuroCatalogClient(String baseUrl, {http.Client? client, Duration timeout = const Duration(seconds: 30)}); Future<List<CatalogSeries>> fetchLibrary(); Future<List<CatalogVolume>> fetchVolumes(String seriesName); Future<Map<String, String>> fetchVolumeUuids(String seriesName) /* volume name → volume_uuid */; Future<CatalogManifest> fetchManifest(String seriesName, String volumeName); Uri coverUri(String coverPath); http.Client get httpClient; void close(); }`. Every `fetch*` throws only `CatalogException`. The client owns and closes its `http.Client` only when it created it.

- [ ] **Step 1: Write the failing tests** in `test/media/mokuro_catalog_test.dart`, with inline JSON trimmed from the real responses (`library` with three series: one full, one with `tag: 'Upscaled'`, one with no `titles`; a `series` response with one `ocr_pending: true` volume; a `series.json`; a manifest copied from the spec's check). Groups and assertions:

```dart
group('normaliseCatalogUrl', () {
  test('adds https and drops trailing slashes, query and fragment', () {
    expect(normaliseCatalogUrl('  mokuro.moe/ '), 'https://mokuro.moe');
    expect(normaliseCatalogUrl('https://mokuro.moe/?a=1#x'), 'https://mokuro.moe');
    expect(normaliseCatalogUrl('http://host:8080/sub/'), 'http://host:8080/sub');
  });
  test('refuses empty input and other schemes', () {
    expect(normaliseCatalogUrl('   '), isNull);
    expect(normaliseCatalogUrl('ftp://mokuro.moe'), isNull);
  });
});

test('formatCatalogSize', () {
  expect(formatCatalogSize(98000000), '98 MB');
  expect(formatCatalogSize(55846180 + 398114), '56 MB');
  expect(formatCatalogSize(1000), '1 MB');
});

group('MokuroCatalogClient', () {
  test('fetchLibrary reads titles, tags and series with no titles', ...);
  //   requested URI == Uri.parse('https://mokuro.moe/catalog/api/library')
  //   series[0].displayTitle == '#ゾンビさがしてます', series[1].tag == 'Upscaled'
  //   series[2].native == null, series[2].displayTitle == series[2].name
  test('matches searches native, romaji, English and name, ignoring case', ...);
  //   s.matches('ゾンビ'), s.matches('zombie sagashi'), s.matches('LOOKINGFOR'),
  //   s.matches(''), !s.matches('berserk')
  test('fetchVolumes encodes the series name and keeps ocr_pending', ...);
  //   request.url.path == '/catalog/api/series',
  //   request.url.queryParameters == {'name': '#Zombie Sagashitemasu'}
  test('fetchVolumeUuids reads series.json beside the volumes', ...);
  //   request.url.pathSegments == ['mokuro-reader', '#Zombie Sagashitemasu', 'series.json']
  //   result == {'-Zombie-Sagashitemasu-01': '882d0326-606e-4b84-a496-90dcb68708ce'}
  test('fetchManifest resolves URLs without encoding them again', ...);
  //   fetchManifest('20 Seiki Shounen (Upscaled)', '[浦沢直樹] 20世紀少年 01') requests path
  //   '/catalog/api/manifest' with queryParameters
  //   {'series': '20 Seiki Shounen (Upscaled)', 'volume': '[浦沢直樹] 20世紀少年 01'};
  //   the mock answers the #Zombie manifest from the spec, and
  //   archiveUrl.toString() == 'https://mokuro.moe/mokuro-reader/%23Zombie%20Sagashitemasu/-Zombie-Sagashitemasu-01.cbz'
  //   totalSize == 55846180 + 398114
  test('fetchManifest refuses another manifest version', ...);   // CatalogFailure.unsupported
  test('fetchManifest refuses a manifest with no OCR', ...);      // ocr: null → CatalogFailure.noOcr
  test('an HTML page served with 200 is unparseable', ...);       // CatalogFailure.unparseable
  test('a missing series key is unparseable', ...);               // {"x": []} → unparseable
  test('a 404 is an http failure', ...);                          // CatalogFailure.http
  test('a client exception is a network failure', ...);           // MockClient throws http.ClientException
  test('coverUri encodes the path', ...);
  //   coverUri('#Zombie Sagashitemasu/-Zombie-Sagashitemasu-01.webp').queryParameters['path']
  //   == '#Zombie Sagashitemasu/-Zombie-Sagashitemasu-01.webp', path '/catalog/api/cover'
});
```

Each failure test asserts with `throwsA(isA<CatalogException>().having((e) => e.failure, 'failure', CatalogFailure.x))`.

- [ ] **Step 2: Run the tests to see them fail**

Run: `flutter test test/media/mokuro_catalog_test.dart`
Expected: compilation errors (no `MokuroCatalogClient`).

- [ ] **Step 3: Implement `lib/src/media/sources/mokuro_catalog.dart`**, export it, raise the `http` constraint. Build request URIs from the base with `Uri.replace(pathSegments: [...base.pathSegments, ...], queryParameters: {...})` so names are encoded once; resolve manifest URLs with `base.resolve(url)`. Map `TimeoutException`, `http.ClientException`, `IOException` to `network`; non-200 to `http` (status in `detail`); `FormatException`/`TypeError` while decoding or reading fields to `unparseable`. Follow `explanation_client.dart` for the shape.

- [ ] **Step 4: Run the tests to see them pass**

Run: `flutter test test/media/mokuro_catalog_test.dart && flutter analyze`
Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — `Add the mokuro-bunko catalog client`

---

### Task 2: The batch downloader

**Files:**
- Create: `lib/src/media/sources/mokuro_catalog_download.dart`
- Modify: `lib/media.dart` (export)
- Test: `test/media/mokuro_catalog_download_test.dart`

**Interfaces:**
- Consumes: `MokuroCatalogClient.httpClient`, `CatalogManifest`, `CatalogException` (Task 1); `importMokuroVolume`, `MokuroImportParams`, `MokuroImportResult` (existing).
- Produces:
  - `class CatalogCancelToken { void cancel(); bool get isCancelled; Future<void> get whenCancelled; }`
  - `class CatalogDownload { const CatalogDownload({required this.volumeName, required this.manifest}); final String volumeName; final CatalogManifest manifest; }`
  - `class CatalogDownloadProgress { final int volumeIndex /* 0-based */; final int volumeCount; final int receivedBytes /* whole batch */; final int totalBytes /* whole batch */; final bool importing; }`
  - `class CatalogDownloadException implements Exception { final String volumeName; final Object error /* CatalogException or MokuroImportException */; }`
  - `Future<int> downloadCatalogVolumes({required http.Client client, required List<CatalogDownload> downloads, required Directory temporaryDirectory, required CatalogCancelToken cancel, required Future<void> Function(String archivePath) importArchive, required void Function(CatalogDownloadProgress) onProgress})`: returns how many volumes were imported (fewer than `downloads.length` only when cancelled); throws `CatalogDownloadException` on the first failure.

Behaviour, per volume in order: stop if cancelled; create a fresh subdirectory of `temporaryDirectory`; stream `archiveUrl` to `volume.cbz` and `ocrUrl` to `volume.mokuro` (`http.AbortableRequest` with `abortTrigger: cancel.whenCancelled`; also check `isCancelled` per chunk, since `MockClient` ignores the trigger); report progress per chunk; then report `importing: true` and `await importArchive(<dir>/volume.cbz)` (not abortable); delete the subdirectory in a `finally`. A cancel during a download deletes that volume's files and returns the count so far. A cancel during the import lets it finish, counts it, and returns before the next download. A non-200 response is `CatalogException(CatalogFailure.http)`, a dropped stream `CatalogException(CatalogFailure.network)`, both wrapped in `CatalogDownloadException` with the volume's name; an importer's `MokuroImportException` is wrapped the same way.

- [ ] **Step 1: Write the failing tests.** A `MockClient.streaming` serves byte lists by URL; the temporary directory is a `Directory.systemTemp.createTempSync`. Tests:

```dart
test('downloads each volume beside its OCR and imports it', ...);
//   importer records paths; for each call, File(path).existsSync(),
//   p.basename(path) == 'volume.cbz', File(p.setExtension(path, '.mokuro')).readAsBytesSync() == ocrBytes;
//   returns 2; temporaryDirectory.listSync() is empty afterwards
test('reports bytes over the whole batch', ...);
//   last progress: receivedBytes == totalBytes == sum of both manifests' sizes; volumeCount == 2;
//   some progress has importing == true
test('a real archive goes through importMokuroVolume', ...);
//   importer = (path) async => importMokuroVolume(MokuroImportParams(archivePath: path, volumesDirectory: volumes.path));
//   served .cbz built with ZipEncoder as in mokuro_import_test.dart; volumes/uuid-1/volume.mokuro exists
test('a dropped connection stops the batch and names the volume', ...);
//   second volume's archive stream emits a chunk then an http.ClientException;
//   throwsA(isA<CatalogDownloadException>().having((e) => e.volumeName, 'volumeName', 'vol 02'));
//   the importer was called once (vol 01 kept); temporaryDirectory empty
test('an HTTP error is a failure of that volume', ...);           // 404 → error is CatalogException(http)
test('an import error is a failure of that volume', ...);         // importer throws MokuroImportException(noOcr)
test('cancel during a download keeps earlier volumes and deletes the partial one', ...);
//   cancel.cancel() from the stream after the first chunk of vol 02; returns 1; temp empty; importer called once
test('cancel during an import finishes it and starts nothing else', ...);
//   importer of vol 01 calls cancel.cancel() then completes; returns 1;
//   no request was made for vol 02's URLs
```

- [ ] **Step 2: Run the tests to see them fail**

Run: `flutter test test/media/mokuro_catalog_download_test.dart`
Expected: compilation errors.

- [ ] **Step 3: Implement `lib/src/media/sources/mokuro_catalog_download.dart`** and export it.

- [ ] **Step 4: Run the tests to see them pass**

Run: `flutter test test/media/ && flutter analyze`
Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — `Download catalog volumes into the import`

---

### Task 3: Catalogs and the Add volume popup

**Files:**
- Create: `lib/src/pages/implementations/manga_add_volume_dialog_page.dart`, `lib/src/pages/implementations/manga_add_catalog_dialog_page.dart`
- Modify: `lib/src/media/sources/reader_mokuro_source.dart`, `lib/pages.dart`, `lib/i18n/strings.i18n.json` + regenerated `lib/i18n/strings.g.dart`, `lib/src/pages/implementations/reader_mokuro_history_page.dart` only if its placeholder string changes (see Step 4)
- Test: `test/media/reader_mokuro_source_test.dart` (unchanged tests must still pass)

**Interfaces:**
- Consumes: `normaliseCatalogUrl`, `catalogHost`, `MokuroCatalogClient.fetchLibrary`, `CatalogException` (Task 1).
- Produces on `ReaderMokuroSource`:
  - `static const StringListPreference _catalogs = StringListPreference('reader_mokuro/catalogs', defaultValue: []);`
  - `List<String> get catalogs` (a copy); `Future<void> addCatalog(String url)` (no-op when present); `Future<void> removeCatalog(String url)`.
  - `Future<MokuroImportResult> importArchive({required AppModel appModel, required String archivePath})`: runs `importMokuroVolume` in `compute`, puts the media item exactly as `importVolume` did (keeping the existing row), shows the missing-pages toast, calls `refreshTab()`. Throws `MokuroImportException`.
  - `String importErrorMessage(MokuroImportError error)` (the current private `_importErrorMessage`, made public for the volume page's toasts).
  - `importVolume` keeps the picker, then calls `importArchive` inside `runWithProgress`, catching `MokuroImportException` for the toast as today.
  - `getActions`' `+` opens `MangaAddVolumeDialogPage` with `showDialog`.
- Produces pages: `MangaAddVolumeDialogPage` (no parameters), `MangaAddCatalogDialogPage` (pops `String?`, the normalised URL added). `MangaCatalogPage` is pushed from the popup but created in Task 4: until then a catalog tap does nothing.

- [ ] **Step 1: Refactor `importVolume` into `importVolume` + `importArchive`, add the catalog list.** Behaviour of file import unchanged.

- [ ] **Step 2: Add volume popup** — an `AlertDialog` titled "Add volume": one row per catalog (`catalogHost(url)`, trailing trash `IconButton` with tooltip; the trash asks "Remove the catalog <host>? Downloaded volumes stay in the library." with Remove/Cancel, then `removeCatalog`), an empty-list line ("No catalogs yet"), "Add catalog" and "Import file" rows, and a Close action. "Import file" pops the popup, then calls `importVolume` with the tab's context. A catalog tap pops the popup and pushes `MangaCatalogPage(catalogUrl: url)` (Task 4).

- [ ] **Step 3: Add catalog popup** — one URL `TextField` (hint `https://mokuro.moe`), Cancel/Add. Add: `normaliseCatalogUrl`; `null` → toast "This is not a web address"; already in `catalogs` → pop with it (no duplicate); else `runWithProgress` around `MokuroCatalogClient(url).fetchLibrary()`; on `CatalogException` toast "No mokuro catalog answers at this address" and stay open; on success `addCatalog` and pop with the URL. The Add volume popup rebuilds its list after it closes.

- [ ] **Step 4: Strings** in `strings.i18n.json` (keys prefixed `manga_catalog_`/`manga_add_`), then `dart run slang`. Change `manga_no_volumes_added` to "No volumes yet: tap + to download one from a catalog or import a file".

- [ ] **Step 5: Verify**

Run: `dart run slang && flutter analyze && flutter test`
Expected: `No issues found!`; all tests pass. On the emulator (`flutter run -d emulator-5554`): `+` opens the popup; Import file imports as before; adding `mokuro.moe` lists `mokuro.moe`; adding `https://mokuro.moe/` again adds nothing; adding `example.com` toasts and stays open; the trash asks, then removes.

- [ ] **Step 6: Commit** — `Add catalogs and the Add volume popup`

---

### Task 4: The series page

**Files:**
- Create: `lib/src/pages/implementations/manga_catalog_page.dart`
- Modify: `lib/pages.dart`, `lib/i18n/strings.i18n.json` + `strings.g.dart`

**Interfaces:**
- Consumes: `MokuroCatalogClient.fetchLibrary`, `coverUri`, `CatalogSeries.displayTitle`/`matches`/`tag`, `catalogHost` (Task 1).
- Produces: `class MangaCatalogPage extends BasePage { const MangaCatalogPage({required this.catalogUrl, super.key}); final String catalogUrl; }`. Pushes `MangaSeriesPage(catalogUrl: ..., series: CatalogSeries)` (Task 5; until then a tap does nothing).

- [ ] **Step 1: Build the page.** `Scaffold` with an `AppBar` titled `catalogHost(catalogUrl)` and a search `IconButton`; search replaces the title with an autofocused `TextField` filtering with `CatalogSeries.matches` on each change, and a close button clearing it. Body states: loading (`CircularProgressIndicator`), error (message for the `CatalogFailure` + Retry button re-running the fetch), loaded (a `GridView.builder` with `SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 150, childAspectRatio: ReaderMokuroSource.instance.aspectRatio)`, tiles styled like `HistoryReaderPage.buildMediaItemContent`: cover as `CachedNetworkImageProvider(client.coverUri(series.cover).toString())` in a `FadeInImage` with a blank error builder, the `displayTitle` strip at the bottom, the `tag` as a small badge at the top left when non-null). The builder makes covers lazy; the cache manager keeps them in the temporary directory. Series in server order. The fetch happens in `initState` only; the page keeps its list, scroll and search while routes are pushed over it. Close the client in `dispose`.

- [ ] **Step 2: Error strings** — one per `CatalogFailure` used here ("Could not reach the catalog", "The catalog answered with an error", "The catalog sent something unexpected"), plus "Retry" and the search hint ("Search titles").

- [ ] **Step 3: Verify**

Run: `dart run slang && flutter analyze && flutter test`
Expected: clean, passing. On the emulator: mokuro.moe opens with a spinner then ~1,100 series; covers appear while scrolling and come back without refetching when scrolling up; 20世紀少年 appears twice, one with an "Upscaled" badge; searching `zombie`, `ゾンビ` and `lookingfor` each finds #ゾンビさがしてます; with networking turned off (`adb shell svc wifi disable; adb shell svc data disable`), opening the catalog shows the error and Retry works after re-enabling.

- [ ] **Step 4: Commit** — `Browse a catalog's series`

---

### Task 5: The volume page, downloads and progress

**Files:**
- Create: `lib/src/pages/implementations/manga_series_page.dart`, `lib/src/pages/implementations/manga_download_dialog.dart`
- Modify: `lib/pages.dart`, `lib/i18n/strings.i18n.json` + `strings.g.dart`, `lib/src/pages/implementations/manga_catalog_page.dart` (push the page on tap)

**Interfaces:**
- Consumes: `MokuroCatalogClient.fetchVolumes`/`fetchVolumeUuids`/`fetchManifest`/`coverUri` (Task 1); `downloadCatalogVolumes`, `CatalogDownload`, `CatalogCancelToken`, `CatalogDownloadProgress`, `CatalogDownloadException` (Task 2); `ReaderMokuroSource.importArchive`, `importErrorMessage` (Task 3); `appModel.getMediaSourceHistory(mediaSource: ReaderMokuroSource.instance)`, `appModel.temporaryDirectory`.
- Produces: `class MangaSeriesPage extends BasePage { const MangaSeriesPage({required this.catalogUrl, required this.series, super.key}); }`; `class MangaDownloadDialog extends StatefulWidget { const MangaDownloadDialog({required this.progress, required this.cancel, super.key}); final ValueListenable<CatalogDownloadProgress?> progress; final CatalogCancelToken cancel; }`.

- [ ] **Step 1: The page.** Title: `series.displayTitle`. On `initState`, `fetchVolumes` and `fetchVolumeUuids` together; a failure of `fetchVolumes` is the error + Retry state as in Task 4; a failure of `fetchVolumeUuids` gives an empty map (no checks). Show volumes with `!ocrPending`, in server order, as cover tiles labelled with `volume.name`. A tile is **in the library** when `uuids[volume.name]` is among the `mediaIdentifier`s of `getMediaSourceHistory`; it then shows a check on a green circle (`Colors.green.shade700`, white `Icons.check`, ~20 px) at the cover's bottom-right, above the title strip.

- [ ] **Step 2: Tap and selection.** Selection follows `StashPage`: long-press selects, taps toggle while selecting, the `AppBar` shows the count, a close button and a download `IconButton`. A tap outside selection, or the download button, first fetches the manifests of the volumes concerned under `runWithProgress` (a `CatalogException` → toast "<volume name>: <message>", `noOcr` reading "this volume has no OCR yet", and stop), then asks:
  - one volume: "Download <name>?" / "<size>." — or, when in the library, "<name> is already in your library. Download it again? Its reading position and stash are kept." / "<size>."
  - several: "Download <n> volumes?" / "<size> in total."
  with Download/Cancel, sizes from `formatCatalogSize(sum of totalSize)`.

- [ ] **Step 3: The download.** Show `MangaDownloadDialog` (`barrierDismissible: false`, back ignored with `PopScope(canPop: false)`) fed by a `ValueNotifier<CatalogDownloadProgress?>`, and run `downloadCatalogVolumes` with the catalog client's `httpClient`, a fresh `Directory(p.join(appModel.temporaryDirectory.path, 'catalogDownloads'))`, and `importArchive: (path) => ReaderMokuroSource.instance.importArchive(appModel: appModel, archivePath: path)`. The dialog shows "Volume <i+1> of <n>", a `LinearProgressIndicator` (`receivedBytes / totalBytes`, indeterminate while `importing`), "<received> / <total>" with `formatCatalogSize`, and a Cancel button that is never disabled: it calls `cancel.cancel()` and its label becomes "Cancelling…". When the batch ends: close the dialog, leave selection mode, refresh the checks. On `CatalogDownloadException`: toast "<volume name>: <message>" (`importErrorMessage` for `MokuroImportException`, the Task 4 messages for `CatalogException`).

- [ ] **Step 4: Wire the series page tap** to push `MangaSeriesPage`.

- [ ] **Step 5: Verify**

Run: `dart run slang && flutter analyze && flutter test`
Expected: clean, passing. On the emulator, with #ゾンビさがしてます (1 volume, 56 MB) and a short series: tap downloads one volume with the bytes moving, then the check appears and the volume is in the Manga tab and opens; long-press two volumes, the confirmation gives the total, both arrive; cancel mid-download keeps the first and leaves `catalogDownloads/` empty (`adb shell run-as org.kaqui.yomimoto ls cache/catalogDownloads`); cutting the network mid-download toasts the volume's name; downloading a volume you have warns and keeps its position; back returns to the series page as left, then to the Manga tab.

- [ ] **Step 6: Commit** — `Download volumes from a catalog`

---

### Task 6: Documentation

**Files:**
- Modify: `CLAUDE.md` (the manga paragraph of "Reader internals"), `docs/superpowers/specs/2026-10-31-manga-reader-design.md` ("Next project: catalogs (findings)")

- [ ] **Step 1: `CLAUDE.md`.** After the import paragraph of the manga section, add a paragraph: catalogs are mokuro-bunko servers stored as the `reader_mokuro/catalogs` preference; `MokuroCatalogClient` (`mokuro_catalog.dart`) reads the API (library, series, `series.json`, manifest; only the manifest is versioned); `downloadCatalogVolumes` (`mokuro_catalog_download.dart`) downloads `volume.cbz` + `volume.mokuro` into the temporary directory and imports them through the existing import; romaji is searched, never shown; design in `docs/superpowers/specs/2026-10-31-manga-catalogs-design.md`. Update the import paragraph's opening ("Import takes a `.cbz` or `.zip` only…") to say file import is one of the two ways in.

- [ ] **Step 2: The reader design.** Add one line under "Next project: catalogs (findings)": "Built: see `2026-10-31-manga-catalogs-design.md`."

- [ ] **Step 3: Verify** — `flutter analyze && flutter test`; expected clean and passing.

- [ ] **Step 4: Commit** — `Document the manga catalogs`
