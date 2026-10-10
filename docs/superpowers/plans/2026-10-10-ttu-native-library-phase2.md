# ttu native library — phase 2 implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans (recommended: the tasks share one small protocol and most verification needs the emulator/CDP setup of the executing session) or superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The Novels tab becomes a Flutter library backed by Isar: it shows instantly without any WebView, and books are imported, refreshed and deleted from Flutter. ttu's own manager is no longer reachable.

**Architecture:** The fork gains library commands (`listBooks`, `getCover`, `importBooks`, `deleteBook`) and an empty `host` route to run them on. The app runs those commands in an on-demand headless WebView (`TtuHostOperations`), mirrors the book list into Isar `MediaItem` rows with cover files on disk, and drives import (file picker → staging directory served to the WebView → ttu's own importer), delete and refresh from the library UI. IndexedDB stays the source of truth (spec "S1").

**Tech Stack:** as phase 1 — SvelteKit/TypeScript fork, Flutter + `flutter_inappwebview` 6.1.5 (`WebViewAssetLoader`, `CustomPathHandler`), Isar, `file_picker` 12, `mime` 2.

**Spec:** `docs/superpowers/specs/2026-10-10-ttu-bridge-and-native-library-design.md` §8.3 (phase 2 commands), §10, §11, §12 "Phase 2", §13.

## Global Constraints

- Everything from the phase 1 plan's Global Constraints still applies (two jj repos, commit trailers, conventional commits in FORK / `TTU: …` in APP, FORK license header, overlay only under `apps/web/src/lib/host/` plus small hooks, `flutter analyze` 0 errors/warnings, `///` docs on public members, British spelling, no automated tests — verification is FORK lint/build + headless-Chromium CDP checks, APP analyze + emulator checks).
- **Never push the APP repository.** FORK pushes and tags only after asking the user.
- APP analyzer ceiling: **77 issues** (current value).
- APK builds need `ANDROID_HOME=$HOME/android/android-sdk-linux`.
- FORK checks: `pnpm check` must stay at the upstream baseline of **42 errors**; `pnpm eslint <paths>` (run from the fork root) and `pnpm prettier --check <paths>` clean; `pnpm build` passes. pnpm lives in `~/.local/bin` (prefix `PATH`).
- Bridge `PROTOCOL_VERSION` / `TtuBridge.protocolVersion` go from **1 to 2** (commands added).
- The library is **not** subject to the generic media-history limit (`AppModel.maximumMediaHistoryItems` = 100, enforced by `addMediaItem`): mirror writes use a new uncapped `AppModel.putMediaItem`.
- Book `MediaItem.mediaIdentifier` is the **relative** reader path `b.html?id=<ttu id>` (settings item: `settings.html`); the reader page prefixes `ReaderTtuSource.url()`. Its `uniqueKey` is therefore independent of the origin.
- Library order: most recently opened (or imported) first. Opening a book re-puts its row (new Isar id); the page shows `getMediaSourceHistory(...).reversed`.
- Progress is not shown in the grid.

## Review Focus

1. **More than 100 books** — none may disappear from the library (would happen if `addMediaItem` were used). Pinned by Task 5 Step 1 (uncapped `putMediaItem`) and Task 5 Step 7.
2. **Importing a book whose title already exists, or several files at once, or a non-EPUB/HTMLZ/TXT file** — duplicates update in place (ttu upserts by title), multiple files all appear, unsupported files are rejected with a message and nothing else breaks. Pinned by Task 1 Step 5 and Task 6 Step 4.
3. **Import failure or timeout** (corrupt EPUB, huge file) — an error dialog with ttu's message, the progress dialog closes, staging files are removed, the library is unchanged. Pinned by Task 1 Step 5 and Task 6 Step 4.
4. **Library drift** (book deleted in IndexedDB by other means, mirror row without book, book without mirror row) — Refresh reconciles both ways and cleans cover files. Pinned by Task 5 Step 7.
5. **Reopening the settings page from the library and leaving it** — must return to the library (host-mode exit), never land on ttu's manager. Pinned by Task 2 Step 3 and Task 8 Step 3.

---

## Task 1: FORK — host route and library commands

**Files:**
- Create: `apps/web/src/routes/host/+page.svelte`
- Create: `apps/web/src/lib/host/host-library.ts`
- Modify: `apps/web/src/lib/host/host-init.ts` (call `initHostLibrary()`)
- Modify: `apps/web/src/lib/host/host-bridge.ts` (`PROTOCOL_VERSION = 2`)

**Interfaces:**
- Consumes: `registerHostCommand` (phase 1); upstream `database` (`$lib/data/store`), `importData` (`$lib/functions/replication/replicator`), `getStorageHandler` (`$lib/data/storage/storage-handler-factory`), `StorageKey` (`$lib/data/storage/storage-types`).
- Produces (wire, protocol 2):
  - `listBooks()` → `{id: number, title: string}[]`
  - `getCover({id})` → `string | null` (data URL)
  - `importBooks({urls: string[]})` → `undefined`, throws `Error(<ttu message>)` on failure
  - `deleteBook({id})` → `undefined`, throws on failure
  - route `/host` (prerendered `host.html`): empty page; loading it initialises the bridge like any other page.

- [ ] **Step 1: Create `host-library.ts`**

```ts
/**
 * @license BSD-3-Clause
 * Copyright (c) 2026, ッツ Reader Authors
 * All rights reserved.
 */

import { getStorageHandler } from '$lib/data/storage/storage-handler-factory';
import { StorageKey } from '$lib/data/storage/storage-types';
import { database } from '$lib/data/store';
import { importData } from '$lib/functions/replication/replicator';
import { registerHostCommand } from '$lib/host/host-bridge';

function blobToDataUrl(blob: Blob) {
  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = () => reject(reader.error);
    reader.readAsDataURL(blob);
  });
}

/** Ids and titles only: walks the title index so book contents are never loaded. */
async function listBooks() {
  const db = await database.db;
  const books: { id: number; title: string }[] = [];
  let cursor = await db.transaction('data').store.index('title').openKeyCursor();

  while (cursor) {
    books.push({ id: cursor.primaryKey as number, title: cursor.key as string });
    cursor = await cursor.continue();
  }

  return books;
}

async function getCover({ id }: Record<string, unknown>) {
  if (typeof id !== 'number') {
    throw new Error('getCover: id must be a number');
  }

  const db = await database.db;
  const cover = (await db.get('data', id))?.coverImage;

  return cover instanceof Blob ? blobToDataUrl(cover) : null;
}

async function importBooks({ urls }: Record<string, unknown>) {
  if (!Array.isArray(urls)) {
    throw new Error('importBooks: urls must be an array');
  }

  const files = await Promise.all(
    urls.map(async (url: string) => {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`Cannot read ${url}: ${response.status}`);
      }
      const name = decodeURIComponent(url.split('/').pop() || 'book.epub');
      return new File([await response.blob()], name);
    })
  );

  const error = await importData(
    document,
    getStorageHandler(window, StorageKey.BROWSER),
    files,
    new AbortController().signal
  );

  if (error) {
    throw new Error(error);
  }
}

async function deleteBook({ id }: Record<string, unknown>) {
  if (typeof id !== 'number') {
    throw new Error('deleteBook: id must be a number');
  }

  const db = await database.db;
  const book = await db.get('data', id);
  if (!book) {
    return;
  }

  const { error } = await database.deleteData(
    [id],
    new Map([[id, book.title]]),
    new AbortController().signal,
    false
  );

  if (error) {
    throw new Error(error);
  }
}

export function initHostLibrary() {
  registerHostCommand('listBooks', listBooks);
  registerHostCommand('getCover', getCover);
  registerHostCommand('importBooks', importBooks);
  registerHostCommand('deleteBook', deleteBook);
}
```

If `pnpm check` reports new type errors on the idb cursor (`openKeyCursor` typing), fix them with the narrowest cast, not by loading full records.

- [ ] **Step 2: Register it, bump the protocol, add the route**

- `host-init.ts`: import `initHostLibrary` from `$lib/host/host-library` and call it after `initHostTheme();`.
- `host-bridge.ts`: `export const PROTOCOL_VERSION = 2;`
- `routes/host/+page.svelte`:
  ```svelte
  <!--
    Empty page loaded by the jidoujisho app in a headless WebView to run
    library commands (see $lib/host/host-library.ts).
  -->
  ```

- [ ] **Step 3: Static checks**

```bash
SP=<scratchpad>; $SP/forkcheck.sh apps/web/src/lib/host
cd /home/blastrock/work/ebook-reader-lite && PATH=$HOME/.local/bin:$PATH pnpm prettier --check apps/web/src/lib/host apps/web/src/routes/host
find apps/web/build -maxdepth 1 -name 'host*'
```

Expected: check 42 errors (baseline), eslint 0, build OK, `apps/web/build/host.html` exists and no new build directory appeared (the APP's `pubspec.yaml` asset list must still match; if a `host/` directory appears, note it for Task 5).

- [ ] **Step 4: CDP check — list and cover**

Serve the build with the scratchpad `serve.mjs`, launch a fresh profile, import the test EPUB through `/manage` (as in phase 1's `book.mjs`), then with a pre-document stub (`Page.addScriptToEvaluateOnNewDocument` defining `window.flutter_inappwebview = {_platformReady: true, callHandler: …}`) load `/host` and evaluate:
- `await window.ttuHost.listBooks({})` → one entry with the book's id and title;
- `(await window.ttuHost.getCover({id})).slice(0, 22)` → starts with `data:image/`;
- the `ready` event carries `protocolVersion: 2` and `route: '/host'`.

- [ ] **Step 5: CDP check — import and delete (Review Focus 2, 3)**

Copy the test EPUB and a second EPUB (`/home/blastrock/Downloads/No Game No Life - LN 01.epub`) into `apps/web/build/import-test/` under ASCII names (test-only; delete afterwards), then on `/host`:
- `await ttuHost.importBooks({urls: ['/import-test/a.epub', '/import-test/b.epub']})` → resolves; `listBooks` has both titles;
- importing `a.epub` again → still one entry for that title (same id);
- `ttuHost.importBooks({urls: ['/import-test/missing.epub']})` → rejects with `Cannot read …: 404`;
- import of a file named `x.pdf` → rejects with ttu's message (it only accepts epub/htmlz/txt);
- `await ttuHost.deleteBook({id})` → `listBooks` no longer has it; deleting it again resolves (no-op).

Remove `apps/web/build/import-test/` afterwards.

- [ ] **Step 6: Commit**

```bash
cd /home/blastrock/work/ebook-reader-lite && jj commit apps/web/src/lib/host '"apps/web/src/routes/host/+page.svelte"' -m "feat(host): add headless host route with library commands

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 2: FORK — no way to the manager in host mode

**Files:**
- Modify: `apps/web/src/lib/components/book-reader/book-reader-header.svelte` (items block)
- Modify: `apps/web/src/lib/components/settings/settings-header.svelte`

**Interfaces:**
- Consumes: `isHost`, `sendToHost` (phase 1), `mergeEntries.EXIT` (phase 1).
- Produces: in host mode the reader header lists neither Manager nor Statistics; the settings header's leave button sends `exit` when it would otherwise go to the manager.

- [ ] **Step 1: Reader header**

In the `$: { const items = []; … }` block of `book-reader-header.svelte`, replace

```ts
    if (isOldUrl) {
      items.push(mergeEntries.DOMAIN_HINT);
    } else {
      items.push(mergeEntries.STATISTICS);
    }
```

with

```ts
    if (isOldUrl) {
      items.push(mergeEntries.DOMAIN_HINT);
    } else if (!isHost()) {
      items.push(mergeEntries.STATISTICS);
    }
```

and replace

```ts
    items.push(mergeEntries.SETTINGS, mergeEntries.MANAGE);

    if (isHost()) {
      items.push(mergeEntries.EXIT);
    }
```

with

```ts
    items.push(mergeEntries.SETTINGS);
    items.push(isHost() ? mergeEntries.EXIT : mergeEntries.MANAGE);
```

- [ ] **Step 2: Settings header**

In `settings-header.svelte` add to the script block:

```ts
  import { faDoorOpen } from '@fortawesome/free-solid-svg-icons';
  import { mergeEntries } from '$lib/components/merged-header-icon/merged-entries';
  import { baseIconClasses } from '$lib/css-classes';
  import { isHost, sendToHost } from '$lib/host/host-bridge';

  $: exitsToHost = isHost() && leavePageLink.endsWith(mergeEntries.MANAGE.routeId);
```

(merge `baseIconClasses` into the existing `$lib/css-classes` import, and `faDoorOpen` into the existing fontawesome import), and replace `<MergedHeaderIcon {leavePageLink} />` with:

```svelte
    {#if exitsToHost}
      <button class={baseIconClasses} title="Exit" on:click={() => sendToHost('exit')}>
        <Fa icon={faDoorOpen} />
      </button>
    {:else}
      <MergedHeaderIcon {leavePageLink} />
    {/if}
```

(When settings were reached from a book, `leavePageLink` is that book and the normal link is kept.)

- [ ] **Step 3: Checks (Review Focus 5)**

`forkcheck.sh` on the two files + prettier. CDP with the host stub, narrow viewport:
- reader header popover lists `Jump, Images, Settings, Exit` (no Statistics, no Manager); without the stub it lists `Statistics, …, Settings, Manager`;
- full load of `/settings` → header shows a door button; clicking it sends `{type: 'exit'}`;
- reader → Settings (client-side) → the leave link still goes back to `/b?id=…`.

- [ ] **Step 4: Commit**

```bash
cd /home/blastrock/work/ebook-reader-lite && jj commit apps/web/src/lib/components -m "feat(host): hide manager and statistics entries in host mode

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 3: APP — bridge library commands

**Files:**
- Modify: `lib/src/media/sources/ttu_bridge.dart`

**Interfaces:**
- Consumes: wire protocol 2 (Task 1).
- Produces:
  ```dart
  class TtuBook { TtuBook.fromJson(Map<String, dynamic>); final int id; final String title; }
  // TtuBridge:
  static const int protocolVersion = 2;
  Future<List<TtuBook>> listBooks();
  Future<String?> getCover(int id);
  Future<void> importBooks(List<String> urls, {required Duration timeout});
  Future<void> deleteBook(int id);
  ```

- [ ] **Step 1: Implement**

- `protocolVersion = 2`.
- `_call` gains a named `Duration timeout = commandTimeout` parameter used in `.timeout(timeout)`.
- Add:

```dart
/// A book in ttu's IndexedDB.
class TtuBook {
  /// Create the book from its wire form.
  TtuBook.fromJson(Map<String, dynamic> json)
      : id = json['id'] as int,
        title = json['title'] as String? ?? '';

  /// ttu's id for the book (IndexedDB key of the `data` store).
  final int id;

  /// The book's title.
  final String title;
}
```

and in `TtuBridge`:

```dart
  /// Every book in ttu's library.
  Future<List<TtuBook>> listBooks() async {
    List<dynamic> raw = (await _call('listBooks') as List<dynamic>?) ?? [];
    return raw
        .map((e) => TtuBook.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  /// The cover of book [id] as a data URL, or null if it has none.
  Future<String?> getCover(int id) async =>
      await _call('getCover', {'id': id}) as String?;

  /// Import the files at [urls] (served to the WebView) with ttu's importer.
  Future<void> importBooks(List<String> urls, {required Duration timeout}) =>
      _call('importBooks', {'urls': urls}, timeout: timeout);

  /// Delete book [id] and its bookmark from ttu's library.
  Future<void> deleteBook(int id) => _call('deleteBook', {'id': id});
```

- [ ] **Step 2: Analyse and commit**

```bash
cd /home/blastrock/work/jidoujisho && flutter analyze lib/src/media/sources/ttu_bridge.dart
```

Expected: no issues. Commit `TTU: add library commands to the bridge` (path `lib/src/media/sources/ttu_bridge.dart`). Do not install on the emulator yet: protocol 2 needs the Task 1 build (`tool/fetch_ttu.sh --local ../ebook-reader-lite`, which Task 5 does).

---

## Task 4: APP — headless host operations and the import path handler

**Files:**
- Create: `lib/src/media/sources/ttu_host_operations.dart`
- Create: `lib/src/media/sources/ttu_import_path_handler.dart`
- Modify: `lib/media.dart` (two exports, alphabetical among the `sources/ttu_*` lines)

**Interfaces:**
- Consumes: `TtuBridge`, `TtuReadyEvent` (Task 3), `ReaderTtuSource.instance.url()` / `.webViewSettings`, `TtuAssetPathHandler` (phase 1).
- Produces:
  ```dart
  class TtuImportPathHandler extends CustomPathHandler { TtuImportPathHandler(Directory directory); }  // serves <origin>/import/<index>/<name> from <directory>/<index>/<name>
  class TtuHostOperations {
    static Future<T> run<T>(Future<T> Function(TtuBridge bridge) action, {Directory? importDirectory});
  }
  ```

- [ ] **Step 1: `ttu_import_path_handler.dart`**

```dart
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

/// Serves files staged for import from [directory] at
/// `<origin>/import/<index>/<name>`, so that ttu's importer can `fetch` them
/// under their original file names.
class TtuImportPathHandler extends CustomPathHandler {
  /// Create the handler.
  TtuImportPathHandler(this.directory) : super(path: '/import/');

  /// Directory holding the staged files.
  final Directory directory;

  @override
  Future<WebResourceResponse?> handle(String requestPath) async {
    List<String> segments = requestPath.split('?').first.split('/');
    if (segments.length != 2 || int.tryParse(segments[0]) == null) {
      return null;
    }
    String name = Uri.decodeComponent(segments[1]);
    if (name.isEmpty || name.contains('/') || name == '..' || name == '.') {
      return null;
    }

    File file = File(path.join(directory.path, segments[0], name));
    if (!file.existsSync()) {
      return null;
    }

    return WebResourceResponse(
      contentType: lookupMimeType(name) ?? 'application/octet-stream',
      data: await file.readAsBytes(),
    );
  }
}
```

(If `CustomPathHandler.handle`'s parameter must be named `path`, rename the `path` package import prefix to `p` instead.)

- [ ] **Step 2: `ttu_host_operations.dart`**

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:yuuna/media.dart';

/// Runs ebook-reader-lite library commands in a short-lived headless
/// WebView on the reader's origin, so they share its IndexedDB.
class TtuHostOperations {
  TtuHostOperations._();

  /// How long the host page may take to load.
  static const Duration loadTimeout = Duration(seconds: 30);

  /// Start a headless WebView on `host.html`, wait for its bridge, run
  /// [action], and dispose of the WebView whatever happens. Files in
  /// [importDirectory] are served at `<origin>/import/<index>/<name>`.
  static Future<T> run<T>(
    Future<T> Function(TtuBridge bridge) action, {
    Directory? importDirectory,
  }) async {
    ReaderTtuSource source = ReaderTtuSource.instance;
    Completer<TtuBridge> ready = Completer<TtuBridge>();
    TtuBridge? bridge;

    InAppWebViewSettings settings = source.webViewSettings;
    if (importDirectory != null) {
      settings.webViewAssetLoader = WebViewAssetLoader(
        pathHandlers: [
          TtuImportPathHandler(importDirectory),
          TtuAssetPathHandler(),
        ],
      );
    }

    HeadlessInAppWebView webView = HeadlessInAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(source.url('host.html'))),
      initialSettings: settings,
      onWebViewCreated: (controller) {
        bridge = TtuBridge(
          controller: controller,
          onReady: (event) {
            if (ready.isCompleted) {
              return;
            }
            if (event.isCompatible) {
              ready.complete(bridge);
            } else {
              ready.completeError(TtuBridgeException(
                'ready',
                'protocol ${event.protocolVersion}, app expects '
                    '${TtuBridge.protocolVersion}',
              ));
            }
          },
        );
      },
    );

    try {
      await webView.run();
      TtuBridge readyBridge = await ready.future.timeout(loadTimeout);
      return await action(readyBridge);
    } on TimeoutException {
      throw TtuBridgeException('ready', 'host page did not load');
    } finally {
      await webView.dispose();
    }
  }
}
```

(`TimeoutException` from `action` itself is already wrapped by `TtuBridge._call`; the `on TimeoutException` above only catches the load timeout.)

- [ ] **Step 3: Export, analyse, commit**

Add `export 'src/media/sources/ttu_host_operations.dart';` and `export 'src/media/sources/ttu_import_path_handler.dart';` to `lib/media.dart`. Run the analyze gate (≤ 77, 0 errors/warnings). Commit `TTU: run library commands in a headless host WebView`.

---

## Task 5: APP — Isar mirror and refresh

**Files:**
- Modify: `lib/src/models/app_model.dart` (add `putMediaItem`)
- Modify: `lib/src/media/sources/reader_ttu_source.dart`
- Modify: `lib/src/pages/implementations/reader_ttu_source_history_page.dart`
- Modify: `lib/src/pages/implementations/history_reader_page.dart` (`showProgress`)
- Modify: `lib/src/pages/implementations/reader_ttu_source_page.dart` (relative identifiers, bump on open)
- Modify: `lib/i18n/strings.i18n.json` (+ regenerate)

**Interfaces:**
- Consumes: `TtuHostOperations.run`, `TtuBridge.listBooks/getCover` (Tasks 3–4).
- Produces (used by Tasks 6–7):
  ```dart
  // AppModel
  void putMediaItem(MediaItem item);
  // ReaderTtuSource
  MediaItem bookItem({required int id, required String title, String? coverPath});
  int? bookIdOf(MediaItem item);
  Directory coversDirectory(AppModel appModel);
  Future<void> syncLibrary({required AppModel appModel, required TtuBridge bridge});
  Future<void> refreshLibrary({required BuildContext context, required AppModel appModel});
  Future<T?> runWithProgress<T>({required BuildContext context, required String message, required Future<T> Function() task}); // shows a blocking progress dialog, then an error dialog on failure (returns null)
  ```

- [ ] **Step 1: `AppModel.putMediaItem`**

Next to `addMediaItem`:

```dart
  /// Insert or replace [item] as the most recent entry of its source's
  /// history, without the history size limit of [addMediaItem]. For
  /// sources whose history is a library that must not lose entries.
  void putMediaItem(MediaItem item) {
    _database.writeTxnSync(() {
      _database.mediaItems.deleteByUniqueKeySync(item.uniqueKey);
      item.id = null;
      _database.mediaItems.putSync(item);
    });
  }
```

- [ ] **Step 2: Library helpers in `ReaderTtuSource`**

Add (imports: `dart:io`, `package:mime/mime.dart`, `package:path/path.dart` as `path`):

```dart
  static const String _bookPathPrefix = 'b.html?id=';

  /// The library entry for ttu book [id].
  MediaItem bookItem({required int id, required String title, String? coverPath}) {
    return MediaItem(
      mediaIdentifier: '$_bookPathPrefix$id',
      title: title,
      imageUrl: coverPath == null ? null : 'file://$coverPath',
      mediaSourceIdentifier: uniqueKey,
      position: 0,
      duration: 1,
      canDelete: false,
      canEdit: true,
    );
  }

  /// ttu's id for a library entry, or null if [item] is not a book (e.g. the
  /// settings page).
  int? bookIdOf(MediaItem item) {
    if (!item.mediaIdentifier.startsWith(_bookPathPrefix)) {
      return null;
    }
    return int.tryParse(item.mediaIdentifier.substring(_bookPathPrefix.length));
  }

  /// Where library covers are stored, one file per book id.
  Directory coversDirectory(AppModel appModel) =>
      Directory(path.join(appModel.appDirectory.path, 'ttuCovers'));

  /// Make the Isar library match ttu's IndexedDB: add missing books (with
  /// their covers) and drop entries whose book is gone.
  Future<void> syncLibrary({
    required AppModel appModel,
    required TtuBridge bridge,
  }) async {
    List<TtuBook> books = await bridge.listBooks();
    Map<int, MediaItem> mirrored = {
      for (MediaItem item in appModel.getMediaSourceHistory(mediaSource: this))
        if (bookIdOf(item) != null) bookIdOf(item)!: item,
    };
    Directory covers = coversDirectory(appModel)..createSync(recursive: true);

    for (TtuBook book in books) {
      if (mirrored.containsKey(book.id)) {
        continue;
      }
      String? coverPath;
      String? dataUrl = await bridge.getCover(book.id);
      UriData? data = dataUrl == null ? null : Uri.parse(dataUrl).data;
      if (data != null) {
        String extension = extensionFromMime(data.mimeType) ?? 'img';
        File file = File(path.join(covers.path, '${book.id}.$extension'));
        file.writeAsBytesSync(data.contentAsBytes());
        coverPath = file.path;
      }
      appModel.putMediaItem(
        bookItem(id: book.id, title: book.title, coverPath: coverPath),
      );
    }

    Set<int> ids = books.map((book) => book.id).toSet();
    for (MapEntry<int, MediaItem> entry in mirrored.entries) {
      if (ids.contains(entry.key)) {
        continue;
      }
      for (FileSystemEntity file in covers.listSync()) {
        if (path.basenameWithoutExtension(file.path) == '${entry.key}') {
          file.deleteSync();
        }
      }
      await appModel.deleteMediaItem(entry.value);
    }

    refreshTab();
  }
```

and the UI wrappers:

```dart
  /// Run [task] behind a blocking progress dialog; on failure show the error
  /// and return null.
  Future<T?> runWithProgress<T>({
    required BuildContext context,
    required String message,
    required Future<T> Function() task,
  }) async {
    NavigatorState navigator = Navigator.of(context);
    bool progressShown = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Row(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(width: 24),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ).then((_) => progressShown = false);

    try {
      return await task();
    } catch (error) {
      if (progressShown) {
        progressShown = false;
        navigator.pop();
      }
      await showDialog(
        context: navigator.context,
        builder: (context) => AlertDialog(
          title: Text(t.ttu_operation_failed),
          content: Text(error is TtuBridgeException ? error.message : '$error'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t.dialog_close),
            ),
          ],
        ),
      );
      return null;
    } finally {
      if (progressShown) {
        progressShown = false;
        navigator.pop();
      }
    }
  }
```

Then:

```dart
  /// Reconcile the library with ttu's IndexedDB.
  Future<void> refreshLibrary({
    required BuildContext context,
    required AppModel appModel,
  }) async {
    await runWithProgress(
      context: context,
      message: t.ttu_refreshing,
      task: () => TtuHostOperations.run(
        (bridge) => syncLibrary(appModel: appModel, bridge: bridge),
      ),
    );
  }
```

- [ ] **Step 3: Replace the headless history read**

In `reader_ttu_source.dart` delete `ttuBooksProvider`, `getBooksHistory`, `getItemsFromJson`, `getHistoryJs`, and `onSourceExit`'s body (`closeMedia` already calls `refreshTab()`; keep the override only if the base class requires it, otherwise delete it). Remove imports that become unused (`dart:convert`, `collection`, `flutter_riverpod` if unused).

The settings button's `MediaItem` uses `mediaIdentifier: 'settings.html'`.

Add a refresh action to `getActions` (between settings and the existing launch button for now):

```dart
  /// Reconciles the library with ttu's IndexedDB.
  Widget buildRefreshButton({
    required BuildContext context,
    required AppModel appModel,
  }) {
    return FloatingSearchBarAction(
      showIfOpened: true,
      child: JidoujishoIconButton(
        size: Theme.of(context).textTheme.titleLarge?.fontSize,
        tooltip: t.ttu_refresh_library,
        icon: Icons.refresh,
        onTap: () => refreshLibrary(context: context, appModel: appModel),
      ),
    );
  }
```

- [ ] **Step 4: History page reads Isar**

Rewrite `_ReaderTtuSourceHistoryPageState` on the model of `reader_mokuro_history_page.dart`: listen to `mediaSource.tabRefreshNotifier` in `initState`/`dispose`, and

```dart
  @override
  Widget build(BuildContext context) {
    List<MediaItem> items = appModel
        .getMediaSourceHistory(mediaSource: mediaSource)
        .reversed
        .toList();

    return items.isEmpty ? buildPlaceholder() : buildHistory(items);
  }

  @override
  bool get showProgress => false;
```

In `history_reader_page.dart` add to `HistoryReaderPageState`:

```dart
  /// Whether tiles show a reading-progress bar.
  bool get showProgress => true;
```

and wrap the `LinearProgressIndicator(...)` child as `if (showProgress) LinearProgressIndicator(...)`.

- [ ] **Step 5: Reader page — relative identifiers, last opened**

In `reader_ttu_source_page.dart`:
- initial URL: `mediaSource.url(widget.item?.mediaIdentifier ?? 'manage.html')`;
- in `initState`, after `super.initState()`:
  ```dart
    MediaItem? item = widget.item;
    if (item != null && mediaSource.bookIdOf(item) != null) {
      appModelNoUpdate.putMediaItem(item);
    }
  ```

- [ ] **Step 6: Strings**

Add to `strings.i18n.json` next to `ttu_no_books_added`: `"ttu_refresh_library": "Refresh library"`, `"ttu_refreshing": "Refreshing library…"`, `"ttu_operation_failed": "Library operation failed"`. Change `ttu_no_books_added` to `"No books yet: import EPUB, HTMLZ or TXT files"`. `dart run slang`.

- [ ] **Step 7: Verify on the emulator (Review Focus 1, 4)**

```bash
PATH=$HOME/.local/bin:$PATH tool/fetch_ttu.sh --local ../ebook-reader-lite
```

(If the build added a directory, add it to `pubspec.yaml` as the script says.) Analyze gate; build; install. Then:
1. Novels tab opens instantly with no book (mirror empty) — no WebView is created (logcat shows no `host.html`/`index.html` GET at tab open).
2. Refresh → the Slime book imported during phase 1 appears with its cover.
3. Open it, exit → it stays first; reading position restored.
4. "Book without mirror row" is exactly step 2 (the phase-1 book). "Mirror row without book" is exercised in Task 7 (delete removes the book in ttu, then `syncLibrary` drops the row through the same branch); the TS side of `listBooks` reflecting deletions is proven in Task 1 Step 5.
5. Review Focus 1 (no 100-item cap) is verified by reading, not on device: ttu rows are only ever written by `putMediaItem` (sync and reader open), and `openMedia` never calls `addMediaItem` for ttu because `implementsHistory` stays `false`. Ledger this.

- [ ] **Step 8: Commit (two commits)**

1. `lib/src/models/app_model.dart` → `AppModel: add an uncapped putMediaItem`
2. the rest (`lib`, `pubspec.yaml` if changed) → `TTU: mirror the library in Isar`

---

## Task 6: APP — import from Flutter

**Files:**
- Modify: `lib/src/media/sources/reader_ttu_source.dart`
- Modify: `lib/i18n/strings.i18n.json` (+ regenerate)

**Interfaces:**
- Consumes: `runWithProgress`, `syncLibrary`, `TtuHostOperations.run(importDirectory:)`, `TtuBridge.importBooks`.
- Produces: `Future<void> importBooks({required BuildContext context, required AppModel appModel})` and an import action in `getActions`.

- [ ] **Step 1: Implement**

```dart
  static const List<String> _importExtensions = ['epub', 'htmlz', 'txt'];

  /// Let the user pick book files, import them with ttu's importer and add
  /// them to the library.
  Future<void> importBooks({
    required BuildContext context,
    required AppModel appModel,
  }) async {
    List<PlatformFile> picked = await FilePicker.pickFiles(type: FileType.any);
    if (picked.isEmpty || !context.mounted) {
      return;
    }

    List<PlatformFile> books = picked
        .where((file) => _importExtensions
            .contains(path.extension(file.name).replaceFirst('.', '').toLowerCase()))
        .toList();
    if (books.length != picked.length) {
      Fluttertoast.showToast(msg: t.ttu_unsupported_files);
    }
    if (books.isEmpty) {
      return;
    }

    Directory staging =
        Directory(path.join(appModel.temporaryDirectory.path, 'ttu-import'));
    if (staging.existsSync()) {
      staging.deleteSync(recursive: true);
    }
    staging.createSync(recursive: true);

    int totalBytes = 0;
    List<String> urls = [];
    for (int i = 0; i < books.length; i++) {
      // One directory per file keeps original names (ttu takes TXT titles
      // and the format from them) even when two picked files share a name.
      Directory slot = Directory(path.join(staging.path, '$i'))..createSync();
      String name = books[i].name;
      File staged = File(books[i].path!).copySync(path.join(slot.path, name));
      totalBytes += staged.lengthSync();
      urls.add(url('import/$i/${Uri.encodeComponent(name)}'));
    }

    try {
      await runWithProgress(
        context: context,
        message: t.ttu_importing(n: books.length),
        task: () => TtuHostOperations.run(
          (bridge) async {
            await bridge.importBooks(
              urls,
              timeout: Duration(seconds: 60 + totalBytes ~/ (256 * 1024)),
            );
            await syncLibrary(appModel: appModel, bridge: bridge);
          },
          importDirectory: staging,
        ),
      );
    } finally {
      staging.deleteSync(recursive: true);
      await FilePicker.clearTemporaryFiles();
    }
  }
```

Add `buildImportButton` (icon `Icons.add`, tooltip `t.ttu_import_books`) to `getActions`, before the refresh button.

Strings: `"ttu_import_books": "Import books"`, `"ttu_importing": {"one": "Importing $n book…", "other": "Importing $n books…"}` (match the plural form of existing keys like `retrying_in` used to), `"ttu_unsupported_files": "Only EPUB, HTMLZ and TXT files can be imported"`.

- [ ] **Step 2: Analyse, build, install**

Analyze gate; `flutter build apk --debug` with `ANDROID_HOME`; `adb install -r`.

- [ ] **Step 3: Emulator — happy path**

`adb push` two EPUBs to `/sdcard/Download/` (the Slime test copy is already there; add `No Game No Life - LN 01.epub` as `ngnl.epub`). Import button → pick both (long-press for multi-select in the Android picker) → progress dialog → both books in the library with covers, newest first; open one, lookup works, exit.

- [ ] **Step 4: Emulator — edge cases (Review Focus 2, 3)**

1. Import the same EPUB again → no duplicate tile.
2. Pick a non-book file (push any `.png` to Download) → toast, nothing imported.
3. Corrupt EPUB (`head -c 2000 <epub> > broken.epub`, push) → error dialog with ttu's message, progress dialog gone, library unchanged.
4. After each import (successful or not): `adb shell run-as app.arianneorpilla.yuuna ls cache` shows no `ttu-import` directory (debug builds allow `run-as`).

- [ ] **Step 5: Commit**

`TTU: import books from the library` (paths: `lib`).

---

## Task 7: APP — delete from Flutter

**Files:**
- Modify: `lib/src/media/sources/reader_ttu_source.dart`
- Modify: `lib/src/pages/implementations/reader_ttu_source_history_page.dart`
- Modify: `lib/i18n/strings.i18n.json` (+ regenerate)

**Interfaces:**
- Consumes: `runWithProgress`, `syncLibrary`, `bookIdOf`, `TtuBridge.deleteBook`.
- Produces: `Future<bool> deleteBook({required BuildContext context, required AppModel appModel, required MediaItem item})` (true if deleted).

- [ ] **Step 1: Implement**

```dart
  /// Ask for confirmation, then delete [item]'s book from ttu and the
  /// library. Returns whether it was deleted.
  Future<bool> deleteBook({
    required BuildContext context,
    required AppModel appModel,
    required MediaItem item,
  }) async {
    int? id = bookIdOf(item);
    if (id == null) {
      return false;
    }

    bool confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(item.title),
            content: Text(t.ttu_delete_book_confirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  t.dialog_delete,
                  style: TextStyle(color: Theme.of(context).colorScheme.primary),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(t.dialog_cancel),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !context.mounted) {
      return false;
    }

    return await runWithProgress(
          context: context,
          message: t.ttu_deleting,
          task: () => TtuHostOperations.run((bridge) async {
            await bridge.deleteBook(id);
            await syncLibrary(appModel: appModel, bridge: bridge);
            return true;
          }),
        ) ??
        false;
  }
```

In the history page state:

```dart
  @override
  List<Widget> extraActions(MediaItem item) {
    return [
      TextButton(
        onPressed: () async {
          NavigatorState navigator = Navigator.of(context);
          bool deleted = await mediaSource.deleteBook(
            context: context,
            appModel: appModel,
            item: item,
          );
          if (deleted) {
            navigator.pop();
          }
        },
        child: Text(
          t.dialog_delete,
          style: TextStyle(color: theme.colorScheme.primary),
        ),
      ),
    ];
  }
```

(`context` here is the history page's; the long-press dialog stays above it and is popped on success.)

Strings: `"ttu_delete_book_confirm": "Delete this book and its reading position?"`, `"ttu_deleting": "Deleting book…"`.

- [ ] **Step 2: Verify on the emulator**

Analyze gate, build, install. Long-press a book → Delete → confirm → tile gone; Refresh → it does not come back (ttu deleted it); the other books are intact; long-press → Delete → Cancel → nothing happens.

- [ ] **Step 3: Commit**

`TTU: delete books from the library` (paths: `lib`).

---

## Task 8: APP — retire the manager entry point, docs, release

**Files:**
- Modify: `lib/src/media/sources/reader_ttu_source.dart` (remove `buildLaunchButton` and `t.manager`'s last use)
- Modify: `lib/i18n/strings.i18n.json` (remove `manager` if unused elsewhere)
- Modify: `CLAUDE.md`
- Modify: `tool/ttu.lock` (after the release)

- [ ] **Step 1: Remove the manager button**

Delete `buildLaunchButton` and its entry in `getActions` (final order: import, refresh, settings). Remove `"manager"` from the strings if no other use (`grep -rn "t.manager" lib`). `dart run slang`; analyze gate.

- [ ] **Step 2: `CLAUDE.md`**

In "Reader internals" replace "history is read back out of IndexedDB via injected JS." with: "The Novels tab is an Isar mirror of ttu's library (`MediaItem` rows, covers in `ttuCovers/`), written with the uncapped `AppModel.putMediaItem`; import, delete and refresh run ttu's own code through `TtuHostOperations` (a headless WebView on the fork's `host` route). IndexedDB stays the source of truth." Update the analyzer count if it changed.

- [ ] **Step 3: Emulator pass (Review Focus 5)**

Library settings button → ttu settings → door button → back in the library. Open a book → header has no Manager/Statistics, has Exit. Whole phase-2 checklist from spec §13 once more.

- [ ] **Step 4: Commit**

`TTU: remove the manager entry point` (paths: `lib`, `CLAUDE.md`).

- [ ] **Step 5: Release v3.1.0 (ask the user first)**

Ask the user to confirm, then from the fork: `jj bookmark set main -r <last fork commit>`, `git tag -a v3.1.0 -m "ebook-reader-lite v3.1.0" main`, `git push origin main v3.1.0` (SSH; the user may need to approve the key prompt — run it with a generous timeout). Check `gh run list -R blastrock/ebook-reader-lite --workflow Release`; if no run appears, tell the user (phase 1 needed a manual re-trigger).

- [ ] **Step 6: Pin**

`tool/fetch_ttu.sh --update v3.1.0`, plain `tool/fetch_ttu.sh`, build, emulator smoke (library, open, lookup), commit `TTU: pin ebook-reader-lite v3.1.0` (path `tool/ttu.lock`). **Do not push the APP repository.**
