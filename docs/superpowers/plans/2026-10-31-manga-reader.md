# Manga Reader Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the broken legacy-HTML mokuro integration with our own manga reader page (WebView) over `.mokuro` volumes imported from `.cbz`/`.zip`, with the library, positions, stash and cards owned by Flutter.

**Architecture:** A plain HTML/CSS/JS page in `assets/manga-reader/` renders one volume (page images plus an invisible OCR text overlay, laid out with code ported from mokuro-reader) and talks to Flutter through a `MokuroBridge` modelled on `TtuBridge`. Import extracts a volume into app storage in an isolate; each volume is a `media_item` row like a ttu book. Schema goes to version 2 with a migration that drops the old catalogs and volumes.

**Tech Stack:** Flutter/Dart, `flutter_inappwebview` (asset loader, JS handlers), `async_zip` (`ZipFileReaderSync`/`ZipFileWriterSync`, pure Dart), Drift, plain ES modules in the WebView, `pnpm dlx esbuild` once to port mokuro-reader's TypeScript.

**Spec:** `docs/superpowers/specs/2026-10-31-manga-reader-design.md`

## Global Constraints

- Follow `CLAUDE.md`: barrel imports only (`package:yuuna/<barrel>.dart`), new files get an `export` line in their barrel; `///` docs on every public member; British spelling; format new code by hand to match the file (do not run `dart format` on existing files); `unawaited(...)` for fire-and-forget; toasts through `showToast`.
- `flutter analyze` reports no issues (infos included) after every task; `flutter test` passes after every task.
- `ReaderMokuroSource.uniqueKey` stays `reader_mokuro`; its preference keys keep the `reader_mokuro/` prefix.
- Do not rename internal `jidoujisho`/`yuuna` identifiers.
- No runtime or build-time dependency on mokuro-reader; no bundler for the reader page. The one generated file (`mokuro-layout.js`) is produced by a committed script and committed.
- Ported mokuro-reader code (GPL-3.0) carries a header naming its source files and commit `bfaeb482`.
- Only `.cbz` and `.zip` are importable. OCR: `<stem>.mokuro` beside the archive wins, else exactly one `.mokuro` inside it.
- Reader defaults, not settings: right to left; portrait one page, landscape two-page spreads with the cover (page 0) alone; fit to screen; WebView's own pinch-zoom; no page-turn animation; overlay text invisible until a tap.
- Kept settings: highlight on tap, volume-key page turning, inverted volume keys. Dropped: dark theme, extend beyond navigation bar.
- Never romaji anywhere.
- Each task ends with a jj commit: `jj describe -m "<message>"` then `jj new`, message ending with the two attribution lines from the session (`Co-Authored-By: …`, `Claude-Session: …`). Never move bookmarks; the user pushes.
- Android builds need `ANDROID_HOME=/home/blastrock/android/android-sdk-linux`; the emulator is `emulator-5554`.

## Review Focus

1. **File names that URLs encode.** Real volumes are named like `[赤坂アカ×横槍メンゴ] 【推しの子】 01/00001.webp`, with `#`, `%`, spaces and brackets. Every image must load: the asset loader hands handlers an already-decoded path, which must not be decoded again (as `TtuImportPathHandler` documents). Pinned by `MokuroVolumePathHandler` tests in Task 4 and the QA volume in Task 9.
2. **A picked file that is not a valid archive, or OCR that is not valid JSON or is missing fields.** Import must end in a toast, not a crash or a half-written volume directory. Pinned by the corrupt-archive and invalid-OCR tests in Task 2.
3. **Re-importing a volume already in the library.** It keeps its id (so its stash), its position and its user title. Pinned by the `volumeItem` test in Task 5.
4. **Rotating the device mid-volume.** The reader stays on the same page; the spread pairing recomputes. Pinned by the rotation check in Task 3 and on the emulator in Task 9.
5. **OCR text containing `...` or `．．．`.** mokuro-reader's `processLine` turns these into `…`, which shifts offsets. The tap offset, the text sent to Flutter and the highlight must all use the processed text. Pinned by the ellipsis check in Task 3's debug harness.

---

### Task 1: Remove the old mokuro reader and migrate the schema to version 2

**Files:**
- Delete: `lib/src/pages/implementations/mokuro_catalog_browse_page.dart`, `mokuro_catalog_dialog_page.dart`, `mokuro_catalog_manage_dialog_page.dart`, `mokuro_catalog_edit_dialog_page.dart`, `mokuro_link_dialog_page.dart`; `lib/src/utils/misc/mokuro_catalog.dart`, `lib/src/utils/misc/mokuro_payload.dart`
- Modify: `lib/pages.dart`, `lib/utils.dart` (exports); `lib/src/database/tables.dart` (remove `MokuroCatalogs`); `lib/src/database/app_database.dart` (table list, `schemaVersion`, migration, class doc); `lib/src/database/app_store.dart` (catalog methods, class doc); `lib/src/models/app_model.dart` (catalog accessors and methods); `lib/src/media/sources/reader_mokuro_source.dart` (strip to a library-only stub); `lib/src/pages/implementations/settings_page.dart` (drop the dark-theme switch); `lib/i18n/strings.i18n.json` + regenerated `strings.g.dart`; `DEBT.md` (remove the "Mokuro history trimming can delete stashes" entry)
- Create: `drift_schemas/drift_schema_v2.json`, `test/database/generated/schema_v2.dart` (generated); modify generated `test/database/generated/schema.dart`
- Test: `test/database/schema_test.dart`

**Interfaces:**
- Produces: `AppDatabase.schemaVersion == 2`. `ReaderMokuroSource` keeps `uniqueKey: 'reader_mokuro'`, `explanationKind`, the highlight-on-tap and volume-key preferences and toggles. It loses `useDarkTheme`/`toggleUseDarkTheme`, `extendPageBeyondNavigationBar`/`toggleExtendPageBeyondNavigationBar`, `launchFilePicker`, `generateMediaItemFromWebView`, `getImageUrl`, the catalog/link/pick buttons, and `generateImages` (re-added in Task 8). `getActions` returns `[]` and `buildLaunchPage` throws `UnimplementedError` until Task 6, `implementsHistory` becomes `false`, `overridesAutoImage` stays `true`.

- [ ] **Step 1: Write the failing migration test** in `test/database/schema_test.dart`. Change the existing snapshot test to version 2 (`startAt(2)`, `migrateAndValidate(db, 2)`, renamed to "…matches the version 2 snapshot"). Add:

```dart
test('upgrading from version 1 drops mokuro catalogs and old volumes',
    () async {
  SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
  InitializedSchema schema = await verifier.schemaAt(1);
  schema.rawDatabase.execute('''
    INSERT INTO media_item (id, media_source_identifier, media_identifier,
      title, position, duration, can_delete, can_edit, last_opened_at)
    VALUES (1, 'reader_mokuro', 'file:///a.html', 'old', 0, 1, 1, 1, 0),
           (2, 'reader_ttu', 'b.html?id=1', 'book', 0, 1, 0, 1, 0);
    INSERT INTO stash_item (media_item_id, term, reading, definitions,
      sentence, word_start, word_length, position, created_at)
    VALUES (1, '猫', 'ねこ', '[]', '猫', 0, 1, 0, 0),
           (2, '犬', 'いぬ', '[]', '犬', 0, 1, 0, 0);
    INSERT INTO mokuro_catalog (name, url, "order") VALUES ('c', 'u', 0);
    INSERT INTO preference (key, value) VALUES
      ('reader_mokuro/use_dark_theme', 'true'),
      ('reader_mokuro/extend_page_beyond_navbar', 'true'),
      ('reader_mokuro/highlight_on_tap', 'false');
  ''');
  AppDatabase db = AppDatabase(schema.newConnection());
  addTearDown(db.close);

  await verifier.migrateAndValidate(db, 2);

  expect(await db.select(db.mediaItems).map((r) => r.id).get(), [2]);
  expect(await db.select(db.stashItems).map((r) => r.term).get(), ['犬']);
  expect(
      await db.select(db.preferenceEntries).map((r) => r.key).get(),
      ['reader_mokuro/highlight_on_tap']);
});
```

Copy the column names of the `INSERT`s from `test/database/generated/schema_v1.dart` if any differ (the v1 snapshot is the truth).

- [ ] **Step 2: Run it and check it fails**

Run: `flutter test test/database/schema_test.dart`
Expected: FAIL. `schemaAt`/`migrateAndValidate(db, 2)` fail because version 2 does not exist yet.

- [ ] **Step 3: Remove the catalog code and bump the schema.** Delete the files listed above and their exports, the `MokuroCatalogs` table, the `AppStore` catalog methods (`catalogs`, `catalogUrlTaken`, `nextCatalogOrder`, `putCatalog`, `replaceCatalogs`, `deleteCatalog`, `_catalogCompanion`) and the `AppModel` ones (`mokuroCatalogs`, `updateCatalogsOrder`, `deleteCatalog`, `addCatalog`, `catalogUrlHasDuplicate`, plus anything else that only served them). Strip `ReaderMokuroSource` as described in Interfaces, and drop the dark-theme switch from `settings_page.dart`. Delete i18n keys that no longer have a caller: check each of `catalog_delete_confirmation`, `pick_file`, `open_url`, `catalogs`, `url`, `duplicate_catalog`, `no_catalogs_listed`, `invalid_mokuro_file`, `create_catalog` with `grep -rn "t\.<key>\b" lib`, plus any key only the deleted pages used. Then `dart run slang`. Set `schemaVersion => 2` and add to `MigrationStrategy`:

```dart
onUpgrade: (m, from, to) async {
  if (from < 2) {
    await customStatement('DROP TABLE IF EXISTS mokuro_catalog');
    await customStatement(
        "DELETE FROM media_item WHERE media_source_identifier = 'reader_mokuro'");
    await customStatement("DELETE FROM preference WHERE key IN "
        "('reader_mokuro/use_dark_theme', "
        "'reader_mokuro/extend_page_beyond_navbar')");
  }
},
```

`foreign_keys` is on for every connection (`configureConnection`), so the stash rows cascade. If drift runs `onUpgrade` with foreign keys off, delete `stash_item` rows of those media items explicitly first. Update the class doc of `AppDatabase` to say version 2 dropped the mokuro catalogs and old volumes. Remove the DEBT.md entry.

- [ ] **Step 4: Regenerate**

Run: `dart run build_runner build --delete-conflicting-outputs && dart run drift_dev schema dump lib/src/database/app_database.dart drift_schemas/ && dart run drift_dev schema generate drift_schemas/ test/database/generated/`
Expected: `drift_schemas/drift_schema_v2.json` and `test/database/generated/schema_v2.dart` exist, and `drift_schema_v1.json` is unchanged (`jj diff --stat drift_schemas/drift_schema_v1.json` empty).

- [ ] **Step 5: Run the tests and analyzer**

Run: `flutter test && flutter analyze`
Expected: all pass; "No issues found!"

- [ ] **Step 6: Commit** with message `Remove the legacy mokuro reader and its catalogs`.

---

### Task 2: Parse `.mokuro` files and import volumes from archives

**Files:**
- Create: `lib/src/media/sources/mokuro_volume.dart`, `lib/src/media/sources/mokuro_import.dart`
- Modify: `lib/media.dart` (exports)
- Test: `test/media/mokuro_volume_test.dart`, `test/media/mokuro_import_test.dart`

**Interfaces:**
- Produces, in `mokuro_volume.dart`:
  - `class MokuroVolume` with `MokuroVolume.parse(String json)`, which throws `FormatException` when `title`, `volume` or `volume_uuid` is not a string, `volume_uuid` is not `^[A-Za-z0-9-]+$`, `pages` is not a non-empty list, or a page lacks a string `img_path` or int `img_width`/`img_height`. Unknown keys are ignored, and blocks are not parsed in Dart.
  - Fields: `final String title`, `final String volume`, `final String volumeUuid`, `final List<MokuroPage> pages`.
  - `String get displayTitle`: `volume` when it already contains `title`, else `'$title $volume'`.
  - `class MokuroPage { final String imgPath; final int width; final int height; }`
- Produces, in `mokuro_import.dart`:
  - `class MokuroImportParams { const MokuroImportParams({required this.archivePath, required this.volumesDirectory}); final String archivePath; final String volumesDirectory; }`
  - `class MokuroImportResult { final String volumeUuid; final String title; final int pageCount; final int missingPages; final String directory; final String? coverPath; }`. `title` is `displayTitle`; `coverPath` is the absolute path of page 0's image, or null if it is missing.
  - `enum MokuroImportError { notAnArchive, noOcr, severalOcr, invalidOcr }`
  - `class MokuroImportException implements Exception { MokuroImportException(this.error, [this.detail]); final MokuroImportError error; final String? detail; }`
  - `MokuroImportResult importMokuroVolume(MokuroImportParams params)`: top-level, for `compute`.
  - `String? resolveImageEntry(String imgPath, Set<String> fileEntries)`: the archive entry for a page, or null.
  - Volume layout on disk: `<volumesDirectory>/<volumeUuid>/volume.mokuro` (the OCR bytes as is) and `<volumesDirectory>/<volumeUuid>/images/<imgPath>` (each page's image under its `img_path`).

- [ ] **Step 1: Write the failing parsing tests** (`mokuro_volume_test.dart`):
  - `parse` reads the mokuro tool's sample `../mokuro/tests/data/expected_results/test0/vol1.mokuro`, copied to `test/media/fixtures/vol1.mokuro` (commit the copy; the sibling repo is not in CI). Expect `title == 'test0'`, `volume == 'vol1'`, `pages.first.imgPath == '000a.jpg'`, `pages.length` equal to the sample's page count, and `displayTitle == 'test0 vol1'`.
  - `displayTitle` is `'[赤坂アカ×横槍メンゴ] 【推しの子】 01'` for title `'【推しの子】'` and that volume name. It contains the title.
  - `parse` throws `FormatException` for: `'[]'`; a missing `volume_uuid`; `volume_uuid: '../x'`; `pages: []`; a page without `img_path`.
  - `parse` ignores `ocr_engine` and unknown keys.

- [ ] **Step 2: Run them and check they fail**

Run: `flutter test test/media/mokuro_volume_test.dart`
Expected: FAIL, `MokuroVolume` is not defined.

- [ ] **Step 3: Implement `mokuro_volume.dart`** and export it from `lib/media.dart`.

- [ ] **Step 4: Run them and check they pass.** Same command, expected PASS.

- [ ] **Step 5: Write the failing import tests** (`mokuro_import_test.dart`). Build archives in a temp directory with `ZipFileWriterSync` (`create`, `writeData`, `close`), using tiny byte strings as image data. Cases:
  - **OCR beside, tool layout:** `vol1.cbz` holds `vol1/000a.jpg` and `vol1/000b.jpg`, with `vol1.mokuro` beside it whose `img_path`s are `000a.jpg` and `000b.jpg`. Result: `pageCount 2`, `missingPages 0`, files at `<dir>/images/000a.jpg`, `<dir>/volume.mokuro` byte-identical to the source, and `coverPath` ending in `images/000a.jpg`.
  - **OCR beside, bunko layout:** the entries are `【推しの子】 01/00001.webp`, and `img_path` is `【推しの子】 01/00001.webp`. The image ends up at `<dir>/images/【推しの子】 01/00001.webp`.
  - **OCR inside:** `v.zip` contains `v.mokuro` and `001.jpg` at the root, with nothing beside it. The import succeeds.
  - **Beside wins over inside:** both exist with different titles, and the result's title is the one beside.
  - **No OCR** throws `MokuroImportException` with `noOcr`. **Two `.mokuro` inside, none beside** throws `severalOcr`. **Not a zip** (a text file named `x.cbz`) throws `notAnArchive`. **Invalid JSON** throws `invalidOcr`. In each failure case `volumesDirectory` stays empty.
  - **Missing pages:** a page whose image is absent gives `missingPages 1`, and the import still succeeds.
  - **Re-import** replaces the directory: an old stray file in `<dir>/images/` is gone afterwards.
  - **Path safety:** `img_path` `../evil.jpg` counts as missing, and nothing is written outside `<dir>`.
  - `resolveImageEntry`: `('a.jpg', {'a.jpg'})` gives `'a.jpg'`; `('a.jpg', {'vol/a.jpg', 'vol/b.jpg'})` gives `'vol/a.jpg'` (single top folder); `('a.jpg', {'x/a.jpg', 'y/b.jpg'})` gives null; `('../a.jpg', {'a.jpg'})` gives null.

- [ ] **Step 6: Run them and check they fail.** Run: `flutter test test/media/mokuro_import_test.dart`. Expected: FAIL, the symbols are undefined.

- [ ] **Step 7: Implement `mokuro_import.dart`.** Approach:
  - Open the archive with `ZipFileReaderSync`. A `ZipException` on open becomes `notAnArchive`.
  - Find the OCR: the sibling `p.setExtension(archivePath, '.mokuro')` if it exists, else the archive's `.mokuro` entries (exactly one).
  - Parse the OCR with `MokuroVolume.parse`. A `FormatException` becomes `invalidOcr`.
  - Extract into `<volumesDirectory>/<uuid>.importing` (deleted first if present): each page's `resolveImageEntry` to `images/<imgPath>`, and the OCR to `volume.mokuro`.
  - Delete any existing `<uuid>` directory, then rename `.importing` to `<uuid>`.
  - Remove `.importing` on any failure.
  - `resolveImageEntry` normalises with `p.posix.normalize` and rejects absolute paths and `..` segments. It tries the archive root first, then the single top-level folder if every file entry shares one.

- [ ] **Step 8: Run all tests and the analyzer.** Run: `flutter test && flutter analyze`. Expected: PASS; no issues.

- [ ] **Step 9: Commit** with message `Import mokuro volumes from archives`.

---

### Task 3: The reader page, with block-level text and a desktop debug mode

**Files:**
- Create: `assets/manga-reader/index.html`, `assets/manga-reader/reader.css`, `assets/manga-reader/reader.js`
- Modify: `pubspec.yaml` (asset entry `- assets/manga-reader/`, with a comment that the page is hand-written, no build)

**Interfaces:**
- Produces the page contract that Tasks 4, 5 and 7 rely on:
  - **URL:** `https://appassets.androidplatform.net/manga/index.html?page=<int>&theme=<light|dark>`. The page fetches the volume from `../volume/volume.mokuro` and its images from `../volume/images/<img_path>`, each path segment `encodeURIComponent`-ed.
  - **Protocol version:** `export const PROTOCOL_VERSION = 1` in `reader.js`.
  - **Events,** sent with `window.flutter_inappwebview.callHandler('mokuroHost', message)`:
    - `{type:'ready', protocolVersion}`, once the volume is parsed;
    - `{type:'page', pages:[int…], count:int}` on every change of the pages shown (ascending indices), including the first render;
    - `{type:'tap', text, offset, page, x, y}` for a tap on a block's character: `text` is the block's processed lines joined with no separator, `offset` the UTF-16 index of the tapped character in it, `page` the block's page index, and `x`/`y` the tap in WebView logical pixels;
    - `{type:'tap', text:'', offset:-1, page:-1, x, y}` for a dismiss (a tap on no block while a block is shown);
    - `{type:'menu'}` for a tap on no block in the middle half of the width while no block is shown.
  - **Commands,** on `window.mokuroHost`, each `async` and returning `undefined` unless stated: `nextPage()`, `prevPage()` (in reading order), `goToPage({page})`, `highlight({start, length})` (selects that range of the shown block's joined text), `clearOverlay()` (hides the shown block and clears the selection), `getSelectedText()` (returns the selection without line breaks, trimmed).
  - **Debug mode:** without `window.flutter_inappwebview` and with `debug=1` in the query, events go to `console.log('mokuroHost', message)`. `window.mokuroHost` is still installed.

- [ ] **Step 1: Prepare the desktop harness** (not committed). Run:

```sh
D=/tmp/claude-1000/-home-blastrock-work-yomimoto/377e94d8-6ea9-48ff-931c-7cefdf888011/scratchpad
mkdir -p $D/serve/volume/images && ln -sfn /home/blastrock/work/yomimoto/assets/manga-reader $D/serve/manga
unzip -oq "$D/qa/[赤坂アカ×横槍メンゴ] 【推しの子】 01.cbz" -d $D/serve/volume/images
command cp -f "$D/qa/[赤坂アカ×横槍メンゴ] 【推しの子】 01.mokuro" $D/serve/volume/volume.mokuro
```

Then run `python3 -m http.server 8765 -d $D/serve` in the background. If the QA files are gone, re-download them through the manifest API (the spec's catalog findings give the requests).

- [ ] **Step 2: Implement the page** in `reader.js` (an ES module loaded by `index.html`) and `reader.css`:
  - **Rendering:** each page is a `div` sized to `img_width`×`img_height` image px. It holds an `img` filling it; on a load error the `img` is hidden and the box stays blank. It also holds one absolutely positioned block `div` per OCR block at `box`, with `writing-mode: vertical-rl` when `vertical`, `font-size: <font_size>px`, `line-height: 1.1em` and `white-space: nowrap`, and one `span` per line inside a `p`. Text and background are transparent unless the block has `.shown`, which gives an opaque background (white with black text, or black with white text when `theme=dark`). Use the font stack `'Noto Sans JP', 'Noto Sans CJK JP', sans-serif`.
  - **Spreads:** in portrait (`matchMedia('(orientation: portrait)')`), one page per screen. In landscape, `[0]`, `[1,2]`, `[3,4]`…, and a lone last page alone. Within a spread the lower index is on the right. The spread is scaled with a CSS transform to fit the viewport and centred, with the page background from `theme`. On `resize`, re-pair around the current lowest shown page and send `page` only if the pages changed.
  - **Viewport meta:** `width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=5`.
  - **Taps,** on `click`:
    - If a block is shown and the tap hits no block, dismiss.
    - Else, if `document.caretRangeFromPoint` lands in a block's text, show that block (hiding any other) and send `tap`.
    - Else, if `x < 25%` of the width, go to the next page (right to left); if `x > 75%`, the previous page; otherwise send `menu`.
    - `x`/`y` are `(clientX - visualViewport.offsetLeft) * visualViewport.scale`, and the same for `y`.
  - **Swipes:** a single-finger `touchend` with `|dx| > 50px` and `|dx| > 2|dy|`, while `visualViewport.scale < 1.01`, turns the page. `dx > 0` goes to the next page.
  - **Long-press selection:** on `selectionchange` with a non-collapsed selection inside a block, give that block `.shown`.
  - **Text:** apply mokuro-reader's ellipsis rule to every line before rendering (`...` and `．．．` become `…`; Task 4 replaces this with the ported `processLine`). The `text`/`offset` of a tap and the `highlight` ranges index this processed joined text, mapped to (line span, offset) when building DOM ranges.

- [ ] **Step 3: Check in a desktop browser.** Open `http://localhost:8765/manga/index.html?page=0&debug=1` in Chrome with mobile emulation in portrait (DevTools device toolbar), then:
  - Page 0 shows alone with the console showing `ready` and then `page {pages:[0], count:224}`.
  - Clicking the left quarter shows page 1 (`page` event). The right quarter goes back.
  - Clicking a speech bubble's text makes it visible and logs a `tap` whose `text` is the bubble's lines and whose `offset` matches the clicked character.
  - `await mokuroHost.highlight({start:0, length:2})` selects the first two characters of that bubble.
  - Clicking empty space dismisses (logs a dismiss tap). Clicking the middle again logs `menu`.
  - Switching to landscape shows `[1,2]` from page 1, with page 1 on the right. Back in portrait it shows page 1 (Review Focus 4).
  - In the console, find a line containing `…` in the volume, or edit `volume.mokuro` to put `...` in a bubble. Its tap `text` contains `…`, and `highlight` over it selects the right characters (Review Focus 5).

- [ ] **Step 4: Commit** with message `Add the manga reader page`.

---

### Task 4: Align the overlay on the printed lines with mokuro-reader's layout

**Files:**
- Create: `tool/port_mokuro_layout.sh`, `assets/manga-reader/mokuro-layout.js` (generated by the script)
- Modify: `assets/manga-reader/reader.js`

**Interfaces:**
- Consumes: the page structure from Task 3.
- Produces: `mokuro-layout.js`, an ES module exporting `layoutLines`, `processLine`, `getDefaultMeasurer` and `lineTransform`, unchanged from mokuro-reader `bfaeb482` `src/lib/reader/{line-coords-layout,line-grid,glyph-insets}.ts`.

- [ ] **Step 1: Write `tool/port_mokuro_layout.sh <mokuro-reader checkout>`.** It:
  - copies the three `.ts` files into a temp directory;
  - writes a stub `fonts-ready.ts` there exporting `currentFontLoadEpoch = () => 0`;
  - writes an entry file re-exporting the four names;
  - runs `pnpm dlx esbuild@0.24.2 <entry> --bundle --format=esm --outfile=assets/manga-reader/mokuro-layout.js`;
  - prepends a header: the GPL-3.0 notice, the source repository, the files, the commit (`git -C <checkout> rev-parse --short HEAD`), and "generated by tool/port_mokuro_layout.sh, do not edit".

  It fails (`set -euo pipefail`) if the checkout's HEAD is not `bfaeb482` unless `--any-ref` is given.

- [ ] **Step 2: Run it**

Run: `tool/port_mokuro_layout.sh ../mokuro-reader`
Expected: `assets/manga-reader/mokuro-layout.js` exists, starts with the header, and `node --input-type=module -e "import('./assets/manga-reader/mokuro-layout.js').then(m => console.log(Object.keys(m).sort().join()))"` prints `getDefaultMeasurer,layoutLines,lineTransform,processLine`.

- [ ] **Step 3: Use it in `reader.js`.** Replace the ellipsis rule with `processLine`. For each block with `lines_coords`, call `layoutLines(block, processed, getDefaultMeasurer())`. When it returns layouts, give each line span `font-size`, `letter-spacing`, its target and inset as data, hide `hidden` lines (they keep their text in the joined string, so offsets do not shift: render them with `display:none` spans), give `wrap` lines their width and height, and once laid out (`requestAnimationFrame`, and again after `document.fonts.ready`) set each span's `transform`/`transform-origin` from `lineTransform({natural, target, box, inset, rotation, vertical})`, measured as mokuro-reader's `positionPerLine` does (`offsetLeft`/`offsetTop`/`offsetWidth`/`offsetHeight`, all spans read before any is written). When it returns null, keep Task 3's block layout. Measure only while the block is laid out: blocks are always laid out (transparent, not `display:none`), so a single pass after render suffices.

- [ ] **Step 4: Check in the desktop harness.** Reload the page from Task 3's harness, with a temporary debug toggle `?debug=1&showall=1` that adds `.shown` to every block. The overlay text sits on the printed text across the first ten pages, with vertical punctuation (ー, 「」, 、, 。) upright or turned as printed, and taps and `highlight` still behave as in Task 3, Step 3.

- [ ] **Step 5: Commit** with message `Align the manga overlay with mokuro-reader's line layout`.

---

### Task 5: Serve the reader to a WebView and define the bridge

**Files:**
- Create: `lib/src/media/sources/mokuro_asset_path_handler.dart`, `lib/src/media/sources/mokuro_volume_path_handler.dart`, `lib/src/media/sources/mokuro_bridge.dart`
- Modify: `lib/media.dart`
- Test: `test/media/mokuro_volume_path_handler_test.dart`, `test/media/mokuro_bridge_test.dart`

**Interfaces:**
- Consumes: the page contract (Task 3) and the volume layout (Task 2).
- Produces:
  - `class MokuroAssetPathHandler extends CustomPathHandler`, at path `/manga/`, serving `assets/manga-reader/<path>` like `TtuAssetPathHandler` does (no extension fallbacks).
  - `class MokuroVolumePathHandler extends CustomPathHandler`, at path `/volume/`, with `MokuroVolumePathHandler(this.directory)` and `static File? volumeFile(Directory directory, String path)`. It answers every `/volume/` path itself, 404 when `volumeFile` is null or missing, as `TtuImportPathHandler` does.
  - `class MokuroBridge` with `MokuroBridge({required this.controller, this.onReady, this.onTap, this.onPage, this.onMenu})` registering handler `mokuroHost`, and `static const int protocolVersion = 1`. Commands: `Future<void> nextPage()`, `prevPage()`, `goToPage(int page)`, `highlight({required int start, required int length})`, `clearOverlay()`, `Future<String> getSelectedText()`. Errors and timeouts become `MokuroBridgeException(command, message)`, with a 10 s timeout, as `TtuBridge`.
  - Event classes with `fromJson`:
    - `MokuroReadyEvent { int protocolVersion; bool get isCompatible; }`
    - `MokuroTapEvent { String text; int offset; int page; int x; int y; bool get isDismiss; }`, where `isDismiss` is `offset < 0 || text.isEmpty`
    - `MokuroPageEvent { List<int> pages; int count; int get last; }`, where `last` is the highest index shown
  - `menu` calls `onMenu()`.

- [ ] **Step 1: Write the failing tests.**
  - Path handler: `volumeFile(dir, 'volume.mokuro')` gives `<dir>/volume.mokuro`. `volumeFile(dir, 'images/[赤坂アカ×横槍メンゴ] 【推しの子】 01/00001.webp')` gives that file, with the path not decoded again. Names with `%`, `#` and `+` resolve as is. `''`, `'../x'`, `'images/../../x'`, `'/etc/passwd'` and `'images/'` give null (Review Focus 1).
  - Bridge events: `MokuroTapEvent.fromJson({'type':'tap','text':'あい','offset':1,'page':3,'x':10.6,'y':20.2})` has `offset 1`, `page 3`, `x 11`, `y 20`, `isDismiss false`. The dismiss form has `isDismiss true`. `MokuroPageEvent.fromJson({'pages':[5,6],'count':200}).last == 6`. `MokuroReadyEvent.fromJson({'protocolVersion':1}).isCompatible` is true, and with 2 it is false.

- [ ] **Step 2: Run them and check they fail.** Run: `flutter test test/media/mokuro_volume_path_handler_test.dart test/media/mokuro_bridge_test.dart`. Expected: FAIL, undefined.

- [ ] **Step 3: Implement the three files** and export them.

- [ ] **Step 4: Run all tests and the analyzer.** Run: `flutter test && flutter analyze`. Expected: PASS; no issues.

- [ ] **Step 5: Commit** with message `Serve the manga reader and add its bridge`.

---

### Task 6: The Manga library: import, list, delete

**Files:**
- Create: `lib/src/utils/misc/run_with_progress.dart` (moved out of `ReaderTtuSource`)
- Modify: `lib/utils.dart`; `lib/src/media/sources/reader_ttu_source.dart` (call the moved function); `lib/src/media/sources/reader_mokuro_source.dart`; `lib/src/pages/implementations/reader_mokuro_history_page.dart`; `lib/i18n/strings.i18n.json` + `strings.g.dart`
- Test: `test/media/reader_mokuro_source_test.dart`

**Interfaces:**
- Consumes: `importMokuroVolume`, `MokuroImportParams`, `MokuroImportResult`, `MokuroImportException`, `MokuroImportError` (Task 2).
- Produces:
  - `Future<T?> runWithProgress<T>({required BuildContext context, required String message, required Future<T> Function() task})`, top-level, same behaviour as today. Keep the `TtuBridgeException` special case.
  - On `ReaderMokuroSource`:
    - `Directory volumesDirectory(AppModel appModel)`, which is `<appDirectory>/mangaVolumes`;
    - `Directory volumeDirectory(AppModel appModel, MediaItem item)`, which is `<volumesDirectory>/<item.mediaIdentifier>`;
    - `static MediaItem volumeItem({required MokuroImportResult result, MediaItem? existing})`, giving `mediaIdentifier: result.volumeUuid`, `title: result.title`, `imageUrl: 'file://${result.coverPath}'` or null, `position: existing?.position ?? 0`, `duration: result.pageCount`, `canDelete: false`, `canEdit: true`, and `id`/`overrideTitle` from `existing`;
    - `Future<void> importVolume({required BuildContext context, required AppModel appModel})`;
    - `Future<bool> deleteVolume({required BuildContext context, required AppModel appModel, required MediaItem item})`.
  - New i18n keys:
    - `manga_import_volume`: "Import volume"
    - `manga_importing`: "Importing volume…"
    - `manga_no_volumes_added`: "No volumes yet: import a CBZ or ZIP processed by mokuro"
    - `manga_import_no_ocr`: "No .mokuro file next to or inside this archive"
    - `manga_import_several_ocr`: "This archive holds several .mokuro files"
    - `manga_import_invalid_ocr`: "The .mokuro file could not be read"
    - `manga_import_not_archive`: "This file is not a CBZ or ZIP archive"
    - `manga_import_missing_pages(n)`: "Imported, but {n} pages are missing"
    - `manga_delete_volume_confirm`: "Delete this volume, its reading position and its stash?"

- [ ] **Step 1: Write the failing test** (`reader_mokuro_source_test.dart`):
  - `volumeItem(result: r, existing: null)` has `position 0`, `duration r.pageCount`, `mediaSourceIdentifier 'reader_mokuro'`, `mediaIdentifier r.volumeUuid` and `imageUrl 'file://<cover>'`.
  - With `existing` (id 7, position 42, overrideTitle 'Mine'), the result keeps `id 7`, `position 42` and `overrideTitle 'Mine'`, and takes the new title and duration (Review Focus 3).
  - A null `coverPath` gives a null `imageUrl`.

- [ ] **Step 2: Run it and check it fails.** Run: `flutter test test/media/reader_mokuro_source_test.dart`. Expected: FAIL.

- [ ] **Step 3: Implement.**
  - **Move `runWithProgress`.**
  - **`importVolume`:**
    - Open `FilesystemPicker.open` with `allowedExtensions: ['.cbz', '.zip']`, `rootDirectories` from `getFilePickerDirectoriesForMediaSource(this)`, and the picker settings the old `launchFilePicker` used, then remember the directory with `setLastPickedDirectory`.
    - Run `compute(importMokuroVolume, MokuroImportParams(...))` inside `runWithProgress(message: t.manga_importing)`.
    - Map a `MokuroImportException` to its toast instead of the error dialog: catch it inside the task and return null.
    - On success, `putMediaItem(volumeItem(result: r, existing: <history item with that mediaIdentifier>))`, a `missingPages` toast when it is non-zero, and `refreshTab()`.
  - **`deleteVolume`:** a confirmation dialog like `ReaderTtuSource.deleteBook`, then `appModel.deleteMediaItem(item)` and delete `volumeDirectory`. Override `onMediaItemClear` to delete the directory too.
  - **`getActions`:** an import button (icon `Icons.add`, tooltip `t.manga_import_volume`).
  - **`buildHistoryPage`:** like `ReaderTtuSourceHistoryPage`. Keep `showProgress` true. `extraActions` gives a Stash button (`StashPage(item: item)`) and a Delete button calling `deleteVolume`. The placeholder message is `t.manga_no_volumes_added`.
  - Keep `buildLaunchPage` throwing until Task 7.
  - Remove the old `getMediaSourceHistory`-based dedup code if any is left.

- [ ] **Step 4: Run all tests and the analyzer.** Run: `flutter test && flutter analyze`. Expected: PASS; no issues.

- [ ] **Step 5: Check on the emulator.** Push the QA files with `adb -s emulator-5554 push "<qa>/[赤坂アカ×横槍メンゴ] 【推しの子】 01.cbz" "<qa>/[赤坂アカ×横槍メンゴ] 【推しの子】 01.mokuro" /sdcard/Download/`, where `<qa>` is the scratchpad `qa/` directory. Run `ANDROID_HOME=/home/blastrock/android/android-sdk-linux flutter run -d emulator-5554`, then on the Manga tab:
  - Import the `.cbz`. The volume appears with its cover and the title `[赤坂アカ×横槍メンゴ] 【推しの子】 01`.
  - Import again: still one entry.
  - Long-press and Delete: it is gone, and so is its directory (`adb shell run-as org.kaqui.yomimoto ls files/` or the app directory's actual location).
  - Import a non-archive renamed `.cbz`: a toast, no entry.

- [ ] **Step 6: Commit** with message `Add the Manga library and volume import`.

---

### Task 7: The reader screen

**Files:**
- Create: `lib/src/pages/implementations/reader_mokuro_source_page.dart`, `lib/src/pages/implementations/mokuro_reader_bar.dart`
- Modify: `lib/pages.dart`; `lib/src/media/sources/reader_mokuro_source.dart` (`buildLaunchPage`, `peek`, `webViewSettings`)

**Interfaces:**
- Consumes: `MokuroBridge` and its events (Task 5), the handlers (Task 5), and `volumeDirectory` (Task 6).
- Produces:
  - `class ReaderMokuroSourcePage extends BaseSourcePage` with `const ReaderMokuroSourcePage({required MediaItem super.item, this.peekPage, super.key})` and `final int? peekPage`.
  - `class MokuroReaderBar extends StatelessWidget` with `MokuroReaderBar({required int firstShown, required int lastShown, required int count, required VoidCallback onHide, required VoidCallback onNext, required VoidCallback onPrevious, required ValueChanged<int> onGoTo})`.
  - On `ReaderMokuroSource`: `InAppWebViewSettings webViewSettings(Directory volume)`, giving an asset loader with `[MokuroAssetPathHandler(), MokuroVolumePathHandler(volume)]`, `supportZoom: true`, `builtInZoomControls: true` and `displayZoomControls: false`. Also `Future<void> peek({required WidgetRef ref, required AppModel appModel, required MediaItem item, required int position})`, which works like `ReaderTtuSource.peekBook` and passes `peekPage` to the page.

- [ ] **Step 1: Implement `ReaderMokuroSourcePage`**, modelled on `ReaderTtuSourcePage` (focus and volume keys, `PopScope`, the recursive-search immersive-mode dance, the context menu with search, copy, share and creator, and `onCreatorClose`). Differences:
  - **Load:** `initState` calls `appModelNoUpdate.putMediaItem(item)` unless peeking. The WebView loads `ReaderTtuSource.origin` + `/manga/index.html?page=<peekPage ?? item.position>&theme=<dark|light from Theme.of(context).brightness>`. The scaffold background is the theme's background; there is no `SafeArea` top inset.
  - **`onReady`:** show the `ttu_bridge_mismatch` snackbar when the protocol versions differ. Do not rename the key; it says "reader build", which fits.
  - **`onPage`:** keep `_shown`/`_count` for the bar. Unless peeking, set `item.position = event.last`, `item.duration = event.count` and call `appModel.updateMediaItem(item)`. If the zoom scale is above 1.01, `controller.zoomBy(zoomFactor: 0.01, animated: false)`. Track the scale with `onZoomScaleChanged`.
  - **`onTap`:** popup position, lone-surrogate fix, `getGuessHighlightLength`, `bridge.highlight` (wrapped in `emptyContextMenu` as `_highlight` is in ttu), `searchDictionaryResult`, `getFinalHighlightLength`, and highlight again, all as in ttu. Then `mediaSource.setCurrentSentence(selection: JidoujishoTextSelection(text: event.text, range: TextRange(start: start, end: start + length)), position: event.page)` and `mediaSource.setExtraData(<the page's img_path>)`. The page reads `img_path` from a `MokuroVolume` parsed once at open from `<volume>/volume.mokuro`. A dismiss clears the result, the sentence and the overlay.
  - **`onMenu`:** toggle `MokuroReaderBar` over the WebView (a `Stack` child at the top).
  - **`clearDictionaryResult`:** also `bridge.clearOverlay()`.
  - **Volume keys:** `bridge.nextPage()`/`prevPage()`, honouring the inverted setting as ttu does.

- [ ] **Step 2: Implement `MokuroReaderBar`.** A bar with:
  - a hide button;
  - previous and next buttons, placed for right-to-left reading: next on the left;
  - a `Slider` over `0…count-1`, inside `Directionality(textDirection: TextDirection.rtl)` so page 0 is at the right end;
  - the label `'${first + 1} / $count'`, or `'${first + 1}–${last + 1} / $count'` for a spread.

  Moving the slider calls `onGoTo(value.round())` on `onChangeEnd`. Colours come from the theme. No animation.

- [ ] **Step 3: Wire the source.** `buildLaunchPage` returns `ReaderMokuroSourcePage(item: item!, peekPage: _peekPage)`. `peek` mirrors `peekBook`.

- [ ] **Step 4: Run the tests and the analyzer.** Run: `flutter test && flutter analyze`. Expected: PASS; no issues.

- [ ] **Step 5: Check on the emulator** with the imported QA volume:
  - It opens on page 0.
  - A tap on the left edge goes to page 1, the right edge back, and a swipe right goes forward.
  - A tap on a bubble shows its clean text and the popup on the word, with the word highlighted.
  - A tap outside hides both.
  - A middle tap shows the bar. The slider dragged to its left end goes to page 224, and the label reads `224 / 224`.
  - Back, then reopen: same page.
  - Rotate to landscape: a spread, on the same page (Review Focus 4).
  - Long-press a bubble: native selection with the app's menu, and Copy works.
  - Pinch-zoom, then turn the page: back to fit.
  - The volume keys turn pages after a first tap (see `CLAUDE.md`'s quirk).
  - The tile's progress bar is full after reaching the last page.

- [ ] **Step 6: Commit** with message `Add the manga reader screen`.

---

### Task 8: Stash, peek and card images from the manga reader

**Files:**
- Modify: `lib/src/creator/creator_context.dart`; `lib/src/creator/actions/instant_export_action.dart`; `lib/src/creator/actions/card_creator_action.dart`; `lib/src/models/app_model.dart` (`openCreator`); `lib/src/pages/implementations/creator_page.dart`; `lib/src/media/media_source.dart`; `lib/src/media/source_types/reader_media_source.dart`; `lib/src/media/sources/reader_ttu_source.dart` (`peekBook` becomes `peek`); `lib/src/media/sources/reader_mokuro_source.dart`; `lib/src/pages/implementations/stash_item_page.dart`; `lib/src/media/stash_item.dart` and `lib/src/database/tables.dart` (doc comments: the position is "in the source's own units: ttu bookmark units for books, the page index for manga")
- Test: `test/media/reader_mokuro_source_test.dart` (extended)

**Interfaces:**
- Produces:
  - `CreatorContext({required sentence, this.mediaItem, this.imageData})` with `final String? imageData`. It is the media source's data for generating the card image, and `CreatorContext.current` sets it from `appModel.currentMediaSource?.currentExtraData`.
  - On `ReaderMediaSource`: `Future<void> peek({required WidgetRef ref, required AppModel appModel, required MediaItem item, required int position})` (abstract), implemented by both readers.
  - On `MediaSource`: `String? imageDataFor({required AppModel appModel, required MediaItem item, required int position})`, which returns null by default. `ReaderMokuroSource` returns `imagePathOfPage(volumeDirectory(appModel, item), position)`.
  - `static String? imagePathOfPage(Directory volume, int page)` on `ReaderMokuroSource` gives the page's `img_path` from `<volume>/volume.mokuro`, or null when the page is out of range or the file is unreadable.
  - `ReaderMokuroSource.generateImages(...)` copies `<volumeDirectory>/images/<data>` into the preview directory, as the old file branch did.
  - `appModel.openCreator(..., CreatorContext? creatorContext)` passes it to `CreatorPage(creatorContext: …)`.

- [ ] **Step 1: Write the failing test.** `ReaderMokuroSource.imagePathOfPage(Directory volume, int page)` on a volume directory written by Task 2's import in a temp dir: it returns `'000b.jpg'` for page 1, and null for page 99 and for -1.

- [ ] **Step 2: Run it and check it fails.** Run: `flutter test test/media/reader_mokuro_source_test.dart`. Expected: FAIL.

- [ ] **Step 3: Implement.**
  - In `instant_export_action.dart` and `creator_page.dart`, the image override reads `creatorContext.mediaItem` and `creatorContext.imageData` instead of `appModel.getCurrentMediaItem()` and `mediaSource.currentExtraData`. The condition becomes: the context has a media item whose source `overridesAutoImage`. The creator page uses `widget.creatorContext ?? CreatorContext.current(appModel)`.
  - `card_creator_action.dart` passes its `creatorContext` to `openCreator`.
  - `StashItemPage` builds its `CreatorContext` with `imageData: source.imageDataFor(item: widget.mediaItem, position: item.position)`, and `_jump` calls `(widget.mediaItem.getMediaSource(appModel: …) as ReaderMediaSource).peek(…)`.
  - Rename `peekBook` to `peek` (an `@override`).
  - Re-add `generateImages` to `ReaderMokuroSource`.

- [ ] **Step 4: Run all tests and the analyzer.** Run: `flutter test && flutter analyze`. Expected: PASS; no issues.

- [ ] **Step 5: Check on the emulator:**
  - Look up a word in the QA volume and add it to the stash.
  - Make a card from the popup: the image is the page.
  - Close the reader and open the stash from the library: the word is there.
  - Peek: the volume opens on that page. Turn a page, go back and reopen: the saved position is the one from before the peek.
  - Make a card from the stash item: the image is that page, and the sentence is the bubble.
  - A ttu book's stash peek still works.

- [ ] **Step 6: Commit** with message `Stash words and make cards from manga`.

---

### Task 9: Documentation and end-to-end QA

**Files:**
- Modify: `CLAUDE.md`; `docs/TOOLCHAIN.md` (the device-test list mentions "mokuro browse")

- [ ] **Step 1: Update `CLAUDE.md`:**
  - "What this is": the reading item says the manga reader reads mokuro volumes.
  - The `HomeTab` table needs no change.
  - Persistence: drop "mokuro catalogs" from the SQLite list. Say that schema version 2 exists and that its 1 → 2 migration dropped the catalogs and the legacy volumes because installs already held data, and that until 1.0 a schema edit changes the latest version in place unless installed data must be kept.
  - Replace the mokuro reader-internals paragraph with:
    - `assets/manga-reader/` (hand-written, `mokuro-layout.js` generated by `tool/port_mokuro_layout.sh` from mokuro-reader `bfaeb482`);
    - the `/manga/` and `/volume/` handlers;
    - `MokuroBridge` and its protocol version shared with `reader.js`;
    - volumes in `mangaVolumes/<volume_uuid>/` (`volume.mokuro`, `images/<img_path>`) as `media_item` rows keyed by `volume_uuid`, position = page index;
    - import of `.cbz`/`.zip` only, the OCR beside or inside;
    - the desktop debug harness (`?debug=1`, served with `python3 -m http.server`);
    - the stash and peek by page.
  - Commands: add `tool/port_mokuro_layout.sh ../mokuro-reader`.

- [ ] **Step 2: Update `docs/TOOLCHAIN.md`'s device checks** to name the manga reader instead of "mokuro browse".

- [ ] **Step 3: Full QA on the emulator,** from a fresh install (`adb uninstall org.kaqui.yomimoto`, then `flutter run`):
  - Every check of Tasks 6–8 again.
  - Pages whose folder and file names have `【】`, `×`, spaces and brackets all load (Review Focus 1).
  - Import the mokuro tool's sample, `../mokuro/tests/data/expected_results/test0/vol1.mokuro` with its images zipped as `vol1.cbz` beside it (the test data's input images): it opens and taps work.
  - Dark theme: the reader background and overlay follow it.
  - `flutter analyze` and `flutter test` are clean.

  Report anything that fails, with what was seen.

- [ ] **Step 4: Commit** with message `Document the manga reader`.
