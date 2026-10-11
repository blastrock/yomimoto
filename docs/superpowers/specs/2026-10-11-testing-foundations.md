# Testing foundations — brief

Date: 2026-10-11

Hand-off brief for an agent with no prior context. It covers the first three
steps of adding tests to Yomimoto and its ttu fork. Read `CLAUDE.md` and
`docs/TOOLCHAIN.md` first; they bind everything below. The section
"Pitfalls already hit" lists traps found while building the stash feature;
read it before running anything.

## Prompt for the implementing agent

> Implement steps 1–3 of
> `docs/superpowers/specs/2026-10-11-testing-foundations.md` (this file), in
> order, in `/home/blastrock/work/yomimoto` and the sibling ttu fork
> `/home/blastrock/work/ebook-reader-lite`. Read `CLAUDE.md`,
> `docs/TOOLCHAIN.md` and this whole brief first, including "Pitfalls
> already hit". Each step is its own set of jj commits. Verify every step as
> the brief says before moving on, and report the exact commands and their
> results. Where the brief says "stop and report", do that instead of
> working around it. Do not push, do not create tags, and do not change
> product code except where a step explicitly says so. When done, list what
> you verified, what you could not verify (e.g. the GitHub Actions run),
> and every decision you made that the brief did not settle.

1. **CI gate** for the app (analyze, then tests).
2. **Playwright end-to-end tests** in the ttu fork (`../ebook-reader-lite`),
   covering the host bridge's tap positions and peek mode.
3. **First Dart unit tests** in the app: pure code only, no device, no
   database, no mocks.

Each step is a separate unit of work with its own commits. Do them in this
order; step 1's workflow gains a `flutter test` line in step 3.

## Ground rules

- Both repositories are git-colocated **jj** repos. Commit with
  `jj commit -m '…'`. End app commit messages with the attribution trailer
  given in your session. Never push, and never create release tags unless the
  user asks; the user pushes.
- **Characterisation, not correction.** These tests pin today's behaviour. If
  a test reveals behaviour that looks wrong, do not change product code in
  this work: keep the test on the current behaviour (or mark it `skip:` with
  a reason) and report the finding to the user.
- **Pin exact versions** of every new dependency and GitHub Action, with a
  comment when the choice is unusual (`CLAUDE.md`, `pubspec.yaml`
  convention). Pick versions that are current stable releases, not
  pre-releases.
- `flutter analyze` must stay at **76 infos, 0 errors, 0 warnings**. New code
  adds no infos. The strict rule set in `analysis_options.yaml` applies to
  `test/` too; fix what it reports rather than excluding `test/`. If a rule
  is genuinely unsuited to tests (e.g. `public_member_api_docs` firing on a
  test helper), ask the user before adding an exclusion.
- British spelling in comments and strings, `package:` imports through the
  barrels (`package:yuuna/utils.dart`, …), never `lib/src/...` paths.

---

## Step 1 — CI gate for the app

### Current state

`.github/workflows/main.yml` is stale and fails against the current
toolchain:

```yaml
- uses: actions/setup-java@v2      # java-version: '11'
- uses: subosito/flutter-action@v2 # flutter-version: '3.13.5'
- run: flutter pub get
- run: flutter pub run build_runner build --delete-conflicting-outputs
- run: flutter analyze
- run: flutter build apk --target-platform=android-arm64
```

It also only triggers on the `main` branch, but the user's current work
line is not on `main` (the `main` bookmark points at an older lineage).
Trigger on every push and pull request instead, as the fork's CI does
(`on: [push, pull_request]`).

### What to build

Rewrite `main.yml` (keep the file name, retitle it e.g. "CI"). **No APK
build** for now (user decision): the workflow only gates analysis and tests.

1. `actions/checkout` and `subosito/flutter-action` with **Flutter
   3.44.8**, stable channel, cache enabled. No `setup-java`: Java is only
   needed for Android builds, which this workflow no longer does. Exact versions: `docs/TOOLCHAIN.md`. Pin each
   action to an exact release tag, as the fork's `ci.yml` does
   (`actions/checkout@v7.0.1` style).
2. `tool/fetch_ttu.sh` **before** `flutter pub get` / `flutter analyze`.
   `pubspec.yaml` lists `assets/ttu-ebook-reader/` and its subdirectories,
   which are git-ignored and populated by that script; without them the
   analyzer reports missing asset directories. The script needs `curl`,
   `unzip` and `sha256sum` (all present on `ubuntu-latest`) and downloads the
   release pinned in `tool/ttu.lock`.
3. `flutter pub get`.
4. **Do not run `build_runner` or `slang` to produce code.** Generated files
   are committed. Instead, add a freshness check: run
   `dart run build_runner build --delete-conflicting-outputs` and
   `dart run slang`, then `git diff --exit-code` so CI fails when someone
   forgot to regenerate. (Observed locally: build_runner rewrote 30 outputs
   but only the changed one differed, so it is deterministic. If CI shows a
   spurious diff, drop this check and report it rather than fighting it.)
5. **Analyze gate**: commit a script, e.g. `tool/check_analyze.sh`, and call
   it from CI. `flutter analyze` exits non-zero on infos by default, so the
   script runs `flutter analyze --no-fatal-infos` (warnings and errors stay
   fatal), counts info lines, and fails if they exceed a maximum held in the
   script (76). This is the logic that was used locally:

   ```bash
   out=$(flutter analyze --no-fatal-infos 2>&1); rc=$?
   infos=$(grep -c " info " <<<"$out")
   bad=$(grep -cE " (error|warning) " <<<"$out")
   echo "analyze: rc=$rc infos=$infos errors+warnings=$bad"
   [ "$rc" -eq 0 ] && [ "$bad" -eq 0 ] && [ "$infos" -le 76 ]
   ```

   Print the analyzer output when it fails. Keep the number in one place and
   reference the script from `CLAUDE.md` (which currently says 76 in prose).

### Verification

GitHub Actions cannot be run locally. Run each step's command locally in the
same order to prove the sequence works (fresh clone of the repo into a
temporary directory is the honest test: it proves `fetch_ttu.sh` is enough).
If `actionlint` is installed, lint the workflow. Then tell the user the
workflow is ready to be validated by a push; do not push.

### Docs

Update `CLAUDE.md`: the "`.github/workflows/main.yml` is stale" paragraph
goes away; the Commands block gains `tool/check_analyze.sh`.

---

## Step 2 — Playwright end-to-end tests in the ttu fork

### Why

The fork's host overlay (`apps/web/src/lib/host/`) is the contract between
ttu and the app, and it depends on real layout: positions come from DOM
ranges, peek from ttu's bookmark loading. A throwaway headless-Chromium
script (Chrome DevTools Protocol, no dependencies) already proved all of it
during the stash feature work. This step turns that script into a
maintained Playwright suite that runs in the fork's CI.

### What exists in the fork today

- No test tooling (`package.json` has no test runner). CI
  (`.github/workflows/ci.yml`): pnpm 12.3.4, Node 24.21.0, `pnpm install`,
  `pnpm svelte-kit sync` in `apps/web`, `pnpm eslint .` **at the repository
  root**, `pnpm build`.
- `pnpm build` writes a static site to `apps/web/build/` (adapter-static,
  `404.html` fallback). Pages are `b.html?id=<book id>`, `host.html`,
  `manage.html`, … The build directory is git-ignored.
- `pnpm check` already fails upstream (42 errors); ignore it.
- `@zip.js/zip.js` 2.4.26 is already a dependency (useful for building the
  fixture EPUB in TypeScript).
- Fork convention: the overlay lives in **new files**, upstream files only
  get small hooks, so the fork can be rebased. Tests go in a new
  `apps/web/e2e/` directory plus `apps/web/playwright.config.ts`; touching
  upstream files should not be needed beyond `package.json` and CI.

### Facts the tests rely on (all verified)

- **Debug host**: with `localStorage.ttuHostDebug = '1'`, `installDebugHost`
  (`host-debug.ts`) installs a fake `window.flutter_inappwebview` whose
  `callHandler(name, payload)` logs to the console; `isHost()` is then true
  and `window.ttuHost.<command>(args)` exposes the commands.
  `installDebugHost` returns early if `window.flutter_inappwebview` already
  exists — so a Playwright `addInitScript` can define its own
  `{ _platformReady: true, callHandler(name, payload) { … } }` before any
  app script runs, recording events in `window.__events`. That is cleaner
  than what the CDP script did (replacing `callHandler` after load). The
  init-script variant is **not yet verified**; if it does not work, fall
  back to the debug flag plus replacing `callHandler` after load, which is
  verified.
- **Events**: `tap` payload is `{ type: 'tap', text, offset, x, y, position }`;
  `position` is ttu's character count at the tapped character (or -1).
- **Commands used**: `listBooks({})` → `[{ id, title }]`;
  `importBooks({ urls: [url] })` (fetches same-origin URLs, then imports);
  `nextPage({})`, `prevPage({})`.
- **View mode**: `localStorage.viewMode` = `'paginated'` (default) or
  `'continuous'`. Run the position tests in both.
- **Bookmarks** live in IndexedDB database `books`, object store `bookmark`,
  keyed by book id. The default keybinding **KeyB** saves a bookmark
  (`store.ts`: `KeyB: BookReaderAvailableKeybind.BOOKMARK`).
- **Character counting**: ttu counts only characters matching
  `get-character-count.ts`'s regex (Japanese, digits, Latin letters;
  punctuation such as `。` and ruby `<rt>` text are not counted). The tests
  mirror the regex to compute expected differences (Appendix B).
- **Peek**: `b.html?id=N&peek=P` opens at position P and suppresses every
  bookmark write for the session (`bookmarkPage` and `completeBook` in
  `routes/b/+page.svelte` are guarded by `getPeekPosition()` from
  `host-position.ts`). `getPeekPosition()` returns undefined when
  `!isHost()`, so outside the app `peek` is ignored.
- The SvelteKit **service worker** fails to register when served this way;
  that console error is expected and must be filtered out of any
  "no uncaught errors" assertion.

### Serving the build

Serve `apps/web/build/` statically and put the fixture EPUB next to it so
`importBooks` can fetch it from the same origin. Verified approach:
`python3 -m http.server 8765 --bind 127.0.0.1` with the build directory as
working directory (Python 3 is on `ubuntu-latest`). Wire it as Playwright's
`webServer`. `vite preview` may work too but was not tried; if you use it,
check that `/b.html?id=…` and `/host.html` resolve. Do not write the fixture
into the source tree: generate it in Playwright `globalSetup` into the
served directory (git-ignored), or into a temporary directory served
alongside.

### Fixture book

A two-chapter EPUB 3 with furigana and Latin letters. Generator used so far
(Python; port it to TypeScript with `@zip.js/zip.js`, or keep a small
script — your call). It is in Appendix A. Requirements: `mimetype` stored
uncompressed as the first entry; chapter 1 paragraph 6 contains
`彼は<ruby>漢字<rt>かんじ</rt></ruby>を書いた。ABCとあいうえお。`; chapter 2
paragraph 11 contains `目標の言葉はここにある。探偵が<ruby>謎<rt>なぞ</rt></ruby>を解いた。`;
all other paragraphs are a filler sentence ×3, 40 paragraphs per chapter.

### Test cases

Use a fixed viewport (800×1000 was used). Positions are character counts, so
they do not depend on the viewport; screen coordinates do.

**Positions** — run in both view modes:

| Case | Expected (observed in both modes) |
|---|---|
| First character of the first paragraph (`これは試験…`) | 3 (the heading `第1章` counts 3) |
| Fifth character of the same paragraph | first + 4 (= 7) |
| `漢` (inside ruby) then `を` right after the ruby | difference 2 (425 → 427): ruby text not counted |
| `を` then `と` in `を書いた。ABCとあいうえお` | difference = ttu count of `を書いた。ABC` = 7 (434) |
| `目` of `目標の言葉` (chapter 2) | 4167, and greater than any chapter-1 position |
| `目` then `探` | difference = ttu count of `目標の言葉はここにある。` (4178) |

Asserting the absolute values is fine (they only depend on the fixture); keep
the difference assertions too, since they state the rules.

**Peek** — both view modes:

1. *Control*: open the book normally, turn 3 pages, press KeyB → the stored
   bookmark has `exploredCharCount > 0`. This proves the suppression checks
   below are meaningful.
2. `peek=4167`: the reader opens with `目標の言葉` on screen.
3. For `peek=4167`, `peek=0` and `peek=99999999`: read the stored bookmark,
   open with peek, turn 3 pages, press KeyB, navigate away
   (`manage.html`), read the stored bookmark again → **byte-identical**
   (compare JSON). No uncaught page errors apart from the service worker.
4. *Outside the app*: without the debug host (no `flutter_inappwebview`, no
   `ttuHostDebug`), `?peek=` is ignored — opening with `peek` and pressing
   KeyB does save a bookmark. This case was **not** verified before; it is
   new coverage.

### Pitfalls already hit

- **Clicking while a page turn is still animating** taps the wrong place: a
  test once reported 4214 instead of 4167 for that reason. After bringing a
  word on screen, wait for the scroll to settle (600 ms worked), re-measure,
  then click; and **assert that the tap hit the intended character** using
  the event's `text[offset]` before asserting `position`. A failure then says
  "missed the target" instead of a wrong number.
- To bring a word on screen, loop `ttuHost.nextPage({})` until the
  character's bounding box is inside the viewport (Appendix B).
- Run the suite in a fresh browser profile per test file (Playwright's
  default), and import the book once per context; `listBooks` tells whether
  it is already there.

### CI and scripts

- Add `@playwright/test` (exact version) to `apps/web` devDependencies and a
  `test:e2e` script (`playwright test`).
- In `ci.yml`, after "Test build": install Chromium
  (`pnpm exec playwright install --with-deps chromium`, in `apps/web`) and
  run the suite. Only Chromium is needed: the app's WebView is Chromium.
- `pnpm eslint .` at the root must pass on the new TypeScript. Check whether
  `apps/web/tsconfig.eslint.json` / the ESLint config cover `e2e/` and the
  Playwright config; extend them if needed.
- Upload the Playwright report as an artifact on failure (optional, cheap).

### Docs

Add a short "Tests" note to the fork's README or `apps/web/src/lib/host/`
documentation if one exists, and update the app's `CLAUDE.md` ("Working on
the ttu side") to say how to run the e2e suite.

---

## Step 3 — First Dart unit tests (pure code)

### Setup

- `pubspec.yaml` `dev_dependencies`: add

  ```yaml
  flutter_test:
    sdk: flutter
  ```

  keeping alphabetical order (`sort_pub_dependencies` is enforced:
  `build_runner`, `dart_mappable_builder`, `flutter_lints`, `flutter_test`,
  `isar_community_generator`). No `mocktail` yet; nothing in this step needs
  mocks.
- Create `test/`, mirroring `lib/src/`: e.g.
  `test/utils/jidoujisho_text_selection_test.dart`,
  `test/media/stash_item_test.dart`,
  `test/media/ttu_bridge_test.dart`,
  `test/language/japanese_sentences_test.dart`.
- Add `flutter test` to the CI workflow from step 1, after the analyze gate.

### 3.1 Text helpers

`JidoujishoTextSelection` (`lib/src/utils/misc/jidoujisho_text_selection.dart`):
`textBefore` / `textInside` / `textAfter` return `''` when
`range == TextRange.empty` (which is `(-1, -1)`), otherwise
`range.textBefore/Inside/After(text)`. Cases: a word in the middle; at the
start; at the end; the whole text; `TextRange.empty`.

`StashItem` (`lib/src/media/stash_item.dart`, plain constructor, no database
needed):

- `stashKey` is `'$mediaSourceIdentifier/$mediaIdentifier/$term/$reading'`.
- `getSelection()` builds `TextRange(start: wordStart, end: wordStart +
  wordLength)`. Note: with `wordLength == 0` this is a **collapsed range at
  `wordStart`, not `TextRange.empty`** — `textBefore` is the text up to
  `wordStart`, `textInside` is `''`, `textAfter` the rest. Pin that.
  `AddToStashAction` stores `wordStart: 0, wordLength: 0` when the reader had
  no word range, which gives `textAfter` = whole sentence; the item page
  falls back to the plain sentence when `textInside` is empty.

### 3.2 Sentence splitting

`lib/src/language/implementations/japanese_language.dart`:

- `getSentences(text)` splits with `RegExp(r'.{1,}?([。.?？!！]+|\n)')` via
  the `allMatchesWithSep` extension (`lib/src/language/language_utils.dart`);
  no match → `[text]`.
- `getSentenceFromParagraph({paragraph, index, startOffset, endOffset})`
  walks the sentences until the cumulative length passes `index`, and
  returns that sentence with the range shifted to be relative to it.

These feed the Sentence and Cloze fields of every card, so table-driven
tests with real paragraphs are worth it. Cases to cover:

- One sentence; several sentences ending in `。`; runs such as `？！` and
  `。。`; ASCII `.`, `?`, `!`; a `\n` boundary.
- Text with **no terminator** at all, and text whose **last sentence has no
  terminator** (does the tail survive? read `allMatchesWithSep` and pin what
  it does).
- `getSentenceFromParagraph` with the word in the first, a middle and the
  last sentence; a word straddling nothing special; `index` past the end of
  the paragraph. Check both the returned `text` and `range`.

Reach the methods through `JapaneseLanguage.instance`. The class has
`static Mecab mecab = Mecab()`, a lazily initialised static that these two
methods do not touch, and `initialise()` (which loads MeCab assets) must not
be called. If merely referencing the class tries to load MeCab's native
library in the test VM, stop and report: the fix is a small extraction of
the sentence functions, which is a product-code change for the user to
approve.

### 3.3 Bridge parsing

`lib/src/media/sources/ttu_bridge.dart` — the app's side of the protocol:

- `TtuTapEvent.fromJson`: full payload; missing `text` → `''`; missing
  `offset` → -1; missing `position` → -1; `x`/`y` given as doubles are
  rounded; `isDismiss` is true when `offset < 0` or `text` is empty.
- `TtuThemeEvent.fromJson`: colours from `{r, g, b, a}`, with `a` missing →
  opaque; fractional components rounded.
- `TtuBook.fromJson`: missing `title` → `''`.
- `TtuReadyEvent`: `isCompatible` is true exactly when `protocolVersion ==
  TtuBridge.protocolVersion` (currently 3); missing `route` → `''`.

`TtuBridge` itself needs an `InAppWebViewController`; out of scope here.

### Verification

`flutter test` green; the analyze gate (step 1 script) still passes. Then
update `CLAUDE.md`: the "There are **no tests**" paragraph becomes a short
description of `test/` and how to run it.

---

## Pitfalls already hit

Found while building and verifying the stash feature on this machine. Most
cost real time; none is obvious from the code.

### Shell and tooling

- **Commands run in zsh** (Claude Code's shell, with a snapshot of the
  user's zsh configuration), not bash. In zsh an unquoted `$VAR` holding
  `cmd arg` is *not* word-split: `$U ls` fails with "no such file or
  directory: python3 -I …". Put multi-word commands in small executable
  scripts instead of variables.
- **`cp` and `mv` are aliased to interactive mode.** `cp -r` over existing
  files prompts and silently skips them (a stale build was served once
  because of this); `mv` over an existing file blocks waiting for an answer.
  Use `command cp -rf` / `command mv -f`, or write to a fresh directory.
- **Never pipe a verification command into `tail`/`head` in a gate.** The
  pipeline's status is the last command's, so a failing test run was once
  recorded as passing. Use `set -o pipefail`, or redirect the output to a
  file and inspect it separately.
- **`bash -c '…'` scripts containing `rm` are blocked** by a Claude Code
  safety check that cannot inspect them, and the whole command (including
  unrelated parts such as a commit) does not run. Put such sequences in a
  script file, and keep commits in their own commands.
- **Do not search the home directory broadly** (`find ~ …`): it timed out
  after two minutes. Search the two repositories or known paths.
- Run Python with `python3 -I`. Pillow is installed (useful for cropping
  screenshots).

### Flutter / app

- **`flutter analyze` exits 1 on infos** by default; use
  `--no-fatal-infos` and count infos yourself (step 1). The real baseline
  is **76** infos (CLAUDE.md said 77 until the stash work fixed it).
- **`ANDROID_HOME` is not set in this shell.** Flutter then falls back to
  `/usr/lib/android-sdk`, which has neither NDK `29.0.14206865` nor accepted
  licences, and Gradle fails with `LicenceNotAcceptedException`. The user's
  SDK is `/home/blastrock/android/android-sdk-linux`; prefix Android builds
  with `ANDROID_HOME=/home/blastrock/android/android-sdk-linux`. (Running
  Flutter also rewrites the untracked `android/local.properties` `sdk.dir`.)
  Not needed for analyze or `flutter test`.
- **Lint traps that produced new infos and had to be fixed:**
  - `comment_references`: `[Foo]` in a doc comment must resolve in scope.
    Record fields (`[heading]` of a returned record) and types not imported
    in that file do not; use backticks instead.
  - `unnecessary_null_checks`: e.g. `set.remove(item.id!)` where the
    parameter is already nullable.
  - Doc comments on every public member (`public_member_api_docs`), and
    `sort_constructors_first`.
- `BasePageState.appModel` / `creatorModel` are `ref.watch`; use the
  `…NoUpdate` getters outside `build`.
- `package:spaces` has no `Space.big()`; the sizes used in the app are
  `extraSmall`, `semiSmall`, `small`, `normal`, `semiBig`.
- Isar: an *unattached* `IsarLinks` (e.g. on a `DictionaryHeading` you
  construct yourself) iterates as empty and does not throw; `contains`,
  `lookup` and `toSet` do require it attached. Relevant to later steps.
- `dart run build_runner build --delete-conflicting-outputs` takes about a
  minute here; `dart run slang` a few seconds.
- `tool/fetch_ttu.sh --local ../ebook-reader-lite` builds the fork into the
  app's assets (needs `pnpm install` done in the fork). The installed
  assets are git-ignored, so `jj st` stays clean.

### ttu fork

- **Run `pnpm eslint .` from the repository root**, as CI does. From
  `apps/web` it fails with 148 "Cannot read file
  'apps/web/tsconfig.eslint.json'" errors that are not real.
- `pnpm build` prints many warnings (Sass `@import` / legacy JS API
  deprecations, Svelte `untrack`/`fork`/`settled` "not exported", unused
  `Subscription` imports). They are pre-existing and harmless; judge the
  build by its exit status.
- Page turns animate: measure positions only after the scroll settles (see
  step 2's pitfalls).

### jj

- The working copy `@` is an empty change on top of the last commit; git's
  `HEAD` is `@-`. `jj commit -m '…'` finalises the current changes and
  starts a new empty `@`. The `main` bookmark is on an older, unrelated
  lineage — do not move it or rebase onto it.

### Emulator (only if you need a device; steps 1–3 do not)

An Android emulator (`emulator-5554`) may be running, with a debug Yomimoto
(`org.kaqui.yomimoto`) and the old upstream app (`app.arianneorpilla.yuuna`)
installed — do not uninstall either. Things that bit: `adb shell input text`
cannot type Japanese; taps sent while a popup menu is still animating are
silently dropped (wait ~3 s after opening a menu); `uiautomator dump`
positions can lag the screen; the app needs all-files access
(`adb shell appops set --uid org.kaqui.yomimoto MANAGE_EXTERNAL_STORAGE
allow`); the first launch of a debug build can stay black until relaunched;
the file picker's "Recent" does not show files pushed with `adb push` (open
Downloads from the roots menu); toasts last ~2 s, so screenshot them right
away; AnkiDroid is not installed, so card export cannot be tested there.

---

## Out of scope (later steps, already discussed with the user)

- Field tests with mocks (`mocktail`): Sentence/Cloze/Context/Term/Reading
  fields via `onCreatorOpenAction` with a `CreatorContext`, then the meaning
  fields with a stubbed `AppModel`.
- Extracting stash storage out of `AppModel` into a class taking an `Isar`,
  then Isar-backed tests (desktop `Isar.initializeIsarCore(download: true)`):
  Yomichan import, dictionary search/deinflection, stash storage.
- Widget tests of pages, MeCab, AnkiDroid, and on-device integration tests.

---

## Appendix A — fixture EPUB generator (Python, used so far)

```python
import sys, zipfile
out = sys.argv[1]
def chapter(n, paras):
    body = "\n".join(f"<p>{p}</p>" for p in paras)
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="ja"><head><title>第{n}章</title></head>
<body><h1>第{n}章</h1>
{body}
</body></html>'''
filler = "これは試験のための文章です。猫が静かに窓の外を見ていました。"
ch1 = [filler * 3 for _ in range(40)]
ch1[5] = "彼は<ruby>漢字<rt>かんじ</rt></ruby>を書いた。ABCとあいうえお。" + filler
ch2 = [filler * 3 for _ in range(40)]
ch2[10] = "目標の言葉はここにある。探偵が<ruby>謎<rt>なぞ</rt></ruby>を解いた。" + filler
z = zipfile.ZipFile(out, "w")
z.writestr("mimetype", "application/epub+zip", compress_type=zipfile.ZIP_STORED)
z.writestr("META-INF/container.xml", '''<?xml version="1.0"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
<rootfiles><rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/></rootfiles></container>''')
z.writestr("OEBPS/content.opf", '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="id">
<metadata xmlns:dc="http://purl.org/dc/elements/1.1/"><dc:identifier id="id">stash-test</dc:identifier>
<dc:title>試験の本</dc:title><dc:language>ja</dc:language><meta property="dcterms:modified">2026-10-11T00:00:00Z</meta></metadata>
<manifest><item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
<item id="c1" href="c1.xhtml" media-type="application/xhtml+xml"/><item id="c2" href="c2.xhtml" media-type="application/xhtml+xml"/></manifest>
<spine><itemref idref="c1"/><itemref idref="c2"/></spine></package>''')
z.writestr("OEBPS/nav.xhtml", '''<?xml version="1.0" encoding="UTF-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops"><head><title>目次</title></head>
<body><nav epub:type="toc"><ol><li><a href="c1.xhtml">第1章</a></li><li><a href="c2.xhtml">第2章</a></li></ol></nav></body></html>''')
z.writestr("OEBPS/c1.xhtml", chapter(1, ch1))
z.writestr("OEBPS/c2.xhtml", chapter(2, ch2))
z.close()
```

## Appendix B — browser-side helpers from the CDP script

Expressions evaluated in the page; adapt to `page.evaluate` / `page.mouse`.

```js
// Centre of the index-th character of the first text node containing
// `needle` inside the book, and whether it is fully on screen.
const walker = document.createTreeWalker(
  document.querySelector('.book-content'), NodeFilter.SHOW_TEXT);
let node;
while ((node = walker.nextNode())) {
  const at = node.data.indexOf(needle);
  if (at === -1) continue;
  const range = new Range();
  range.setStart(node, at + index);
  range.setEnd(node, at + index + 1);
  const box = range.getBoundingClientRect();
  return { x: box.left + box.width / 2, y: box.top + box.height / 2,
           onScreen: box.width > 0 && box.left >= 0 && box.top >= 0 &&
                     box.right <= innerWidth && box.bottom <= innerHeight };
}
return null;
```

```js
// Stored bookmark of book `id` (null if none).
const db = await new Promise((res, rej) => {
  const r = indexedDB.open('books'); r.onsuccess = () => res(r.result); r.onerror = rej;
});
return await new Promise((res) => {
  const t = db.transaction('bookmark').objectStore('bookmark').get(id);
  t.onsuccess = () => res(t.result ?? null);
});
```

```js
// ttu's character count (mirror of get-character-count.ts), Node side.
const isNotJapanese =
  /[^0-9A-Z○◯々-〇〻ぁ-ゖゝ-ゞァ-ヺー０-９Ａ-Ｚｦ-ﾝ\p{Radical}\p{Unified_Ideograph}]+/gimu;
const ttuCount = (s) => Array.from(s.replace(isNotJapanese, '')).length;
```

Flow that worked: set `localStorage` (`ttuHostDebug`, `viewMode`) on
`manage.html`; open `host.html`; `listBooks`, `importBooks` if empty; open
`b.html?id=<id>`; wait for `.book-content`; bring the target on screen with
`nextPage` (150 ms between turns), wait 600 ms, re-measure, click, read the
recorded `tap` event, check `text[offset]` is the intended character, then
assert `position`.
