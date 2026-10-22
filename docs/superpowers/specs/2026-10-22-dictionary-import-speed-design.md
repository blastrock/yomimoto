# Faster Yomichan dictionary import

## Why

Importing a large Yomichan dictionary on an e-ink device takes many minutes.
Measured on the user's Supernote Nomad (RK3566, four Cortex-A55 cores, 4 GB
RAM, Android 11), with a profile build of the current code:

| Dictionary | Size | Today |
|---|---|---|
| `[Bilingual] JMdict (Recommended)` — 513k entries, 810k entry tags | 18 MB zip, 182 MB JSON | 576 s |
| `[Freq] JPDB (Recommended)` — 515k frequencies, imported after JMdict | 6 MB zip, 48 MB JSON | 253 s |
| Both | | **829 s (13.8 min)** |

The user wants this substantially faster and accepts a complex change for a
large gain.

### Where the time goes

Measured on the device (JMdict):

- Dart `jsonDecode` of every term bank: 42 s, done **twice** (a first pass
  only counts entries for the progress text).
- `processDefinition` re-encoding structured content to JSON: 26 s.
- `StringListConverter` JSON-encoding the definition list (escaping the
  already-encoded structured content again): 40 s.
- File reads: 6 s, twice.
- The remaining ~410 s is the per-row work in `DictionaryImportWriter`: one to
  four FFI round trips per row, `RETURNING` result sets, Dart record hashing.

Things that were measured and are **not** the bottleneck, so are out of scope:

- SQLite tuning: `cache_size` 128 MB −15%, `synchronous=OFF` no gain,
  `journal_mode=OFF` no gain, dropping and recreating secondary indexes −5%.
  The import is CPU-bound, not I/O-bound.
- Progress messages to the UI: −5% when suppressed.

### What was validated

A throwaway prototype parsing the banks inside SQLite (`json_each`) and
inserting set-based, in chunks, with the banks read from the zip into memory,
was run on the device:

| | JMdict | JPDB | Total | vs today |
|---|---|---|---|---|
| Prototype, today's definition format kept | 152 s | 83 s | 235 s | −72% |

On desktop, the prototype's database was compared table by table with
today's import of the same two dictionaries: `dictionary`, `heading`, `tag`,
`entry_tag`, `heading_tag`, `pitch` and `frequency` are identical, ids
included. `entry` is identical except that 65,984 definitions keep a JSON
escape as written in the source (`\u0026`) where Dart's re-encode writes `&`;
every one of them decodes to the same value. Two further optimisations,
validated on desktop but not on the device (see *Performance work*), are
expected to bring the total to roughly −78%.

## Goals

- Import Yomichan dictionaries several times faster on slow devices: target
  at least −70% on the JMdict + JPDB pair on the Supernote, aim for ~−78%.
- Same database content as today (see *Equivalence* for the one accepted
  difference). No schema change.
- Malformed dictionaries still fail the import as a whole, as today.
- A meaningful progress bar during import.
- Stop extracting the bank JSON to flash, and stop keeping it on disk after
  import.
- No UI freeze while the archive is opened.

## Non-goals

- Migaku import: keeps its current path and `DictionaryImportWriter`.
- Changing the stored definition format, the schema, or search.
- SQLite pragma tuning (measured as not worth it).
- Parallelising across cores.
- Deletion speed.

## Anti-goals

- A different database content for the same dictionary, beyond the JSON
  escape difference described below. Lookups, display and card creation must
  not notice the change.
- A dictionary that imports "successfully" but crashes or misbehaves at
  lookup because a wrongly typed value slipped in.
- A progress display that freezes at one value for most of the import (it may
  pause per file, see below).

## Constraints

- Project rules in `CLAUDE.md` apply: barrel imports, strict lints with
  `flutter analyze` clean, British spelling, isolate entry points top-level,
  no migration code, generated files committed.
- The import stays one transaction: failure leaves nothing behind.
- Bundled SQLite is 3.54 (`sqlite3` package build hook): JSON functions, `->`
  and `->>`, `jsonb`, STRICT tables and `MATERIALIZED` CTEs are available.
- `async_zip`'s FFI symbols are not available under `flutter test` (the test
  host fails on `zip_open`). Code that needs to be unit-tested must not depend
  on reading a zip.
- After an import, structured content still finds its images in the
  dictionary's resource directory (`dictionaryResourceDirectory/<id>/`), at
  the path the definition names.

## Design

### 1. SQLite parses the banks

For a Yomichan dictionary, the import isolate no longer decodes JSON in Dart.
Each bank file's bytes are bound as a parameter and parsed by SQLite with
`json_each(CAST(? AS TEXT))`. Binding the bytes and casting avoids a Dart
UTF-8 decode; the cast is required because SQLite would otherwise treat a
blob as JSONB.

Per dictionary, inside the existing transaction:

1. **Tags.** Each `tag_bank_*` file: one `INSERT INTO tag … SELECT … FROM
   json_each(…) ON CONFLICT (dictionary_id, name) DO UPDATE …`, keeping
   today's "defining again overwrites" behaviour. Tags go first: entries refer
   to them.
2. **Term banks**, one file at a time:
   - One statement stages the whole file into a temporary `stage` table, one
     row per entry, with term, reading, definition tags, popularity, the
     definitions already converted to today's format (§3) and term tags.
   - Then, in chunks of 1000 staged rows: insert the missing headings, the
     entries, the entry tags, the heading tags. Report progress after each
     chunk (§6).
   - The stage is emptied before the next file.
3. **Kanji banks**: staged and inserted the same way, the definition text
   built in SQL to match today's `StringBuffer` output exactly (§3).
4. **Term meta banks** (frequencies and pitches): staged into a temporary
   `meta_stage` table, with each frequency's reading, value and display value
   computed during staging (§4), then inserted in chunks of 1000 like terms.

Entry ids are assigned explicitly (`stage.n` plus the current maximum entry id
taken before the file), so entry tags can be inserted without reading ids
back. Headings are inserted in staging order with `ON CONFLICT DO NOTHING`;
the prototype showed this gives the same heading ids as today.

**Join order.** The tag statements split the space-separated tag string with
`json_each` and must keep the stage as the outer loop (`CROSS JOIN`). Without
it SQLite's planner loops over the tags on the outside and re-splits every
row once per tag: 150 s instead of 2 s on desktop.

**Tag splitting** builds a JSON array from the tag string; backslashes and
double quotes in tag names are escaped first, so any tag name works. An
empty or missing definition-tag string yields no tags, as today.

### 2. STRICT staging tables for type checking

`stage` and `meta_stage` are `TEMP` tables declared `STRICT`, with `NOT NULL`
where today's Dart code requires a value. A value that cannot be converted to
the column type (for example a popularity of `"abc"`) makes the staging
statement fail, which aborts the import's transaction, as a Dart cast error
does today. This restores today's validation without touching the real
schema (SQLite cannot switch an existing table to STRICT and back).

Accepted leniency compared with today: SQLite converts values that convert
losslessly — a number where a string is expected becomes text, `"5"` for a
popularity becomes 5.0 — where Dart's casts would have failed. Such data
imports correctly.

A term bank's definitions field that is not a JSON array must fail the
import: the conversion expression yields NULL for it and the `NOT NULL`
constraint rejects it. (`raise()` is only allowed inside triggers.)

The error message is SQLite's, e.g. `cannot store TEXT value in REAL column
stage.popularity`. Like today's error, it does not name the offending entry.

Every path that writes into a non-STRICT real table must be covered, or a
wrong-typed value is stored and only fails when read (an anti-goal). In the
prototype three paths were not, and the implementation closes them:

- tags were inserted straight into `tag` (a `sorting_order` of `"abc"` would
  be stored as text): stage them through a STRICT temp table too;
- pitch positions were inserted straight into `pitch.downstep`: stage them
  through a STRICT table too;
- a definition element such as `{type: "text", text: 5}` would put a number
  in the stored array, which `StringListConverter` (`List<String>.from`)
  rejects at read: a definition element whose string-valued source is not a
  string makes the whole definitions value NULL, so the `NOT NULL` check
  fails the import.

### 3. Definitions keep today's format

`entry.definitions` stays a JSON array of strings, produced in SQL during
staging, matching `YomichanFormat.processDefinition` element by element:

- a string: kept as is;
- `{type: "text"}`: its `text`;
- `{type: "structured-content"}` or `{type: "image"}`: its `content`
  serialised as JSON, as a string; a missing `content` gives the string
  `"null"`, as `jsonEncode(null)` does today (an existing oddity, kept);
- anything else: dropped.

**Equivalence.** SQLite keeps JSON escapes as written in the source, where
Dart's decode and re-encode normalises them: the source's `\u0026` stays
`\u0026` inside the stored string where today it becomes `&`. Both decode to
the same value, and everything that reads definitions decodes them first.
This difference is accepted.

Kanji bank definitions are built today in Dart from on'yomi, kun'yomi and
meanings (`音読み`, `訓読み`, `意味` sections with `  • ` bullets, trimmed,
skipped when empty). The SQL must produce the same string, and kanji entries
whose definition comes out empty must still be skipped. No test dictionary
had kanji banks, so this was not measured. If an exact SQL equivalent proves
impractical, kanji banks (small) may stay on a Dart path; the builder decides.

Keeping the format costs about 38 s on the device compared with storing the
source arrays raw (measured). It was chosen to avoid any schema or reader
change.

### 4. Frequencies and pitches

`meta_stage` computes, for each row and in staging, the heading reading, the
value and the display value, reproducing
`prepareFrequenciesYomichanFormat`'s cases in its order: plain number (int or
double), object with `reading` and a `frequency` object, object with
`displayValue`, object with `value`, object with a numeric `frequency`, and
anything else. A row whose case leaves the reading unset is skipped, as
today. Integral doubles display without a decimal part, as today. Pitches
take `reading` (default empty) and each element of `pitches`' `position`.
Meta rows of any other type are ignored, as today.

**Order.** Today all term and kanji banks are imported before any meta bank,
and all pitches before all frequencies; that order decides which heading ids
new headings get. The new path also processes every term and kanji bank
before any meta bank, whatever their order in the archive. Within meta
banks it may interleave pitches and frequencies row by row: for a dictionary
that has both, heading and row ids can then differ from today's, with the
same content. This is accepted (no test dictionary has both).

The prototype's statement for this is in the appendix. It was reworked after
the device run (see *Performance work*); the reworked form produced
identical rows on desktop.

### 5. Reading from the zip

The bank JSON is no longer extracted to flash.

- The whole import, opening the archive included, runs in the import isolate.
  Today the extraction runs on the UI isolate and freezes the app for about
  5 s on the device.
- `index.json` is read from the archive for the dictionary name, then the
  existing duplicate-name check runs before anything is written.
- Bank files (`tag_bank_*`, `term_bank_*`, `kanji_bank_*`,
  `term_meta_bank_*`) are read one at a time into memory with
  `ZipFileReaderSync.read` and handed to the SQL import as bytes. Files are
  3–4 MB in JMdict, 48 MB for JPDB's single meta bank.
- Every other archive entry (images and any other resources structured
  content may reference), except `index.json`, is extracted to the
  dictionary's staging resource directory, which the existing flow renames to
  `<id>` on success. The bank JSON therefore no longer stays in each
  dictionary's resource directory (182 MB for JMdict today).

How the format functions receive their input is left to the builder (see
*Left to the builder*), under the constraint that the SQL import itself is
testable without a zip.

### 6. Progress

- Progress is a fraction of the total size of the bank files (from the zip
  entries' sizes), updated after each chunk of 1000 rows and at each file's
  end. No pre-counting pass.
- The dialog's indeterminate `CircularProgressIndicator` is replaced by a
  determinate progress bar showing the fraction, with the percentage as text.
  This also stops an indefinitely animating spinner, which causes constant
  refreshes on e-ink.
- Because each file is parsed in a single statement, the bar pauses while a
  file is staged, then advances in steps. For JPDB's single 48 MB file the
  pause is long (most of its import). This is accepted.
- The per-entry and per-phase texts (`import_found_*`, `import_write_*`)
  are no longer used by the Yomichan path. The builder removes the ones no
  format uses any more; Migaku's progress may keep its current text.

### 7. What stays

- `DictionaryImportWriter` and the Migaku format, unchanged.
- The one-transaction import, the WAL truncate after commit, the error and
  cancellation behaviour as seen by the user (message, then "import failed").
- Schema, search, display and card creation.

## Performance work

Two optimisations were found after the device run of the prototype. Both are
expected in the implementation:

- **Frequency staging via `jsonb`, computed once.** Each `d->>'…'` on the
  frequency object re-parsed it. Converting it once with `jsonb(value->2)`
  inside a `MATERIALIZED` CTE (so the planner does not inline it back into
  every use) took the staging of JPDB from 7.6 s to 3.5 s on desktop, with
  identical rows. Without `MATERIALIZED` it is no faster. Device estimate:
  JPDB from 83 s to 50–55 s.
- **Heading ids resolved once per file.** The prototype's chunked statements
  look each heading up by `(term, reading)` in the entry insert and join
  `entry` again for heading tags. An earlier, unchunked prototype resolved
  heading ids once into the stage (`UPDATE stage SET heading_id = …`) and was
  faster (91 s against 114 s for the raw-definition variant of JMdict on the
  device). Resolving once per chunk or per file is expected to recover
  15–20 s.

The same `jsonb` trick applied to definitions brought nothing measurable
(3.3 s → 3.1 s on ten JMdict files) and is not required.

## Verification

- **Unit tests** (`test/`, mirroring `lib/src/`), running the SQL import on
  small bank fixtures with no zip involved: tags, terms with plain-text,
  `text`-object, structured-content and image definitions, unknown
  definition types dropped, tag splitting (including a tag name with a quote),
  heading reuse across dictionaries, kanji banks, every frequency shape
  including the skipped one, pitches, and failures (wrongly typed value,
  definitions not a list, broken JSON) leaving nothing written.
- **One-off equivalence check before the old Yomichan code is deleted**:
  import JMdict and JPDB (the two zips named above, available on the user's
  machine) with today's code and with the new code into two databases on
  desktop, and compare every table with `EXCEPT` in both directions; entries
  that differ must be equal once their definitions are JSON-decoded. This is
  how the prototype was checked. Ids depend on file order: today's code
  takes the extracted directory's `listSync()` order, the new one the
  archive's. For the check, feed the new SQL import the extracted files in
  `listSync()` order, so ids are comparable.
- `/home/blastrock/Downloads/` also has a jitendex zip whose images sit in
  subdirectories: use it to check that images are extracted to the right
  paths and display.
- **On the Supernote**, a profile build: JMdict then JPDB, timed, compared
  with the 576 s / 253 s baseline. Do not install a debug build over the
  user's installed `org.kaqui.yomimoto` (release-signed: the signature
  mismatch would force an uninstall and wipe their library). The measurements
  above used a temporary `applicationId` suffix.
- Manual device check: lookups display JMdict structured content (with an
  image if any test dictionary has one), frequencies show, card creation
  works.

## Left to the builder

- How `DictionaryFormat` changes to fit a format whose import works from an
  archive in one pass (e.g. Yomichan overriding a single import hook, while
  Migaku keeps the current per-phase functions), keeping isolate entry points
  top-level.
- How progress travels from the isolate to the dialog (today a `String`
  through a `SendPort`) and the strings for the new progress text.
- The exact SQL, starting from the appendix.
- Whether kanji banks go through SQL or stay on a Dart path (§3).
- Where the duplicate-name check runs now that the archive is opened in the
  isolate: in the isolate against the `dictionary` table (`name` is already
  unique), or by sending the name back to the UI isolate first. The user
  must still get today's "already imported" message, before anything is
  written or extracted.
- Where the new code lives (`lib/src/database/` next to the writer, or the
  format file), within the barrel rules.
- Updating `CLAUDE.md`'s persistence section (it calls the import writer "the
  one raw writer") and `DEBT.md` if a shortcut is taken.

## Calls made during design (not discussed with the user)

- Every non-bank archive entry except `index.json` is extracted, not only
  images, since structured content may reference other files.
- The source's JSON escapes are preserved in stored definitions (accepted
  difference, see §3).
- Lossless type conversions by SQLite are accepted (§2).
- Tags and pitches are staged through STRICT tables too, and wrongly typed
  definition elements fail the import (§2), so no write path skips type
  checking.
- Every term and kanji bank is processed before any meta bank; pitch and
  frequency ids may interleave (§4).
- The `"null"` string for image definitions without `content` is kept for
  equivalence.
- Progress pauses during the staging of each file, notably on JPDB's single
  large file.
- Kanji banks may stay on a Dart path if exact SQL equivalence is
  impractical.

## Appendix: prototype SQL

From the throwaway prototype, validated on desktop against today's import
(term and frequency statements) and timed on the device. Parameter numbers
are as bound in the prototype; `?1` is the file's bytes where it is the only
parameter.

Term staging:

```sql
CREATE TEMP TABLE stage (
  n INTEGER PRIMARY KEY,
  term TEXT NOT NULL,
  reading TEXT NOT NULL,
  def_tags TEXT,
  popularity REAL NOT NULL,
  definitions TEXT NOT NULL,
  term_tags TEXT NOT NULL
) STRICT;

INSERT INTO stage (term, reading, def_tags, popularity, definitions, term_tags)
SELECT r.value->>0, r.value->>1, r.value->>2, r.value->>4,
  CASE WHEN json_type(r.value->5) = 'array' THEN (
    SELECT json_group_array(d) FROM (
      SELECT CASE
        WHEN e.type = 'text' THEN e.atom
        WHEN e.type = 'object' AND e.value->>'type' = 'text' THEN e.value->>'text'
        WHEN e.type = 'object'
            AND e.value->>'type' IN ('structured-content', 'image')
          THEN COALESCE(json(e.value->'content'), 'null') || ''
      END AS d
      FROM json_each(r.value->5) e
      ORDER BY e.id
    ) WHERE d IS NOT NULL) END,
  r.value->>7
FROM json_each(CAST(?1 AS TEXT)) r;
```

The outer row must be aliased (`r`): inside the definitions subquery a bare
`value` binds to the inner `json_each`, which silently produced empty
definition lists in the prototype. `|| ''` strips the JSON subtype so the
content is added to the array as a string.

Per chunk (`?1`, `?2`: the chunk's `n` range; `?3`: the entry id offset;
`?4`: the dictionary id):

```sql
INSERT INTO heading (term, reading)
SELECT term, reading FROM stage WHERE n BETWEEN ?1 AND ?2
ON CONFLICT DO NOTHING;

INSERT INTO entry (id, heading_id, dictionary_id, definitions, popularity)
SELECT n + ?3,
  (SELECT id FROM heading h WHERE h.term = s.term AND h.reading = s.reading),
  ?4, definitions, popularity
FROM stage s WHERE n BETWEEN ?1 AND ?2;

INSERT OR IGNORE INTO entry_tag (entry_id, tag_id)
SELECT s.n + ?3, t.id
FROM stage s
CROSS JOIN json_each('["' || replace(replace(replace(s.def_tags,
    '\', '\\'), '"', '\"'), ' ', '","') || '"]') j
CROSS JOIN tag t ON t.dictionary_id = ?4 AND t.name = j.value
WHERE s.n BETWEEN ?1 AND ?2 AND s.def_tags IS NOT NULL;

INSERT OR IGNORE INTO heading_tag (heading_id, tag_id)
SELECT e.heading_id, t.id
FROM stage s
CROSS JOIN entry e ON e.id = s.n + ?3
CROSS JOIN json_each('["' || replace(replace(replace(s.term_tags,
    '\', '\\'), '"', '\"'), ' ', '","') || '"]') j
CROSS JOIN tag t ON t.dictionary_id = ?4 AND t.name = j.value
WHERE s.n BETWEEN ?1 AND ?2;
```

Frequency and pitch staging, in the reworked `jsonb` + `MATERIALIZED` form:

```sql
CREATE TEMP TABLE meta_stage (
  n INTEGER PRIMARY KEY,
  term TEXT NOT NULL,
  type TEXT NOT NULL,
  reading TEXT,
  value REAL,
  display_value TEXT,
  data ANY
) STRICT;

INSERT INTO meta_stage (term, type, reading, value, display_value, data)
SELECT term, type,
  CASE
    WHEN type = 'pitch' THEN COALESCE(d->>'reading', '')
    WHEN t <> 'object' THEN ''
    WHEN d->>'reading' IS NOT NULL AND json_type(d, '$.frequency') = 'object'
      THEN d->>'reading'
    WHEN d->>'displayValue' IS NOT NULL OR d->>'value' IS NOT NULL
        OR json_type(d, '$.frequency') IN ('integer', 'real')
      THEN COALESCE(d->>'reading', '')
  END,
  CASE
    WHEN t IN ('integer', 'real') THEN d->>'$'
    WHEN t <> 'object' THEN 0
    WHEN d->>'reading' IS NOT NULL AND json_type(d, '$.frequency') = 'object'
      THEN COALESCE(d->'frequency'->>'value', 0)
    WHEN d->>'displayValue' IS NOT NULL OR d->>'value' IS NOT NULL
      THEN COALESCE(d->>'value', 0)
    ELSE d->>'frequency'
  END,
  CASE
    WHEN t = 'integer' THEN d->>'$'
    WHEN t = 'real' THEN iif(d->>'$' = floor(d->>'$'),
      CAST(CAST(d->>'$' AS INTEGER) AS TEXT), d->>'$')
    WHEN t <> 'object' THEN d->>'$'
    WHEN d->>'reading' IS NOT NULL AND json_type(d, '$.frequency') = 'object'
      THEN COALESCE(d->'frequency'->>'displayValue', '')
    WHEN d->>'displayValue' IS NOT NULL THEN d->>'displayValue'
    WHEN d->>'value' IS NOT NULL THEN CAST(CAST(d->>'value' AS INTEGER) AS TEXT)
    WHEN json_type(d, '$.frequency') = 'integer' THEN d->>'frequency'
    ELSE iif(d->>'frequency' = floor(d->>'frequency'),
      CAST(CAST(d->>'frequency' AS INTEGER) AS TEXT), d->>'frequency')
  END,
  CASE WHEN type = 'pitch' THEN d->'pitches' END
FROM (
  WITH x AS MATERIALIZED (
    SELECT value->>0 AS term, value->>1 AS type, jsonb(value->2) AS d,
      json_type(value->2) AS t
    FROM json_each(CAST(?1 AS TEXT))
  ) SELECT * FROM x
)
WHERE type IN ('freq', 'pitch');
```

Per chunk (`?3`: the dictionary id):

```sql
INSERT INTO heading (term, reading)
SELECT term, reading FROM meta_stage
WHERE n BETWEEN ?1 AND ?2 AND reading IS NOT NULL
ON CONFLICT DO NOTHING;

INSERT INTO frequency (heading_id, dictionary_id, value, display_value)
SELECT (SELECT id FROM heading h WHERE h.term = m.term AND h.reading = m.reading),
  ?3, value, display_value
FROM meta_stage m
WHERE n BETWEEN ?1 AND ?2 AND type = 'freq' AND reading IS NOT NULL;

INSERT INTO pitch (heading_id, dictionary_id, downstep)
SELECT (SELECT id FROM heading h WHERE h.term = m.term AND h.reading = m.reading),
  ?3, p.value->>'position'
FROM meta_stage m CROSS JOIN json_each(m.data) p
WHERE m.n BETWEEN ?1 AND ?2 AND m.type = 'pitch'
ORDER BY m.n, p.id;
```

With `d` now JSONB, `d->'pitches'` stores JSONB in `data`; `json_each`
accepts it. The pitch path was not exercised by either test dictionary.
