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
2. **Dictionary** — Yomichan / Migaku imports, searched from Isar.
3. **Card creation** — the full Anki creator, with all its enhancements, exported
   to AnkiDroid.

### Fork ground rules

- **No backward compatibility is owed.** The fork ships under its own
  Android `applicationId`, so every install is fresh: Isar and Hive start empty.
  Do not write migration code, orphan cleanup, index clamping, or defensive
  nullable-ing for things that were removed. Deleting a schema from
  `globalSchemas` is free.
- **The rename is external only.** The `applicationId` is
  `org.kaqui.yomimoto` and the label `Yomimoto`; the AnkiDroid note type, tag,
  DCIM folder and exported file names say Yomimoto too. Internal identifiers
  deliberately keep the upstream names: the Dart package `yuuna`, the Android
  `namespace`/Java package `app.arianneorpilla.yuuna` (and the
  `app.arianneorpilla.yuuna/anki` method channel), `Jidoujisho*` classes and
  `jidoujisho_*.dart` files, and internal protocol strings (`jidoujisho://`,
  `jidoujisho-message-type`). Do not rename these as a side effect.
- **An older fork lineage exists in this repo's history** (`cc7e4925..8189e2fa`,
  "白い熊 辞書"). It did similar removals against the pre-migration tree. It is
  considered diverged — ignore it, do not cherry-pick from it.
- E-ink UI tuning (refresh behaviour, contrast, animation suppression) is a
  **later pass** that has not started.

## Commands

```sh
tool/fetch_ttu.sh                                          # ebook-reader-lite build → assets/ttu-ebook-reader/ (--local <path> to build a checkout)
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Isar, json, dart_mappable
dart run slang                                             # regenerate lib/i18n/strings.g.dart
tool/check_analyze.sh                                      # flutter analyze gate: no errors/warnings, infos ≤ baseline
flutter build apk --release --split-per-abi
```

`flutter analyze` reports infos on pre-existing code
(`use_build_context_synchronously`, `unnecessary_underscores`,
`strict_top_level_inference`), and exits non-zero because of them.
`tool/check_analyze.sh` is the real gate: it fails on any error or warning, or
when infos exceed the baseline held in the script (`max_infos`). Do not let
that number grow; new code should be clean. Lower it when you fix infos.

There are **no tests** — no `test/` directory, no widget or unit tests. Changes
are verified by `flutter analyze` plus manual device testing.

CI (`.github/workflows/main.yml`, every push and pull request) fetches the
pinned ttu build, checks that generated files are fresh (regenerates them and
fails on `git diff`), and runs `tool/check_analyze.sh`. It builds no APK.
`slang.yaml` turns off slang's build timestamp so the freshness check is
deterministic.

## Toolchain

Read **`docs/TOOLCHAIN.md`** before touching `pubspec.yaml` or anything under
`android/`. It records the versions (Flutter 3.44.8 / JDK 21 / AGP 8.11.1,
compileSdk 36 / targetSdk 32 / minSdk 24), and — more importantly — *what is
pinned below latest and why*: AGP stays on 8 because `app/build.gradle` uses the
legacy variant API and plugins still call `jcenter()`; `targetSdk` stays at 32;
Material 3 stays off; `permission_handler`, `dart_mappable_builder` are held.
Each pin also carries its reason in a comment at the constraint itself. **Do not
bump a pinned thing without reading the reason first.**

Two mechanisms keep old packages alive, and they are not interchangeable:

- **`android/settings.gradle`'s `gradle.beforeProject` shim** handles anything
  that is purely a *Gradle configuration* problem — a missing `namespace`, a
  compileSdk pinned too low, a buildscript that only lists dead `jcenter()`.
  Packages stay hosted and keep updating. This is the default fix.
- **`vendor/`** is for packages needing actual *source* changes. Each carries an
  `UPSTREAM.md` (source, ref, why, exit condition) and a `local-changes.patch`
  (`diff -ruN` against pristine upstream) so it can be refreshed rather than
  reconstructed. See `vendor/README.md`. Reach for this only when the shim
  cannot help.

Known debt worth knowing about: `spaces` is a dead git-pinned package imported
in 46 files and is the only reason for two `dependency_overrides`; `ve_dart` is
also a third-party git ref. Both are liabilities of the same kind that already
bit this project once.

## Architecture

### Barrel imports

`lib/` has seven barrel files — `creator.dart`, `dictionary.dart`,
`language.dart`, `media.dart`, `models.dart`, `pages.dart`, `utils.dart` —
re-exporting everything under `lib/src/<name>/`. **Always import the barrel**
(`package:yuuna/media.dart`), never a file under `lib/src/` directly, and always
`package:` imports (`always_use_package_imports` is enforced). Adding a file
means adding an `export` line to its barrel.

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
| `QuickAction` | `AppModel.populateQuickActions` | the icon buttons on a dictionary result |

To add or remove any of these, edit the corresponding `populate*` list in
`lib/src/models/app_model.dart` — that is the single registry. Registration
order is meaningful for home tabs (tab order) and for defaults elsewhere.

Language is **not** an extension point. The app reads Japanese only, and the UI
is English only (via slang, see below). `JapaneseLanguage`
(`lib/src/language/`) is a plain singleton for segmentation (MeCab), sentence
splitting, highlight lengths, furigana and pitch display. The dictionary search
isolate entry point `prepareSearchResultsJapaneseLanguage` lives in the same
file.

### `AppModel`

`lib/src/models/app_model.dart` (~3200 lines) is the god object: a
`ChangeNotifier` behind a Riverpod `appProvider`, holding every registry, every
directory path, the Isar handle, the Hive preference boxes, dictionary search,
Anki export, and a navigator key so dialogs can be opened without a
`BuildContext`. `AppModel.initialise()` in `main()` runs the whole startup
sequence and must complete before `runApp`.

`CreatorModel` (`creatorProvider`) is the much smaller sibling holding card
creator field state.

New global state generally belongs in `AppModel`. That is not an endorsement of
its size — but splitting it is its own project, not a side effect of a feature.

### Persistence

- **Hive** — key-value preferences. `Box('appModel')` for app-wide settings
  (accessed through typed getter/setter pairs on `AppModel`, e.g. `isDarkMode`,
  `maximumTerms`), plus a per-`MediaSource` box for source-specific settings.
- **Isar** (`isar_community` fork) — the real database: dictionary entries,
  headings, pitches, frequencies, tags, search-result cache, media items, Anki
  mappings, search history, mokuro catalogs, stash items. Schemas are listed
  in `globalSchemas` at the top of `app_model.dart`; the list must match the
  `@Collection()` classes. A `MediaItem` names its origin with a single
  `mediaSourceIdentifier` — the source and the tab are the same object.

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

### i18n

`slang`, not `flutter_localizations` codegen. Strings live in
`lib/i18n/strings.i18n.json`; `lib/i18n/strings.g.dart` is **generated — never
edit it**. Regenerate with `dart run slang`. Access is the global `t` (exported
via `utils.dart`), e.g. `t.options_attribution`, and `t[key]` for dynamic keys
like a home tab's `uniqueKey`. Only `en-US` exists; upstream's Crowdin
translations are gone.

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

  The Novels tab is an Isar mirror of that library: `MediaItem` rows whose
  `mediaIdentifier` is the relative reader path `b.html?id=<ttu id>`, with
  covers stored in `ttuCovers/`. Rows are written with
  `AppModel.putMediaItem`, which unlike `addMediaItem` has no 100-item cap;
  `implementsHistory` stays `false` so `openMedia` never caps them. Import,
  delete and Refresh run ttu's own code through `TtuHostOperations` (a
  headless WebView on the fork's `host` route), then `syncLibrary`
  reconciles the mirror. ttu's manager page is not reachable from the app.

  The **stash** is a per-book list of saved words (`StashItem`, keyed by the
  book's `mediaIdentifier`), filled by the `AddToStashAction` quick action and
  shown by `StashPage` / `StashItemPage` from the library's long-press dialog.
  A `tap` event carries the tapped character's `position` in ttu bookmark
  units; `ReaderTtuSource.peekBook` opens `b.html?id=N&peek=<position>`,
  which starts at that position and saves no bookmark for the session.
  Card fields take their sentence and book from a `CreatorContext`, never
  from the reader's live state, so cards can be made from a stash item.
  Deleting a book (through `syncLibrary`) deletes its stash.

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
- **mokuro** — reads mokuro-processed manga (HTML + OCR text overlay), with a
  catalog of remote/local sources persisted in Isar (`MokuroCatalog`).

Both hand selected text to `AppModel.openRecursiveDictionarySearch` — that path,
selection → lookup → card creation, is the app's core interaction. Treat it as
load-bearing.

## Conventions

- The code predates the current `dart format` style: running it on an
  existing file rewrites unrelated lines. Format new code by hand to match the
  surrounding file instead.
- `analysis_options.yaml` enables a large strict rule set on top of
  `flutter_lints` 6. Notably **`public_member_api_docs`**: every public class,
  member and getter needs a `///` doc comment. Also `prefer_single_quotes`,
  `sort_constructors_first`, `sort_pub_dependencies`,
  `always_put_control_body_on_new_line`, `prefer_asserts_with_message`.
  Generated files and `vendor/` are excluded.
- Spelling in identifiers, comments and strings is **British/upstream style**
  (`initialise`, `localisation`, `customisation`). Match it.
- Dependency and override entries in `pubspec.yaml` carry a comment explaining
  *why* whenever they are unusual. Keep that up — it is the only record.
- Generated files (`*.g.dart`, `*.mapper.dart`, `lib/i18n/strings.g.dart`) are
  committed. Regenerate rather than hand-edit, and commit the result.

## Version control

This is a **git-colocated jj repo**. `git status` will show a detached HEAD;
that is normal. Prefer `jj` commands.
