# ttu bridge and native library — design

Date: 2026-10-10
Status: draft, awaiting review

## 1. Context

The ッツ (ttu) EPUB reader is embedded as a prebuilt SvelteKit app
(`assets/ttu-ebook-reader/`, 57 MB) shown in `flutter_inappwebview`. Today the
integration is brittle:

- ttu → Flutter messages are JSON strings sent through `console.log`, parsed in
  `onConsoleMessage` behind a 50 ms debounce that silently drops messages.
- ~350 lines of JavaScript live in Dart strings and are re-injected on every
  `onLoadStop` / `onTitleChanged`: tap-to-lookup (hand-written ruby-stripping
  DOM walk), a near-duplicate DOM walk for highlighting, a `<style>` injection,
  an Exit menu entry matched on compiled Tailwind classes via
  `MutationObserver`, and volume-key page turns faked as `wheel` events.
- The library is read by booting the whole ttu app in a `HeadlessInAppWebView`,
  reading IndexedDB with injected JS, base64-encoding every cover, logging the
  whole library as one console line and polling for it every 500 ms with no
  timeout. This is why the Novels tab is slow.
- The dictionary theme is derived from `localStorage.theme` through a
  hard-coded 6-entry colour table.
- The bundled build is a **patched** ttu from 2023-04-29 whose patch source is
  not in this repository; it cannot be rebuilt. Upstream has ~1,800 commits
  since.

The fork of ttu now exists: `../ebook-reader-lite`, remote
`git@github.com:blastrock/ebook-reader-lite.git`, with `upstream` pointing at
`ttu-ttu/ebook-reader`. Multi-language support has already been removed from
this app; it is Japanese-only.

## 2. Goals

1. Replace the injection-based integration with a **typed JS bridge**, the
   ttu side of which lives in the fork as a small, rebaseable overlay.
2. Bring ttu up to **latest upstream**, built reproducibly from the fork.
3. Move the **book library into Flutter**, loading instantly from Isar, with
   import and delete done from Flutter.

## 3. Non-goals

- Making ttu stateless (S2) or Flutter-owned storage (S3). IndexedDB stays the
  source of truth; this may change later together with a sync server.
- Reimplementing reader settings in Flutter. ttu's own settings page stays.
- Removing ttu features from the fork's source. Unused features stay in the
  code and on the settings page; they are just unreachable from our UI.
- E-ink tuning, furigana customisation, typography settings in Flutter.
- Mokuro. Untouched.

### Features in scope (must keep working)

- Reading: paginated and continuous, vertical and horizontal, furigana,
  position restore (ttu's basic auto-bookmark).
- Reader appearance via ttu's settings page.
- Tap-to-lookup → Flutter dictionary popup → card creation; long-press
  selection with the Flutter context menu (Search / Stash / Copy / Share /
  Creator).
- Volume-key page turns.
- An Exit entry inside the reader.

### ttu features deliberately left unused

Statistics and reading tracker, reading goals, sync/backup (GDrive, OneDrive,
filesystem, zip), bookmark variants (manual, custom reading point, selection
to bookmark), spoiler controls, ttu's furigana options, audiobook/subtitle
(ttu-whispersync) storage, ttu's book manager (after phase 2).

## 4. Architecture overview

```
┌──────────────────────── Flutter (yuuna) ────────────────────────┐
│ ReaderTtuSource (library: Isar MediaItem mirror + cover files)  │
│ ReaderTtuSourcePage ── TtuBridge ──┐                            │
│ TtuHostOperations (headless) ──────┤  callHandler('ttuHost')    │
│                                    │  callAsyncJavaScript(...)   │
└────────────────────────────────────┼────────────────────────────┘
                                     │
┌──────────── ebook-reader-lite (WebView) ────────────────────────┐
│ lib/host/host-bridge.ts   transport, protocol, window.ttuHost   │
│ lib/host/host-lookup.ts   tap → paragraph/offset, highlight     │
│ lib/host/host-library.ts  list / cover / import / delete        │
│ small hooks in routes/b, header entries, layout                 │
│ unchanged: reader, importer, DatabaseService, IndexedDB         │
└─────────────────────────────────────────────────────────────────┘
```

Division of responsibility:

- **ttu** owns everything that needs the DOM or IndexedDB: tap detection,
  paragraph text extraction (ruby-stripped), mapping text offsets back to DOM
  ranges for highlighting, page turning, EPUB import, book storage.
- **Flutter** owns everything else: deciding the search term and highlight
  length (`JapaneseLanguage`, unchanged), the dictionary popup and its
  position, sentence extraction, the context menu, card creation, the library
  UI, and the file picker.

## 5. The fork: `ebook-reader-lite`

### 5.1 Overlay principles

- The fork's `main` is upstream's `main` plus a linear series of overlay
  commits, rebased onto `upstream/main` when updating.
- New code goes in **new files** under `apps/web/src/lib/host/`. Edits to
  upstream files are limited to small hooks (import + one call). This keeps
  rebase conflicts rare and obvious.
- Everything in the overlay is **inert unless running inside the app**: host
  mode is detected by the presence of `window.flutter_inappwebview`. Outside
  the app the fork behaves exactly like upstream, so it can still be run and
  debugged with `pnpm dev` in a desktop browser.
- Overlay commits use the repo's conventional-commit style (commitlint is
  configured).

### 5.2 Overlay contents

| Piece | Where | Upstream files touched |
|---|---|---|
| Bridge transport, protocol version, `window.ttuHost` command registry, `ready` event | `lib/host/host-bridge.ts` | `routes/+layout.svelte` (one import/init call) |
| Host stylesheet: `rt`/`rp` unselectable, selection colour (moved from Dart) | `lib/host/host.css` | none (loaded by host-bridge in host mode) |
| Page commands `nextPage` / `prevPage` | `host-bridge.ts` | `routes/b/+page.svelte` (register the current `pageManager`) |
| Tap-to-lookup, `highlight`, `clearSelection`, `getSelectedText` | `lib/host/host-lookup.ts` | `routes/b/+page.svelte` (attach the tap listener to the book content) |
| Theme reporting | `host-bridge.ts` (subscribes to `themeOption$`) | none |
| Exit header entry (phase 1); hide Manager and Statistics entries in host mode (phase 2) | `merged-entries.ts` + header handlers | `merged-header-icon/merged-entries.ts`, `book-reader-header.svelte`, settings header |
| Headless library operations route (phase 2) | `routes/host/+page.svelte`, `lib/host/host-library.ts` | none (new route) |
| Service worker registration off (only if hosting requires it, see §7) | `svelte.config.js` | one line |
| Release workflow | `.github/workflows/release.yml` | none |

Upstream's `deploy.yml` targets upstream's hosting; it is disabled in the
GitHub UI for the fork rather than deleted, to avoid an overlay change.

### 5.3 Release

`release.yml` runs on tags matching `vX.Y.Z`: `pnpm install`,
`pnpm svelte-kit sync`, `pnpm build` in `apps/web`, then zips `apps/web/build`
into `ebook-reader-lite-<tag>.zip` and attaches it to a GitHub Release. Node and pnpm
versions are taken from the existing `ci.yml` so they move together with
upstream's.

The fork's version numbers are its own and do not follow upstream's release
scheme. Upstream already used the tags `v1.0.0` and `v2.0.0` (inherited by the
fork), so the fork starts at `v3.0.0`.

Fonts stay as upstream bundles them (`src/lib/assets/fonts` → build output).

## 6. Getting the build into the app

- `assets/ttu-ebook-reader/` is **removed from version control** and
  gitignored.
- `tool/ttu.lock` records the release tag, the download URL and the zip's
  sha256.
- `tool/fetch_ttu.sh`:
  - default: download the pinned release zip, verify the sha256, replace
    `assets/ttu-ebook-reader/` with its contents;
  - `--local <path>`: run `pnpm build` in a local fork checkout and copy its
    output instead (for iterating on the bridge without making a release);
  - `--update <tag>`: download a new release and rewrite `tool/ttu.lock`.
- `pubspec.yaml` lists every asset directory of the build (Flutter asset
  directories are not recursive). SvelteKit 2's output directory names
  (`_app/immutable/{assets,chunks,entry,nodes}` and the prerendered route
  directories) are fixed, so the list is static; the script fails loudly if
  the build contains a directory that `pubspec.yaml` does not list.
- `CLAUDE.md`'s command list gains `tool/fetch_ttu.sh` before the build
  commands, and its "Reader internals" section is rewritten.

## 7. Hosting

Target: replace `local_assets_server` with `InAppWebViewSettings.webViewAssetLoader`
on the fixed origin `https://appassets.androidplatform.net`. This removes the
port, the "port in use, retrying" UI, and `ttuInternalVersion` cache busting
(asset-loader responses are not HTTP-cached by the WebView).

Two things must be verified by a spike at the start of that step:

1. **Path prefix.** ttu uses absolute paths and `VITE_PAGE_PATH`
   (`lib/data/env.ts`). Either serve the build at the origin root through a
   `CustomPathHandler` reading Flutter assets, or build with a matching base
   path. Whichever works with the fewest overlay changes wins.
2. **Service worker.** Requests made by a service worker do not go through the
   asset loader. If the SvelteKit service worker breaks loading, disable its
   registration in the fork (`kit.serviceWorker.register = false`).

**Fallback:** if the spike fails, keep `local_assets_server` on the fixed port
`ReaderTtuSource.port`. Nothing else in this design depends on the hosting
choice. Either way, the origin changes once in this project, which is free
(no backward compatibility owed).

## 8. Bridge protocol

### 8.1 Transport

- **ttu → Flutter:** a single JS handler, `ttuHost`, called as
  `window.flutter_inappwebview.callHandler('ttuHost', {type, ...payload})`.
  The Dart side dispatches on `type`. No debounce; every message is delivered.
  Calls are made only after the `flutterInAppWebViewPlatformReady` event.
- **Flutter → ttu:** `callAsyncJavaScript` with a fixed body
  `return await window.ttuHost[command](args)` and real `arguments`; results
  come back as JSON values. No JS is built by string concatenation.
- **Versioning:** `host-bridge.ts` exports `PROTOCOL_VERSION` (integer). The
  `ready` event carries it; Dart compares against its own constant and logs an
  error and shows a snackbar on mismatch (it means `tool/ttu.lock` and the Dart
  code disagree).

### 8.2 Events (ttu → Flutter)

| Type | Payload | When |
|---|---|---|
| `ready` | `protocolVersion`, `route` (`b`, `settings`, `manage`, `host`) | bridge initialised on a page |
| `tap` | `text`, `offset`, `x`, `y` | tap on book content. `offset` is a UTF-16 index into `text` (the ruby-stripped paragraph); `offset = -1` when the tap hit no character, which Flutter treats as "dismiss" |
| `theme` | `backgroundColor`, `fontColor` (CSS colour strings) | on `ready` in the reader and settings, and on every theme change |
| `exit` | — | Exit header entry tapped |

### 8.3 Commands (Flutter → ttu)

Phase 1 (reader page):

| Command | Args | Result |
|---|---|---|
| `nextPage` / `prevPage` | — | — (calls ttu's own `pageManager`; works in paginated and continuous modes) |
| `highlight` | `start`, `length` (offsets into the last `tap`'s `text`) | — (sets the DOM selection over the corresponding range, crossing ruby and inline elements) |
| `clearSelection` | — | — |
| `getSelectedText` | — | string, ruby text excluded |

Phase 2 (headless `host` route):

| Command | Args | Result |
|---|---|---|
| `listBooks` | — | `[{id, title, lastBookOpen}]` |
| `getCover` | `id` | data URL or `null` |
| `importBooks` | `urls` (files served to the WebView, see §10.3) | `[{id, title}]`, or throws with ttu's error message |
| `deleteBook` | `id` | — |

### 8.4 Lookup flow

1. User taps book content. `host-lookup.ts` uses `caretRangeFromPoint`,
   corrects for the "tap on the right half of a character" case (existing
   behaviour), finds the enclosing paragraph, and builds its text from text
   nodes excluding `rt`, `rp` and hidden nodes (reusing upstream's
   `getParagraphNodes`). It keeps the node/offset map for that paragraph and
   sends `tap`.
2. Flutter computes the search term, start offset and guessed length with
   `JapaneseLanguage`, calls `highlight(start, guessLength)`, searches, then
   calls `highlight(start, finalLength)` — as today, minus the duplicated DOM
   walk. Sentence extraction stays in Flutter.
3. Popup dismiss → `clearSelection`.

Upstream's tap-to-flip edge buttons are separate elements above the book
content, so their taps never reach the lookup listener; no special handling is
needed.

## 9. Flutter side

### 9.1 New: `TtuBridge`

`lib/src/media/sources/ttu_bridge.dart` (exported from `media.dart`). Wraps an
`InAppWebViewController`:

- registers the `ttuHost` handler and decodes events into typed Dart objects
  (`TtuReadyEvent`, `TtuTapEvent`, `TtuThemeEvent`, `TtuExitEvent`), exposed as
  callbacks;
- exposes commands as typed async methods (`nextPage()`,
  `highlight(start:, length:)`, `listBooks()`, …);
- owns `protocolVersion`.

### 9.2 Reader page rewrite (`reader_ttu_source_page.dart`)

- All injected JS strings are deleted (`javascriptToExecute`,
  `_exitMenuItemJs`, `leftArrowSimulateJs`, `rightArrowSimulateJs`,
  `unselectWebViewTextSelection`'s inline JS, `selectTextOnwards`).
- `onConsoleMessage` becomes logging only.
- Volume keys call `nextPage` / `prevPage`. The **volume page-turning speed
  setting is removed** (it only existed to scale the fake wheel event), with
  its preference, settings row and i18n strings. "Inverted" stays.
- The dictionary theme comes from the `theme` event: the popup colour is the
  reported background colour at `dictionaryEntryOpacity`, and light/dark is
  chosen from its luminance. The hard-coded theme table is deleted. The
  `adaptTtuTheme` setting stays.
- The download handling (`blobToBase64Handler`, `downloadFileJs`) and the
  `onCreateWindow` popup only served ttu's export and OAuth flows, which are
  unused; they are deleted.
- The context menu stays a Flutter `ContextMenu`; it reads text through
  `getSelectedText`.

### 9.3 Dead code removed in `reader_ttu_source.dart`

`importBackup`, `onSourceExit`'s commented-out backup, `showClearPrompt`, the
duplicate `get` JS string, the `empty`-message first-run defaults hack (ttu's
own defaults apply), and — after phase 2 — `getHistoryJs`, `getItemsFromJson`
and the headless history read.

## 10. Phase 2: native library

### 10.1 Mirror

The library is the standard media history already used elsewhere: Isar
`MediaItem` rows with `mediaSourceIdentifier = 'reader_ttu'`,
`mediaIdentifier` = the ttu book id, `title`, and `imageUrl = file://…` pointing
to a cover file in a `ttuCovers` directory under the app's support directory
(`MediaSource.getDisplayThumbnailFromMediaItem` already renders `file://`
images). `ReaderTtuSource.implementsHistory` becomes `true`; ordering is by
last opened, which Flutter records when it opens a book. Progress is not shown.

The Novels tab reads only from Isar. No WebView is involved in showing the
library.

### 10.2 Headless operations

`TtuHostOperations` runs a `HeadlessInAppWebView` on the fork's `host` route
(a page with no UI that only initialises the bridge and the database), with a
`TtuBridge` attached, and a timeout on every call. It is started on demand for
import, delete and refresh, and disposed afterwards. It shares IndexedDB with
the reader because it uses the same origin.

### 10.3 Operations

- **Import:** the library's import action opens `file_picker` for `.epub`
  (also `.htmlz` and `.txt`, which ttu supports at no extra cost). Picked files
  are copied to a staging directory that the WebView can fetch (an asset-loader
  `InternalStoragePathHandler`, or a route on the local server under the
  fallback). `importBooks(urls)` runs ttu's own `importData` against the
  browser storage handler. On success Flutter fetches each new book's cover,
  writes it to `ttuCovers`, adds the `MediaItem`, and deletes the staged
  files. Errors show ttu's message in a dialog.
- **Delete:** a library item's delete action confirms, calls `deleteBook(id)`,
  then removes the `MediaItem` and the cover file.
- **Open:** opens `b?id=<id>` in `ReaderTtuSourcePage` and records last opened.
- **Refresh:** a library action that calls `listBooks`, adds missing items
  (fetching their covers), and removes items whose book no longer exists. Also
  run once automatically after import and delete. There is no automatic
  refresh at startup: since Flutter is the only way to add or remove books,
  the mirror only drifts after a failure.

### 10.4 Reader UI in host mode

The reader's Manager and Statistics header entries are hidden in host mode;
Exit returns to the Flutter library. How ttu's settings page navigates back
(to the manager or to the previous book) is checked during phase 2; any link
it offers to the manager is redirected to `exit` in host mode. The library
tab's "manager" launch button is removed; its
settings button still opens ttu's `settings` page.

## 11. Error handling

- Every bridge command has a timeout (default 10 s; import scales with file
  size) and surfaces as a Dart exception with the JS error message.
- Protocol mismatch on `ready`: logged and shown once as a snackbar; the
  reader still opens.
- Headless operations always dispose their WebView in a `finally`.
- A missing `assets/ttu-ebook-reader/` (fetch script not run) fails the Flutter
  build because the `pubspec.yaml` asset directories do not exist, which is
  the clearest possible signal.

## 12. Phasing and commits

Commits are small and each leaves both repos building. Fork commits are
conventional-commit style; app commits follow this repo's style.

### Phase 1 — bridge and upgrade (ttu's manager still serves as the library)

Fork:
1. `feat(host): add host bridge skeleton and ready event`
2. `feat(host): add host stylesheet`
3. `feat(host): expose page turning to the host`
4. `feat(host): tap-to-lookup, highlight and selection commands`
5. `feat(host): report theme colours`
6. `feat(host): add Exit header entry in host mode`
7. `ci: add release workflow`; tag `v3.0.0`

App:
1. Add `tool/fetch_ttu.sh`, `tool/ttu.lock`; untrack and gitignore
   `assets/ttu-ebook-reader/`; update `pubspec.yaml` asset list and `CLAUDE.md`
   commands.
2. Add `TtuBridge`.
3. Switch the reader page to the bridge for exit and page turns; remove the
   volume speed setting.
4. Switch lookup, highlight and the context menu to the bridge; delete the
   injected JS.
5. Switch theme adaptation to the `theme` event; delete the colour table.
6. Delete download/popup-window handling and other dead code.
7. Hosting: spike, then switch to the asset loader (or record the fallback).
8. Update `CLAUDE.md` "Reader internals".

### Phase 2 — native library

Fork:
1. `feat(host): add headless host route with library commands`
2. `feat(host): hide manager and statistics entries in host mode`; tag
   `v3.1.0`

App:
1. Add `TtuHostOperations`.
2. Mirror ttu books into Isar history with cover files; Novels tab reads from
   Isar; delete the headless history JS.
3. Import from Flutter.
4. Delete from Flutter.
5. Refresh action.
6. Remove the manager launch button; update `CLAUDE.md`.

## 13. Verification

There are no automated tests in the app. Each step is verified by:

- App: `flutter analyze` stays at 0 errors / 0 warnings with no new infos.
- Fork: `pnpm check` and `pnpm build` pass in `apps/web`.
- Manual device check after each user-visible step. Phase 1 checklist:
  open a book; tap-lookup in vertical and horizontal text, on plain text,
  inside ruby, at paragraph start/end, and on empty space (dismisses);
  highlight length matches the result; long-press → each context-menu action;
  volume up/down in paginated and continuous modes, and inverted;
  Exit (confirmation shown); theme change updates the popup colour; position
  is restored on reopening. Phase 2 checklist: library loads with no WebView;
  import one and several EPUBs; covers shown; delete; reopen restores
  position; refresh after manually deleting a book from ttu's settings.

## 14. Risks and things to verify during implementation

- **Hosting spike** (§7): path prefix and service worker under the asset
  loader. Fallback defined.
- **`flutterInAppWebViewPlatformReady` timing** in the headless WebView.
- **Domain hint / external-read warning**: upstream shows hints based on the
  page's URL (`isOnOldUrl`) and on external sources; check neither triggers on
  our origin. If one does, suppress it in host mode.
- **Ruby edge cases in lookup**: gaiji images and nested inline elements; the
  node map must handle what `getParagraphNodes` returns.
- **Large imports**: staging and fetching a big EPUB through the WebView; the
  timeout must scale.
