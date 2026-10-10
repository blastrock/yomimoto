# CLAUDE.md

## What this is

A Flutter/Android app for reading foreign-language text with instant dictionary
lookup and Anki card creation. It is a **fork of jidoujisho (`yuuna`) 2.9.1**,
being repurposed into a **book reader with first-class e-ink support**.

Everything else upstream had — YouTube, ChatGPT, the video player, the browser,
clipboard/websocket/lyrics readers, image share intents — has been deleted. What
remains is deliberately three things:

1. **Reading** — the embedded ッツ (ttu) EPUB reader and mokuro manga reader.
2. **Dictionary** — Yomichan / Migaku imports, searched from Isar.
3. **Card creation** — the full Anki creator, with all its enhancements, exported
   to AnkiDroid.

### Fork ground rules

- **No backward compatibility is owed.** The fork will ship under its own
  Android `applicationId`, so every install is fresh: Isar and Hive start empty.
  Do not write migration code, orphan cleanup, index clamping, or defensive
  nullable-ing for things that were removed. Deleting a schema from
  `globalSchemas` is free.
- **The rename has not happened yet.** The package is still `yuuna`, the
  `applicationId` is still `app.arianneorpilla.yuuna`, and the label is still
  `jidoujisho`. The new name is undecided.
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
flutter analyze                                            # must stay free of errors and warnings
flutter build apk --release --split-per-abi
```

`flutter analyze` currently reports **81 infos, 0 errors, 0 warnings**, all on
pre-existing code (`use_build_context_synchronously`, `unnecessary_underscores`,
`strict_top_level_inference`). Do not let that number grow; new code should be
clean.

There are **no tests** — no `test/` directory, no widget or unit tests. Changes
are verified by `flutter analyze` plus manual device testing.

`.github/workflows/main.yml` is **stale**: it still pins Flutter 3.13.5 and JDK
11 and will fail against the current toolchain. Ignore it, or fix it as part of
whatever you are doing.

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
  mappings, search history, mokuro catalogs. Schemas are listed in
  `globalSchemas` at the top of `app_model.dart`; the list must match the
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
  `flutter_inappwebview`. Books live in the WebView's IndexedDB, not in Isar;
  history is read back out of IndexedDB via injected JS. The origin
  (`ReaderTtuSource.origin`) must stay fixed: IndexedDB is tied to it. The
  reader page talks to ttu only through `TtuBridge` (the fork's
  `apps/web/src/lib/host/`), never by injecting JS.
- **mokuro** — reads mokuro-processed manga (HTML + OCR text overlay), with a
  catalog of remote/local sources persisted in Isar (`MokuroCatalog`).

Both hand selected text to `AppModel.openRecursiveDictionarySearch` — that path,
selection → lookup → card creation, is the app's core interaction. Treat it as
load-bearing.

## Conventions

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
