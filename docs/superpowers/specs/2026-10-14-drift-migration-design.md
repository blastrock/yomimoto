# Replace Isar with Drift

## Goal

Yomimoto is heading for a 1.0 release, after which backward compatibility of
persisted data is enforced. Isar (`isar_community` 3.3.2) is unmaintained, and
its generator is the only reason `analyzer` is pinned below 4.8. Replace it
with Drift on SQLite before 1.0, so that the 1.0 schema is a relational
baseline with Drift's schema snapshots and migration tests behind it.

Success means:

- Same user-visible behaviour: dictionary import and deletion, lookups from
  both readers, the Dictionary tab and its history, the stash, the Novels and
  Manga libraries, Anki profiles, mokuro catalogs, card creation and export.
- Import and lookup speed comparable to or better than Isar, measured on a
  device against a baseline taken before the change.
- `flutter analyze` and `flutter test` clean; the `analyzer` pin is gone.
- Schema version 1 is committed as a Drift schema snapshot with a test.

No data is carried over from Isar installs: there is still no backward
compatibility owed before 1.0.

Hive (key-value preferences) is out of scope and is replaced in a follow-up
spec before 1.0.

## Architecture

- **Backend**: Drift's `NativeDatabase` over `package:sqlite3` (FFI, bundled
  SQLite). Not `drift_sqflite`.
- **One file**, `yomimoto.sqlite`, in the app documents directory, with
  `journal_mode=WAL`, `foreign_keys=ON`, `busy_timeout` set, and
  `auto_vacuum=INCREMENTAL` (set in `onCreate`, before any table exists).
- **Main isolate**: `AppModel.initialise()` opens a `sqlite3.Database`, wraps
  it with `NativeDatabase.opened(raw)` into `AppDatabase`, and forces it open
  so the schema exists before the first read. `AppModel` keeps both handles:
  `_db` (Drift) and `_raw` (the same connection). Drift runs on the main
  isolate, not `createInBackground`, so that both share one connection.
- **Other isolates** (search, import, delete) open their own connection to
  the same file. WAL lets the main connection read during an import.
- **No cache layer.** Getters that UI `build()` methods call stay synchronous
  by reading the database directly through `_raw`.

### Rules

1. On the main isolate, all writes go through Drift (async). Raw `sqlite3`
   on the main isolate is for reads only, so Drift's `watch()` streams stay
   correct.
2. The dictionary import writer is the one exception: it writes through raw
   `sqlite3` prepared statements inside the import isolate's transaction, for
   speed. No streams exist in that isolate.
3. A function returning a `DictionaryHeading` returns it fully loaded
   (entries, tags, pitches, frequencies, dictionaries). Nothing loads lazily.

### Code layout

- New folder `lib/src/database/` with its own barrel `lib/database.dart`
  (the eighth). It holds the Drift table definitions, `AppDatabase`, the JSON
  type converters, `search.drift`, the heading loader, the raw read helper and
  `DictionaryImportWriter`.
- Model classes stay where they are, with their names and helper methods, and
  become Drift row classes through `@UseRowClass`: `Dictionary`,
  `DictionaryEntry`, `DictionaryHeading`, `DictionaryTag`, `DictionaryPitch`,
  `DictionaryFrequency`, `MediaItem`, `StashItem`, `AnkiMapping`,
  `MokuroCatalog`, `SearchHistoryItem`. They lose their Isar annotations and
  links. Fields that are not columns become plain mutable fields with empty
  defaults, filled by the loader:
  - `DictionaryHeading.entries`, `.pitches`, `.frequencies`, `.tags`
  - `DictionaryEntry.tags`, `.dictionary`
  - `DictionaryPitch.dictionary`, `DictionaryFrequency.dictionary`
- `DictionarySearchResult` becomes a plain in-memory class (`searchTerm`,
  `bestLength`, `headings`). It is no longer persisted.

## Schema (version 1)

Columns are listed without types where obvious. `JSON` means a `TEXT` column
with a Drift `TypeConverter`; nothing queries inside those.

### Dictionary data

```
dictionary(id INTEGER PK AUTOINCREMENT, name UNIQUE, format_key,
           "order" UNIQUE, is_hidden, is_collapsed)

heading(id INTEGER PK, term, reading, UNIQUE(term, reading))
  INDEX(reading)

entry(id PK, heading_id → heading, dictionary_id → dictionary ON DELETE CASCADE,
      definitions JSON, popularity)
  INDEX(heading_id), INDEX(dictionary_id)

pitch(id PK, heading_id → heading, dictionary_id → dictionary ON DELETE CASCADE,
      downstep)
  INDEX(heading_id), INDEX(dictionary_id)

frequency(id PK, heading_id → heading, dictionary_id → dictionary ON DELETE CASCADE,
          value, display_value)
  INDEX(heading_id), INDEX(dictionary_id)

tag(id PK, dictionary_id → dictionary ON DELETE CASCADE, name, category,
    sorting_order, notes, popularity, UNIQUE(dictionary_id, name))

heading_tag(heading_id → heading ON DELETE CASCADE, tag_id → tag ON DELETE CASCADE,
            PK(heading_id, tag_id))
  INDEX(tag_id)

entry_tag(entry_id → entry ON DELETE CASCADE, tag_id → tag ON DELETE CASCADE,
          PK(entry_id, tag_id))
  INDEX(tag_id)
```

- `term` and `reading` use the default BINARY collation, so `GLOB 'prefix*'`
  can use the index. Isar's case-insensitive matching (relevant only to Latin
  script) is dropped.
- Heading ids are plain integers. `fastHash` and hash-derived ids for headings
  and tags are removed.

### App data

```
media_item(id PK, media_source_identifier, media_identifier, title, image_url?,
           position, duration, can_delete, can_edit,
           UNIQUE(media_source_identifier, media_identifier))

stash_item(id PK, media_item_id → media_item ON DELETE CASCADE, term, reading,
           dictionary_name?, definitions JSON, sentence, word_start, word_length,
           position, date_added, UNIQUE(media_item_id, term, reading))

anki_mapping(id PK, label UNIQUE, model, "order" UNIQUE, export_field_keys JSON,
             creator_field_keys JSON, creator_collapsed_field_keys JSON, tags JSON,
             actions JSON, enhancements JSON, export_media_tags?, use_br_tags?,
             prepend_dictionary_names?)

mokuro_catalog(id PK, name, url UNIQUE, "order" UNIQUE)

search_history_item(id PK, search_term UNIQUE)

dictionary_history(id PK, search_term UNIQUE)
```

- The stash refers to its book by foreign key, which replaces the
  `mediaSourceIdentifier`/`mediaIdentifier` pair, the `stashKey` concatenation
  and the manual `deleteStashForMedia` call in `syncLibrary`. It refers to the
  dictionary word by `(term, reading, dictionary_name)` strings on purpose:
  the stash is user data that must survive a dictionary being deleted and
  reimported, and reattach when it returns.
- `putMediaItem` becomes a true upsert
  (`ON CONFLICT(media_source_identifier, media_identifier) DO UPDATE`) that
  keeps the row id. Its current delete-then-put would wipe every stash through
  the cascade.
- Mokuro media items are trimmed to the 100 most recent by `addMediaItem`.
  Mokuro items cannot be stashed today (no `currentPosition`), so the cascade
  cannot delete a stash through trimming. Mokuro stashing is planned; this is
  recorded in `DEBT.md`.
- `dictionary_history` replaces the `dictionaryHistory` Hive box and the
  persisted `DictionarySearchResult` collection.

### Dropped

- `entry.imagePaths`, `entry.audioPaths`, `entry.extra`: never written.
- `media_item.base64Image`, `audioUrl`, `author`, `extraUrl`, `extra`,
  `authorIdentifier`, `sourceMetadata`: never written by the remaining
  sources. Code reading them goes too.
- `search_history_item.historyKey`: every caller passes the dictionary tab's
  key.
- `DictionarySearchResult.scrollPosition`: always 0; its updater
  (`updateDictionaryHistoryHelper`) is never called.
- The Isar `termLength` and `popularity` indexes, and the concatenated unique
  keys (`stashKey`, `MediaItem.uniqueKey` as an index, `SearchHistoryItem.uniqueKey`).

## Data access

### Synchronous reads (main isolate)

One helper, `List<T> _selectSync<T>(table, sql, args)`, runs `_raw.select` and
maps each row through Drift's generated `table.map(row)`, reusing Drift's
column decoding and type converters. It backs the getters UI code reads in
`build()`: `dictionaries`, `mappings`, `mokuroCatalogs`, the mapping lookup by
label, `getStashItems`, `getSearchHistory`, `dictionaryHistory` and the media
item lists.

This depends on `table.map` being synchronous and accepting raw `sqlite3`
rows. That is verified first (see Sequencing). If it does not hold, each row
class gets a short hand-written `fromRow` instead.

### Asynchronous access

Everything else goes through Drift. `writeTxnSync` becomes `_db.transaction`.
`AppModel` mutators (`putStashItem`, `updateMediaItem`, `addMediaItem`,
`putMediaItem`, `deleteMediaItem`, search history and dictionary history
updates, mapping and catalog setters, dictionary toggles and reordering)
return `Future`s; callers `await` them before reading back or notifying.

### Heading loader

`loadHeadings(db, headingIds)` is a top-level function usable from any
isolate. It runs six queries (headings, entries, pitches, frequencies,
heading tags joined to tags, entry tags joined to tags), attaches dictionaries
from one `dictionary` query, and assembles the aggregates in Dart, preserving
the order of `headingIds`. Its SQL lives in `search.drift`.

Users: the search isolate, `resolveStashItem`, `getNoReadingFrequencies`.

## Search

- Still runs in a `cancelable_compute` isolate, which opens its own
  `AppDatabase`. A new lookup cancels the one in flight, as today. (Drift on
  the main isolate runs SQLite on the main isolate, so searching there would
  block the UI.)
- The isolate searches, loads the aggregates, ranks them and returns a fully
  loaded `DictionarySearchResult`. The main isolate runs no query for a
  lookup. `AppModel`'s in-memory `_dictionarySearchCache`, keyed by
  `'$searchTerm/$overrideMaximumTerms'`, stays in front of it.
- Queries are named queries in `lib/src/database/search.drift`, checked
  against the schema at build time, each filtering on
  `EXISTS (SELECT 1 FROM entry WHERE heading_id = h.id)`:
  - `headingsByTerm(:terms)` and `headingsByReading(:readings)` (`IN` lists),
    used for exact and deinflected matches, with deinflected term matches
    ordered by the sum of entry popularity, descending.
  - `headingsByTermStartingWith(:prefix, :limit)`, `GLOB :prefix || '*'`,
    ordered by `length(term)`.
  - `headingsByTermGlob(:pattern, :length?, :limit)` and
    `headingsByReadingGlob(:pattern, :limit)` for `※`/`？`/`*`/`?`
    wildcards, which map to GLOB's `*` and `?`. The length filter applies to
    `?`-only patterns.
  - `headingByTermNoReading(:term)` for the kanji-first rule.
- The algorithm in `prepareSearchResultsJapaneseLanguage` is ported as is:
  the wildcard branch; the per-prefix loop (exact term, exact reading,
  deinflected term, deinflected reading, katakana and hiragana variants);
  `bestLength`; the starts-with injection; the Dart comparator (P tag,
  popularity, frequency by dictionary order, entry count, discovery order);
  kanji-first; truncation to the maximum.
- Deliberate changes:
  - Starts-with and reading searches get a `LIMIT` of the remaining slots.
    Some are unbounded today.
  - The `try`/`catch` with a 200 ms delay around the first query goes.
  - No persistence: no result row written, no trimming to 200 results.
- Dictionary history: `addToDictionaryHistory` upserts the term into
  `dictionary_history` and trims it to 10. On the Dictionary tab each history
  card calls `searchDictionary(term)` with the default maximum and shows a
  placeholder until it resolves. Removing dictionaries clears the history and
  the in-memory cache, as today.

## Import and delete

### Import

1. Main isolate: wipe and extract the archive into
   `dictionaryResources/importing/`. Read the name; refuse a duplicate, as
   today.
2. Import isolate, one transaction: insert the `dictionary` row (`order` is
   the current maximum plus one), import tags, then entries, pitches and
   frequencies, and return the new id.
3. Main isolate: rename `importing/` to `dictionaryResources/<id>/`, where
   structured content finds its images.

On failure the transaction rolls back and the staging directory is deleted.

The format functions (`prepareTags`, `prepareEntries`, `preparePitches`,
`prepareFrequencies` for Yomichan and Migaku) receive a
`DictionaryImportWriter` instead of an `Isar`:

```dart
int headingId(String term, String reading);
void addTag(DictionaryTag tag);
void addEntry({required int headingId, required List<String> definitions,
    required double popularity, List<String> entryTagNames,
    List<String> headingTagNames});
void addPitch({required int headingId, required int downstep});
void addFrequency({required int headingId, required double value,
    required String displayValue});
```

- `headingId` memoises a `Map<(String, String), int>` for the import and, on
  a miss, runs `INSERT … ON CONFLICT(term, reading) DO UPDATE SET term =
  excluded.term RETURNING id`, so headings created by other dictionaries are
  reused.
- `addTag` remembers each tag's id by name; tag names not defined by the
  dictionary are skipped, as today.
- Statements are raw `sqlite3` prepared statements, run synchronously (Rule 2).
- Pitches and frequencies pass their real reading. This fixes an upstream bug
  where a pitch or frequency for a word missing from the term dictionaries
  was attached to the reading-less heading.

### Delete

In an isolate, one transaction:

- One dictionary: `DELETE FROM dictionary WHERE id = ?` (the cascade removes
  its entries, pitches, frequencies, tags and their tag links), then delete
  headings with no entry, pitch, frequency or heading tag.
- All dictionaries: delete from every dictionary table.

Then `PRAGMA incremental_vacuum`, removal of the resource directory, clearing
of the dictionary history and the search cache, and the existing
notification.

## Testing

Unit tests in `test/`, against in-memory SQLite, with no device and no mocks:

- Raw synchronous reads: each getter's query returns correctly mapped rows,
  JSON columns included.
- Import writer: heading shared between two dictionaries; memoisation; tag
  linking and unknown tags skipped; a pitch or frequency for an unknown word
  keeps its reading; a failure rolls the whole import back.
- Loader: aggregates fully and correctly assembled, in the requested order.
- Search, on a small fixture dictionary written through the writer: exact
  term and reading; deinflection (食べた → 食べる); katakana and hiragana
  fallbacks; starts-with ordering and limit; wildcards; kanji-first; P-tag and
  frequency ranking. These characterise behaviour, as the existing tests do.
- Delete: the cascade removes a dictionary's rows; orphan headings go; shared
  headings stay.
- App data: `putMediaItem` keeps the row id; deleting a media item deletes its
  stash; stash uniqueness; search history and dictionary history trimming.
- Schema: `drift_dev schema dump` commits `drift_schemas/drift_schema_v1.json`
  and a generated schema test checks the database against it.

CI: Drift's generated files come from the existing `build_runner` step and
are covered by the freshness check; the schema dump is regenerated and
diffed too. Planning checks that `flutter test` on the Ubuntu runner can load
SQLite.

Manual device testing, compared against a baseline recorded on the Isar build
before the change: JMdict, pitch and frequency dictionary import times; lookup
latency on long selections. Then: reader lookup to card creation to
AnkiDroid export; stash add, peek and card creation; mokuro history;
Dictionary tab history; profile and catalog editing; deleting a dictionary,
with the database file shrinking.

## Sequencing

One branch of commits, each passing `flutter analyze` and `flutter test`.
Isar and Drift coexist until the last steps, so the app works throughout.

1. Spike: Drift's `table.map` on raw `sqlite3` rows.
2. Database scaffolding: packages (per `docs/TOOLCHAIN.md`), `AppDatabase`
   with the full schema, opening in `initialise()`, schema dump and test.
3. App tables to Drift: media items, stash, Anki mappings, mokuro catalogs,
   search history, dictionary history.
4. Dictionary import and delete: the writer, both formats, the staging
   directory, vacuum.
5. Loader and search: `search.drift`, the isolate, ranking, history cards.
6. Model cleanup: remove `IsarLink`s and update the widget call sites.
7. Remove Isar: packages, `globalSchemas`, the `analyzer` pin, `fastHash`.
8. Documentation: `docs/TOOLCHAIN.md`, and `CLAUDE.md`'s Persistence and
   reader sections.

## Out of scope

- Replacing Hive (next spec, before 1.0).
- Collapsing the per-prefix search loop into one query; the dead
  `deinflectionsAlreadySearched` bookkeeping.
- A long-lived search isolate.
- Migrating data from existing Isar installs.
