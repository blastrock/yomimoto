# Manga catalogs — design

## Intent

The manga reader project (`2026-10-31-manga-reader-design.md`) rebuilt the
Manga tab on `.mokuro` volumes and deleted the old catalog code: today the
only way to get a volume is to download a `.cbz` and its `.mokuro` on another
device or in a browser, then import the file. This project brings catalogs
back, the way the user actually finds manga: browsing a **mokuro-bunko**
server (mokuro.moe is the one in use), picking a series, and downloading
volumes straight into the library, on the e-reader, without leaving the app.

A downloaded volume is exactly what a file import produces: the download is a
`.cbz` plus its `.mokuro`, which the existing import accepts as is. Nothing
about reading changes.

## Goals

- Add a mokuro-bunko server by URL; keep a list of them; remove one.
- Browse a catalog's series as a grid of covers with native titles, and
  filter it by title.
- See a series' volumes, which ones are already in the library, and download
  one or several of them into the library with a progress indication.
- Keep importing a local file as today, from the same entry point.

## Non-goals

- Any catalog kind other than mokuro-bunko.
- Renaming a catalog (the user's decision).
- Searching by author: no part of the API carries author names (checked; see
  "The API"). Searching by tag or genre, sorting, filters.
- A "select all" or "download the whole series" action (the user's decision).
- Background downloads, notifications, resuming a download, a download queue
  surviving the page.
- Keeping the series list between visits (fetched every time, the user's
  decision), or offline browsing.
- Login, private servers, OCR layers, the `series.json` metadata beyond
  volume ids.
- Series grouping in the library (still "Later: series" in the reader
  design).
- E-ink tuning. Animations stay (they suit phones); an e-ink option comes
  with the later e-ink pass (the user's decision).

## Anti-goals

- Romaji shown anywhere. Romaji is only searched, never displayed (the one
  exception is below: a series with no titles at all).
- A second import path. Downloads go through the existing
  `importMokuroVolume` unchanged.
- Depending on the API's undocumented shapes more than needed: read only the
  fields listed here and ignore everything else.

## How it behaves

The screens were agreed as a mockup (six phone screens: add-volume popup, add
catalog, series grid, volume grid, selection mode with confirmation,
download progress).

### Add volume

The Manga tab's `+` action no longer opens the file picker directly. It opens
an **Add volume** popup:

- the list of catalogs, each shown by its URL's host (`mokuro.moe`), with a
  **trash button** beside it; empty at first. Tapping a catalog opens its
  series page. The trash button asks for confirmation, then removes the
  catalog (nothing else is deleted: volumes stay in the library);
- **Add catalog**;
- **Import file**, which runs today's `importVolume` flow unchanged.

### Add catalog

A popup asking only for a URL. A URL typed without a scheme gets `https://`
in front; a trailing slash is dropped *(designer's call)*. Before saving, the
app checks that the server answers `GET <url>/catalog/api/library` with the
expected JSON; if not, the catalog is refused with a toast and the popup
stays open so the URL can be fixed *(designer's call)*. Adding a URL already
in the list does nothing.

### Series page

A full page (back returns to the Manga tab), titled with the catalog's host,
with a **search** button in the bar.

- On opening, it fetches the series list (`/catalog/api/library`, about
  700 KB, ~1,100 series) with a spinner. Every opening fetches it again.
  If the request fails, the page shows an error message and a **Retry**
  button.
- The series are a grid of covers, like the library, each with its **native
  title**. A series that has a `tag` (`Upscaled`, `HD Scan`, `Colored`…)
  shows it as a small badge on the cover, because the same work can be listed
  twice (e.g. 20世紀少年 as "20th Century Boys" and as "20 Seiki Shounen
  (Upscaled)") *(designer's call)*. A series with no `titles` (18 on
  mokuro.moe) shows its `name`, the server's folder name, which is usually
  romaji: there is nothing else to show *(designer's call)*.
- Order: the server's order, the simplest (the user's decision; it is
  alphabetical by folder name, so it looks unordered in native titles; to
  revisit if it bothers).
- Covers are downloaded lazily as the user scrolls and kept in a temporary
  cache (the user asked for both where possible).
- **Search** opens a text field in the bar that filters the grid as the user
  types, matching the native, romaji and English titles (and `name`),
  case-insensitively, as a substring. Width/kana normalisation is the
  builder's call.

### Volume page

Tapping a series opens its volumes, as a grid of covers titled with the
series' native title.

- Requests: `/catalog/api/series?name=<series name>` for the volumes, and the
  series' `series.json` (at `/mokuro-reader/<name>/series.json`, where the
  manifests point) for each volume's `volume_uuid`. No manifest is fetched
  to show the page *(designer's call)*. If the series request fails, the
  same error and Retry as the series page; if only `series.json` fails, the
  volumes show without checks.
- Volumes with `ocr_pending` true are **not shown**: the app cannot read
  them. This is decided from the series request alone; a volume whose
  manifest later turns out to have no OCR fails at download with a toast,
  like any other failure *(designer's call)*.
- Each volume is labelled with its server name as is
  (`[浦沢直樹] 20世紀少年 01`) *(designer's call)*.
- A volume already in the library (its `volume_uuid` is the
  `mediaIdentifier` of a `reader_mokuro` item) shows a **small check on a
  green circle at the bottom-right corner** of its cover. A volume whose
  uuid cannot be found in `series.json` simply shows no check.
- **Tap** a volume: a popup asks whether to download it, with its size. For
  a volume already in the library it says so; downloading it again replaces
  its files and keeps its position and stash, as re-importing does today
  *(designer's call)*.
- **Long-press** enters selection mode: the bar shows the number selected,
  a close button and a **download** button; taps toggle volumes. The
  download button asks for confirmation, giving the number of volumes and
  their total size, then downloads them. No "select all".

Sizes come from each volume's manifest
(`/catalog/api/manifest?series=…&volume=…`: `archive.size` +
`ocr.size`), fetched when the popup or confirmation opens, for the volumes
concerned only *(designer's call)*.

### Navigation

The series and volume pages are ordinary pushed routes. Back from the volume
page returns to the series page as it was left (list, scroll and search
kept, nothing fetched again); back from the series page returns to the Manga
tab. "Every opening fetches again" means every time the series page is
opened from the Add volume popup *(designer's call)*.

### Downloading

One **progress dialog** covers the whole batch: which volume of how many,
a progress bar and the bytes downloaded against the total, and a **Cancel**
button *(designer's call)*. The bar may stay indeterminate while the import
of a volume runs.

Volumes are downloaded **one at a time**. For each: fetch its manifest,
download the `.cbz` and the `.mokuro` it names into a fresh temporary
directory, under the same stem (`<stem>.cbz`, `<stem>.mokuro`) so the
existing import pairs them, run the existing import (in its isolate), put
the media item exactly as `importVolume` does, then delete the temporary
directory. Each volume enters the library as soon as it is imported.

- **Failure** (network error, HTTP error, import error) stops the batch with
  a toast naming the volume and the reason; volumes already imported stay
  *(designer's call)*. Import errors reuse the existing import messages.
- **Cancel** aborts the current download, deletes its temporary files and
  stops; volumes already imported stay. The import runs in an isolate that
  cannot be interrupted: Cancel pressed during an import stays available
  (never greyed out), lets that import finish, keeps the volume, then stops
  before the next download (the user's decision).
- Missing pages are reported with the existing toast, once per volume.
- After the batch, the dialog closes and the volume page's checks update.
  The new volumes appear in the Manga tab like imported ones.

## The API

mokuro-bunko's catalog API, as served by mokuro.moe (checked on
2026-10-31). Public, no authentication. All URLs below are relative to the
catalog's base URL; URLs returned *inside* responses (manifest) are absolute
paths on the same host.

| Request | Fields read |
|---|---|
| `GET /catalog/api/library` | `{series: [...]}`; per series: `name` (the key for the other requests), `cover` (a path for the cover request), `titles.native`, `titles.romaji`, `titles.english` (all optional, `titles` itself may be missing), `tag` (optional) |
| `GET /catalog/api/series?name=<name>` | `volumes`: `name`, `cover`, `ocr_pending` |
| `GET /catalog/api/cover?path=<cover>` | the image (WebP on mokuro.moe) |
| `GET /catalog/api/manifest?series=<name>&volume=<volume name>` | `version` (must be 1), `archive.url`, `archive.size`, `ocr.url`, `ocr.size` (an `ocr` missing or null: not readable), `series_file.url` |
| `series_file.url` (`series.json`) | `volumes`: `volume_title` (matches the volume's `name`), `volume_uuid` |

Notes from the check:

- No author names anywhere: not in the library, the series request, the
  manifest nor `series.json`. About a quarter of volume names start with the
  author in brackets; not reliable, not used.
- `series.json` sits next to the volumes, at
  `/mokuro-reader/<name>/series.json`; the manifests' `series_file.url`
  points there.
- The manifest is versioned and mokuro-reader relies on it; the library and
  series requests are not versioned. A response that does not parse is shown
  as the page's error, not a crash.
- The server sends `cache-control: no-store` on the library.
- Volumes are 40–55 MB on mokuro.moe; series go up to 194 volumes.

## How it is built

The parts decided:

- **Catalog list**: a `StringListPreference` of base URLs, a private
  constant of `ReaderMokuroSource` keyed `reader_mokuro/catalogs`. No table,
  no schema change *(designer's call; the schema stays at version 2)*.
- **API client**: pure Dart, with the `http` package already in
  `pubspec.yaml`, parsing into small typed classes; unit-tested against
  canned JSON (recorded from mokuro.moe), no network in tests.
- **Downloads**: streamed with `http` so bytes can be counted, cancellable by
  closing the client. Written to the app's temporary directory.
- **Import**: `importMokuroVolume` and the media item put from
  `ReaderMokuroSource` unchanged; the part of `importVolume` after the
  picker is shared rather than copied.
- **Cover cache**: `cached_network_image` (already a dependency, its cache
  is in the temporary directory) or anything equivalent.
- **Pages**: the series and volume pages are `BasePage`s in
  `lib/src/pages/implementations/`, the popups are dialog pages, following
  `SettingsPage` as the model; strings in `strings.i18n.json`.
- `CLAUDE.md`'s mokuro paragraph gains a few lines on catalogs; the reader
  design's "Next project: catalogs" section points to this document.

## Testing

- Unit tests (`test/`, no device, no network): parsing each response,
  including missing `titles`, missing `tag`, `ocr_pending`, a manifest of
  another version, malformed JSON; URL normalisation; the search filter;
  matching volumes to `series.json` uuids; the download-then-import step
  against a local fake (a `MockClient` from `package:http/testing.dart`
  serving a small sample `.cbz` and `.mokuro`), including failure and
  cancellation leaving no temporary files.
- On a device: add mokuro.moe, refuse a wrong URL, scroll the series grid
  (covers load and come back from cache), search by native, romaji and
  English title, open a series, download one volume, then two by selection,
  cancel a download, cut the network mid-download, see the checks, read a
  downloaded volume, delete a catalog.

## Left to the builder

- Widget structure, layouts and spacing within the agreed screens.
- The progress dialog's exact layout and update rate.
- Search normalisation beyond case (kana, full-width).
- Request timeouts and the wording of errors.
- Where the API client and download code live (`lib/src/media/sources/`
  beside `mokuro_import.dart` is the natural place).

## Calls made by the designer, not the user

- A catalog is shown by its host name.
- A series' `tag` is a badge on its cover; a series with no titles shows its
  folder name.
- A volume is labelled with its server name as is.
- Adding a catalog checks the server first; `https://` is added when no
  scheme is typed.
- Catalogs are a preference (list of URLs), not a table.
- A failed volume stops the batch; finished volumes stay.
- Cancel exists and keeps finished volumes.
- Downloading a volume already in the library replaces it like a re-import.
- Unreadable volumes are hidden from `ocr_pending` alone; no manifest is
  fetched to show the volume page, only for sizes and downloads.
- Back from the volume page returns to the series page as it was left.
