# CLAUDE.md

## What this is

**Yomimoto (読本)**, by Philippe Daouadi: a Flutter/Android app for reading
Japanese text with instant dictionary lookup and Anki card creation. It is a
**fork of jidoujisho (`yuuna`) 2.9.1**, being repurposed into a **book reader
with first-class e-ink support**. Repository: github.com/blastrock/yomimoto.

Everything else upstream had — YouTube, ChatGPT, the video player, the browser,
clipboard/websocket/lyrics readers, image share intents — has been deleted. What
remains is deliberately three things:

1. **Reading** — the embedded ッツ (ttu) EPUB reader and mokuro manga reader.
2. **Dictionary** — Yomichan / Migaku imports, searched from SQLite.
3. **Card creation** — the full Anki creator, with all its enhancements, exported
   to AnkiDroid.

### Fork ground rules

- **No backward compatibility is owed.** The fork ships under its own
  Android `applicationId`, so every install is fresh: the database starts
  empty. Do not write migration code, orphan cleanup, index clamping,
  or defensive nullable-ing for things that were removed. Schema changes
  have their own rule: see Persistence.
- **The rename is external only.** The `applicationId` is
  `org.kaqui.yomimoto` and the label `Yomimoto`; the AnkiDroid note type, tag,
  DCIM folder and exported file names say Yomimoto too. Internal identifiers
  deliberately keep the upstream names: the Dart package `yuuna`, the Android
  `namespace`/Java package `app.arianneorpilla.yuuna` (and the
  `app.arianneorpilla.yuuna/anki` method channel), `Jidoujisho*` classes and
  `jidoujisho_*.dart` files, and internal protocol strings (`jidoujisho://`,
  `jidoujisho-message-type`). Do not rename these as a side effect.
- The E-ink theme exists (see Pages); the rest of e-ink tuning (refresh
  behaviour, animation suppression) is a **later pass** that has not started.

## Commands

```sh
tool/fetch_ttu.sh                                          # ebook-reader-lite build → assets/ttu-ebook-reader/ (--local <path> to build a checkout)
tool/port_mokuro_layout.sh ../mokuro-reader                # mokuro-reader's line layout → assets/manga-reader/mokuro-layout.js
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # json, dart_mappable, Drift
dart run drift_dev schema dump lib/src/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/database/generated/
dart run slang                                             # regenerate lib/i18n/strings.g.dart
flutter analyze                                            # must report no issues, infos included
flutter test                                               # unit tests in test/
flutter build apk --release --split-per-abi
tool/build_release.sh                                      # the same, signed: prompts for the keystore password
```

`flutter analyze` must stay clean: CI fails on any issue, infos included. Fix
new infos rather than suppressing them; `dart fix --apply` handles most of the
mechanical ones.

`test/` mirrors `lib/src/`. The tests cover pure code and the database layer,
which runs against in-memory or temp-file SQLite: no device, no mocks. They
characterise current behaviour, oddities included, rather than prescribe it.
Anything touching `AppModel`, MeCab or the WebView is verified by manual device
testing.

CI (`.github/workflows/main.yml`) fetches the pinned ttu build, fails if
regenerating the generated files changes anything (the Drift schema dump and
its test helpers included), then runs `flutter analyze` and `flutter test`. It
builds no APK.

## Toolchain

Read **`docs/TOOLCHAIN.md`** before touching `pubspec.yaml` or anything under
`android/`. It records the versions and *what is pinned below latest and why*;
each pin also carries its reason in a comment at the constraint itself. **Do not
bump a pinned thing without reading the reason first.**

Two mechanisms keep old packages alive, and they are not interchangeable:

- **`android/settings.gradle`'s `gradle.beforeProject` shim** handles anything
  that is purely a *Gradle configuration* problem: a missing `namespace`, a
  compileSdk pinned too low, a buildscript that only lists dead `jcenter()`.
  Packages stay hosted and keep updating. This is the default fix.
- **`vendor/`** is for packages needing actual *source* changes, when the shim
  cannot help. See `vendor/README.md`.

Deliberate shortcuts and known debt are recorded in **`DEBT.md`**. Add an entry
when you take one.

## Architecture

### Barrel imports

Each directory under `lib/src/` has a barrel file in `lib/` re-exporting
everything in it. **Always import the barrel** (`package:yuuna/media.dart`),
never a file under `lib/src/` directly. Adding a file means adding an `export`
line to its barrel.

### Everything is a registered singleton

The app is built out of extension-point abstract classes. Each concrete
implementation is a **private-constructor singleton** exposed as
`static X get instance`, and carries a `uniqueKey` string that is the stable
identity used for persisted preference keys — the display name can change
freely, the `uniqueKey` cannot.

| Abstraction | Registered in | Concrete implementations |
|---|---|---|
| `HomeTab` | `AppModel.populateTabs` | `ReaderTtuSource` (Novels), `ReaderMokuroSource` (Manga), `DictionaryTab` — these three *are* the bottom nav tabs, in order |
| `MediaSource` | — | a `HomeTab` backed by a library of media items; both readers are one, the dictionary tab is not |
| `DictionaryFormat` | `AppModel.populateDictionaryFormats` | `YomichanFormat`, `MigakuFormat` |
| `Field` | `globalFields` (top of `app_model.dart`) | `SentenceField`, `TermField`, … 19 creator fields |
| `Enhancement` | `AppModel.populateEnhancements` | per-field: Forvo audio, Massif/Tatoeba/ImmersionKit sentences, image pickers, … |
| `QuickAction` | `AppModel.populateQuickActions` | the icon buttons on a dictionary result, in a fixed order: `headingQuickActions` on the term, `entryQuickActions` on each definition |

To add or remove any of these, edit the corresponding `populate*` list in
`lib/src/models/app_model.dart` — that is the single registry. Registration
order is meaningful for home tabs (tab order) and for defaults elsewhere.

Language is **not** an extension point: the app reads Japanese only, and the UI
is English only. `JapaneseLanguage` (`lib/src/language/`) is a plain singleton;
the dictionary search isolate entry point
`prepareSearchResultsJapaneseLanguage` lives in the same file.

### `AppModel`

`lib/src/models/app_model.dart` is the god object: a
`ChangeNotifier` behind a Riverpod `appProvider`, holding every registry, every
directory path, the database handles and the preference store, dictionary
search, Anki export, and a navigator key so dialogs can be opened without a
`BuildContext`. `AppModel.initialise()` in `main()` runs the whole startup
sequence and must complete before `runApp`.

`CreatorModel` (`creatorProvider`) is the much smaller sibling holding card
creator field state.

New global state generally belongs in `AppModel`. That is not an endorsement of
its size — but splitting it is its own project, not a side effect of a feature.

### Persistence

Everything persisted lives in SQLite; there is no other store.

- **SQLite** — the database, through Drift over `sqlite3` (FFI; the
  package's build hook bundles SQLite): dictionary entries, headings,
  pitches, frequencies, tags, media items, Anki mappings,
  stash items, the search history, and the dictionary history
  (`dictionary_history`, which stores each looked-up term with the wildcard
  flag it was searched with; the Dictionary tab searches them again to show
  its history cards). One file, `yomimoto.sqlite`, in the support
  directory. `AppDatabase` (`lib/src/database/`) declares the tables
  (`tables.dart`) and the search and loader queries (`search.drift`).
  `AppStore` holds app data: synchronous raw `sqlite3` reads and Drift writes
  over one shared connection. On the main isolate raw SQL is for reads only;
  every write goes through Drift. The isolates (`search`, import,
  deletion) open their own connections, and the import isolate is the one
  raw writer. A Yomichan dictionary goes through `importYomichanBanks`
  (`yomichan_import.dart`): each bank file's bytes, read straight from the
  archive, are parsed by SQLite with `json_each` and inserted set-based.
  Every bank is staged first in a `STRICT` temporary table, which is the
  import's type check: a wrongly typed value fails the whole import. A
  Migaku dictionary goes through `DictionaryImportWriter`, row by row.
  `loadHeadings` produces fully loaded headings. A `MediaItem` names its
  origin with a single `mediaSourceIdentifier` — the source and the tab are
  the same object; a title the user gave it is its `override_title` column,
  which saving the item leaves alone. The database creates the Standard
  profile with id 1 (`AnkiMapping.standardProfileId`) and it cannot be
  deleted, so the selected profile is stored by id and always resolves.
- **Preferences** — the `preference` table, key to JSON value, read and
  written only through `PreferenceStore` (`lib/src/preferences/`,
  `AppModel.preferences`). Each setting is a constant `Preference<T>`
  descriptor naming its key and constant default: app-wide ones in
  `Preferences`, a reader's own as private constants in its source, keyed
  `<uniqueKey>/<name>`. Callers use the descriptors directly
  (`appModel.preferences.get(Preferences.maximumTerms)`); `AppModel` keeps
  accessors only where it adds logic (the theme mode, the selected profile,
  the dictionary format). `PreferenceStore` loads every row at startup and
  `set` updates memory before writing through Drift: callers set without
  awaiting and read back at once, so do not remove that cache. Adding a
  setting needs no schema change; after 1.0, renaming a key or changing a
  value's type or meaning is a data migration in a `schemaVersion` bump.

  The schema is at version 3. Versions 2 and 3 are pre-1.0 bumps made because
  installs already held data: version 2's migration drops the legacy mokuro
  reader's catalogs, volumes (with their stashes) and two settings, version
  3's removes the deleted text segmentation enhancement from every profile's
  slots, and `test/database/schema_test.dart` tests each from the previous
  snapshot. Until
  1.0 ships, a schema edit changes the latest version in place and re-dumps
  it (`drift_schemas/`), unless installed data must be kept; after 1.0, every
  change bumps `schemaVersion`, adds a migration, dumps a new snapshot and
  adds a migration test (`drift_dev make-migrations`).

Dictionary import, deletion and search run in **isolates** via `compute` /
`cancelable_compute`. Isolate entry points must therefore be **top-level
functions**, by convention placed at the bottom of the file that uses them —
this is why `DictionaryFormat` takes function references in its constructor
rather than declaring abstract methods.

### Pages

`BasePage`/`BasePageState` (`lib/src/pages/base_page.dart`) is the root widget
class: a `ConsumerStatefulWidget` giving every page `appModel`, `creatorModel`,
their `NoUpdate` (`ref.read`) variants for use in `initState`/`dispose`, `theme`,
`textTheme`, and the shared text-selection controls that wire selection →
dictionary lookup. Subclasses: `BaseTabPage`, `BaseHistoryPage`,
`BaseSourcePage` (media pages; also listens for creator open/close).

Concrete pages live in `lib/src/pages/implementations/`. Dialogs are pages too.
`SettingsPage` is the newest and the best model to imitate for new UI.

Reusable widgets are `lib/src/utils/components/jidoujisho_*.dart`.

The E-ink theme borders windows, text buttons and the dictionary's quick
actions; other buttons have no border in it, deliberately.

### i18n

`slang`, not `flutter_localizations` codegen. Strings live in
`lib/i18n/strings.i18n.json`; `lib/i18n/strings.g.dart` is **generated, never
edit it**. Access is the global `t` (exported via `utils.dart`), e.g.
`t.options_attribution`, and `t[key]` for dynamic keys like a home tab's
`uniqueKey`. Only `en-US` exists.

### Reader internals

- **ttu** — `assets/ttu-ebook-reader/` is the build of the `ebook-reader-lite`
  fork (github.com/blastrock/ebook-reader-lite), not committed:
  `tool/fetch_ttu.sh` downloads the release pinned in `tool/ttu.lock`. It is
  served by a `WebViewAssetLoader` (`TtuAssetPathHandler`) on
  `https://appassets.androidplatform.net` and displayed in
  `flutter_inappwebview`. Books live in the WebView's IndexedDB, which stays
  the source of truth. The origin (`ReaderTtuSource.origin`) must stay fixed:
  IndexedDB is tied to it. The app talks to ttu only through `TtuBridge` (the
  fork's `apps/web/src/lib/host/`), never by injecting JS.

  The app sets the book's colours: `AppColors.ttu` is a `TtuColours` per
  theme, sent with `setTheme` when the bridge is ready and when the theme
  changes. The theme chosen in ttu's own settings has no effect in the app.
  The fork keeps the last colours in `localStorage.ttuHostTheme`, so a book
  opens in them before the command arrives.

  The Novels tab is a database mirror of that library: `MediaItem` rows whose
  `mediaIdentifier` is the relative reader path `b.html?id=<ttu id>`, with
  covers stored in `ttuCovers/`. Rows are written with
  `AppModel.putMediaItem`, which unlike `addMediaItem` has no 100-item cap;
  `implementsHistory` stays `false` so `openMedia` never caps them. Import,
  delete and Refresh run ttu's own code through `TtuHostOperations` (a
  headless WebView on the fork's `host` route), then `syncLibrary`
  reconciles the mirror. ttu's manager page is not reachable from the app.

  The **stash** is a per-book list of saved words (`StashItem`, a foreign key to
  the book's `media_item` row, `ON DELETE CASCADE`), filled by the
  `AddToStashAction` quick action and shown by `StashPage` / `StashItemPage`
  from the library's long-press dialog. A `tap` event carries the tapped
  character's `position` in ttu bookmark units; `ReaderTtuSource.peekBook` opens
  `b.html?id=N&peek=<position>`, which starts at that position and saves no
  bookmark for the session. Card fields take their sentence and book from a
  `CreatorContext`, never from the reader's live state, so cards can be made
  from a stash item. Deleting a book (through `syncLibrary`) deletes its stash.
  `putMediaItem` upserts by source and identifier, keeps the row id (the stash
  refers to it) and orders the library by `last_opened_at`.

  Working on the ttu side:

  - The fork's overlay lives in new files under `apps/web/src/lib/host/`, with
    only small hooks in upstream files, so it can be rebased onto upstream.
    It is inert outside the app (gated on `window.flutter_inappwebview`).
    `localStorage.ttuHostDebug = '1'` installs a fake host in a desktop
    browser: events are logged to the console and commands can be called as
    `window.ttuHost.<command>({...})`.
  - The protocol version is `PROTOCOL_VERSION` in `host-bridge.ts` and
    `TtuBridge.protocolVersion`; bump both when an event or command changes
    shape. A mismatch shows a snackbar in the reader.
  - Iterate with `tool/fetch_ttu.sh --local ../ebook-reader-lite` (needs
    `pnpm install` done in the fork once). Releases are `vX.Y.Z` tags on the
    fork, built by its `release.yml`; pin one with
    `tool/fetch_ttu.sh --update <tag>` and commit `tool/ttu.lock`.
  - Upstream's `pnpm check` already fails (42 errors); only CI's
    `pnpm eslint .` (run from the fork's root), `pnpm build` and the
    end-to-end tests are expected to pass.
  - The overlay's end-to-end tests are Playwright, in the fork's
    `apps/web/e2e/`: tap positions and peek, in both view modes, against a
    generated fixture EPUB. Run them in `apps/web` after `pnpm build`, with
    `pnpm test:e2e` (`pnpm exec playwright install chromium` once). A change
    to positions or peek should come with a case there.

  Known quirks, all harmless:

  - The SvelteKit service worker fails to register under the asset loader
    (requests made by a service worker bypass `WebViewAssetLoader`), which
    logs an `Uncaught (in promise) TypeError` in the console. ttu works
    without it; do not chase it.
  - Volume keys only reach Flutter once the WebView has been touched: before
    that no native view has focus, so keys sent with `adb shell input
    keyevent` right after opening a book change the system volume instead.
    Tap the page first when testing on an emulator.
  - Tapping another word while one is highlighted starts a new lookup: the
    tap's mousedown clears the selection before `click` fires.
- **manga** — reads volumes processed by mokuro: page images and a `.mokuro`
  file (per-page OCR text blocks with their boxes and line quads). Nothing of
  mokuro or mokuro-reader runs in the app. `assets/manga-reader/` is our own
  page (hand-written HTML/CSS/JS, no build step) showing one volume in a
  WebView; `mokuro-layout.js` beside it is mokuro-reader's line layout
  (`line-coords-layout`, `line-grid`, `glyph-insets` at `bfaeb482`), generated
  by `tool/port_mokuro_layout.sh`: do not edit it. The page is served on the
  asset loader's origin at `/manga/` (`MokuroAssetPathHandler`), the open
  volume's files at `/volume/` (`MokuroVolumePathHandler`), and the app talks
  to it only through `MokuroBridge` (`mokuroHost` handler, `window.mokuroHost`
  commands); its protocol version is `PROTOCOL_VERSION` in `reader.js` and
  `MokuroBridge.protocolVersion`: bump both when a message changes shape.
  The page stores nothing.

  Volumes come in two ways, both from the tab's `+` popup: a file, or a
  catalog download. Import takes a `.cbz` or `.zip` only, with its
  `.mokuro` beside it (how mokuro-bunko serves volumes) or inside it
  (`ReaderMokuroSource.importArchive`, shared by both ways), and copies the
  volume into
  `mangaVolumes/<volume_uuid>/` (`volume.mokuro`, `images/<img_path>`) in an
  isolate (`importMokuroVolume`). `img_path` is resolved at the archive root,
  then in its single top-level folder, since producers disagree. Each volume
  is a `media_item` keyed by its `volume_uuid`; re-importing keeps the row.
  The position is the highest page shown, and the stash position is the page
  index; `ReaderMokuroSource.peek` opens a page without saving. A bubble is
  a card's sentence, its page the image (also for cards from the stash,
  through `CreatorContext.imageData`).

  Catalogs are mokuro-bunko servers (mokuro.moe), stored as base URLs in
  the `reader_mokuro/catalogs` preference. `MokuroCatalogClient`
  (`mokuro_catalog.dart`) reads their public API: the library, a series'
  volumes, its `series.json` (volume ids, for the library check) and a
  volume's manifest; only the manifest is versioned, and a version other
  than 1 is refused. `downloadCatalogVolumes` (`mokuro_catalog_download.dart`)
  downloads `volume.cbz` and `volume.mokuro` into
  `<temporary>/catalogDownloads/` one volume at a time and hands them to the
  import; Cancel stops a download at once but lets an import finish. Native
  titles are shown, romaji only searched.

  The page works in a desktop browser with `?debug=1` (events logged to the
  console, commands callable as `await mokuroHost.<command>({...})`): serve
  a directory holding `manga/` (the assets) and `volume/` (a `volume.mokuro`
  and its `images/`) with `python3 -m http.server`.

Both hand selected text to `AppModel.openRecursiveDictionarySearch` — that path,
selection → lookup → card creation, is the app's core interaction. Treat it as
load-bearing.

**Sentence explanation**: the `ExplainSentenceAction` heading quick action sends the reader's current
sentence to the Anthropic Messages API with the user's key and shows the
translation and the sentence's parts (reading, meaning) in
`SentenceExplanationDialogPage`. The prompts, schema, request and parsing are
pure code in `lib/src/utils/explanation/`; the novel prompt comes out of a
measured comparison, so change it only with a new one. Each reader's source
gives its `MediaSource.explanationKind` (novel or manga); the ttu page sets
`explanationContext` to the `getContext` bridge command (preceding paragraphs
with furigana as `kanji(reading)`), and manga sends the bubble alone. Settings:
`Preferences.explanationApiKey` and `explanationPreset` (Sonnet 5.5 or
Haiku 5.5, each with its own thinking settings).

## Conventions

- The code predates the current `dart format` style: running it on an
  existing file rewrites unrelated lines. Format new code by hand to match the
  surrounding file instead.
- `analysis_options.yaml` enables a strict rule set, notably
  **`public_member_api_docs`**: every public class, member and getter needs a
  `///` doc comment.
- Toasts go through `showToast` (`lib/src/utils/misc/toast.dart`), never
  `Fluttertoast.showToast` directly.
- Spelling in identifiers, comments and strings is **British/upstream style**
  (`initialise`, `localisation`, `customisation`). Match it.
- Dependency and override entries in `pubspec.yaml` carry a comment explaining
  *why* whenever they are unusual. Keep that up — it is the only record.
- Generated files (`*.g.dart`, `*.mapper.dart`, `lib/i18n/strings.g.dart`) are
  committed. Regenerate rather than hand-edit, and commit the result.

## Version control

This is a **git-colocated jj repo**. `git status` will show a detached HEAD;
that is normal. Prefer `jj` commands.
