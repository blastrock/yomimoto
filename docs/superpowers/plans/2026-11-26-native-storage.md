# Native Storage Access Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Remove the vendored `filesystem_picker`, `external_path` and every storage permission; import manga through the system picker; stage AnkiDroid media in app-private storage shared through narrow FileProvider paths.

**Architecture:** Manga import picks one volume with `file_picker` (multi-select, `FileType.any`), a pure function turns the pick into an archive path plus an optional `.mokuro` path, and `importMokuroVolume` takes that `.mokuro` path explicitly instead of looking beside the archive. AnkiDroid media is staged in one app-private directory; the retry into a second directory goes. The last task moves that directory into the cache and gives each FileProvider its own minimal paths file.

**Tech Stack:** Flutter/Dart, `file_picker` 12.3 (already a dependency), `archive`, Android manifest/FileProvider XML, slang i18n.

**Spec:** `docs/superpowers/specs/2026-11-26-native-storage-design.md`

## Global Constraints

- `flutter analyze` reports no issues, infos included; `flutter test` passes.
- Every public class, member and getter has a `///` doc comment (`public_member_api_docs`).
- Import barrels (`package:yuuna/media.dart`, …), never `lib/src/` files; a new file gets an `export` line in its barrel.
- Toasts through `showToast`; British spelling; format new code by hand to match the file (do not run `dart format` on existing files).
- Strings in `lib/i18n/strings.i18n.json`, then `dart run slang`; commit the regenerated `lib/i18n/strings.g.dart`.
- No new dependency. No migration: the removed preference is pre-1.0 (schema rule in CLAUDE.md, Persistence).
- Internal identifiers keep upstream names (`yuuna`, `Jidoujisho*`, …).
- Commits are jj: `jj describe -m "<message>"` then `jj new`; every message ends with
  `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` and
  `Claude-Session: https://claude.ai/code/session_01HHbqLMnNBCPuxtNcDcKdng`. Do not push or move bookmarks.
- Android builds: `ANDROID_HOME=/home/blastrock/android/android-sdk-linux flutter build apk --debug --target-platform android-x64`; emulator `Pixel_9` (Android 16) has AnkiDroid 2.25.3 with a collection and Yomimoto granted `com.ichi2.anki.permission.READ_WRITE_DATABASE`.

## Review Focus

- Upper-case extensions (`VOL1.CBZ`, `vol1.Mokuro`) must be recognised — pinned in Task 2's tests.
- Cancelling the picker must do nothing: no dialog, no toast — checked on device in Task 3.
- A failed import must still clear the picker's cache copies — `finally` in Task 3, checked on device.
- A `.mokuro` beside the archive but not picked must no longer be found (it was before) — pinned in Task 1's tests.
- AnkiDroid refusing a file must show `error_export_media_ankidroid` once, not retry — Task 4, by reading the code path; no device case (needs a broken AnkiDroid).

---

### Task 1: Import takes the `.mokuro` path explicitly

**Files:**
- Modify: `lib/src/media/sources/mokuro_import.dart` (`MokuroImportParams`, `MokuroImportError` docs, `importMokuroVolume` doc, `_readOcr`)
- Modify: `lib/src/media/sources/mokuro_catalog_download.dart:85-160` (`importArchive` callback)
- Modify: `lib/src/media/sources/reader_mokuro_source.dart:228-250` (`importArchive`)
- Modify: `lib/src/pages/implementations/manga_series_page.dart:210-211`
- Test: `test/media/mokuro_import_test.dart`, `test/media/mokuro_catalog_download_test.dart`

**Interfaces:**
- Produces: `MokuroImportParams({required String archivePath, String? ocrPath, required String volumesDirectory})`; `ocrPath` null means "the only `.mokuro` inside the archive".
- Produces: `downloadCatalogVolumes(..., required Future<void> Function(String archivePath, String ocrPath) importArchive, ...)`, called with the downloaded `volume.cbz` and `volume.mokuro`.
- Produces: `ReaderMokuroSource.importArchive({required AppModel appModel, required String archivePath, String? ocrPath})`.

- [ ] **Step 1: Update the tests**

In `mokuro_import_test.dart`: `beside(name, contents)` becomes `String ocrFile(String name, String contents, {Directory? directory})`, writing into `directory ?? sources` and returning the path; `import(String archivePath, {String? ocrPath})`. Existing tests that used `beside` pass the returned path as `ocrPath`. Rename and add:

```dart
test('imports the mokuro tool layout, OCR given', ...)          // was "OCR beside the archive"
test('prefers the given OCR to the one inside', ...)            // was "prefers the OCR beside…"
test('refuses an archive with several OCR files and none given', ...)
test('reads the given OCR from another directory', () {
  String path = archive('vol1.cbz', {'001.jpg': 'x'});
  Directory elsewhere = Directory(p.join(root.path, 'elsewhere'))..createSync();
  String ocrPath = ocrFile('picked.mokuro', ocr(['001.jpg']), directory: elsewhere);
  expect(import(path, ocrPath: ocrPath).missingPages, 0);
});
test('ignores a .mokuro beside the archive when none is given', () {
  String path = archive('vol1.cbz', {'001.jpg': 'x'});
  ocrFile('vol1.mokuro', ocr(['001.jpg']));
  expect(() => import(path), failsWith(MokuroImportError.noOcr));
});
```

In `mokuro_catalog_download_test.dart`, every `importArchive` callback takes `(archive, ocr)`; the importing test calls `importMokuroVolume(MokuroImportParams(archivePath: archive, ocrPath: ocr, volumesDirectory: volumes.path))`, and one test asserts `p.basename(ocr) == 'volume.mokuro'` and `p.dirname(ocr) == p.dirname(archive)`.

- [ ] **Step 2: Run the tests, expect compile failure**

Run: `flutter test test/media/mokuro_import_test.dart test/media/mokuro_catalog_download_test.dart`
Expected: FAIL — `ocrPath` is not a parameter; the callback arity does not match.

- [ ] **Step 3: Implement**

`_readOcr(String? ocrPath, Map<String, ArchiveFile> files)`: read `ocrPath` when given, else the single `.mokuro` inside as today. Docs: `noOcr` = "No `.mokuro` file was given and the archive holds none."; `severalOcr` = "No `.mokuro` file was given and the archive holds several."; `importMokuroVolume`'s doc says its OCR is `ocrPath`, else the only `.mokuro` inside. `downloadCatalogVolumes` passes `p.join(directory.path, 'volume.mokuro')`; `ReaderMokuroSource.importArchive` forwards `ocrPath`; `manga_series_page.dart` passes both paths. Update `importArchive`'s doc (no "beside it").

- [ ] **Step 4: Run tests and analyzer**

Run: `flutter test && flutter analyze`
Expected: all pass, "No issues found!"

- [ ] **Step 5: Commit** — `Take the volume's .mokuro path explicitly`

---

### Task 2: The pick rule

**Files:**
- Create: `lib/src/media/sources/mokuro_pick.dart`
- Modify: `lib/media.dart` (export it, alphabetical among the `mokuro_*` lines)
- Test: `test/media/mokuro_pick_test.dart`

**Interfaces:**
- Produces:
  ```dart
  /// The files of one volume, as picked for an import.
  class MokuroPick {
    const MokuroPick({required this.archivePath, this.ocrPath});
    final String archivePath;
    final String? ocrPath;
  }
  /// [files] (each file's original name and its local copy's path) as one
  /// volume: one archive (`.cbz`, `.zip`) alone, or with one `.mokuro`, in
  /// any order and whatever their names. Null for anything else, or when a
  /// file has no local path.
  MokuroPick? mokuroPickOf(List<({String name, String? path})> files)
  ```
  Extensions are compared case-insensitively on `name`.

- [ ] **Step 1: Write the failing tests**

```dart
({String name, String? path}) f(String name) => (name: name, path: '/c/$name');

test('an archive alone', () => expect(mokuroPickOf([f('v.cbz')]), isA<MokuroPick>()
    .having((x) => x.archivePath, 'archive', '/c/v.cbz').having((x) => x.ocrPath, 'ocr', isNull)));
test('an archive and a .mokuro, either order, any names', ...)   // [f('a.mokuro'), f('b.zip')] → archive /c/b.zip, ocr /c/a.mokuro
test('upper-case extensions', ...)                                // [f('V.CBZ'), f('V.Mokuro')] → pair
test('refuses a .mokuro alone', ...)                              // isNull
test('refuses two archives', ...)                                 // [f('a.cbz'), f('b.zip')] → isNull
test('refuses two .mokuro files with an archive', ...)            // isNull
test('refuses another file', ...)                                 // [f('v.cbz'), f('notes.txt')] → isNull
test('refuses more than two files', ...)                          // [f('v.cbz'), f('v.mokuro'), f('w.mokuro')] → isNull
test('refuses nothing picked', ...)                               // [] → isNull
test('refuses a file without a local path', ...)                  // [(name: 'v.cbz', path: null)] → isNull
```

- [ ] **Step 2: Run, expect failure**

Run: `flutter test test/media/mokuro_pick_test.dart`
Expected: FAIL — `mokuroPickOf` undefined.

- [ ] **Step 3: Implement `mokuroPickOf` in `mokuro_pick.dart`**

- [ ] **Step 4: Run tests and analyzer**

Run: `flutter test test/media/mokuro_pick_test.dart && flutter analyze`
Expected: PASS, "No issues found!"

- [ ] **Step 5: Commit** — `Add the manga import's pick rule`

---

### Task 3: Manga import through the system picker

**Files:**
- Modify: `lib/src/media/sources/reader_mokuro_source.dart` (`importVolume`, `importErrorMessage`)
- Modify: `lib/src/models/app_model.dart:2006-2056` (delete `getLastPickedDirectory`, `setLastPickedDirectory`, `getFilePickerDirectoriesForMediaSource`)
- Modify: `lib/src/preferences/preferences.dart:80-86` (delete `lastPickedDirectory` and its `// Files.` heading)
- Modify: `lib/i18n/strings.i18n.json`, regenerate `lib/i18n/strings.g.dart`
- Modify: `pubspec.yaml` (delete the `filesystem_picker` entry and its comment), `pubspec.lock` (`flutter pub get`)
- Delete: `vendor/filesystem_picker/`
- Modify: `CLAUDE.md:320-323`

**Interfaces:**
- Consumes: `mokuroPickOf`, `MokuroPick` (Task 2); `ReaderMokuroSource.importArchive(..., ocrPath:)` (Task 1).

- [ ] **Step 1: Strings**

Add, beside the other `manga_import_*` keys:
- `"manga_import_failed": "Could not import the volume"`
- `"manga_import_pick": "Select the volume's archive (.cbz or .zip) and its .mokuro file together, or the archive alone if its .mokuro file is inside it."`

Change `"manga_import_no_ocr"` to `"This archive has no .mokuro file inside. Select the archive and its .mokuro file together."`
Run: `dart run slang` — expect `strings.g.dart` regenerated.

- [ ] **Step 2: Rewrite `importVolume`**

`FilePicker.pickFiles(type: FileType.any)` (multi-select is the default; no `allowedExtensions`: `.mokuro` has no MIME type and filtering would hide it). Empty result → return silently. Map each `PlatformFile` to `(name: file.name, path: file.path)` and call `mokuroPickOf`; null → error dialog with `t.manga_import_pick`. Otherwise `runWithProgress` with `t.manga_importing` around `importArchive(archivePath:, ocrPath:)`; a `MokuroImportException` → error dialog with `importErrorMessage(error.error)` (local import errors become dialogs; the missing-pages toast stays a toast). The whole body after the pick sits in `try { … } finally { await FilePicker.clearTemporaryFiles(); }`.

Error dialog: a private `Future<void> _showImportError(BuildContext context, String message)` — `AlertDialog(title: Text(t.manga_import_failed), content: Text(message), actions: [TextButton(… t.dialog_close …)])`, styled like `deleteVolume`'s dialog. Check `context.mounted` before showing.

Remove the `filesystem_picker` import and the `lastPickedDirectory` use.

- [ ] **Step 3: Delete the dead code and the vendored package**

Delete the three `AppModel` methods, `Preferences.lastPickedDirectory`, the `filesystem_picker` pubspec entry and `vendor/filesystem_picker/`; run `flutter pub get`. Remove any import of `filesystem_picker` that remains (`grep -rn filesystem_picker lib test` → nothing).

- [ ] **Step 4: CLAUDE.md**

Replace "Import takes a `.cbz` or `.zip` only, with its `.mokuro` beside it (how mokuro-bunko serves volumes) or inside it" with: import picks one volume through the system picker: a `.cbz` or `.zip` with its `.mokuro` picked alongside (how mokuro writes it and mokuro-bunko serves it) or inside it (`mokuroPickOf`); the catalog download hands its two files to the same `ReaderMokuroSource.importArchive`.

- [ ] **Step 5: Gates**

Run: `flutter analyze && flutter test`
Expected: "No issues found!", all pass.

- [ ] **Step 6: Device check**

Build and install the debug APK. Generate in the scratchpad, with a short script, a volume `vol1.cbz` (two JPEGs under `vol1/`) with `vol1.mokuro` beside it (pages `000a.jpg`, `000b.jpg`, `volume_uuid` `test-1`), and `inside.cbz` holding its own `inside.mokuro` (`volume_uuid` `test-2`); `adb push` them to `/sdcard/Download/yomimoto-test/`. In the Manga tab's `+` → Import file, check with screenshots:
1. Cancel the picker → nothing shown.
2. Pick `vol1.cbz` alone → dialog "Could not import the volume" with the no-`.mokuro` text.
3. Pick `vol1.mokuro` alone → dialog with the pick text.
4. Pick `vol1.cbz` + `vol1.mokuro` → volume in the library, opens and shows its pages.
5. Pick `inside.cbz` alone → imported.
6. After each, `adb shell run-as org.kaqui.yomimoto ls cache/file_picker` → empty or absent.

- [ ] **Step 7: Commit** — `Import manga through the system file picker`

---

### Task 4: Drop storage permissions and DCIM staging

**Files:**
- Modify: `lib/src/models/app_model.dart` — `_exportDirectory`/`exportDirectory` (≈183), delete `_alternateExportDirectory`/`alternateExportDirectory` (≈188), `prepareJidoujishoDirectory` (≈506-533), `prepareFallbackJidoujishoDirectory` (≈538), `initialise` (≈592, ≈606-607), `requestExternalStoragePermissions` (≈1007-1035), `getImageExportFile`/`getImageCompressedFile`/`getAudioExportFile` (≈1104-1126), `addFileToMedia` (≈1318-1393)
- Modify: `android/app/src/main/AndroidManifest.xml:3-5,14`
- Modify: `lib/i18n/strings.i18n.json` (delete `storage_permissions`), regenerate `strings.g.dart`
- Modify: `pubspec.yaml`, `pubspec.lock` (delete `external_path`)
- Modify: `docs/TOOLCHAIN.md:48-50`, `DEBT.md:19-21`, `CLAUDE.md:27-28`

- [ ] **Step 1: Export staging**

`prepareJidoujishoDirectory` becomes the body of the old fallback: `<appDirectory>/yomimotoExport/` with its `.nomedia`, returning it; delete the DCIM version, the fallback method and `alternateExportDirectory`. `getImageExportFile()`, `getImageCompressedFile()`, `getAudioExportFile()` lose `fallback` and use `exportDirectory`. `addFileToMedia` loses `fallback`; on `PlatformException` it shows `t.error_export_media_ankidroid` (as the fallback branch did) and rethrows — no retry.

- [ ] **Step 2: Permissions**

Delete `requestExternalStoragePermissions` and its call in `initialise`; `permission_handler` stays imported only if `app_model.dart` still uses it (it should not; the recorder imports it itself). Manifest: delete `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `MANAGE_EXTERNAL_STORAGE` and `android:requestLegacyExternalStorage="true"`. Delete the `storage_permissions` string; `dart run slang`.

- [ ] **Step 3: `external_path`**

Delete it from `pubspec.yaml`; `flutter pub get`; `grep -rn external_path lib` → nothing.

- [ ] **Step 4: Docs**

`docs/TOOLCHAIN.md`: "four plugins … (`external_path`, `flutter_archive`, `flutter_exit_app`, `flutter_image_compress_common`)" → three, without `external_path`. `DEBT.md`: drop `external_path` from the built-in Kotlin list. `CLAUDE.md`: "the AnkiDroid note type, tag, DCIM folder and exported file names say Yomimoto too" → drop "DCIM folder".

- [ ] **Step 5: Gates**

Run: `flutter analyze && flutter test`
Expected: "No issues found!", all pass.

- [ ] **Step 6: Device check**

Uninstall Yomimoto (`adb uninstall org.kaqui.yomimoto`), install the new debug APK, grant `com.ichi2.anki.permission.READ_WRITE_DATABASE`, launch:
1. No storage or camera permission prompt, no "Please grant…" toast.
2. Merged manifest (`build/app/intermediates/merged_manifest/debug/processDebugMainManifest/AndroidManifest.xml`) has none of the three storage permissions.
3. Import a dictionary (any small Yomichan zip pushed to `/sdcard/Download/`), look a word up, create a card with an image (pick-image enhancement, gallery) and a recorded or picked audio file, export it. `adb shell ls /sdcard/AnkiDroid/collection.media/` shows both files; AnkiDroid's browser shows the note with them.

- [ ] **Step 7: Commit** — `Drop the storage permissions and the DCIM staging`

---

### Task 5: Narrow the FileProvider paths

**Files:**
- Modify: `lib/src/models/app_model.dart` (`prepareJidoujishoDirectory`)
- Create: `android/app/src/main/res/xml/anki_media_paths.xml`, `android/app/src/main/res/xml/webview_file_paths.xml`
- Delete: `android/app/src/main/res/xml/provider_paths.xml`
- Modify: `android/app/src/main/AndroidManifest.xml` (both `<provider>`s' `FILE_PROVIDER_PATHS`)

- [ ] **Step 1: Staging in the cache**

`prepareJidoujishoDirectory` returns `<temporaryDirectory>/ankiMediaExport/`, created if missing, no `.nomedia`. In `initialise`, it must run after `_temporaryDirectory` is set (it already is).

- [ ] **Step 2: Paths files**

```xml
<!-- anki_media_paths.xml: media handed to AnkiDroid, staged by AppModel.prepareJidoujishoDirectory. -->
<paths>
  <cache-path name="anki_media" path="ankiMediaExport/" />
</paths>
```
```xml
<!-- webview_file_paths.xml: flutter_inappwebview's camera captures for a web file input (getExternalFilesDir(null)). -->
<paths>
  <external-files-path name="captures" path="." />
</paths>
```
`${applicationId}.provider` uses `@xml/anki_media_paths`; `…flutter_inappwebview.fileprovider` uses `@xml/webview_file_paths`. Delete `provider_paths.xml`.

- [ ] **Step 3: Gates**

Run: `flutter analyze && flutter test`
Expected: "No issues found!", all pass.

- [ ] **Step 4: Device check**

Build, install, export a card with an image and audio as in Task 4 step 6.3; both files reach `collection.media`, and `logcat` shows no `IllegalArgumentException: Failed to find configured root`.

- [ ] **Step 5: Commit** — `Narrow the FileProvider paths`

---

### Task 6: Remove the design and plan

- [ ] **Step 1:** Delete `docs/superpowers/specs/2026-11-26-native-storage-design.md` and this plan; `grep -rn "native-storage" --exclude-dir=.git .` → nothing.
- [ ] **Step 2: Commit** — `Remove the native storage design and plan`
