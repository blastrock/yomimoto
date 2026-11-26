# Native storage access: design

## Intent

Drop the vendored `filesystem_picker`, `external_path` and the all-files
permission. The app then reads only files the user hands it through the
system picker, and writes only to its own folders.

## Approaches

- **One volume per pick, both files at once (chosen).** Manga import uses
  the system picker (`file_picker`, already used for EPUBs and
  dictionaries) with multi-select: the user selects the archive and its
  `.mokuro` together. Costs a copy of the picked files into the cache
  before import, one volume's worth.
- Several volumes per pick, same picker: `file_picker` copies every picked
  file before returning, with no progress, so peak storage is the whole
  selection. Rejected.
- A whole folder (`ACTION_OPEN_DOCUMENT_TREE`): one volume copied at a
  time, but `file_picker` cannot list or read a granted folder, so it needs
  a native channel (list, copy) in `MainActivity`; Android 11+ also refuses
  the storage root and `Download/` itself. Rejected for now; a possible
  follow-up, which would reuse this change's pairing rule.

Mokuro writes the `.mokuro` beside the images and mokuro-bunko serves it
beside the archive, so picking both files is the common case; an archive
with its `.mokuro` inside is also accepted.

## Manga import

- No dialog before the picker: the error dialog explains what to select
  the first time it is needed.
- The picker is `FileType.any`, multi-select. Filtering by extension is not
  possible: `.mokuro` has no MIME type, and `file_picker` would filter on
  the other extensions only, hiding the `.mokuro` files.
- What was picked is checked by a pure function:
  - one archive and one `.mokuro`: import them as a pair, whatever their
    names;
  - one archive alone: import it, the `.mokuro` being inside;
  - anything else (a `.mokuro` alone, two archives, other files, more than
    two files): an error dialog explains what to select, no import.
  An archive alone without a `.mokuro` inside fails in the import, as
  today (`MokuroImportError.noOcr`), and that error also becomes a dialog
  explaining that both files must be selected.
- One import is one volume, as today.
- `importMokuroVolume` takes the `.mokuro` path explicitly (or none: look
  inside the archive). The "beside the archive with its name" lookup goes;
  the catalog download passes its downloaded `volume.mokuro` explicitly.
- The picker's cache copies are cleared after the import, success or
  failure (`FilePicker.clearTemporaryFiles`, as the EPUB import does).
- Removed: `filesystem_picker` and `vendor/filesystem_picker/`,
  `getFilePickerDirectoriesForMediaSource`, the `lastPickedDirectory`
  preference (pre-1.0: no migration).

## AnkiDroid media export

Verified on an emulator (Android 16, AnkiDroid 2.25.3, Yomimoto with no
storage permission): media staged in the app's own `yomimotoExport/`
reaches AnkiDroid intact through the existing `FileProvider` grant.

- Stage only in `yomimotoExport/`; remove `prepareJidoujishoDirectory`
  (DCIM), the alternate directory and the retry-on-`PlatformException`.
- Removes `external_path`.

## Permissions

- Remove `requestExternalStoragePermissions` and its startup toast
  (`storage_permissions`): its camera request is a no-op (`CAMERA` is not
  declared; `image_picker` uses the camera app's intent).
- Manifest: remove `MANAGE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`,
  `WRITE_EXTERNAL_STORAGE` and `requestLegacyExternalStorage`.
- `permission_handler` stays (microphone for the recorder).

## FileProvider paths (a separate commit, after the rest)

`res/xml/provider_paths.xml` shares the whole filesystem (`root-path`,
`external-path`, …). Both providers in the app manifest use it: ours
(`${applicationId}.provider`, AnkiDroid media) and
flutter_inappwebview's, which the app must declare and which, being the
same resource name, also overrides the plugin's own `provider_paths.xml`.
Neither provider is exported and a URI is only readable once granted
(AnkiDroid gets a read grant per exported file), so this is least
privilege, not an open hole.

- Staging moves to `<cache>/ankiMediaExport/` (`temporaryDirectory`): the
  files live only until AnkiDroid has copied them, and `app_flutter/`
  (where `yomimotoExport/` is) has no FileProvider tag but `root-path`.
  No `.nomedia`: internal storage is not media-scanned.
- Our provider gets its own `anki_media_paths.xml`: a single
  `cache-path` for `ankiMediaExport/`.
- The WebView provider gets its own `webview_file_paths.xml`: a single
  `external-files-path`, the only place it writes (camera captures for a
  web file input, `getExternalFilesDir(null)`); no page the app can reach
  has one, and its `getUriForFile` failure is caught.
- `provider_paths.xml` is deleted.
- Verified on device by exporting a card with image and audio again.

## Non-goals

- Importing several volumes in one pick, or a whole folder (see
  Approaches).
- Cleaning up `DCIM/yomimoto/` on existing installs.

## Docs

CLAUDE.md (manga import), `vendor/README.md`, `docs/TOOLCHAIN.md`,
`DEBT.md` (`external_path` leaves the built-in Kotlin list).

## Verification

Unit tests for the selection check and for import with an explicit
`.mokuro` path. On device: a fresh install asks for no storage permission;
import a pair, an archive with its OCR inside, an archive without, a
`.mokuro` alone; a card with image and audio reaches AnkiDroid.
