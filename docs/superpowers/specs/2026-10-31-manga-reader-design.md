# Manga reader — design

## Intent

The Manga tab is broken. It opens mokuro's **legacy per-volume HTML** (the
self-contained reader page the mokuro OCR tool writes next to each volume) in
a WebView and injects ~450 lines of JavaScript that depend on that page's
internals (`pageContainer`, `state`, `storageKey`, `updatePage`,
`zoomFitToScreen`). Catalogs are saved URLs browsed in that WebView until a
legacy HTML page happens to load. The catalog in use today (mokuro.moe)
never serves one: it hands volumes to mokuro-reader, the separate web app. So
the hooks never fire, no lookup works, and the user is just browsing a
website.

The legacy HTML is frozen upstream ("will not be developed further") and will
be turned off by default in a future mokuro release. The format mokuro and
every tool around it now share is the **`.mokuro` file**: one JSON file per
volume, next to the volume's images, holding the OCR text boxes.

This project rebuilds the Manga tab on that format, with the same split ttu
has (a web page renders, Flutter owns everything else), but **without
depending on any mokuro project**. The hard part of mokuro, the OCR, happens
offline on a computer before reading. What is left (drawing an image with
text boxes over it) is small enough to own. Forking mokuro-reader, which is
large and actively developed, is what the user wants to avoid.

The reader behaves like basic mokuro: you see the whole page, you read bubble
by bubble, and tapping a word shows that bubble's text in clean type over the
bubble and opens the dictionary popup on the word. The clean text is a real
help on blurry scans. Long-press selects text natively, to copy a sentence.

## Goals

- Read a mokuro-processed volume: page images with an OCR text overlay,
  vertical Japanese text laid out properly (punctuation included).
- Tap a character → that bubble's text appears over the bubble, the matched
  word is highlighted, the dictionary popup opens, as in the Novels reader.
- Long-press → native WebView text selection with handles, to copy text.
- Cards from the manga reader: the bubble as sentence, the page as image.
- Volumes are a library like Novels: imported once, kept until deleted, the
  page remembered across sessions, read volumes visible at a glance.
- A per-volume stash, with peek opening the volume at the word's page.
- Import a volume from a local `.cbz` or `.zip`, with its `.mokuro` beside it
  or inside it.

## Non-goals (this project)

- **Catalogs.** Browsing and downloading from mokuro-bunko servers
  (mokuro.moe) is the next project, in its own session. Its findings so far
  are recorded at the end of this document. This project deletes the current
  catalog code; until the next one lands, opening a file is the only way in.
- **Series.** Volumes are a flat list, like novels. Grouping volumes into a
  series with one combined word list is a later project; see "Later: series".
- Reader settings beyond what is listed under "Settings". The reader has
  mokuro's defaults built in: no timer, statistics, reading speed, themes,
  scroll modes, page transitions, font choices.
- OCR "layers" (mokuro-reader's extra `<volume>.layer.<id>.mokuro` files:
  pre-edit originals, alternative OCR engines, machine translations). Only
  the main `.mokuro` is read.
- Editing OCR, legacy `.html` volumes, image-only volumes with no `.mokuro`,
  unzipped image folders.
- Romaji anywhere. A `.mokuro` has no romaji; nothing in this project adds
  any.
- E-ink tuning (the later pass), apart from not adding animations.

## Anti-goals

- Depending on mokuro-reader at runtime or at build time, or forking it.
- Injecting JavaScript into a page we do not own. The app talks to the reader
  page only through a bridge, as with ttu.
- A build step for the reader page (no bundler, no npm). It is a few hundred
  lines of plain HTML, CSS and JavaScript.
- Compatibility code for the removed catalog and legacy features beyond the
  one migration below: no reading old rows, no fallbacks.

## Constraints

- The `.mokuro` format, as written by the mokuro tool (0.2.x) and by
  mokuro-bunko:

  ```jsonc
  {
    "version": "0.2.5",
    "title": "…", "title_uuid": "…",      // series
    "volume": "…", "volume_uuid": "…",
    "ocr_engine": { … },                   // mokuro-bunko only; ignore
    "pages": [{
      "img_path": "001.jpg",               // relative to the volume's image root
      "img_width": 827, "img_height": 1170,
      "blocks": [{
        "box": [x1, y1, x2, y2],
        "vertical": true,
        "font_size": 23,
        "lines": ["お父さんは私が", "殺してあげるって"],
        "lines_coords": [[[x, y] ×4], …]   // one quad per line
      }]
    }]
  }
  ```

  Unknown keys are ignored. Sample files: `../mokuro/tests/data/expected_results/`.
- Code ported from mokuro-reader (GPL-3.0, like Yomimoto) keeps a header
  naming its source file and commit (`bfaeb482`).
- The project rules in `CLAUDE.md` apply: barrels, singletons, `uniqueKey`
  stability, `public_member_api_docs`, British spelling, `flutter analyze`
  clean.

## How it behaves

### The Manga tab

A list of volumes ordered by last opened, like Novels, built on the same
`HistoryReaderPage` base. Each entry shows its cover (the first page) and its
title, and keeps the base page's progress bar (`position / duration`).
A volume counts as **read** when the bar is full: the existing bar already
shows full above 97%, and reaching the last page or spread sets it to 100%.

Long-press opens the existing media item dialog: rename (`override_title`),
delete, stash. Deleting a volume deletes its files and, through the existing
`ON DELETE CASCADE`, its stash, as deleting a book does.

The tab's actions: **Import** and the reader's settings. No catalog button, no
link button.

### Import

The user picks one file with the existing `FilesystemPicker` (the app holds
`MANAGE_EXTERNAL_STORAGE`, so siblings of the picked file are readable by
path; the current Mokuro source already uses this picker and
`getFilePickerDirectoriesForMediaSource`).

**Only `.cbz` and `.zip` files are accepted** (the user's decision). The OCR
is found by the archive's stem: a `<stem>.mokuro` beside the archive wins
(that is how mokuro-bunko serves volumes: its `.cbz` holds no `.mokuro`);
otherwise the archive must contain exactly one `.mokuro`. Unzipped image
folders and picking a `.mokuro` directly are not supported.

Pages' `img_path` values are not laid out the same way by every producer: the
mokuro tool writes paths relative to the volume's image folder (`000a.jpg`),
mokuro-bunko writes them with that folder's name in front
(`[赤坂アカ×横槍メンゴ] 【推しの子】 01/00001.webp`), and its archive holds
the images under that folder. Resolve each `img_path` against the archive
root first, then against the archive's single top-level folder if it has one.

An archive with no OCR is refused with a toast naming what was missing. A
volume whose pages reference images
that are not in the image root imports anyway, and the import ends with a
toast saying how many pages are missing; missing pages render as an empty
page of the right size. (mokuro-bunko marks some volumes "damaged"; refusing
them would be worse than showing a gap.)

The volume is **copied into app storage**: the `.mokuro` and its images,
extracted from the archive, under one directory per volume in the
app directory. The library must not break when the user moves or deletes
their files.

A volume's identity is its `volume_uuid`. Importing a volume already in the
library replaces its files and keeps its row (position, stash), through
`putMediaItem`'s upsert by identifier.

Import runs with a progress indication (archives of 50–100 MB are normal) and
must not block the UI thread.

### The reader page

Opening a volume shows the page at its saved position, fitted to the screen.

- **Page order**: right to left.
- **Spreads**: one page in portrait; two pages side by side in landscape,
  with the first page (the cover) shown alone so that spreads pair as
  printed. This is mokuro's "auto" mode with its default `hasCover`.
- **Turning pages**: swipe, tap near the left or right edge, and the volume
  keys (with today's volume-key settings). No page-turn animation. A tap that
  lands on a block is a lookup even near an edge; only a tap on no block
  turns the page.
- **Full screen**: immersive, as the current reader is (`immersiveSticky`).
- **Zoom**: the WebView's own pinch-zoom and pan; turning the page resets to
  fit-to-screen.
- **Background**: follows the app's light or dark theme.

### The bar

Hidden while reading. It holds:

- a button that hides the bar;
- previous page and next page buttons;
- a slider over the whole volume, running **right to left** like the pages
  (the first page at the right end);
- the page number and the total, `12 / 200` (in a spread, the pages shown,
  `12–13 / 200`).

Moving the slider or pressing a button turns the page with the bar left open.
A tap on the middle of the screen that lands on no block shows it (the edges
still turn pages). Tapping the middle again, or the hide button, hides it.
Leaving the reader is the back button, as today.

Summoning the bar by zooming out was considered and dropped for now: with the
WebView's own zoom, a pinch at the minimum fires nothing, and showing the bar
whenever the zoom returns to the minimum would pop it up after every zoom.

### Text overlay and lookup

Every OCR block is laid out over its bubble at all times, as invisible text,
so the browser can hit-test it. Nothing shows until a tap.

Tapping a character:

1. The block under the finger becomes visible: its lines in clean type on an
   opaque background, over the bubble, in the block's writing direction.
2. The text from the tapped character to the end of the block is sent to the
   dictionary, exactly as the Novels reader does (`getGuessHighlightLength`,
   search, `getFinalHighlightLength`), and the matched word is highlighted
   in the overlay.
3. The popup opens. The sentence for cards is the block's text (lines
   joined), with the word as its range; the explanation feature already
   sends the bubble alone for manga (`ExplanationKind.manga`).

Tapping another character starts a new lookup. Tapping outside any block, or
closing the popup, hides the overlay and the highlight.

The text sits on the printed glyphs as closely as practical. The model is
mokuro-reader's: each line is a rotated box built from its `lines_coords`
quad, its characters placed on a uniform grid along it, the grid rendered
with CSS `letter-spacing` and the rotation with a CSS transform (see
`mokuro-reader/src/lib/reader/line-grid.ts`, `line-coords-layout.ts`,
`glyph-insets.ts`). Port the core of that, not every guard: the goal is the
overlay landing on the bubble's text, not pixel parity with mokuro-reader.

Vertical text uses `writing-mode: vertical-rl`, so the browser picks the
font's vertical forms for ー, 「」, 、, 。 and the like.

### Selection

Long-press starts the WebView's native selection with handles, inside the
overlay text, making the touched block visible. The selection menu is the
app's shared text-selection menu (search, copy), as elsewhere. A plain tap is
always a lookup, never a selection.

### Stash and peek

Same as Novels, per volume. `AddToStashAction` already refuses when the
source has no position; the manga reader sets one. A stash item's
`position` is the **page index** of the bubble the word was found in (the
field's doc comment, today "in ttu bookmark units", becomes "in the source's
own units"). The stash is reached from the library's long-press dialog, as for
novels.

Peek opens the volume at that page and leaves the saved position untouched
for the session, like `ReaderTtuSource.peekBook`. The stash item page's jump
button calls the peek of the item's own source rather than `ReaderTtuSource`.

### Cards

The image field gets the current page's image, from the volume's directory,
as the current Mokuro source does through `generateImages`. Cards made later
from a stash item get the page image too: the item's volume and page say
which file it is. How that reaches the image field (today the image comes
from the source's live `currentExtraData`, which a stash card does not have)
is the builder's to design; `CreatorContext` is the natural carrier.

### Settings

The Mokuro section of `SettingsPage` keeps: highlight on tap, volume-key page
turning, inverted volume keys. It loses: dark theme (the reader follows the
app theme) and "extend page beyond navigation bar" (the reader is always
immersive). The preference keys keep the `reader_mokuro/` prefix.

## How it is built

### Pieces

| Piece | Where | What |
|---|---|---|
| Reader page | `assets/manga-reader/` (HTML, CSS, JS; no build) | Renders one volume from its `.mokuro`; speaks the bridge |
| Asset/volume serving | a `CustomPathHandler` like `TtuAssetPathHandler` | Serves the reader page and the open volume's files on the asset-loader origin |
| Bridge | Dart class beside `TtuBridge` | Typed events and commands, with a protocol version checked on `ready` |
| Source | `ReaderMokuroSource` (rewritten; `uniqueKey` stays `reader_mokuro`) | Library, import, peek, images, settings |
| Reader page (Flutter) | a `BaseSourcePage`, modelled on `ReaderTtuSourcePage` | WebView, bridge wiring, lookup, volume keys, position saving |
| Import | pure Dart, testable | Pairing, `.mokuro` parsing, copying/extracting into app storage |

The reader page is its own HTML document in its own WebView. It stores
nothing: Flutter tells it which volume and page to show and is told about
page changes. It may share the asset-loader origin with ttu as long as it
writes no web storage; otherwise it uses its own path prefix and storage
stays untouched.

### The bridge

Same shape as `TtuBridge`: events through one JavaScript handler, commands as
methods on a `window` object called with `callAsyncJavaScript`. The page is
inert outside the app and has a debug mode for a desktop browser (a fake host
logging events, commands callable from the console, a volume loaded from a
URL), as ebook-reader-lite's `ttuHostDebug` does. The exact messages are the
builder's; at least:

- events: `ready` (protocol version), `tap` (the block's lines, the tapped
  character's index in the joined text, the page index; or a dismiss),
  `page` (the pages now shown), `menu` (a request to toggle the bar);
- commands: open a volume at a page, turn the page, go to a page, highlight
  a range in the shown block, clear the overlay.

The bar is a Flutter widget over the WebView (the slider is a `Slider`
under right-to-left `Directionality`); the page only reports `menu`.

### Data

- `media_item`: one row per volume. `mediaSourceIdentifier` is
  `reader_mokuro`; `mediaIdentifier` is the `volume_uuid`; `title` is
  `<title> <volume>` from the `.mokuro` (the tool's `volume` is often just
  `vol1`, the series name is in `title`), or `volume` alone when it already
  contains `title`; `duration` is the page count; `position` is the
  page index (in a spread, the higher page, so the last spread reads as
  finished); `imageUrl` points at the cover file. Written with
  `putMediaItem` (no cap), `implementsHistory` becomes `false`.
- Volume files: one directory per volume under the app directory, keyed by
  something stable (the `volume_uuid` or the row id).
- `stash_item`: unchanged schema.
- Removed: the `mokuro_catalog` table and everything reading it.

### Migration

1.0 is not released, but existing installs have data, so the user asked for a
simple migration rather than editing version 1 in place. `schemaVersion`
becomes 2, with the snapshot and test workflow `CLAUDE.md` describes for after
1.0 (`drift_dev make-migrations`: `drift_schemas/drift_schema_v2.json`, the
generated test helpers, a migration test from v1). The 1 → 2 step:

- drops the `mokuro_catalog` table;
- deletes the `media_item` rows of `reader_mokuro` (old volumes are legacy
  HTML URLs the new reader cannot open; their stashes go with them through
  the cascade, and there should be none since mokuro could not stash);
- deletes the preference rows of the dropped settings
  (`reader_mokuro/use_dark_theme`, `reader_mokuro/extend_page_beyond_navbar`).

Leftover files of the old reader (`mokuroImagePreview/`) are a temporary
directory and need nothing. `CLAUDE.md`'s schema paragraph is updated to say
version 2 exists and how it got there.

### Removed

- `mokuro_catalog_browse_page.dart`, `mokuro_catalog_dialog_page.dart`,
  `mokuro_catalog_manage_dialog_page.dart`,
  `mokuro_catalog_edit_dialog_page.dart`, `mokuro_link_dialog_page.dart`,
  `mokuro_catalog.dart`, `mokuro_payload.dart` (dead code), and their barrel
  exports and i18n strings.
- The `MokuroCatalog` table, its `AppStore` methods and its mention in
  `CLAUDE.md`'s persistence section.
- The legacy `.html` detection and the injected JavaScript.
- `DEBT.md`'s "Mokuro history trimming can delete stashes" entry: manga stops
  being a capped history.

`CLAUDE.md`'s mokuro paragraph is rewritten to describe the new reader.

## Later: series

Not built now, recorded so nothing here blocks it. A `series` table and a
series reference on `media_item`; a series' word list is the union of its
volumes' stashes, so stash rows never move (each keeps its volume, which
peek needs). Volumes would group by `title_uuid`, merging series with the same
`title` (the mokuro tool assigns a random `title_uuid` per parent folder, so
volumes processed in different folders would otherwise split). This would
work for light novels in the Novels tab too. Whether deleting a volume should
then keep its words is that project's question.

## Next project: catalogs (findings)

mokuro.moe runs **mokuro-bunko**, whose catalog page is drawn from a public
JSON API (no login needed for browsing):

| Request | Returns |
|---|---|
| `GET /catalog/api/library` | every series (~1,100, ~700 KB): name, cover path, native/romaji/English titles, tags, genres, counts |
| `GET /catalog/api/series?name=…` | the series' volumes: name, cover, page count, OCR pending |
| `GET /catalog/api/cover?path=…` | a cover image |
| `GET /catalog/api/manifest?series=…&volume=…` | versioned (`version: 1`) file list: `.cbz` URL and size, `.mokuro` URL with sha256, cover, `series.json`, layers |

A volume download is a `.cbz` plus a `.mokuro`, which the import of this
project accepts as is. The manifest is a contract mokuro-reader relies on;
the library and series requests are not versioned. Catalogs would be
mokuro-bunko servers added by URL; show native titles, never romaji.

## Testing

- Dart unit tests (in `test/`, no device): `.mokuro` parsing, import pairing
  (OCR beside, OCR inside, both, none, two inside), `img_path` resolution for
  both layouts, extraction into a temp app directory, the bridge's event
  parsing as for `TtuBridge`, and the 1 → 2 migration.
- QA volume: 【推しの子】 (Upscaled) volume 1 from mokuro.moe, 224 WebP pages,
  a `.cbz` (41 MB) with its `.mokuro` beside it, downloaded to
  `/tmp/claude-1000/-home-blastrock-work-yomimoto/377e94d8-6ea9-48ff-931c-7cefdf888011/scratchpad/qa/`
  (session scratch: re-download through the manifest API if it is gone). The
  mokuro tool's sample volumes in `../mokuro/tests/data` cover its own
  `img_path` layout, zipped for import.
- The reader page: manual, in a desktop browser through its debug mode,
  then on the emulator and a device.
- On a device: import each layout, read with lookups in portrait and
  landscape, long-press copy, stash then peek, make a card live and from the
  stash (image present), delete a volume, reopen at the saved page.

## Image formats

Page images are kept as imported (JPEG, PNG, WebP, AVIF; the mokuro tool
accepts all four). The WebView shows them all. Library covers go through
Flutter's decoder, which handles AVIF only where Android's own decoder does
(Android 12+): on older devices an AVIF volume shows no cover. Card images
are the page file as is. No conversion step is added; AVIF volumes are rare.

## Left to the builder

- The bridge's exact messages and protocol versioning.
- The reader page's structure, gesture handling, and how much of
  mokuro-reader's alignment code is worth porting.
- The app-storage layout and how the WebView reaches the volume's files.
- How the page image reaches cards made from a stash item.
- How import reports progress and errors.

## Calls made by the designer, not the user

- The reader page lives in this repository as plain assets, not in a separate
  repository with a build like ttu.
- Volumes are copied into app storage rather than read in place.
- A volume's identity is its `volume_uuid`; re-importing replaces its files
  and keeps its position and stash.
- Import uses the existing `FilesystemPicker`, so a `.mokuro` next to the
  picked archive can be found by path.
- Volumes with missing images import anyway, with blank pages and a toast
  giving the number of missing pages.
- The library title is `<title> <volume>`.
- A volume counts as read when its progress bar is full; no manual toggle.
- The reader follows the app theme; the dark-theme and "extend beyond the
  navigation bar" settings go.
- A tap on a block near an edge is a lookup, not a page turn.
- The bar is drawn by Flutter, not by the reader page.
- Page images keep their format; AVIF covers may be missing before Android 12.
- Stash cards get the page image.
