# Replace Isar with Drift: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move every Isar collection to a Drift/SQLite database whose schema version 1 becomes the 1.0 baseline, with no change in what the user sees.

**Architecture:** One SQLite file opened on the main isolate through a raw `sqlite3` connection that Drift (`NativeDatabase.opened`) shares. Widgets keep synchronous getters, which read through the raw connection (`AppStore`); all main-isolate writes go through Drift. Dictionary search, import and deletion run in isolates on their own connections. Import writes through raw prepared statements (`DictionaryImportWriter`); search uses compile-checked queries in `search.drift`, and builds fully loaded headings with `loadHeadings`.

**Tech Stack:** Flutter 3.44.8 / Dart 3.12, `drift` 2.35, `drift_dev` 2.35, `sqlite3` 3.5 (SQLite bundled by its build hook), `build_runner`, `flutter_test`.

**Spec:** `docs/superpowers/specs/2026-10-14-drift-migration-design.md`. Read it before starting any task. `DEBT.md` records the one shortcut the spec takes.

## Global Constraints

- Versions: `drift: ^2.35.2`, `drift_dev: ^2.35.1`, `sqlite3: ^3.5.2` (held below 3.6: 3.6+ needs `hooks` ^2.2, whose `record_use` needs `meta` ^1.19, and Flutter 3.44 pins `meta` 1.18), `dart_mappable_builder: ^4.10.0`. Until Task 9, `isar_community`, `isar_community_flutter_libs` and `isar_community_generator` are `^3.4.1` (3.4.1 is the first generator release that accepts analyzer ≥13, which `drift_dev` requires).
- `flutter analyze` reports **no issues, infos included**, and `flutter test` passes, at the end of every task.
- `public_member_api_docs`: every public class, member, getter and top-level declaration in `lib/` gets a `///` comment. Other enforced rules that bite new code: `prefer_single_quotes`, `always_put_control_body_on_new_line` (always use braces and put bodies on their own line), `sort_constructors_first`, `avoid_types_on_closure_parameters`, `prefer_constructors_over_static_methods` (use factories or top-level functions, never a static method returning its own class), `comment_references` (only put `[Name]` in a doc comment when `Name` is in scope; otherwise use backticks), `missing_whitespace_between_adjacent_strings`, `unnecessary_await_in_return`, `use_null_aware_elements`.
- British spelling in identifiers, comments and strings (`initialise`, `normalise`).
- Imports: `package:` imports only, through the barrels (`package:yuuna/database.dart`, never `package:yuuna/src/...`). Tests import their own helpers relatively (`import 'test_database.dart';`), which the rule allows.
- `sqlite3` exports a `Row` class that clashes with Flutter's `Row` widget: import it as `import 'package:sqlite3/sqlite3.dart' show Database, sqlite3;` (add `SqliteException` where needed), never unrestricted.
- Do not run `dart format` on existing files; it rewrites unrelated lines. Format new code by hand in the style of the surrounding file (2-space indent, trailing commas in multi-line argument lists).
- Generated files (`*.g.dart`, `*.mapper.dart`, `lib/i18n/strings.g.dart`, `drift_schemas/*.json`, `test/database/generated/*`) are committed. Regenerate, never hand-edit.
- Internal names keep the upstream spelling (`yuuna`, `Jidoujisho*`, `jidoujisho_*.dart`). Do not rename them.
- No code migrates data from Isar installs. The schema stays at version 1; before 1.0 ships, schema changes edit version 1 and re-dump it.
- On the main isolate, raw `sqlite3` is for reads only; every write goes through Drift. The import isolate's `DictionaryImportWriter` is the one raw writer.
- The SQLite file is `yomimoto.sqlite` in the app support directory (`AppModel.databaseDirectory`).
- Version control is jj. Commit with `jj commit -m "<message>"`; every message ends with a blank line and `Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>`. Run `jj status` first and check that only the task's files are listed. Messages are short imperative sentences, as in `jj log`.
- Shell: `cp` and `mv` are interactive aliases. Use `command cp -f` / `command mv -f`.

## Review Focus

Inputs and conditions the spec implies, but no test of the spec's own list covers. Each one has a test in the owning task.

1. **A selection containing a GLOB metacharacter** (`[`, or `*`/`?` typed while wildcards are on): the lookup returns normally instead of throwing. Tested in Task 8 (`search('[*', wildcards: true)`).
2. **Wildcard search on a word containing a non-BMP kanji** (𠮟る): SQLite's `length()` counts characters, Dart's `String.length` counts UTF-16 units, and the length filter must use characters. Tested in Task 8 (`search('𠮟？', wildcards: true)` finds 𠮟る).
3. **A book opened while the library sync writes the same item**: two concurrent upserts of one `(source, identifier)` leave one row. Tested in Task 3.
4. **Reordering under `UNIQUE("order")`**: swapping two dictionaries, profiles or catalogs never trips the constraint. Tested in Task 4 (profiles) and Task 7 (dictionaries).
5. **An import that fails partway** (a malformed bank file, or a duplicate name that slipped past the UI check) leaves no dictionary row and no data. Tested in Task 7.

## Manual checkpoints (for the human)

- **Before Task 1:** on a device, with the current Isar build, import JMdict, one pitch dictionary and one frequency dictionary, and time each. Time a few lookups on long selections. Write the numbers down; Task 10 compares against them.
- **Task 10** is a device pass at the end. An executor without a device stops after Task 9 and hands over.

## File structure

Created:

| File | Responsibility |
|---|---|
| `build.yaml` | `drift_dev` options (named parameters on generated queries) |
| `lib/database.dart` | Barrel for `lib/src/database/` |
| `lib/src/database/converters.dart` | Drift `TypeConverter`s: JSON lists and maps, microsecond timestamps |
| `lib/src/database/tables.dart` | Every Drift table definition |
| `lib/src/database/app_database.dart` | `AppDatabase`, connection configuration, file name |
| `lib/src/database/search.drift` | Named SQL queries for search and the heading loader |
| `lib/src/database/app_store.dart` | `AppStore`: synchronous reads and Drift writes for app data and the dictionary list |
| `lib/src/database/dictionary_import_writer.dart` | `DictionaryImportWriter`: raw prepared-statement writes during an import |
| `lib/src/database/dictionary_deletion.dart` | Delete one or all dictionaries, orphan headings, vacuum |
| `lib/src/database/heading_loader.dart` | `loadHeadings`: rows → fully loaded `DictionaryHeading`s |
| `drift_schemas/drift_schema_v1.json` | Committed schema snapshot (generated) |
| `test/database/generated/` | Schema helpers for the schema test (generated) |
| `test/database/test_database.dart` | In-memory database and fixture helpers for tests |
| `test/database/app_database_test.dart`, `schema_test.dart`, `app_store_test.dart`, `dictionary_import_writer_test.dart`, `search_queries_test.dart`, `dictionary_deletion_test.dart`, `heading_loader_test.dart` | Tests |
| `test/dictionary/dictionary_utils_test.dart` | Import isolate entry point tests |
| `test/language/japanese_search_test.dart` | Search algorithm tests |

Modified, mainly: `pubspec.yaml`, `analysis_options.yaml`, `.github/workflows/main.yml`, `docs/TOOLCHAIN.md`, `CLAUDE.md`, `lib/src/models/app_model.dart`, the model classes (`lib/src/media/media_item.dart`, `stash_item.dart`, `lib/src/creator/anki_mapping.dart`, `lib/src/utils/misc/mokuro_catalog.dart`, `lib/src/dictionary/dictionary*.dart`), both dictionary formats, `dictionary_format.dart`, `dictionary_operations_params.dart`, `dictionary_utils.dart`, `japanese_language.dart`, and the pages and fields that read Isar links.

Deleted: `lib/src/creator/search_history_item.dart` (+ `.g.dart`), the Isar-only `.g.dart` part files.

---

### Task 0: Isar baseline (manual)

Done by the human, on a device, before any code changes: see *Manual checkpoints*. Nothing to commit.

---

### Task 1: Dependencies and toolchain

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`, every regenerated `*.g.dart` / `*.mapper.dart`
- Modify: `docs/TOOLCHAIN.md`

**Interfaces:**
- Produces: `drift`, `sqlite3` and `drift_dev` resolvable; Isar generator 3.4.1; the `dart_mappable_builder` pin lifted.

- [ ] **Step 1: Edit `pubspec.yaml`**

In `dependencies`, after `device_info_plus: ^13.2.0` add:

```yaml
  drift: ^2.35.2
```

Change `isar_community: ^3.3.2` to `isar_community: ^3.4.1` and `isar_community_flutter_libs: ^3.3.2` to `isar_community_flutter_libs: ^3.4.1`.

After the `spaces:` block (before `stack_trace:`) add:

```yaml
  # Held at 3.5: sqlite3 3.6+ needs hooks ^2.2, whose record_use needs meta
  # ^1.19, and Flutter 3.44 pins meta 1.18. Bundles SQLite through its build
  # hook; sqlite3_flutter_libs is end-of-life and not needed.
  sqlite3: ^3.5.2
```

In `dev_dependencies`, replace the `dart_mappable_builder` comment and constraint (the four comment lines starting `# Pinned below 4.8` and the constraint line) with:

```yaml
  dart_mappable_builder: ^4.10.0
```

After it add:

```yaml
  drift_dev: ^2.35.1
```

Replace `isar_community_generator: ^3.3.2` with:

```yaml
  # 3.4.1 is the first release accepting analyzer >=13, which drift_dev and
  # dart_mappable_builder 4.10 need. Removed with Isar.
  isar_community_generator: ^3.4.1
```

- [ ] **Step 2: Resolve and regenerate**

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Expected: `pub get` resolves `analyzer` 13.x, `drift` 2.35.2, `drift_dev` 2.35.1, `sqlite3` 3.5.2, `isar_community_generator` 3.4.1, `dart_mappable_builder` 4.10.x. `build_runner` succeeds. `jj diff --stat` shows regenerated `*.g.dart` and `*.mapper.dart` files.

- [ ] **Step 3: Analyze and test**

```sh
flutter analyze
flutter test
```

Expected: `No issues found!` and all tests pass. If `flutter analyze` reports issues inside a regenerated `*.mapper.dart` file, add `- '**.mapper.dart'` under `analyzer: exclude:` in `analysis_options.yaml`, next to `'**.g.dart'`, and rerun.

- [ ] **Step 4: Check that Android still builds with the sqlite3 build hook**

```sh
flutter build apk --debug
```

Expected: the build succeeds and `build/app/outputs/` contains debug APKs. The hook downloads or compiles SQLite for each ABI; a network failure here is an environment problem, not a code one, so report it and stop rather than work around it.

- [ ] **Step 5: Update `docs/TOOLCHAIN.md`**

In the *Held back on purpose* table, delete the `dart_mappable_builder` row and add this row after the `permission_handler` row:

```markdown
| `sqlite3` | 3.5.x | 3.6+ needs `hooks` ^2.2 → `record_use` → `meta` ^1.19, and Flutter 3.44 pins `meta` 1.18 | A Flutter release pinning `meta` ≥ 1.19 |
```

Change the `dependency_validator` row's *Why* cell to `Needs analyzer < 13; drift_dev and dart_mappable_builder need ≥ 13`.

- [ ] **Step 6: Commit**

```sh
jj status
jj commit -m "Add Drift and sqlite3, lift the analyzer pin

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: Database scaffolding

**Files:**
- Create: `build.yaml`, `lib/database.dart`, `lib/src/database/converters.dart`, `lib/src/database/tables.dart`, `lib/src/database/app_database.dart`
- Create: `test/database/test_database.dart`, `test/database/app_database_test.dart`, `test/database/schema_test.dart`
- Generate: `lib/src/database/app_database.g.dart`, `drift_schemas/drift_schema_v1.json`, `test/database/generated/*`
- Modify: `analysis_options.yaml`, `.github/workflows/main.yml`, `lib/src/models/app_model.dart`

**Interfaces:**
- Produces: `AppDatabase` (`AppDatabase(QueryExecutor)`, `AppDatabase.fromRaw(Database)`, `factory AppDatabase.open(String path)`), `configureConnection(Database)`, `openRawDatabase(String path)`, `const databaseFileName`, every table class (`Dictionaries`, `Headings`, `Entries`, `Pitches`, `Frequencies`, `Tags`, `HeadingTags`, `EntryTags`, `MediaItems`, `StashItems`, `AnkiMappings`, `MokuroCatalogs`, `SearchHistoryItems`, `DictionaryHistoryItems`), the converters (`StringListConverter`, `NullableStringListConverter`, `QuickActionsColumnConverter`, `EnhancementsColumnConverter`, `MicrosecondsConverter`), `AppModel.databasePath`. Test helpers `TestDatabase`, `openTestDatabase()`, `countRows(Database, String)`.
- Row classes after this task: `Dictionary` (existing class, through `@UseRowClass`); generated `HeadingRow`, `EntryRow`, `PitchRow`, `FrequencyRow`, `TagRow`, `HeadingTagRow`, `EntryTagRow`, `SearchHistoryRow`, `DictionaryHistoryRow`; and temporary generated `MediaItemRow`, `StashItemRow`, `AnkiMappingRow`, `MokuroCatalogRow`, which Tasks 3 and 4 replace with the model classes.

- [ ] **Step 1: Write the failing tests**

`test/database/test_database.dart`:

```dart
import 'package:sqlite3/sqlite3.dart' show Database, sqlite3;
import 'package:yuuna/database.dart';

/// An opened in-memory database, configured like the app's, with the raw
/// connection Drift runs on.
typedef TestDatabase = ({AppDatabase db, Database raw});

/// Open a fresh [TestDatabase] with its schema created.
Future<TestDatabase> openTestDatabase() async {
  Database raw = sqlite3.openInMemory();
  configureConnection(raw);
  AppDatabase db = AppDatabase.fromRaw(raw);
  await db.customSelect('SELECT 1').get();
  return (db: db, raw: raw);
}

/// The number of rows in [table].
int countRows(Database raw, String table) {
  return raw.select('SELECT COUNT(*) AS count FROM $table').first['count']
      as int;
}
```

`test/database/app_database_test.dart`:

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart' show Database, SqliteException, sqlite3;
import 'package:yuuna/database.dart';

import 'test_database.dart';

void main() {
  group('openRawDatabase', () {
    test('persists WAL and incremental vacuum, and turns on foreign keys',
        () async {
      Directory directory =
          Directory.systemTemp.createTempSync('yomimoto_database_');
      addTearDown(() => directory.deleteSync(recursive: true));
      String file = path.join(directory.path, databaseFileName);

      AppDatabase db = AppDatabase.open(file);
      await db.customSelect('SELECT 1').get();
      await db.close();

      Database plain = sqlite3.open(file);
      addTearDown(plain.close);
      expect(plain.select('PRAGMA journal_mode').first.columnAt(0), 'wal');
      expect(plain.select('PRAGMA auto_vacuum').first.columnAt(0), 2);

      Database configured = openRawDatabase(file);
      addTearDown(configured.close);
      expect(configured.select('PRAGMA foreign_keys').first.columnAt(0), 1);
    });
  });

  group('schema', () {
    late TestDatabase database;

    setUp(() async {
      database = await openTestDatabase();
    });

    tearDown(() => database.db.close());

    test('assigns heading ids on insert', () {
      database.raw.execute(
          "INSERT INTO heading (term, reading) VALUES ('猫', 'ねこ')");
      expect(database.raw.lastInsertRowId, 1);
    });

    test('rejects an entry for a missing heading', () {
      database.raw.execute('INSERT INTO dictionary (name, format_key, "order") '
          "VALUES ('JMdict', 'yomichan', 1)");
      expect(
        () => database.raw.execute(
            'INSERT INTO entry (heading_id, dictionary_id, definitions, '
            "popularity) VALUES (42, 1, '[]', 0)"),
        throwsA(isA<SqliteException>()),
      );
    });

    test('deleting a dictionary deletes what it brought', () {
      Database raw = database.raw;
      raw.execute('INSERT INTO dictionary (name, format_key, "order") '
          "VALUES ('JMdict', 'yomichan', 1)");
      raw.execute("INSERT INTO heading (term, reading) VALUES ('猫', 'ねこ')");
      raw.execute('INSERT INTO entry (heading_id, dictionary_id, definitions, '
          "popularity) VALUES (1, 1, '[\"cat\"]', 0)");
      raw.execute('INSERT INTO pitch (heading_id, dictionary_id, downstep) '
          'VALUES (1, 1, 1)');
      raw.execute('INSERT INTO frequency (heading_id, dictionary_id, value, '
          "display_value) VALUES (1, 1, 10, '10')");
      raw.execute('INSERT INTO tag (dictionary_id, name, category, '
          "sorting_order, notes, popularity) VALUES (1, 'n', 'noun', 0, '', 0)");
      raw.execute('INSERT INTO entry_tag (entry_id, tag_id) VALUES (1, 1)');
      raw.execute('INSERT INTO heading_tag (heading_id, tag_id) VALUES (1, 1)');

      raw.execute('DELETE FROM dictionary');

      for (String table in [
        'entry',
        'pitch',
        'frequency',
        'tag',
        'entry_tag',
        'heading_tag',
      ]) {
        expect(countRows(raw, table), 0, reason: table);
      }
      expect(countRows(raw, 'heading'), 1);
    });
  });

  group('converters', () {
    test('round-trip their values', () {
      const StringListConverter strings = StringListConverter();
      expect(strings.fromSql(strings.toSql(['読む', 'よむ'])), ['読む', 'よむ']);

      const NullableStringListConverter nullable =
          NullableStringListConverter();
      expect(nullable.fromSql(nullable.toSql(['term', null])), ['term', null]);

      const QuickActionsColumnConverter actions = QuickActionsColumnConverter();
      expect(actions.fromSql(actions.toSql({0: 'card_creator'})),
          {0: 'card_creator'});

      const EnhancementsColumnConverter enhancements =
          EnhancementsColumnConverter();
      expect(
        enhancements.fromSql(enhancements.toSql({
          'term': {-1: 'auto', 0: 'manual'},
        })),
        {
          'term': {-1: 'auto', 0: 'manual'},
        },
      );

      const MicrosecondsConverter instants = MicrosecondsConverter();
      DateTime moment = DateTime.fromMicrosecondsSinceEpoch(1760000000123456);
      expect(instants.fromSql(instants.toSql(moment)), moment);
    });
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/database/app_database_test.dart`
Expected: compilation fails: `package:yuuna/database.dart` does not exist.

- [ ] **Step 3: Write `build.yaml`**

```yaml
targets:
  $default:
    builders:
      drift_dev:
        options:
          # Queries in .drift files get named parameters, so call sites read
          # as headingsByReadings(readings: ..., limit: ...).
          named_parameters: true
```

- [ ] **Step 4: Write `lib/src/database/converters.dart`**

```dart
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:yuuna/utils.dart';

/// Stores a list of strings as a JSON array.
class StringListConverter extends TypeConverter<List<String>, String> {
  /// Create the converter.
  const StringListConverter();

  @override
  List<String> fromSql(String fromDb) =>
      List<String>.from(jsonDecode(fromDb) as List<dynamic>);

  @override
  String toSql(List<String> value) => jsonEncode(value);
}

/// Stores a list of optional strings as a JSON array.
class NullableStringListConverter
    extends TypeConverter<List<String?>, String> {
  /// Create the converter.
  const NullableStringListConverter();

  @override
  List<String?> fromSql(String fromDb) =>
      List<String?>.from(jsonDecode(fromDb) as List<dynamic>);

  @override
  String toSql(List<String?> value) => jsonEncode(value);
}

/// Stores a profile's quick actions, slot to action key, as JSON.
class QuickActionsColumnConverter
    extends TypeConverter<Map<int, String>, String> {
  /// Create the converter.
  const QuickActionsColumnConverter();

  @override
  Map<int, String> fromSql(String fromDb) =>
      QuickActionsConverter.fromIsar(fromDb);

  @override
  String toSql(Map<int, String> value) => QuickActionsConverter.toIsar(value);
}

/// Stores a profile's enhancements, field to slot to enhancement key, as JSON.
class EnhancementsColumnConverter
    extends TypeConverter<Map<String, Map<int, String>>, String> {
  /// Create the converter.
  const EnhancementsColumnConverter();

  @override
  Map<String, Map<int, String>> fromSql(String fromDb) =>
      EnhancementsConverter.fromIsar(fromDb);

  @override
  String toSql(Map<String, Map<int, String>> value) =>
      EnhancementsConverter.toIsar(value);
}

/// Stores an instant as microseconds since the epoch, so that instants within
/// the same second keep their order. Drift's own `dateTime()` keeps seconds.
class MicrosecondsConverter extends TypeConverter<DateTime, int> {
  /// Create the converter.
  const MicrosecondsConverter();

  @override
  DateTime fromSql(int fromDb) => DateTime.fromMicrosecondsSinceEpoch(fromDb);

  @override
  int toSql(DateTime value) => value.microsecondsSinceEpoch;
}
```

- [ ] **Step 5: Write `lib/src/database/tables.dart`**

```dart
import 'package:drift/drift.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';

/// Imported dictionaries.
@UseRowClass(Dictionary)
class Dictionaries extends Table {
  @override
  String get tableName => 'dictionary';

  /// Never reused, so a new dictionary cannot inherit an old one's resource
  /// directory.
  IntColumn get id => integer().autoIncrement()();

  /// Title of the dictionary, read from its archive.
  TextColumn get name => text().unique()();

  /// `uniqueKey` of the dictionary format that imported it.
  TextColumn get formatKey => text()();

  /// Position in the user's dictionary list.
  IntColumn get order => integer().unique()();

  /// Whether its results are hidden.
  BoolColumn get isHidden => boolean().withDefault(const Constant(false))();

  /// Whether its entries show folded.
  BoolColumn get isCollapsed => boolean().withDefault(const Constant(false))();
}

/// Words: a term and its reading, shared by every dictionary that has
/// something to say about them.
@DataClassName('HeadingRow')
@TableIndex(name: 'heading_reading', columns: {#reading})
class Headings extends Table {
  @override
  String get tableName => 'heading';

  /// Assigned by SQLite on insert.
  IntColumn get id => integer()();

  /// The word as written.
  TextColumn get term => text()();

  /// The word's reading, empty for kanji entries and words given no reading.
  TextColumn get reading => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {term, reading},
      ];
}

/// One dictionary's definitions of a heading.
@DataClassName('EntryRow')
@TableIndex(name: 'entry_heading_id', columns: {#headingId})
@TableIndex(name: 'entry_dictionary_id', columns: {#dictionaryId})
class Entries extends Table {
  @override
  String get tableName => 'entry';

  /// Assigned by SQLite on insert.
  IntColumn get id => integer()();

  /// The word defined.
  IntColumn get headingId => integer().references(Headings, #id)();

  /// The dictionary giving the definitions.
  IntColumn get dictionaryId => integer()
      .references(Dictionaries, #id, onDelete: KeyAction.cascade)();

  /// The definitions: plain text, or a structured content JSON document.
  TextColumn get definitions => text().map(const StringListConverter())();

  /// The dictionary's popularity score for this entry; higher is commoner.
  RealColumn get popularity => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Pitch accents of headings.
@DataClassName('PitchRow')
@TableIndex(name: 'pitch_heading_id', columns: {#headingId})
@TableIndex(name: 'pitch_dictionary_id', columns: {#dictionaryId})
class Pitches extends Table {
  @override
  String get tableName => 'pitch';

  /// Assigned by SQLite on insert.
  IntColumn get id => integer()();

  /// The word.
  IntColumn get headingId => integer().references(Headings, #id)();

  /// The pitch dictionary it comes from.
  IntColumn get dictionaryId => integer()
      .references(Dictionaries, #id, onDelete: KeyAction.cascade)();

  /// The mora after which the pitch drops; 0 for a flat pattern.
  IntColumn get downstep => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Frequency ranks of headings.
@DataClassName('FrequencyRow')
@TableIndex(name: 'frequency_heading_id', columns: {#headingId})
@TableIndex(name: 'frequency_dictionary_id', columns: {#dictionaryId})
class Frequencies extends Table {
  @override
  String get tableName => 'frequency';

  /// Assigned by SQLite on insert.
  IntColumn get id => integer()();

  /// The word.
  IntColumn get headingId => integer().references(Headings, #id)();

  /// The frequency dictionary it comes from.
  IntColumn get dictionaryId => integer()
      .references(Dictionaries, #id, onDelete: KeyAction.cascade)();

  /// The rank, for sorting; lower is more frequent.
  RealColumn get value => real()();

  /// The rank as the dictionary displays it.
  TextColumn get displayValue => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Labels a dictionary defines, attached to its entries and headings.
@DataClassName('TagRow')
class Tags extends Table {
  @override
  String get tableName => 'tag';

  /// Assigned by SQLite on insert.
  IntColumn get id => integer()();

  /// The dictionary defining the tag.
  IntColumn get dictionaryId => integer()
      .references(Dictionaries, #id, onDelete: KeyAction.cascade)();

  /// The short label, such as `v1` or `P`.
  TextColumn get name => text()();

  /// The kind of tag; picks its colour.
  TextColumn get category => text()();

  /// Display order among tags.
  IntColumn get sortingOrder => integer()();

  /// What the label means.
  TextColumn get notes => text()();

  /// The dictionary's score for the tag.
  RealColumn get popularity => real()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {dictionaryId, name},
      ];
}

/// Tags on a heading as a whole.
@DataClassName('HeadingTagRow')
@TableIndex(name: 'heading_tag_tag_id', columns: {#tagId})
class HeadingTags extends Table {
  @override
  String get tableName => 'heading_tag';

  /// The heading tagged.
  IntColumn get headingId =>
      integer().references(Headings, #id, onDelete: KeyAction.cascade)();

  /// The tag.
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {headingId, tagId};
}

/// Tags on one dictionary's entry.
@DataClassName('EntryTagRow')
@TableIndex(name: 'entry_tag_tag_id', columns: {#tagId})
class EntryTags extends Table {
  @override
  String get tableName => 'entry_tag';

  /// The entry tagged.
  IntColumn get entryId =>
      integer().references(Entries, #id, onDelete: KeyAction.cascade)();

  /// The tag.
  IntColumn get tagId =>
      integer().references(Tags, #id, onDelete: KeyAction.cascade)();

  @override
  Set<Column<Object>> get primaryKey => {entryId, tagId};
}

/// Books in the Novels library and volumes in the mokuro history.
@DataClassName('MediaItemRow')
class MediaItems extends Table {
  @override
  String get tableName => 'media_item';

  /// Kept across saves: the stash refers to it.
  IntColumn get id => integer().autoIncrement()();

  /// The media source owning the item.
  TextColumn get mediaSourceIdentifier => text()();

  /// The item within its source.
  TextColumn get mediaIdentifier => text()();

  /// Display title.
  TextColumn get title => text()();

  /// Cover image.
  TextColumn get imageUrl => text().nullable()();

  /// Source-specific state.
  TextColumn get sourceMetadata => text().nullable()();

  /// Progress, in the source's units.
  IntColumn get position => integer()();

  /// Length, in the source's units.
  IntColumn get duration => integer()();

  /// Whether the user may delete the item.
  BoolColumn get canDelete => boolean()();

  /// Whether the user may override its title and cover.
  BoolColumn get canEdit => boolean()();

  /// When the item was last opened; orders the libraries.
  IntColumn get lastOpenedAt =>
      integer().map(const MicrosecondsConverter())();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {mediaSourceIdentifier, mediaIdentifier},
      ];
}

/// Words saved from books.
@DataClassName('StashItemRow')
class StashItems extends Table {
  @override
  String get tableName => 'stash_item';

  /// Assigned on insert.
  IntColumn get id => integer().autoIncrement()();

  /// The book the word was saved from.
  IntColumn get mediaItemId =>
      integer().references(MediaItems, #id, onDelete: KeyAction.cascade)();

  /// The word as written.
  TextColumn get term => text()();

  /// The word's reading.
  TextColumn get reading => text()();

  /// The dictionary of the entry picked when saving, if one was.
  TextColumn get dictionaryName => text().nullable()();

  /// The definitions shown when saving.
  TextColumn get definitions => text().map(const StringListConverter())();

  /// The sentence the word was found in.
  TextColumn get sentence => text()();

  /// Where the word starts in [sentence].
  IntColumn get wordStart => integer()();

  /// How long the word is in [sentence].
  IntColumn get wordLength => integer()();

  /// Where the word is in the book, in ttu bookmark units.
  IntColumn get position => integer()();

  /// When the word was saved.
  DateTimeColumn get dateAdded => dateTime()();

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
        {mediaItemId, term, reading},
      ];
}

/// Card creation profiles.
@DataClassName('AnkiMappingRow')
class AnkiMappings extends Table {
  @override
  String get tableName => 'anki_mapping';

  /// Assigned on insert.
  IntColumn get id => integer().autoIncrement()();

  /// The profile name.
  TextColumn get label => text().unique()();

  /// The AnkiDroid note type exported to.
  TextColumn get model => text()();

  /// Position in the profile list.
  IntColumn get order => integer().unique()();

  /// Creator field keys, in note field order; null for an empty note field.
  TextColumn get exportFieldKeys =>
      text().map(const NullableStringListConverter())();

  /// Creator fields shown.
  TextColumn get creatorFieldKeys =>
      text().map(const StringListConverter())();

  /// Creator fields shown folded.
  TextColumn get creatorCollapsedFieldKeys =>
      text().map(const StringListConverter())();

  /// Tags added to every exported card.
  TextColumn get tags => text().map(const StringListConverter())();

  /// Quick actions on dictionary results, slot to action key.
  TextColumn get actions => text().map(const QuickActionsColumnConverter())();

  /// Enhancements per field, slot to enhancement key.
  TextColumn get enhancements =>
      text().map(const EnhancementsColumnConverter())();

  /// Whether exported media get Anki tags rather than bare file names.
  BoolColumn get exportMediaTags => boolean().nullable()();

  /// Whether line breaks are exported as `<br>`.
  BoolColumn get useBrTags => boolean().nullable()();

  /// Whether meanings are prefixed with their dictionary's name.
  BoolColumn get prependDictionaryNames => boolean().nullable()();
}

/// Saved mokuro catalogs.
@DataClassName('MokuroCatalogRow')
class MokuroCatalogs extends Table {
  @override
  String get tableName => 'mokuro_catalog';

  /// Assigned on insert.
  IntColumn get id => integer().autoIncrement()();

  /// Display name.
  TextColumn get name => text()();

  /// Where the catalog is.
  TextColumn get url => text().unique()();

  /// Position in the catalog list.
  IntColumn get order => integer().unique()();
}

/// Search terms typed in the dictionary search bar. Ids give recency.
@DataClassName('SearchHistoryRow')
class SearchHistoryItems extends Table {
  @override
  String get tableName => 'search_history_item';

  /// Assigned on insert; never reused, so it orders by recency.
  IntColumn get id => integer().autoIncrement()();

  /// The term searched.
  TextColumn get searchTerm => text().unique()();
}

/// Search terms whose results are shown on the Dictionary tab. Ids give
/// recency.
@DataClassName('DictionaryHistoryRow')
class DictionaryHistoryItems extends Table {
  @override
  String get tableName => 'dictionary_history';

  /// Assigned on insert; never reused, so it orders by recency.
  IntColumn get id => integer().autoIncrement()();

  /// The term searched.
  TextColumn get searchTerm => text().unique()();
}
```

`[sentence]` in the `StashItems` docs refers to a getter of the same class, so `comment_references` is satisfied.

- [ ] **Step 6: Write `lib/src/database/app_database.dart`**

```dart
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/sqlite3.dart' show Database, sqlite3;
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';

part 'app_database.g.dart';

/// Name of the database file, in the app support directory.
const String databaseFileName = 'yomimoto.sqlite';

/// The app's SQLite database: dictionaries, libraries, stashes, profiles,
/// catalogs and histories. Schema version 1 is the 1.0 baseline; every later
/// version comes with a migration and a schema snapshot.
@DriftDatabase(
  tables: [
    Dictionaries,
    Headings,
    Entries,
    Pitches,
    Frequencies,
    Tags,
    HeadingTags,
    EntryTags,
    MediaItems,
    StashItems,
    AnkiMappings,
    MokuroCatalogs,
    SearchHistoryItems,
    DictionaryHistoryItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  /// Open the database over [executor]. Tests pass in-memory executors.
  AppDatabase(super.executor);

  /// Open the database over [raw], a connection prepared by
  /// [configureConnection]. Drift runs on that very connection, so [raw] can
  /// also serve synchronous reads. Closing the database closes [raw].
  AppDatabase.fromRaw(Database raw) : super(NativeDatabase.opened(raw));

  /// Open the database file at [path] on a connection of its own, as the
  /// isolates do.
  factory AppDatabase.open(String path) =>
      AppDatabase.fromRaw(openRawDatabase(path));

  @override
  int get schemaVersion => 1;
}

/// Apply the settings every connection needs: foreign keys, WAL, a busy
/// timeout, and incremental vacuum. `auto_vacuum` only takes effect while the
/// database has no tables, so it sticks from the first open.
void configureConnection(Database database) {
  database
    ..execute('PRAGMA auto_vacuum = INCREMENTAL')
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA foreign_keys = ON')
    ..execute('PRAGMA busy_timeout = 10000');
}

/// Open the database file at [path] on a new raw connection, prepared by
/// [configureConnection].
Database openRawDatabase(String path) {
  Database database = sqlite3.open(path);
  configureConnection(database);
  return database;
}
```

- [ ] **Step 7: Write the barrel `lib/database.dart`**

```dart
export 'src/database/app_database.dart';
export 'src/database/converters.dart';
export 'src/database/tables.dart';
```

- [ ] **Step 8: Generate and run the tests**

```sh
dart run build_runner build --delete-conflicting-outputs
flutter test test/database/app_database_test.dart
```

Expected: `lib/src/database/app_database.g.dart` appears; all tests pass. If `build_runner` reports that `Dictionary`'s constructor does not match the table, compare the constructor in `lib/src/dictionary/dictionary.dart` with the columns above: every column needs a constructor parameter of the same name.

- [ ] **Step 9: Dump the schema and generate the schema test helpers**

```sh
mkdir -p drift_schemas test/database/generated
dart run drift_dev schema dump lib/src/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/database/generated/
```

Expected: `drift_schemas/drift_schema_v1.json`, `test/database/generated/schema.dart` and `test/database/generated/schema_v1.dart`.

Add to `analysis_options.yaml` under `analyzer: exclude:`, after `'**/generated_plugin_registrant.dart'`:

```yaml
    # Drift's schema test helpers, generated by drift_dev schema generate.
    - 'test/database/generated/**'
```

- [ ] **Step 10: Write the schema test `test/database/schema_test.dart`**

```dart
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/database.dart';

import 'generated/schema.dart';

void main() {
  test('the database the app creates matches the version 1 snapshot',
      () async {
    SchemaVerifier verifier = SchemaVerifier(GeneratedHelper());
    AppDatabase db = AppDatabase(await verifier.startAt(1));
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 1);
  });
}
```

Run: `flutter test test/database/schema_test.dart`
Expected: PASS.

- [ ] **Step 11: Open the database at startup**

In `lib/src/models/app_model.dart`:

Add imports, keeping the import block alphabetical within its groups:

```dart
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';
```

After the `_database` field (`late final Isar _database;`) add:

```dart
  /// The SQLite database. See [initialise].
  late final AppDatabase _db;
```

After the `databaseDirectory` getter and its field, add:

```dart
  /// Path of the SQLite database file.
  String get databasePath =>
      path.join(_databaseDirectory.path, databaseFileName);
```

In `initialise()`, immediately before the `/// Initialise persistent database.` comment that opens Isar, add:

```dart
    /// Open the SQLite database. The first query creates the schema on a
    /// fresh install, before anything reads it.
    Database raw = openRawDatabase(databasePath);
    _db = AppDatabase.fromRaw(raw);
    await _db.customSelect('SELECT 1').get();
```

In `shutdown()`, after `await _database.close();` add `await _db.close();`.

- [ ] **Step 12: Check generated files in CI**

In `.github/workflows/main.yml`, replace the `Check generated files` step's `run` block with:

```yaml
        run: |
          dart run build_runner build --delete-conflicting-outputs
          dart run slang
          dart run drift_dev schema dump lib/src/database/app_database.dart drift_schemas/
          dart run drift_dev schema generate drift_schemas/ test/database/generated/
          git diff --exit-code
```

- [ ] **Step 13: Full verification**

```sh
flutter analyze
flutter test
flutter build apk --debug
```

Expected: no issues; all tests pass; the APK builds.

- [ ] **Step 14: Commit**

```sh
jj status
jj commit -m "Add the Drift database and its schema

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: Media items and stash on Drift

**Files:**
- Create: `lib/src/database/app_store.dart`, `test/database/app_store_test.dart`
- Modify: `lib/database.dart`, `lib/src/database/tables.dart`, `lib/src/database/app_database.dart`
- Modify: `lib/src/media/media_item.dart` (+ regenerated `.g.dart`), `lib/src/media/stash_item.dart` (delete `stash_item.g.dart`), `lib/src/media/media_source.dart`, `lib/src/pages/implementations/media_item_dialog_page.dart`
- Modify: `lib/src/models/app_model.dart`, `lib/src/media/sources/reader_ttu_source.dart`, `lib/src/pages/implementations/mokuro_catalog_browse_page.dart`, `lib/src/creator/actions/add_to_stash_action.dart`, `lib/src/pages/implementations/stash_page.dart`, `lib/src/pages/implementations/stash_item_page.dart`
- Modify: `test/media/stash_item_test.dart`

**Interfaces:**
- Consumes: `AppDatabase`, `MediaItems`, `StashItems`, `openTestDatabase`, `countRows` (Task 2).
- Produces: `class AppStore { AppStore({required AppDatabase db, required Database raw}); }` with `List<MediaItem> mediaItems(String mediaSourceIdentifier)`, `Future<void> putMediaItem(MediaItem)`, `Future<void> addMediaItem(MediaItem, {required int maximum})`, `Future<void> updateMediaItem(MediaItem)`, `Future<void> deleteMediaItem(MediaItem)`, `List<StashItem> stashItems(int mediaItemId)`, `Future<bool> putStashItem(StashItem)`, `Future<void> deleteStashItems(List<int>)`, and the private helper `List<T> _select<T>(T Function(Map<String, dynamic>) map, String sql, [List<Object?> parameters])` later tasks extend. `MediaItem.lastOpenedAt` (`DateTime?`); `StashItem.mediaItemId` (`int`). `AppModel` media and stash methods become `Future`s.

- [ ] **Step 1: Write the failing tests `test/database/app_store_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/media.dart';

import 'test_database.dart';

MediaItem _book(
  String identifier, {
  String title = 'Book',
  String source = 'reader_ttu',
}) {
  return MediaItem(
    mediaIdentifier: identifier,
    title: title,
    mediaSourceIdentifier: source,
    position: 0,
    duration: 1,
    canDelete: false,
    canEdit: true,
  );
}

StashItem _stash(int mediaItemId, {String term = '漢字', int position = 10}) {
  return StashItem(
    mediaItemId: mediaItemId,
    term: term,
    reading: 'かんじ',
    dictionaryName: 'JMdict',
    definitions: ['kanji'],
    sentence: '漢字を書く。',
    wordStart: 0,
    wordLength: 2,
    position: position,
    dateAdded: DateTime(2026, 10, 14),
  );
}

void main() {
  late TestDatabase database;
  late AppStore store;

  setUp(() async {
    database = await openTestDatabase();
    store = AppStore(db: database.db, raw: database.raw);
  });

  tearDown(() => database.db.close());

  group('media items', () {
    test('putMediaItem inserts the item and sets its id', () async {
      MediaItem book = _book('b.html?id=1');
      await store.putMediaItem(book);

      expect(book.id, isNotNull);
      expect(book.lastOpenedAt, isNotNull);
      expect(store.mediaItems('reader_ttu').single.mediaIdentifier,
          'b.html?id=1');
    });

    test('putMediaItem on a known item keeps its id and makes it the newest',
        () async {
      MediaItem first = _book('b.html?id=1');
      await store.putMediaItem(first);
      await store.putMediaItem(_book('b.html?id=2', title: 'Other'));

      MediaItem again = _book('b.html?id=1', title: 'Renamed');
      await store.putMediaItem(again);

      expect(again.id, first.id);
      expect(store.mediaItems('reader_ttu').map((item) => item.title),
          ['Other', 'Renamed']);
    });

    test('concurrent puts of the same item leave one row', () async {
      await Future.wait([
        store.putMediaItem(_book('b.html?id=1')),
        store.putMediaItem(_book('b.html?id=1')),
      ]);

      expect(store.mediaItems('reader_ttu'), hasLength(1));
    });

    test('addMediaItem keeps the most recent items of its source only',
        () async {
      await store.putMediaItem(_book('other', source: 'reader_mokuro'));
      for (int i = 0; i < 5; i++) {
        await store.addMediaItem(_book('m$i'), maximum: 3);
      }

      expect(store.mediaItems('reader_ttu').map((item) => item.mediaIdentifier),
          ['m2', 'm3', 'm4']);
      expect(store.mediaItems('reader_mokuro'), hasLength(1));
    });

    test('updateMediaItem saves the position without reordering', () async {
      MediaItem first = _book('a');
      await store.putMediaItem(first);
      await store.putMediaItem(_book('b'));

      first.position = 42;
      await store.updateMediaItem(first);

      List<MediaItem> items = store.mediaItems('reader_ttu');
      expect(items.map((item) => item.mediaIdentifier), ['a', 'b']);
      expect(items.first.position, 42);
    });

    test('deleting a media item deletes its stash', () async {
      MediaItem book = _book('b.html?id=1');
      await store.putMediaItem(book);
      await store.putStashItem(_stash(book.id!));

      await store.deleteMediaItem(book);

      expect(store.mediaItems('reader_ttu'), isEmpty);
      expect(countRows(database.raw, 'stash_item'), 0);
    });
  });

  group('stash', () {
    late MediaItem book;

    setUp(() async {
      book = _book('b.html?id=1');
      await store.putMediaItem(book);
    });

    test('putStashItem refuses a word the book already has', () async {
      expect(await store.putStashItem(_stash(book.id!)), isTrue);
      expect(await store.putStashItem(_stash(book.id!, position: 99)), isFalse);
      expect(store.stashItems(book.id!), hasLength(1));
    });

    test('stashItems come in reading order', () async {
      await store.putStashItem(_stash(book.id!, term: '後', position: 20));
      await store.putStashItem(_stash(book.id!, term: '前', position: 5));

      expect(store.stashItems(book.id!).map((item) => item.term), ['前', '後']);
    });

    test('deleteStashItems deletes those items', () async {
      StashItem kept = _stash(book.id!, term: '残');
      StashItem gone = _stash(book.id!, term: '消');
      await store.putStashItem(kept);
      await store.putStashItem(gone);

      await store.deleteStashItems([gone.id!]);

      expect(store.stashItems(book.id!).map((item) => item.term), ['残']);
    });
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/database/app_store_test.dart`
Expected: compilation fails (`AppStore` undefined; `StashItem` has no `mediaItemId`).

- [ ] **Step 3: Rewrite `lib/src/media/media_item.dart`**

Replace the whole file with:

```dart
import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:yuuna/media.dart';
import 'package:yuuna/models.dart';
part 'media_item.g.dart';

/// An item representable in media history from which a media source may
/// start playback with. This entity does not have any progress information,
/// such as duration or number of chapters and individual progress of those
/// items. That extra information is handled as extra arguments used alongside
/// the [MediaItem], and not included within it. This design is done to reduce
/// the number and complexity of CRUD operations, as including all data in this
/// entity is impractical to include when persisting a progress update.
@JsonSerializable()
class MediaItem {
  /// Initialise a media item with certain details.
  MediaItem({
    required this.mediaIdentifier,
    required this.title,
    required this.mediaSourceIdentifier,
    required this.position,
    required this.duration,
    required this.canDelete,
    required this.canEdit,
    this.id,
    this.imageUrl,
    this.sourceMetadata,
    this.lastOpenedAt,
  });

  /// Create an instance of this class from a serialized format.
  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      _$MediaItemFromJson(json);

  /// Convert this into a serialized format.
  Map<String, dynamic> toJson() => _$MediaItemToJson(this);

  /// A unique identifier for the purposes of database storage. Null until
  /// the item is saved.
  int? id;

  /// Identifies the item across sources: its source and media identifier.
  String get uniqueKey => '$mediaSourceIdentifier/$mediaIdentifier';

  /// The media identifier of this item. Using this variable alone, a media
  /// source must be able to functionally process how to display the media.
  /// If the same item exists in history, then the item is replaced with a
  /// newer item in the addition operation. This key is also used to identify
  /// resources such as thumbnails in the cache.
  String mediaIdentifier;

  /// The name of this item. Typically, this is the name of a book or a manga
  /// volume.
  String title;

  /// The media source, and so the home tab, where this item is from.
  String mediaSourceIdentifier;

  /// The preview image, if any.
  String? imageUrl;

  /// This field may be used to store additional details that the source may
  /// require to get more details on this item.
  String? sourceMetadata;

  /// The current progress of the media in the time this context was made.
  /// This could be the page number of a book or comic.
  int position;

  /// The media's full duration, used to be able to tell the completion of
  /// this media context relative to the position.
  int duration;

  /// Whether or not this [MediaItem] can be deleted.
  final bool canDelete;

  /// Whether or not this [MediaItem] allows overriding the display title and
  /// thumbnail.
  final bool canEdit;

  /// When the item was last opened, set when it is saved through
  /// `AppStore.putMediaItem` or `AppStore.addMediaItem`. Null until then.
  DateTime? lastOpenedAt;

  @override
  operator ==(Object other) =>
      other is MediaItem && other.uniqueKey == uniqueKey;

  @override
  int get hashCode => toJson().hashCode;

  @override
  String toString() {
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    return encoder.convert(this);
  }

  /// Get the [MediaSource] from a [MediaItem] from its serialised identifier.
  MediaSource getMediaSource({required AppModel appModel}) {
    return appModel.tabs[mediaSourceIdentifier]! as MediaSource;
  }

  /// Creates a deep copy of this mapping but with the given variables replaced
  /// with the new values.
  MediaItem copyWith({
    int? id,
    String? mediaIdentifier,
    String? title,
    String? mediaSourceIdentifier,
    String? imageUrl,
    String? sourceMetadata,
    int? position,
    int? duration,
    bool? canDelete,
    bool? canEdit,
    DateTime? lastOpenedAt,
  }) {
    return MediaItem(
      id: id ?? this.id,
      mediaIdentifier: mediaIdentifier ?? this.mediaIdentifier,
      title: title ?? this.title,
      mediaSourceIdentifier:
          mediaSourceIdentifier ?? this.mediaSourceIdentifier,
      imageUrl: imageUrl ?? this.imageUrl,
      sourceMetadata: sourceMetadata ?? this.sourceMetadata,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      canDelete: canDelete ?? this.canDelete,
      canEdit: canEdit ?? this.canEdit,
      lastOpenedAt: lastOpenedAt ?? this.lastOpenedAt,
    );
  }
}
```

- [ ] **Step 4: Rewrite `lib/src/media/stash_item.dart`**

Replace the whole file with:

```dart
import 'package:flutter/services.dart';
import 'package:yuuna/utils.dart';

/// A word saved from a book while reading, with the sentence it was found
/// in, so that a card can be made from it later.
class StashItem {
  /// Create a stash item for the book [mediaItemId].
  StashItem({
    required this.mediaItemId,
    required this.term,
    required this.reading,
    required this.dictionaryName,
    required this.definitions,
    required this.sentence,
    required this.wordStart,
    required this.wordLength,
    required this.position,
    required this.dateAdded,
    this.id,
  });

  /// Database id. Null until the item is saved.
  int? id;

  /// Database id of the book the word was saved from.
  int mediaItemId;

  /// The word as written.
  String term;

  /// The word's reading.
  String reading;

  /// The dictionary of the entry picked when saving; null when the whole
  /// heading was saved.
  String? dictionaryName;

  /// The definitions shown when saving, as plain text.
  List<String> definitions;

  /// The sentence the word was found in.
  String sentence;

  /// Where the word starts in [sentence].
  int wordStart;

  /// How long the word is in [sentence].
  int wordLength;

  /// Where the word is in the book, in ttu bookmark units.
  int position;

  /// When the word was saved.
  DateTime dateAdded;

  /// The word selected in its sentence.
  JidoujishoTextSelection getSelection() {
    return JidoujishoTextSelection(
      text: sentence,
      range: TextRange(start: wordStart, end: wordStart + wordLength),
    );
  }
}
```

Delete the Isar part file:

```sh
rm -f lib/src/media/stash_item.g.dart
```

- [ ] **Step 5: Update `test/media/stash_item_test.dart`**

In `_item`, replace the two lines

```dart
    mediaSourceIdentifier: 'reader_ttu',
    mediaIdentifier: 'b.html?id=3',
```

with `    mediaItemId: 3,`. Delete the test `'is keyed by source, book, term and reading'` (the key moved into the database as a unique constraint, covered by `app_store_test.dart`).

- [ ] **Step 6: Switch the two tables to the model classes**

In `lib/src/database/tables.dart`, replace `@DataClassName('MediaItemRow')` with `@UseRowClass(MediaItem)` and `@DataClassName('StashItemRow')` with `@UseRowClass(StashItem)`, and add `import 'package:yuuna/media.dart';` to its imports. In `lib/src/database/app_database.dart`, add `import 'package:yuuna/media.dart';` (the generated part maps rows into these classes).

- [ ] **Step 7: Write `lib/src/database/app_store.dart`**

```dart
import 'package:drift/drift.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';
import 'package:yuuna/media.dart';

/// The app's own data over one connection: the libraries and their stashes,
/// and in later additions the profiles, catalogs, histories and dictionary
/// list. Reads are synchronous, through [raw], so widgets can call them while
/// building; writes go through [db], which runs on that same connection.
class AppStore {
  /// Wrap [db] and [raw], the connection it runs on.
  AppStore({required this.db, required this.raw});

  /// The Drift database, for writes.
  final AppDatabase db;

  /// The connection [db] runs on, for synchronous reads only.
  final Database raw;

  /// Run [sql] on [raw] and map each row with a Drift table's `map`, which
  /// decodes columns and applies type converters.
  List<T> _select<T>(
    T Function(Map<String, dynamic> row) map,
    String sql, [
    List<Object?> parameters = const [],
  ]) {
    return raw.select(sql, parameters).map(map).toList();
  }

  /// The items of the media source [mediaSourceIdentifier], least recently
  /// opened first.
  List<MediaItem> mediaItems(String mediaSourceIdentifier) {
    return _select(
      db.mediaItems.map,
      'SELECT * FROM media_item WHERE media_source_identifier = ? '
      'ORDER BY last_opened_at, id',
      [mediaSourceIdentifier],
    );
  }

  /// Insert [item], or update the item with the same source and identifier,
  /// marking it opened now. Sets the item's `id` and `lastOpenedAt`.
  Future<void> putMediaItem(MediaItem item) async {
    DateTime now = DateTime.now();
    item.lastOpenedAt = now;
    MediaItemsCompanion companion = MediaItemsCompanion.insert(
      mediaSourceIdentifier: item.mediaSourceIdentifier,
      mediaIdentifier: item.mediaIdentifier,
      title: item.title,
      imageUrl: Value(item.imageUrl),
      sourceMetadata: Value(item.sourceMetadata),
      position: item.position,
      duration: item.duration,
      canDelete: item.canDelete,
      canEdit: item.canEdit,
      lastOpenedAt: now,
    );

    MediaItem row = await db.into(db.mediaItems).insertReturning(
          companion,
          onConflict: DoUpdate(
            (_) => companion,
            target: [
              db.mediaItems.mediaSourceIdentifier,
              db.mediaItems.mediaIdentifier,
            ],
          ),
        );
    item.id = row.id;
  }

  /// [putMediaItem], then forget the least recently opened items of the
  /// same source beyond [maximum].
  Future<void> addMediaItem(MediaItem item, {required int maximum}) async {
    await db.transaction(() async {
      await putMediaItem(item);
      await db.customUpdate(
        'DELETE FROM media_item WHERE media_source_identifier = ?1 '
        'AND id NOT IN (SELECT id FROM media_item '
        'WHERE media_source_identifier = ?1 '
        'ORDER BY last_opened_at DESC, id DESC LIMIT ?2)',
        variables: [
          Variable.withString(item.mediaSourceIdentifier),
          Variable.withInt(maximum),
        ],
        updates: {db.mediaItems},
        updateKind: UpdateKind.delete,
      );
    });
  }

  /// Save [item]'s title, cover, metadata and progress, leaving its recency
  /// alone. Does nothing for an item that was never saved.
  Future<void> updateMediaItem(MediaItem item) async {
    int? id = item.id;
    if (id == null) {
      return;
    }

    await (db.update(db.mediaItems)..where((table) => table.id.equals(id)))
        .write(
      MediaItemsCompanion(
        title: Value(item.title),
        imageUrl: Value(item.imageUrl),
        sourceMetadata: Value(item.sourceMetadata),
        position: Value(item.position),
        duration: Value(item.duration),
      ),
    );
  }

  /// Delete [item], and with it its stash.
  Future<void> deleteMediaItem(MediaItem item) async {
    await (db.delete(db.mediaItems)..where((table) => table.id.equals(item.id!)))
        .go();
  }

  /// The stash of the media item [mediaItemId], in reading order.
  List<StashItem> stashItems(int mediaItemId) {
    return _select(
      db.stashItems.map,
      'SELECT * FROM stash_item WHERE media_item_id = ? ORDER BY position, id',
      [mediaItemId],
    );
  }

  /// Save [item] and set its `id`. Returns false, saving nothing, when its
  /// book already has this word.
  Future<bool> putStashItem(StashItem item) async {
    StashItem? row = await db.into(db.stashItems).insertReturningOrNull(
          StashItemsCompanion.insert(
            mediaItemId: item.mediaItemId,
            term: item.term,
            reading: item.reading,
            dictionaryName: Value(item.dictionaryName),
            definitions: item.definitions,
            sentence: item.sentence,
            wordStart: item.wordStart,
            wordLength: item.wordLength,
            position: item.position,
            dateAdded: item.dateAdded,
          ),
          mode: InsertMode.insertOrIgnore,
        );
    if (row == null) {
      return false;
    }

    item.id = row.id;
    return true;
  }

  /// Delete the stash items with these [ids].
  Future<void> deleteStashItems(List<int> ids) async {
    await (db.delete(db.stashItems)..where((table) => table.id.isIn(ids)))
        .go();
  }
}
```

Add `export 'src/database/app_store.dart';` to `lib/database.dart` (keep the exports alphabetical).

- [ ] **Step 8: Regenerate and run the store tests**

```sh
dart run build_runner build --delete-conflicting-outputs
flutter test test/database/app_store_test.dart test/media/stash_item_test.dart
```

Expected: PASS. (The rest of the app does not compile yet; the next steps fix it.)

- [ ] **Step 9: Remove the dead media item fields' readers**

In `lib/src/media/media_source.dart`, in `getDisplayThumbnailFromMediaItem`, replace everything from `if (item.base64Image == null) {` to the end of the method body (the `if`/`UriData`/`if (data != null)` blocks) with:

```dart
    return MemoryImage(kTransparentImage);
```

In `lib/src/pages/implementations/media_item_dialog_page.dart`, replace the `imageErrorBuilder` closure that tests `widget.item.extraUrl` with:

```dart
              imageErrorBuilder: (_, _, _) => const SizedBox.expand(),
```

If `flutter analyze` later reports `CacheImageProvider` or another import as unused because of these deletions, remove only the import that became unused.

- [ ] **Step 10: Wire `AppModel` to the store**

In `lib/src/models/app_model.dart`:

1. Remove `MediaItemSchema` and `StashItemSchema` from `globalSchemas`.
2. After the `_db` field add:

```dart
  /// Synchronous reads and Drift writes over [_db]. See [initialise].
  late final AppStore _store;
```

3. In `initialise()`, after `await _db.customSelect('SELECT 1').get();` add `_store = AppStore(db: _db, raw: raw);`.
4. Replace `putMediaItem`, `addMediaItem`, `updateMediaItem`, `deleteMediaItem`, `putStashItem`, `getStashItems`, `deleteStashItems`, `deleteStashForMedia` and `getMediaSourceHistory` with:

```dart
  /// Insert or replace [item] as the most recent entry of its source's
  /// history, without the history size limit of [addMediaItem]. For
  /// sources whose history is a library that must not lose entries. Sets
  /// the item's id.
  Future<void> putMediaItem(MediaItem item) => _store.putMediaItem(item);

  /// Add a [MediaItem] to history. This should be called at startup
  /// when the media item is launched.
  Future<void> addMediaItem(MediaItem item) =>
      _store.addMediaItem(item, maximum: maximumMediaHistoryItems);

  /// Update a media item, without performing any deletion or mutation
  /// operations. This is useful when updating constantly, for example,
  /// when a reading position needs to be persisted as the user reads.
  Future<void> updateMediaItem(MediaItem item) => _store.updateMediaItem(item);

  /// Deletes a [MediaItem] from history, with its stash, and also rids of
  /// override values.
  Future<void> deleteMediaItem(MediaItem item) async {
    MediaSource mediaSource = item.getMediaSource(appModel: this);
    await mediaSource.clearOverrideValues(appModel: this, item: item);
    await mediaSource.onMediaItemClear(item);

    await _store.deleteMediaItem(item);
  }

  /// Save [item] to its book's stash. Returns false, saving nothing, if the
  /// book already has this word.
  Future<bool> putStashItem(StashItem item) => _store.putStashItem(item);

  /// The stash of [mediaItem], in reading order.
  List<StashItem> getStashItems(MediaItem mediaItem) =>
      _store.stashItems(mediaItem.id!);

  /// Delete the stash items with these [ids].
  Future<void> deleteStashItems(List<int> ids) => _store.deleteStashItems(ids);
```

and

```dart
  /// Get the history of [MediaItem] for a particular [MediaSource], least
  /// recently opened first.
  List<MediaItem> getMediaSourceHistory({required MediaSource mediaSource}) {
    return _store.mediaItems(mediaSource.uniqueKey);
  }
```

5. In `openMedia`, change `addMediaItem(item);` to `await addMediaItem(item);`.

The old `addMediaItem` trimmed by `maximumSearchHistoryItems` (60) instead of `maximumMediaHistoryItems` (100); the store's `maximum` fixes that.

- [ ] **Step 11: Update the callers**

- `lib/src/media/sources/reader_ttu_source.dart`: in `syncLibrary`, change `appModel.putMediaItem(` to `await appModel.putMediaItem(`, and delete the line `appModel.deleteStashForMedia(entry.value);` (deleting the media item cascades to its stash).
- `lib/src/pages/implementations/mokuro_catalog_browse_page.dart`: change both `appModel.addMediaItem(...)` calls to `await appModel.addMediaItem(...)`, and both `appModel.updateMediaItem(_mediaItem!);` calls to `await appModel.updateMediaItem(_mediaItem!);`. All four are already inside `async` functions. Awaiting the add matters: the page's later `updateMediaItem` needs the id it sets.
- `lib/src/creator/actions/add_to_stash_action.dart`: replace the guard and the `putStashItem` call:

```dart
    MediaItem? mediaItem = appModel.getCurrentMediaItem();
    MediaSource? mediaSource = mediaItem?.getMediaSource(appModel: appModel);
    int? mediaItemId = mediaItem?.id;
    if (mediaItem == null ||
        mediaItemId == null ||
        mediaSource == null ||
        mediaSource.currentPosition < 0) {
      showToast(t.stash_unavailable);
      return;
    }
```

and

```dart
    bool added = await appModel.putStashItem(
      StashItem(
        mediaItemId: mediaItemId,
        term: heading.term,
```

(remove the `mediaSourceIdentifier:` and `mediaIdentifier:` arguments; the remaining arguments stay as they are).
- `lib/src/pages/implementations/stash_page.dart`: change `appModelNoUpdate.deleteStashItems(_selected.toList());` to `await appModelNoUpdate.deleteStashItems(_selected.toList());` (the enclosing method is already `async`).
- `lib/src/pages/implementations/stash_item_page.dart`: in `_delete`, replace

```dart
    appModelNoUpdate.deleteStashItems([item.id!]);
    Navigator.pop(context);
```

with

```dart
    await appModelNoUpdate.deleteStashItems([item.id!]);
    if (mounted) {
      Navigator.pop(context);
    }
```

- `lib/src/pages/implementations/reader_ttu_source_page.dart`: leave `appModelNoUpdate.putMediaItem(item);` in `initState` un-awaited; it sets the item's id when it completes.

- [ ] **Step 12: Full verification**

```sh
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Expected: no issues; all tests pass. `jj status` shows `lib/src/media/stash_item.g.dart` deleted and `media_item.g.dart` regenerated without its Isar section.

- [ ] **Step 13: Commit**

```sh
jj status
jj commit -m "Move media items and the stash to Drift

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: Profiles, catalogs and search history on Drift

**Files:**
- Modify: `lib/src/creator/anki_mapping.dart` (+ regenerated `.g.dart`), `lib/src/utils/misc/mokuro_catalog.dart` (delete `mokuro_catalog.g.dart`)
- Delete: `lib/src/creator/search_history_item.dart`, `lib/src/creator/search_history_item.g.dart`; remove its export from `lib/creator.dart`
- Modify: `lib/src/database/tables.dart`, `lib/src/database/app_database.dart`, `lib/src/database/app_store.dart`, `test/database/app_store_test.dart`
- Modify: `lib/src/models/app_model.dart`, `lib/src/utils/components/jidoujisho_search_history.dart`, `lib/src/pages/implementations/home_dictionary_page.dart`, `recursive_dictionary_page.dart`, `profiles_dialog_page.dart`, `mokuro_catalog_manage_dialog_page.dart`

**Interfaces:**
- Consumes: `AppStore` and `_select` (Task 3).
- Produces on `AppStore`: `List<AnkiMapping> mappings()`, `AnkiMapping? mappingByLabel(String)`, `bool mappingLabelTaken(AnkiMapping)`, `int nextMappingOrder()`, `Future<void> putMapping(AnkiMapping)`, `Future<void> replaceMappings(List<AnkiMapping>)`, `Future<void> deleteMapping(int id)`; `List<MokuroCatalog> catalogs()`, `bool catalogUrlTaken(MokuroCatalog)`, `int nextCatalogOrder()`, `Future<void> putCatalog(MokuroCatalog)`, `Future<void> replaceCatalogs(List<MokuroCatalog>)`, `Future<void> deleteCatalog(int id)`; `List<String> searchHistory()`, `Future<void> addToSearchHistory(String, {required int maximum})`, `Future<void> removeFromSearchHistory(String)`, `Future<void> clearSearchHistory()`; the private helper `Future<void> _addRecentTerm(TableInfo<Table, dynamic> table, String searchTerm, int maximum)` that Task 8 reuses. `AppModel` search history methods lose their `historyKey` parameter.

- [ ] **Step 1: Write the failing tests**

Append to `test/database/app_store_test.dart`, inside `main()` after the `stash` group:

```dart
  group('profiles', () {
    AnkiMapping profile(String label, int order) =>
        AnkiMapping.defaultMapping(order: order).copyWith(label: label);

    test('putMapping round-trips every field and sets the id', () async {
      AnkiMapping standard = AnkiMapping.defaultMapping(order: 0);
      await store.putMapping(standard);

      AnkiMapping loaded = store.mappingByLabel(standard.label)!;
      expect(loaded.id, standard.id);
      expect(loaded.exportFieldKeys, standard.exportFieldKeys);
      expect(loaded.creatorFieldKeys, standard.creatorFieldKeys);
      expect(loaded.tags, standard.tags);
      expect(loaded.actions, standard.actions);
      expect(loaded.enhancements, standard.enhancements);
      expect(loaded.useBrTags, isTrue);
    });

    test('putMapping on a saved profile replaces it', () async {
      AnkiMapping mapping = profile('Mine', 0);
      await store.putMapping(mapping);
      mapping.creatorFieldKeys = ['term'];
      await store.putMapping(mapping);

      expect(store.mappings().single.creatorFieldKeys, ['term']);
    });

    test('replaceMappings swaps orders without a constraint error', () async {
      AnkiMapping a = profile('A', 0);
      AnkiMapping b = profile('B', 1);
      await store.putMapping(a);
      await store.putMapping(b);

      a.order = 1;
      b.order = 0;
      await store.replaceMappings([b, a]);

      expect(store.mappings().map((mapping) => mapping.label), ['B', 'A']);
    });

    test('nextMappingOrder and mappingLabelTaken', () async {
      expect(store.nextMappingOrder(), 0);
      await store.putMapping(profile('A', 0));
      expect(store.nextMappingOrder(), 1);
      expect(store.mappingLabelTaken(profile('A', 5)), isTrue);
      expect(store.mappingLabelTaken(profile('A', 0)), isFalse);
    });
  });

  group('catalogs', () {
    test('put, reorder and delete', () async {
      MokuroCatalog a = MokuroCatalog(name: 'A', url: 'https://a', order: 0);
      MokuroCatalog b = MokuroCatalog(name: 'B', url: 'https://b', order: 1);
      await store.putCatalog(a);
      await store.putCatalog(b);
      expect(store.catalogUrlTaken(
          MokuroCatalog(name: 'C', url: 'https://a', order: 7)), isTrue);
      expect(store.nextCatalogOrder(), 2);

      a.order = 1;
      b.order = 0;
      await store.replaceCatalogs([b, a]);
      expect(store.catalogs().map((catalog) => catalog.name), ['B', 'A']);

      await store.deleteCatalog(b.id!);
      expect(store.catalogs().map((catalog) => catalog.name), ['A']);
    });
  });

  group('search history', () {
    test('re-adding a term makes it the newest, and the oldest go', () async {
      await store.addToSearchHistory('一', maximum: 3);
      await store.addToSearchHistory('二', maximum: 3);
      await store.addToSearchHistory('三', maximum: 3);
      await store.addToSearchHistory('一', maximum: 3);
      await store.addToSearchHistory('四', maximum: 3);

      expect(store.searchHistory(), ['三', '一', '四']);
    });

    test('remove and clear', () async {
      await store.addToSearchHistory('一', maximum: 3);
      await store.addToSearchHistory('二', maximum: 3);
      await store.removeFromSearchHistory('一');
      expect(store.searchHistory(), ['二']);

      await store.clearSearchHistory();
      expect(store.searchHistory(), isEmpty);
    });
  });
```

Add `import 'package:yuuna/creator.dart';` and `import 'package:yuuna/utils.dart';` to the test's imports.

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/database/app_store_test.dart`
Expected: compilation fails (`putMapping` and the other methods are undefined).

- [ ] **Step 3: Strip Isar from `AnkiMapping` and `MokuroCatalog`; delete `SearchHistoryItem`**

`lib/src/creator/anki_mapping.dart`:
- delete `import 'package:isar_community/isar.dart';` and the `@Collection()` line (keep `@JsonSerializable()` and the `part` directive);
- change `Id? id;` to `int? id;`;
- delete every `@Index(...)` line and both `@ignore` lines;
- delete the `actionsIsar` getter and setter and the `enhancementsIsar` getter and setter, with their doc comments.

`lib/src/utils/misc/mokuro_catalog.dart`: replace the whole file with:

```dart
/// Used to persist online catalogs of Mokuro manga.
class MokuroCatalog {
  /// Initialise this object.
  MokuroCatalog({
    required this.name,
    required this.url,
    required this.order,
    this.id,
  });

  /// Used for database purposes. Null until the catalog is saved.
  int? id;

  /// Name of the catalog.
  final String name;

  /// The URL pertaining to the catalog.
  final String url;

  /// The order of this catalog in terms of user sorting, relative to other
  /// catalogs.
  int order;

  @override
  bool operator ==(Object other) => other is MokuroCatalog && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

```sh
rm -f lib/src/utils/misc/mokuro_catalog.g.dart lib/src/creator/search_history_item.dart lib/src/creator/search_history_item.g.dart
```

Remove the line `export 'src/creator/search_history_item.dart';` from `lib/creator.dart`.

- [ ] **Step 4: Switch the two tables to the model classes**

In `lib/src/database/tables.dart`, replace `@DataClassName('AnkiMappingRow')` with `@UseRowClass(AnkiMapping)` and `@DataClassName('MokuroCatalogRow')` with `@UseRowClass(MokuroCatalog)`, and add `import 'package:yuuna/creator.dart';` and `import 'package:yuuna/utils.dart';`. Add the same two imports to `lib/src/database/app_database.dart`.

- [ ] **Step 5: Add the store methods**

In `lib/src/database/app_store.dart`, add `import 'package:yuuna/creator.dart';` and `import 'package:yuuna/utils.dart';`, and append to the class:

```dart
  /// The card creation profiles, in the user's order.
  List<AnkiMapping> mappings() {
    return _select(
        db.ankiMappings.map, 'SELECT * FROM anki_mapping ORDER BY "order"');
  }

  /// The profile named [label], if any.
  AnkiMapping? mappingByLabel(String label) {
    return _select(db.ankiMappings.map,
        'SELECT * FROM anki_mapping WHERE label = ?', [label]).firstOrNull;
  }

  /// Whether another profile, at another position, is named like [mapping].
  bool mappingLabelTaken(AnkiMapping mapping) {
    return raw.select(
      'SELECT 1 FROM anki_mapping WHERE label = ? AND "order" != ? LIMIT 1',
      [mapping.label, mapping.order],
    ).isNotEmpty;
  }

  /// The position after the last profile.
  int nextMappingOrder() {
    return raw
        .select('SELECT COALESCE(MAX("order") + 1, 0) AS next '
            'FROM anki_mapping')
        .first['next'] as int;
  }

  /// Save [mapping], replacing the profile with its id, label or position,
  /// and set its id.
  Future<void> putMapping(AnkiMapping mapping) async {
    AnkiMapping row = await db.into(db.ankiMappings).insertReturning(
          _mappingCompanion(mapping),
          mode: InsertMode.insertOrReplace,
        );
    mapping.id = row.id;
  }

  /// Replace every profile with [mappings], keeping their ids. Used to save
  /// a new order: positions are unique, so they cannot be updated one by one.
  Future<void> replaceMappings(List<AnkiMapping> mappings) async {
    await db.transaction(() async {
      await db.delete(db.ankiMappings).go();
      for (AnkiMapping mapping in mappings) {
        await db.into(db.ankiMappings).insert(_mappingCompanion(mapping));
      }
    });
  }

  /// Delete the profile [id].
  Future<void> deleteMapping(int id) async {
    await (db.delete(db.ankiMappings)..where((table) => table.id.equals(id)))
        .go();
  }

  AnkiMappingsCompanion _mappingCompanion(AnkiMapping mapping) {
    return AnkiMappingsCompanion.insert(
      id: Value.absentIfNull(mapping.id),
      label: mapping.label,
      model: mapping.model,
      order: mapping.order,
      exportFieldKeys: mapping.exportFieldKeys,
      creatorFieldKeys: mapping.creatorFieldKeys,
      creatorCollapsedFieldKeys: mapping.creatorCollapsedFieldKeys,
      tags: mapping.tags,
      actions: mapping.actions!,
      enhancements: mapping.enhancements!,
      exportMediaTags: Value(mapping.exportMediaTags),
      useBrTags: Value(mapping.useBrTags),
      prependDictionaryNames: Value(mapping.prependDictionaryNames),
    );
  }

  /// The mokuro catalogs, in the user's order.
  List<MokuroCatalog> catalogs() {
    return _select(db.mokuroCatalogs.map,
        'SELECT * FROM mokuro_catalog ORDER BY "order"');
  }

  /// Whether another catalog, at another position, has [catalog]'s URL.
  bool catalogUrlTaken(MokuroCatalog catalog) {
    return raw.select(
      'SELECT 1 FROM mokuro_catalog WHERE url = ? AND "order" != ? LIMIT 1',
      [catalog.url, catalog.order],
    ).isNotEmpty;
  }

  /// The position after the last catalog.
  int nextCatalogOrder() {
    return raw
        .select('SELECT COALESCE(MAX("order") + 1, 0) AS next '
            'FROM mokuro_catalog')
        .first['next'] as int;
  }

  /// Save [catalog], replacing the catalog with its id, URL or position, and
  /// set its id.
  Future<void> putCatalog(MokuroCatalog catalog) async {
    MokuroCatalog row = await db.into(db.mokuroCatalogs).insertReturning(
          _catalogCompanion(catalog),
          mode: InsertMode.insertOrReplace,
        );
    catalog.id = row.id;
  }

  /// Replace every catalog with [catalogs], keeping their ids. Used to save a
  /// new order.
  Future<void> replaceCatalogs(List<MokuroCatalog> catalogs) async {
    await db.transaction(() async {
      await db.delete(db.mokuroCatalogs).go();
      for (MokuroCatalog catalog in catalogs) {
        await db.into(db.mokuroCatalogs).insert(_catalogCompanion(catalog));
      }
    });
  }

  /// Delete the catalog [id].
  Future<void> deleteCatalog(int id) async {
    await (db.delete(db.mokuroCatalogs)..where((table) => table.id.equals(id)))
        .go();
  }

  MokuroCatalogsCompanion _catalogCompanion(MokuroCatalog catalog) {
    return MokuroCatalogsCompanion.insert(
      id: Value.absentIfNull(catalog.id),
      name: catalog.name,
      url: catalog.url,
      order: catalog.order,
    );
  }

  /// The search bar's history, oldest first.
  List<String> searchHistory() {
    return raw
        .select('SELECT search_term FROM search_history_item ORDER BY id')
        .map((row) => row['search_term'] as String)
        .toList();
  }

  /// Make [searchTerm] the newest search, keeping the [maximum] newest.
  Future<void> addToSearchHistory(String searchTerm, {required int maximum}) =>
      _addRecentTerm(db.searchHistoryItems, searchTerm, maximum);

  /// Forget the search [searchTerm].
  Future<void> removeFromSearchHistory(String searchTerm) async {
    await (db.delete(db.searchHistoryItems)
          ..where((table) => table.searchTerm.equals(searchTerm)))
        .go();
  }

  /// Forget every search.
  Future<void> clearSearchHistory() async {
    await db.delete(db.searchHistoryItems).go();
  }

  /// Delete [searchTerm] from [table], a table of unique `search_term`s whose
  /// ids give recency, insert it again as the newest, and keep only the
  /// [maximum] newest.
  Future<void> _addRecentTerm(
    TableInfo<Table, dynamic> table,
    String searchTerm,
    int maximum,
  ) async {
    String name = table.actualTableName;
    await db.transaction(() async {
      await db.customUpdate(
        'DELETE FROM $name WHERE search_term = ?',
        variables: [Variable.withString(searchTerm)],
        updates: {table},
        updateKind: UpdateKind.delete,
      );
      await db.customInsert(
        'INSERT INTO $name (search_term) VALUES (?)',
        variables: [Variable.withString(searchTerm)],
        updates: {table},
      );
      await db.customUpdate(
        'DELETE FROM $name WHERE id NOT IN '
        '(SELECT id FROM $name ORDER BY id DESC LIMIT ?)',
        variables: [Variable.withInt(maximum)],
        updates: {table},
        updateKind: UpdateKind.delete,
      );
    });
  }
```

- [ ] **Step 6: Regenerate and run the store tests**

```sh
dart run build_runner build --delete-conflicting-outputs
flutter test test/database/app_store_test.dart
```

Expected: PASS.

- [ ] **Step 7: Wire `AppModel`**

In `lib/src/models/app_model.dart`:

1. Remove `AnkiMappingSchema`, `SearchHistoryItemSchema` and `MokuroCatalogSchema` from `globalSchemas`.
2. Replace these members as follows. Keep every other line of the surrounding methods (dialogs, `notifyListeners()` calls) as it is.

```dart
  /// Returns all export profiles.
  List<AnkiMapping> get mappings => _store.mappings();

  /// Returns all Mokuro catalogs.
  List<MokuroCatalog> get mokuroCatalogs => _store.catalogs();
```

```dart
  /// Get a mapping with a given mapping name.
  AnkiMapping? getMappingFromLabel(String label) =>
      _store.mappingByLabel(label);
```

```dart
  /// Update the user-defined order of mappings in the database.
  /// See the profiles dialog's [ReorderableListView] for usage.
  Future<void> updateMappingsOrder(List<AnkiMapping> newMappings) =>
      _store.replaceMappings(newMappings);

  /// Update the user-defined order of given catalogs in the database.
  /// See the catalog dialog's [ReorderableListView] for usage.
  Future<void> updateCatalogsOrder(List<MokuroCatalog> newCatalogs) =>
      _store.replaceCatalogs(newCatalogs);
```

In `lastSelectedMapping`, replace the `AnkiMapping mapping = _database.ankiMappings...` statement with:

```dart
    AnkiMapping mapping = _store.mappingByLabel(mappingName) ??
        _store.mappingByLabel(mappings.first.label)!;
```

In `populateDefaultMapping` (make it `Future<void> populateDefaultMapping() async`):
- `if (_database.ankiMappings.where().findAllSync().isEmpty) { _database.writeTxnSync(...) }` becomes

```dart
    if (mappings.isEmpty) {
      await _store.putMapping(AnkiMapping.defaultMapping(order: 0));
    } else {
```

- `AnkiMapping standardProfile = _database.ankiMappings.where().labelEqualTo(AnkiMapping.standardProfileName).findFirstSync()!;` becomes `AnkiMapping standardProfile = _store.mappingByLabel(AnkiMapping.standardProfileName)!;`
- the `while` condition becomes `while (_store.mappingByLabel(newLabel) != null) {`
- the `_database.writeTxnSync(() { _database.ankiMappings.putAllSync([...]); });` becomes

```dart
        await _store.putMapping(legacyProfile);
        await _store.putMapping(
            AnkiMapping.defaultMapping(order: nextMappingOrder));
```

  `legacyProfile` is a `copyWith` of the standard profile and keeps its id, so `putMapping` (which replaces by id) relabels the standard row in place and then adds a new standard profile, as `putAllSync` did.

```dart
  /// Delete a selected mapping from the database.
  Future<void> deleteMapping(AnkiMapping mapping) async {
    await _store.deleteMapping(mapping.id!);

    if (mapping.label == lastSelectedMappingName) {
      await setLastSelectedMapping(mappings.first);
    }
  }

  /// Add a selected mapping to the database.
  Future<void> addMapping(AnkiMapping mapping) => _store.putMapping(mapping);

  /// Delete a selected catalog from the database.
  Future<void> deleteCatalog(MokuroCatalog catalog) =>
      _store.deleteCatalog(catalog.id!);

  /// Add a selected catalog to the database.
  Future<void> addCatalog(MokuroCatalog catalog) => _store.putCatalog(catalog);
```

```dart
  /// Check if a mapping with a certain name with a different order already
  /// exists.
  bool mappingNameHasDuplicate(AnkiMapping mapping) =>
      _store.mappingLabelTaken(mapping);

  /// Check if a catalog with a certain URL with a different order already
  /// exists.
  bool catalogUrlHasDuplicate(MokuroCatalog catalog) =>
      _store.catalogUrlTaken(catalog);

  /// Get the newest available order for a new mapping.
  int get nextMappingOrder => _store.nextMappingOrder();

  /// Get the newest available order for a new catalog.
  int get nextCatalogOrder => _store.nextCatalogOrder();
```

In `resetProfileFields`, replace the `_database.writeTxnSync(...)` block with `await _store.putMapping(resetMapping);`.

In `setFieldEnhancement`, `removeField`, `setField`, `removeFieldEnhancement`, `setQuickAction`, `removeQuickAction` and `removeAutoFieldEnhancement`: change the return type from `void` to `Future<void>` (they are already `async`) and replace each `_database.writeTxnSync(() { _database.ankiMappings.putSync(mapping); });` with `await _store.putMapping(mapping);`. In `setQuickAction` the existing `notifyListeners();` stays after it.

In the method that calls `deleteMapping(mapping);` right after `await selectStandardProfile();`, change it to `await deleteMapping(mapping);`.

Replace the search history methods:

```dart
  /// Add [searchTerm] to the search history. If there are already a maximum
  /// number of items in history, the oldest are discarded.
  Future<void> addToSearchHistory({required String searchTerm}) async {
    if (searchTerm.trim().isEmpty) {
      return;
    }

    await _store.addToSearchHistory(searchTerm,
        maximum: maximumSearchHistoryItems);
  }

  /// Remove [searchTerm] from the search history.
  Future<void> removeFromSearchHistory({required String searchTerm}) =>
      _store.removeFromSearchHistory(searchTerm);

  /// Clear the search history.
  Future<void> clearSearchHistory() => _store.clearSearchHistory();

  /// Get the search history, oldest first.
  List<String> getSearchHistory() => _store.searchHistory();
```

- [ ] **Step 8: Update the callers**

- `lib/src/utils/components/jidoujisho_search_history.dart`: delete the `uniqueKey` constructor parameter and field (and change the class doc's last line to `/// a floating search bar body.`); in `build`, `appModel.getSearchHistory(historyKey: widget.uniqueKey)` becomes `appModel.getSearchHistory()`; delete the `uniqueKey:` argument and the `required String uniqueKey,` parameter of `buildSearchHistoryItem`; the long-press handler becomes

```dart
      onLongPress: () async {
        if (widget.searchSuggestions.isNotEmpty) {
          return;
        }

        await appModel.removeFromSearchHistory(searchTerm: searchTerm);
        setState(() {});
        widget.onUpdate();
      },
```

- `lib/src/pages/implementations/home_dictionary_page.dart`: delete `historyKey: homeTab.uniqueKey,` in the `addToSearchHistory` call; `appModel.clearSearchHistory(historyKey: DictionaryTab.instance.uniqueKey);` becomes `await appModel.clearSearchHistory();`; `appModel.getSearchHistory(historyKey: homeTab.uniqueKey)` becomes `appModel.getSearchHistory()`; delete `uniqueKey: homeTab.uniqueKey,` from `JidoujishoSearchHistory(`.
- `lib/src/pages/implementations/recursive_dictionary_page.dart`: delete both `historyKey: DictionaryTab.instance.uniqueKey,` arguments of `addToSearchHistory`; `appModel.clearSearchHistory(historyKey: DictionaryTab.instance.uniqueKey);` becomes `await appModel.clearSearchHistory();`; `.getSearchHistory(historyKey: DictionaryTab.instance.uniqueKey)` becomes `.getSearchHistory()`; delete `uniqueKey: DictionaryTab.instance.uniqueKey,` from `JidoujishoSearchHistory(`.
- `lib/src/pages/implementations/profiles_dialog_page.dart`: in the delete dialog, `appModel.deleteMapping(mapping);` becomes `await appModel.deleteMapping(mapping);`; in `onReorder`, make the closure `async` if it is not and change `appModel.updateMappingsOrder(cloneMappings);` to `await appModel.updateMappingsOrder(cloneMappings);`; `appModel.addMapping(newMapping);` becomes `await appModel.addMapping(newMapping);` (its method is `async`; if `navigator.pop()` follows, it stays after the `await`).
- `lib/src/pages/implementations/mokuro_catalog_manage_dialog_page.dart`: `appModel.deleteCatalog(catalog);` becomes `await appModel.deleteCatalog(catalog);`; in `onReorder` make the closure `async` and `await appModel.updateCatalogsOrder(cloneCatalogs);`.
- `lib/src/pages/implementations/home_page.dart:55`: `appModel.populateDefaultMapping();` stays un-awaited (it shows its own dialog).

If `flutter analyze` reports `use_build_context_synchronously` after one of these `await`s, add an `if (!mounted) { return; }` (or `context.mounted` for a builder context) right after the `await`, before the `context` use.

- [ ] **Step 9: Full verification**

```sh
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Expected: no issues; all tests pass.

- [ ] **Step 10: Commit**

```sh
jj status
jj commit -m "Move profiles, catalogs and search history to Drift

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: Dictionary import writer

**Files:**
- Create: `lib/src/database/dictionary_import_writer.dart`, `test/database/dictionary_import_writer_test.dart`
- Modify: `lib/database.dart`, `test/database/test_database.dart`

**Interfaces:**
- Consumes: the schema (Task 2).
- Produces: `class DictionaryImportWriter { DictionaryImportWriter({required Database database, required int dictionaryId}); int headingId({required String term, required String reading}); void addTag({required String name, required String category, required int sortingOrder, required String notes, required double popularity}); void addEntry({required int headingId, required List<String> definitions, required double popularity, List<String> entryTagNames = const [], List<String> headingTagNames = const []}); void addPitch({required int headingId, required int downstep}); void addFrequency({required int headingId, required double value, required String displayValue}); void close(); }`. Test helpers `int insertTestDictionary(Database raw, String name)` and `int writeTestDictionary(Database raw, String name, void Function(DictionaryImportWriter writer) write)`.

- [ ] **Step 1: Add the fixture helpers to `test/database/test_database.dart`**

```dart
/// Insert a dictionary row named [name], last in order, and return its id.
int insertTestDictionary(Database raw, String name) {
  raw.execute(
    'INSERT INTO dictionary (name, format_key, "order") VALUES '
    '(?, ?, (SELECT COALESCE(MAX("order"), 0) + 1 FROM dictionary))',
    [name, 'yomichan'],
  );
  return raw.lastInsertRowId;
}

/// Insert a dictionary named [name] and let [write] fill it through a
/// [DictionaryImportWriter], as an import would. Returns its id.
int writeTestDictionary(
  Database raw,
  String name,
  void Function(DictionaryImportWriter writer) write,
) {
  int dictionaryId = insertTestDictionary(raw, name);
  DictionaryImportWriter writer =
      DictionaryImportWriter(database: raw, dictionaryId: dictionaryId);
  try {
    write(writer);
  } finally {
    writer.close();
  }
  return dictionaryId;
}
```

- [ ] **Step 2: Write the failing tests `test/database/dictionary_import_writer_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';

import 'test_database.dart';

void main() {
  late TestDatabase database;
  late Database raw;

  setUp(() async {
    database = await openTestDatabase();
    raw = database.raw;
  });

  tearDown(() => database.db.close());

  test('headingId reuses a heading created by another dictionary', () {
    late int first;
    late int second;
    writeTestDictionary(raw, 'A', (writer) {
      first = writer.headingId(term: '猫', reading: 'ねこ');
      writer.addEntry(headingId: first, definitions: ['cat'], popularity: 0);
    });
    writeTestDictionary(raw, 'B', (writer) {
      second = writer.headingId(term: '猫', reading: 'ねこ');
      writer.addEntry(headingId: second, definitions: ['neko'], popularity: 0);
    });

    expect(second, first);
    expect(countRows(raw, 'heading'), 1);
    expect(countRows(raw, 'entry'), 2);
  });

  test('headingId returns the same id for the same word', () {
    writeTestDictionary(raw, 'A', (writer) {
      expect(writer.headingId(term: '犬', reading: 'いぬ'),
          writer.headingId(term: '犬', reading: 'いぬ'));
    });
    expect(countRows(raw, 'heading'), 1);
  });

  test('links known tags and skips unknown ones', () {
    writeTestDictionary(raw, 'A', (writer) {
      writer
        ..addTag(
            name: 'n',
            category: 'partOfSpeech',
            sortingOrder: 0,
            notes: 'noun',
            popularity: 0)
        ..addTag(
            name: 'P',
            category: 'popular',
            sortingOrder: -1,
            notes: 'popular',
            popularity: 10);
      writer.addEntry(
        headingId: writer.headingId(term: '猫', reading: 'ねこ'),
        definitions: ['cat'],
        popularity: 1,
        entryTagNames: ['n', 'unknown', ''],
        headingTagNames: ['P'],
      );
    });

    expect(countRows(raw, 'tag'), 2);
    expect(countRows(raw, 'entry_tag'), 1);
    expect(countRows(raw, 'heading_tag'), 1);
  });

  test('a tag defined twice is one tag', () {
    writeTestDictionary(raw, 'A', (writer) {
      writer
        ..addTag(
            name: 'n',
            category: 'a',
            sortingOrder: 0,
            notes: '',
            popularity: 0)
        ..addTag(
            name: 'n',
            category: 'b',
            sortingOrder: 0,
            notes: '',
            popularity: 0);
    });

    expect(raw.select('SELECT category FROM tag').single['category'], 'b');
  });

  test('a pitch or frequency for an unknown word keeps its reading', () {
    writeTestDictionary(raw, 'Pitch', (writer) {
      writer.addPitch(
          headingId: writer.headingId(term: '行く', reading: 'いく'),
          downstep: 0);
      writer.addFrequency(
          headingId: writer.headingId(term: '行く', reading: 'ゆく'),
          value: 100,
          displayValue: '100');
    });

    expect(
      raw
          .select('SELECT reading FROM heading ORDER BY id')
          .map((row) => row['reading']),
      ['いく', 'ゆく'],
    );
  });

  test('stores definitions as the converter reads them', () async {
    writeTestDictionary(raw, 'A', (writer) {
      writer.addEntry(
        headingId: writer.headingId(term: '猫', reading: 'ねこ'),
        definitions: ['cat', '{"tag":"span"}'],
        popularity: 2.5,
      );
    });

    EntryRow entry = await database.db.select(database.db.entries).getSingle();
    expect(entry.definitions, ['cat', '{"tag":"span"}']);
    expect(entry.popularity, 2.5);
  });
}
```

- [ ] **Step 3: Run them to see them fail**

Run: `flutter test test/database/dictionary_import_writer_test.dart`
Expected: compilation fails (`DictionaryImportWriter` undefined).

- [ ] **Step 4: Write `lib/src/database/dictionary_import_writer.dart`**

```dart
import 'package:sqlite3/sqlite3.dart' show Database, PreparedStatement;
import 'package:yuuna/database.dart';

/// Writes one dictionary's tags, entries, pitches and frequencies during an
/// import, through prepared statements on the import isolate's raw
/// connection. It runs inside the import's transaction, which its caller
/// owns, so a failure leaves nothing behind. The only raw writer in the app:
/// a large dictionary is about a million rows, and Drift's per-statement
/// futures would show in the import time.
class DictionaryImportWriter {
  /// Prepare the statements for writing dictionary [dictionaryId] to
  /// [database].
  DictionaryImportWriter({
    required Database database,
    required this.dictionaryId,
  })  : _upsertHeading = database.prepare(
          'INSERT INTO heading (term, reading) VALUES (?, ?) '
          'ON CONFLICT (term, reading) DO UPDATE SET term = excluded.term '
          'RETURNING id',
        ),
        _upsertTag = database.prepare(
          'INSERT INTO tag (dictionary_id, name, category, sorting_order, '
          'notes, popularity) VALUES (?, ?, ?, ?, ?, ?) '
          'ON CONFLICT (dictionary_id, name) DO UPDATE SET '
          'category = excluded.category, '
          'sorting_order = excluded.sorting_order, '
          'notes = excluded.notes, popularity = excluded.popularity '
          'RETURNING id',
        ),
        _insertEntry = database.prepare(
          'INSERT INTO entry (heading_id, dictionary_id, definitions, '
          'popularity) VALUES (?, ?, ?, ?) RETURNING id',
        ),
        _insertEntryTag = database.prepare(
          'INSERT OR IGNORE INTO entry_tag (entry_id, tag_id) VALUES (?, ?)',
        ),
        _insertHeadingTag = database.prepare(
          'INSERT OR IGNORE INTO heading_tag (heading_id, tag_id) '
          'VALUES (?, ?)',
        ),
        _insertPitch = database.prepare(
          'INSERT INTO pitch (heading_id, dictionary_id, downstep) '
          'VALUES (?, ?, ?)',
        ),
        _insertFrequency = database.prepare(
          'INSERT INTO frequency (heading_id, dictionary_id, value, '
          'display_value) VALUES (?, ?, ?, ?)',
        );

  /// The dictionary being written.
  final int dictionaryId;

  final PreparedStatement _upsertHeading;
  final PreparedStatement _upsertTag;
  final PreparedStatement _insertEntry;
  final PreparedStatement _insertEntryTag;
  final PreparedStatement _insertHeadingTag;
  final PreparedStatement _insertPitch;
  final PreparedStatement _insertFrequency;

  final Map<(String, String), int> _headingIds = {};
  final Map<String, int> _tagIds = {};

  static const StringListConverter _definitions = StringListConverter();

  /// The id of the heading ([term], [reading]), creating it if no
  /// dictionary has it yet. Memoised for the import.
  int headingId({required String term, required String reading}) {
    return _headingIds.putIfAbsent(
      (term, reading),
      () => _upsertHeading.select([term, reading]).first['id'] as int,
    );
  }

  /// Define the tag [name]. Defining it again overwrites it.
  void addTag({
    required String name,
    required String category,
    required int sortingOrder,
    required String notes,
    required double popularity,
  }) {
    _tagIds[name] = _upsertTag.select([
      dictionaryId,
      name,
      category,
      sortingOrder,
      notes,
      popularity,
    ]).first['id'] as int;
  }

  /// Add an entry to the heading [headingId], tagged with
  /// [entryTagNames], and tag the heading with [headingTagNames]. Tag names
  /// this dictionary does not define are skipped.
  void addEntry({
    required int headingId,
    required List<String> definitions,
    required double popularity,
    List<String> entryTagNames = const [],
    List<String> headingTagNames = const [],
  }) {
    int entryId = _insertEntry.select([
      headingId,
      dictionaryId,
      _definitions.toSql(definitions),
      popularity,
    ]).first['id'] as int;

    for (String name in entryTagNames) {
      int? tagId = _tagIds[name];
      if (tagId != null) {
        _insertEntryTag.execute([entryId, tagId]);
      }
    }
    for (String name in headingTagNames) {
      int? tagId = _tagIds[name];
      if (tagId != null) {
        _insertHeadingTag.execute([headingId, tagId]);
      }
    }
  }

  /// Add a pitch accent to the heading [headingId].
  void addPitch({required int headingId, required int downstep}) {
    _insertPitch.execute([headingId, dictionaryId, downstep]);
  }

  /// Add a frequency to the heading [headingId].
  void addFrequency({
    required int headingId,
    required double value,
    required String displayValue,
  }) {
    _insertFrequency.execute([headingId, dictionaryId, value, displayValue]);
  }

  /// Release the prepared statements.
  void close() {
    for (PreparedStatement statement in [
      _upsertHeading,
      _upsertTag,
      _insertEntry,
      _insertEntryTag,
      _insertHeadingTag,
      _insertPitch,
      _insertFrequency,
    ]) {
      statement.close();
    }
  }
}
```

If `PreparedStatement` is not exported under that name by `package:sqlite3/sqlite3.dart` 3.5, use the type `Database.prepare` returns (check with the analyzer's hover or `grep -n "prepare(" ~/.pub-cache/hosted/pub.dev/sqlite3-3.5.2/lib/src/ffi/api.dart`) and update the `show` clause.

Add `export 'src/database/dictionary_import_writer.dart';` to `lib/database.dart`.

- [ ] **Step 5: Run the tests**

Run: `flutter test test/database/dictionary_import_writer_test.dart`
Expected: PASS.

- [ ] **Step 6: Full verification and commit**

```sh
flutter analyze
flutter test
jj status
jj commit -m "Add the dictionary import writer

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Search queries and dictionary deletion

**Files:**
- Create: `lib/src/database/search.drift`, `lib/src/database/dictionary_deletion.dart`
- Create: `test/database/search_queries_test.dart`, `test/database/dictionary_deletion_test.dart`
- Modify: `lib/src/database/app_database.dart`, `lib/database.dart`

**Interfaces:**
- Consumes: `writeTestDictionary` (Task 5).
- Produces, on `AppDatabase` (generated, named parameters): `headingCountByTerm({required String term})` → `Selectable<int>`; `headingsByTerms({required List<String> terms})`, `headingsByTermsByPopularity({required List<String> terms})`, `headingsByReadings({required List<String> readings, required int limit})`, `headingsByTermPrefix({required String prefix, required String prefixEnd, required int limit})`, `headingsByTermGlob({required String pattern, required int minimumLength, required int maximumLength, required int limit})`, `headingsByReadingGlob({required String pattern, required String alternativePattern, required int limit})`, `headingWithEntries({required String term, required String reading})`, `headingByTermAndReading({required String term, required String reading})`, `headingsByIds({required List<int> ids})` → `Selectable<HeadingRow>`; `entriesByHeadings({required List<int> ids})` → `Selectable<EntryRow>`; `pitchesByHeadings`, `frequenciesByHeadings` (same parameter) → `PitchRow` / `FrequencyRow`; `headingTagsByHeadings({required List<int> ids})` → `HeadingTagsByHeadingsResult { int ownerId; TagRow tag; }`; `entryTagsByEntries({required List<int> ids})` → `EntryTagsByEntriesResult { int ownerId; TagRow tag; }`; `noReadingFrequencies({required List<String> terms})` → `NoReadingFrequenciesResult { String term; FrequencyRow frequency; }`; `allDictionaries()` → `Selectable<Dictionary>`. Top-level `Future<void> deleteDictionaryData(AppDatabase db, int dictionaryId)` and `Future<void> deleteAllDictionaryData(AppDatabase db)`.

- [ ] **Step 1: Write the failing tests**

`test/database/search_queries_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';

import 'test_database.dart';

void main() {
  late TestDatabase database;
  late AppDatabase db;

  setUp(() async {
    database = await openTestDatabase();
    db = database.db;
    writeTestDictionary(database.raw, 'JMdict', (writer) {
      writer.addTag(
          name: 'n',
          category: 'partOfSpeech',
          sortingOrder: 0,
          notes: 'noun',
          popularity: 0);
      writer.addTag(
          name: 'P',
          category: 'popular',
          sortingOrder: -1,
          notes: 'popular',
          popularity: 10);
      for ((String, String, double) word in [
        ('食', 'しょく', 1),
        ('食べる', 'たべる', 5),
        ('食べ物', 'たべもの', 3),
        ('生', 'なま', 1),
        ('生', 'せい', 4),
        ('𠮟る', 'しかる', 1),
      ]) {
        writer.addEntry(
          headingId: writer.headingId(term: word.$1, reading: word.$2),
          definitions: ['${word.$1} meaning'],
          popularity: word.$3,
          entryTagNames: ['n'],
          headingTagNames: word.$1 == '食べる' ? ['P'] : [],
        );
      }
      writer.addPitch(
          headingId: writer.headingId(term: '食べる', reading: 'たべる'),
          downstep: 2);
      writer.addPitch(
          headingId: writer.headingId(term: '無', reading: 'む'), downstep: 0);
    });
    writeTestDictionary(database.raw, 'Freq', (writer) {
      writer.addFrequency(
          headingId: writer.headingId(term: '生', reading: ''),
          value: 300,
          displayValue: '300');
    });
  });

  tearDown(() => db.close());

  List<String> terms(List<HeadingRow> rows) =>
      rows.map((row) => '${row.term}/${row.reading}').toList();

  test('headingsByTerms finds headings with entries only', () async {
    expect(terms(await db.headingsByTerms(terms: ['食べる', '無']).get()),
        ['食べる/たべる']);
    expect(await db.headingCountByTerm(term: '無').getSingle(), 1);
  });

  test('headingsByTermsByPopularity puts the most popular first', () async {
    expect(terms(await db.headingsByTermsByPopularity(terms: ['生']).get()),
        ['生/せい', '生/なま']);
  });

  test('headingsByReadings honours its limit', () async {
    expect(
        await db.headingsByReadings(readings: ['なま', 'せい'], limit: 1).get(),
        hasLength(1));
  });

  test('headingsByTermPrefix is shortest first and limited', () async {
    expect(
      terms(await db
          .headingsByTermPrefix(prefix: '食', prefixEnd: '食\u{10FFFF}', limit: 10)
          .get()),
      ['食/しょく', '食べる/たべる', '食べ物/たべもの'],
    );
    expect(
      await db
          .headingsByTermPrefix(prefix: '食', prefixEnd: '食\u{10FFFF}', limit: 2)
          .get(),
      hasLength(2),
    );
  });

  test('headingsByTermGlob filters on character length', () async {
    expect(
      terms(await db
          .headingsByTermGlob(
              pattern: '食??', minimumLength: 3, maximumLength: 3, limit: 10)
          .get()),
      ['食べる/たべる', '食べ物/たべもの'],
    );
    expect(
      terms(await db
          .headingsByTermGlob(
              pattern: '𠮟?', minimumLength: 2, maximumLength: 2, limit: 10)
          .get()),
      ['𠮟る/しかる'],
    );
  });

  test('headingsByReadingGlob matches either pattern', () async {
    expect(
      terms(await db
          .headingsByReadingGlob(
              pattern: 'な?', alternativePattern: 'せ?', limit: 10)
          .get()),
      ['生/なま', '生/せい'],
    );
  });

  test('heading lookups by term and reading', () async {
    expect(await db.headingWithEntries(term: '無', reading: 'む').get(),
        isEmpty);
    expect(await db.headingByTermAndReading(term: '無', reading: 'む').get(),
        hasLength(1));
  });

  test('the loader queries return what the heading links to', () async {
    HeadingRow taberu =
        (await db.headingsByTerms(terms: ['食べる']).get()).single;
    List<int> ids = [taberu.id];

    List<EntryRow> entries = await db.entriesByHeadings(ids: ids).get();
    expect(entries.single.definitions, ['食べる meaning']);
    expect((await db.pitchesByHeadings(ids: ids).get()).single.downstep, 2);
    expect(
        (await db.headingTagsByHeadings(ids: ids).get())
            .map((row) => (row.ownerId, row.tag.name)),
        [(taberu.id, 'P')]);
    expect(
        (await db.entryTagsByEntries(ids: [entries.single.id]).get())
            .map((row) => row.tag.name),
        ['n']);
    expect(
        (await db.noReadingFrequencies(terms: ['生']).get())
            .map((row) => (row.term, row.frequency.displayValue)),
        [('生', '300')]);
    expect((await db.headingsByIds(ids: ids).get()).single.term, '食べる');
  });

  test('allDictionaries is in the user order', () async {
    List<Dictionary> dictionaries = await db.allDictionaries().get();
    expect(dictionaries.map((dictionary) => dictionary.name),
        ['JMdict', 'Freq']);
  });
}
```

`test/database/dictionary_deletion_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';

import 'test_database.dart';

void main() {
  late TestDatabase database;
  late Database raw;
  late int jmdict;

  setUp(() async {
    database = await openTestDatabase();
    raw = database.raw;
    jmdict = writeTestDictionary(raw, 'JMdict', (writer) {
      writer.addTag(
          name: 'n',
          category: 'partOfSpeech',
          sortingOrder: 0,
          notes: '',
          popularity: 0);
      writer.addEntry(
        headingId: writer.headingId(term: '猫', reading: 'ねこ'),
        definitions: ['cat'],
        popularity: 0,
        entryTagNames: ['n'],
        headingTagNames: ['n'],
      );
      writer.addEntry(
        headingId: writer.headingId(term: '犬', reading: 'いぬ'),
        definitions: ['dog'],
        popularity: 0,
      );
    });
    writeTestDictionary(raw, 'Other', (writer) {
      writer.addEntry(
        headingId: writer.headingId(term: '猫', reading: 'ねこ'),
        definitions: ['neko'],
        popularity: 0,
      );
    });
  });

  tearDown(() => database.db.close());

  test('deleteDictionaryData removes one dictionary and its orphans',
      () async {
    await deleteDictionaryData(database.db, jmdict);

    expect(countRows(raw, 'dictionary'), 1);
    expect(raw.select('SELECT term FROM heading').map((row) => row['term']),
        ['猫']);
    expect(countRows(raw, 'entry'), 1);
    expect(countRows(raw, 'tag'), 0);
    expect(countRows(raw, 'entry_tag'), 0);
    expect(countRows(raw, 'heading_tag'), 0);
  });

  test('deleteAllDictionaryData empties every dictionary table', () async {
    await deleteAllDictionaryData(database.db);

    for (String table in [
      'dictionary',
      'heading',
      'entry',
      'pitch',
      'frequency',
      'tag',
      'entry_tag',
      'heading_tag',
    ]) {
      expect(countRows(raw, table), 0, reason: table);
    }
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/database/search_queries_test.dart test/database/dictionary_deletion_test.dart`
Expected: compilation fails (query methods and deletion functions undefined).

- [ ] **Step 3: Write `lib/src/database/search.drift`**

```sql
import 'tables.dart';

-- How many headings have this term, with or without entries.
headingCountByTerm: SELECT COUNT(*) FROM heading WHERE term = :term;

-- Headings with entries whose term is one of these.
headingsByTerms: SELECT * FROM heading
  WHERE term IN :terms
    AND EXISTS (SELECT 1 FROM entry WHERE entry.heading_id = heading.id)
  ORDER BY id;

-- Same, most popular first: by the sum of their entries' popularity.
headingsByTermsByPopularity: SELECT * FROM heading
  WHERE term IN :terms
    AND EXISTS (SELECT 1 FROM entry WHERE entry.heading_id = heading.id)
  ORDER BY (SELECT SUM(popularity) FROM entry WHERE entry.heading_id = heading.id) DESC, id;

-- Headings with entries whose reading is one of these.
headingsByReadings: SELECT * FROM heading
  WHERE reading IN :readings
    AND EXISTS (SELECT 1 FROM entry WHERE entry.heading_id = heading.id)
  ORDER BY id
  LIMIT :limit;

-- Headings with entries whose term starts with :prefix, shortest first.
-- :prefixEnd is :prefix followed by U+10FFFF, so the range uses the index.
headingsByTermPrefix: SELECT * FROM heading
  WHERE term >= :prefix AND term < :prefix_end
    AND EXISTS (SELECT 1 FROM entry WHERE entry.heading_id = heading.id)
  ORDER BY length(term), id
  LIMIT :limit;

-- Headings with entries whose term matches a GLOB pattern, within a length
-- range counted in characters.
headingsByTermGlob: SELECT * FROM heading
  WHERE term GLOB :pattern
    AND length(term) BETWEEN :minimum_length AND :maximum_length
    AND EXISTS (SELECT 1 FROM entry WHERE entry.heading_id = heading.id)
  ORDER BY id
  LIMIT :limit;

-- Headings with entries whose reading matches either GLOB pattern.
headingsByReadingGlob: SELECT * FROM heading
  WHERE (reading GLOB :pattern OR reading GLOB :alternative_pattern)
    AND EXISTS (SELECT 1 FROM entry WHERE entry.heading_id = heading.id)
  ORDER BY id
  LIMIT :limit;

-- The heading (term, reading), if it has entries.
headingWithEntries: SELECT * FROM heading
  WHERE term = :term AND reading = :reading
    AND EXISTS (SELECT 1 FROM entry WHERE entry.heading_id = heading.id);

-- The heading (term, reading), with or without entries.
headingByTermAndReading: SELECT * FROM heading
  WHERE term = :term AND reading = :reading;

-- What the heading loader reads.
headingsByIds: SELECT * FROM heading WHERE id IN :ids;
entriesByHeadings: SELECT * FROM entry WHERE heading_id IN :ids ORDER BY id;
pitchesByHeadings: SELECT * FROM pitch WHERE heading_id IN :ids ORDER BY id;
frequenciesByHeadings: SELECT * FROM frequency WHERE heading_id IN :ids ORDER BY id;
headingTagsByHeadings: SELECT heading_tag.heading_id AS owner_id, tag.**
  FROM heading_tag INNER JOIN tag ON tag.id = heading_tag.tag_id
  WHERE heading_tag.heading_id IN :ids
  ORDER BY tag.id;
entryTagsByEntries: SELECT entry_tag.entry_id AS owner_id, tag.**
  FROM entry_tag INNER JOIN tag ON tag.id = entry_tag.tag_id
  WHERE entry_tag.entry_id IN :ids
  ORDER BY tag.id;
-- Frequencies given for these terms without a reading.
noReadingFrequencies: SELECT heading.term AS term, frequency.**
  FROM frequency INNER JOIN heading ON heading.id = frequency.heading_id
  WHERE heading.reading = '' AND heading.term IN :terms
  ORDER BY frequency.id;
allDictionaries: SELECT * FROM dictionary ORDER BY "order";
```

Drift turns snake_case variable names into camelCase parameters (`:prefix_end` → `prefixEnd`, `:minimum_length` → `minimumLength`, `:alternative_pattern` → `alternativePattern`), which is what the tests call.

In `lib/src/database/app_database.dart`, add `include: {'search.drift'},` to the `@DriftDatabase(...)` annotation, after the `tables:` list.

- [ ] **Step 4: Write `lib/src/database/dictionary_deletion.dart`**

```dart
import 'package:yuuna/database.dart';

/// Delete the dictionary [dictionaryId] with everything it brought, then the
/// headings nothing refers to any more, then give the freed pages back to
/// the file system.
Future<void> deleteDictionaryData(AppDatabase db, int dictionaryId) async {
  await db.transaction(() async {
    await (db.delete(db.dictionaries)
          ..where((table) => table.id.equals(dictionaryId)))
        .go();
    await db.customStatement(_deleteOrphanHeadings);
  });
  await db.customStatement('PRAGMA incremental_vacuum');
}

/// Delete every dictionary and all their data.
Future<void> deleteAllDictionaryData(AppDatabase db) async {
  await db.transaction(() async {
    await db.delete(db.dictionaries).go();
    await db.customStatement(_deleteOrphanHeadings);
  });
  await db.customStatement('PRAGMA incremental_vacuum');
}

/// Deleting a dictionary cascades to its entries, pitches, frequencies and
/// tags; headings belong to no dictionary and go once nothing points at them.
const String _deleteOrphanHeadings = 'DELETE FROM heading WHERE '
    'NOT EXISTS (SELECT 1 FROM entry WHERE entry.heading_id = heading.id) '
    'AND NOT EXISTS (SELECT 1 FROM pitch WHERE pitch.heading_id = heading.id) '
    'AND NOT EXISTS (SELECT 1 FROM frequency '
    'WHERE frequency.heading_id = heading.id) '
    'AND NOT EXISTS (SELECT 1 FROM heading_tag '
    'WHERE heading_tag.heading_id = heading.id)';
```

Add `export 'src/database/dictionary_deletion.dart';` to `lib/database.dart`.

- [ ] **Step 5: Regenerate and run the tests**

```sh
dart run build_runner build --delete-conflicting-outputs
flutter test test/database/search_queries_test.dart test/database/dictionary_deletion_test.dart
```

Expected: PASS. If a generated method's parameter names differ from the ones above (check `app_database.g.dart`), keep the SQL and adjust only the variable names in `search.drift` until they match the *Interfaces* list; later tasks rely on those names.

- [ ] **Step 6: Schema snapshot is unchanged**

```sh
dart run drift_dev schema dump lib/src/database/app_database.dart drift_schemas/
jj diff --stat drift_schemas
```

Expected: no change (queries do not change the schema).

- [ ] **Step 7: Full verification and commit**

```sh
flutter analyze
flutter test
jj status
jj commit -m "Add the search queries and dictionary deletion

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 7: Import, deletion and the dictionary list on Drift

After this task dictionaries are imported into SQLite and listed from it, but lookups still read Isar (Task 8 moves them), so **lookups return nothing between Tasks 7 and 8**. Build and tests pass throughout; say so in the hand-off.

**Files:**
- Modify: `lib/src/dictionary/dictionary_operations_params.dart`, `lib/src/dictionary/dictionary_format.dart`, `lib/src/dictionary/formats/yomichan_dictionary_format.dart`, `lib/src/dictionary/formats/migaku_dictionary_format.dart`, `lib/src/dictionary/dictionary_utils.dart`
- Modify: `lib/src/database/app_store.dart`, `lib/src/models/app_model.dart`, `lib/src/pages/implementations/dictionary_dialog_page.dart`
- Create: `test/dictionary/dictionary_utils_test.dart`
- Modify: `test/database/app_store_test.dart`

**Interfaces:**
- Consumes: `DictionaryImportWriter` (Task 5), `deleteDictionaryData` / `deleteAllDictionaryData` (Task 6), `openRawDatabase`, `AppDatabase.open` (Task 2).
- Produces: `IsolateParams.databasePath` (`String`); `PrepareDictionaryParams({required String dictionaryName, required DictionaryFormat dictionaryFormat, required Directory resourceDirectory, required SendPort alertSendPort, required SendPort sendPort, required String directoryPath, required String databasePath})`; `Future<int> depositDictionaryDataHelper(PrepareDictionaryParams)` (returns the new dictionary's id); `DictionaryFormat.prepareTags/prepareEntries/preparePitches/prepareFrequencies` typed `void Function({required PrepareDictionaryParams params, required DictionaryImportWriter writer})`; `AppStore.dictionaries()`, `AppStore.updateDictionaryFlags(Dictionary)`, `AppStore.reorderDictionaries(List<Dictionary>)`; `AppModel.toggleDictionaryCollapsed/toggleDictionaryHidden/updateDictionaryOrder` return `Future<void>`.

- [ ] **Step 1: Write the failing tests**

Append to `test/database/app_store_test.dart`, inside `main()`:

```dart
  group('dictionaries', () {
    test('listed in order; flags saved; reordered without constraint errors',
        () async {
      insertTestDictionary(database.raw, 'A');
      insertTestDictionary(database.raw, 'B');

      List<Dictionary> dictionaries = store.dictionaries();
      expect(dictionaries.map((dictionary) => dictionary.name), ['A', 'B']);

      Dictionary a = dictionaries.first..isHidden = true;
      await store.updateDictionaryFlags(a);
      expect(store.dictionaries().first.isHidden, isTrue);

      Dictionary b = dictionaries.last;
      a.order = 1;
      b.order = 0;
      await store.reorderDictionaries([b, a]);
      expect(store.dictionaries().map((dictionary) => dictionary.name),
          ['B', 'A']);
    });
  });
```

Add `import 'package:yuuna/dictionary.dart';` to its imports.

`test/dictionary/dictionary_utils_test.dart`:

```dart
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:sqlite3/sqlite3.dart' show Database;
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';

import '../database/test_database.dart';

void main() {
  late Directory directory;
  late String databasePath;
  late Directory resources;
  late ReceivePort progress;
  late ReceivePort alerts;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('yomimoto_import_');
    databasePath = path.join(directory.path, databaseFileName);
    resources = Directory(path.join(directory.path, 'importing'))
      ..createSync();
    progress = ReceivePort();
    alerts = ReceivePort();

    AppDatabase db = AppDatabase.open(databasePath);
    await db.customSelect('SELECT 1').get();
    await db.close();
  });

  tearDown(() {
    progress.close();
    alerts.close();
    directory.deleteSync(recursive: true);
  });

  PrepareDictionaryParams params(String name) => PrepareDictionaryParams(
        dictionaryName: name,
        dictionaryFormat: MigakuFormat.instance,
        resourceDirectory: resources,
        alertSendPort: alerts.sendPort,
        sendPort: progress.sendPort,
        directoryPath: directory.path,
        databasePath: databasePath,
      );

  void writeBank(String contents) {
    File(path.join(resources.path, 'bank.json')).writeAsStringSync(contents);
  }

  int count(String table) {
    Database raw = openRawDatabase(databasePath);
    try {
      return countRows(raw, table);
    } finally {
      raw.close();
    }
  }

  test('deposits a Migaku dictionary and returns its id', () async {
    writeBank('[{"term": "猫", "definition": "cat", "pronunciation": "ねこ"}]');

    int id = await depositDictionaryDataHelper(params('Test'));

    Database raw = openRawDatabase(databasePath);
    addTearDown(raw.close);
    expect(
        raw.select('SELECT id, format_key, "order" FROM dictionary').single,
        {'id': id, 'format_key': 'migaku', 'order': 1});
    expect(raw.select('SELECT term, reading FROM heading').single,
        {'term': '猫', 'reading': 'ねこ'});
    expect(countRows(raw, 'entry'), 1);
  });

  test('a duplicate name fails and leaves the first dictionary alone',
      () async {
    writeBank('[{"term": "猫", "definition": "cat", "pronunciation": "ねこ"}]');
    await depositDictionaryDataHelper(params('Test'));

    await expectLater(
        depositDictionaryDataHelper(params('Test')), throwsA(anything));

    expect(count('dictionary'), 1);
    expect(count('entry'), 1);
  });

  test('a malformed bank rolls the whole import back', () async {
    writeBank('not json');

    await expectLater(
        depositDictionaryDataHelper(params('Broken')), throwsA(anything));

    expect(count('dictionary'), 0);
    expect(count('heading'), 0);
  });
}
```

- [ ] **Step 2: Run them to see them fail**

Run: `flutter test test/dictionary/dictionary_utils_test.dart test/database/app_store_test.dart`
Expected: compilation fails (`dictionaryName`, `databasePath`, `dictionaries()` undefined).

- [ ] **Step 3: Parameters**

In `lib/src/dictionary/dictionary_operations_params.dart`:

`IsolateParams` gains a field (keep `directoryPath`, which Isar search still uses until Task 8):

```dart
  IsolateParams({
    required this.sendPort,
    required this.directoryPath,
    required this.databasePath,
  });
```

```dart
  /// Path of the SQLite database file.
  final String databasePath;
```

Add `required super.databasePath,` to the constructors of `PrepareDirectoryParams`, `DeleteDictionaryParams`, `UpdateDictionaryHistoryParams` and `DictionarySearchParams`.

Replace `PrepareDictionaryParams` with:

```dart
/// For isolate communication purposes. Used for dictionary import.
class PrepareDictionaryParams extends IsolateParams {
  /// Prepare parameters needed for importing a dictionary from an isolate.
  PrepareDictionaryParams({
    required this.dictionaryName,
    required this.dictionaryFormat,
    required this.resourceDirectory,
    required this.alertSendPort,
    required super.sendPort,
    required super.directoryPath,
    required super.databasePath,
  });

  /// The name of the dictionary being imported.
  final String dictionaryName;

  /// The format that the dictionary is being imported in.
  final DictionaryFormat dictionaryFormat;

  /// The directory the archive was extracted to.
  final Directory resourceDirectory;

  /// For sending alerts that the user must see.
  final SendPort alertSendPort;

  /// Send an alert to the user.
  void sendAlert({required String message}) {
    alertSendPort.send(message);
  }
}
```

Keep the existing doc comments of the unchanged members if they differ from these.

- [ ] **Step 4: Format function types**

In `lib/src/dictionary/dictionary_format.dart`, replace `import 'package:isar_community/isar.dart';` with `import 'package:yuuna/database.dart';`, and in each of the four `prepareTags` / `prepareEntries` / `preparePitches` / `prepareFrequencies` declarations replace `required Isar isar,` with `required DictionaryImportWriter writer,`. Update their doc comments to say they write through `writer`, synchronously.

- [ ] **Step 5: Port the Yomichan format**

In `lib/src/dictionary/formats/yomichan_dictionary_format.dart`, replace `import 'package:isar_community/isar.dart';` with `import 'package:yuuna/database.dart';`. The four functions become synchronous `void` functions (drop `Future<void>` and `async`; they had no `await`, but the writer's transaction must not end before they do) taking `required DictionaryImportWriter writer` instead of `required Isar isar`. Keep each function's file-scanning and `params.send(...)` progress code as it is; change only the writes:

In `prepareEntriesYomichanFormat`, the `term_bank` loop body after `definitions` is computed becomes:

```dart
        writer.addEntry(
          headingId: writer.headingId(term: term, reading: reading),
          definitions: definitions,
          popularity: popularity,
          entryTagNames: entryTagNames,
          headingTagNames: headingTagNames,
        );

        n++;
        params.send(t.import_write_entry(
          count: n,
          total: total,
        ));
```

and the `kanji_bank` loop's `if (definition.isNotEmpty) { ... }` block becomes:

```dart
        if (definition.isNotEmpty) {
          writer.addEntry(
            headingId: writer.headingId(term: term, reading: ''),
            definitions: [definition],
            popularity: 0,
            headingTagNames: headingTagNames,
          );

          n++;
          params.send(t.import_write_entry(
            count: n,
            total: total,
          ));
        }
```

In `prepareTagsYomichanFormat`, the loop body after `popularity` is computed becomes:

```dart
      writer.addTag(
        name: name,
        category: category,
        sortingOrder: sortingOrder,
        notes: notes,
        popularity: popularity,
      );

      n++;
      params.send(t.import_write_tag(
        count: n,
        total: count,
      ));
```

In `preparePitchesYomichanFormat`, the `if (type == 'pitch') { ... }` block becomes:

```dart
      if (type == 'pitch') {
        Map<String, dynamic> data = Map<String, dynamic>.from(item[2]);
        String reading = data['reading'] ?? '';
        int headingId = writer.headingId(term: term, reading: reading);

        List<Map<String, dynamic>> distinctPitchJsons =
            List<Map<String, dynamic>>.from(data['pitches']);
        for (Map<String, dynamic> distinctPitch in distinctPitchJsons) {
          int downstep = distinctPitch['position'];
          writer.addPitch(headingId: headingId, downstep: downstep);
        }
      } else {
        continue;
      }
```

In `prepareFrequenciesYomichanFormat`, the frequency's word was a hashed heading id; it becomes a reading. Replace the `if (type == 'freq') { ... }` block with:

```dart
      if (type == 'freq') {
        String? reading;
        late double value;
        late String? displayValue;

        if (item[2] is double) {
          double number = item[2] as double;

          reading = '';
          value = number;
          displayValue =
              (number % 1 == 0) ? number.toInt().toString() : number.toString();
        } else if (item[2] is int) {
          int number = item[2] as int;
          reading = '';
          value = number.toDouble();
          displayValue = number.toString();
        } else if (item[2] is Map) {
          Map<String, dynamic> data = Map<String, dynamic>.from(item[2]);

          if (data['reading'] != null && data['frequency'] is Map) {
            Map<String, dynamic> frequencyData =
                Map<String, dynamic>.from(data['frequency']);

            reading = data['reading'] ?? '';

            num number = frequencyData['value'] ?? 0;

            value = number.toDouble();
            displayValue = frequencyData['displayValue'];
          } else if (data['displayValue'] != null) {
            reading = data['reading'] ?? '';

            num number = data['value'] ?? 0;

            value = number.toDouble();
            displayValue = data['displayValue'];
          } else if (data['value'] != null) {
            reading = data['reading'] ?? '';

            num number = data['value'] ?? 0;

            value = number.toDouble();
            displayValue = number.toInt().toString();
          } else if (data['frequency'] is num) {
            num frequencyValue = data['frequency'];
            reading = data['reading'] ?? '';

            value = frequencyValue.toDouble();
            displayValue = (frequencyValue % 1 == 0)
                ? frequencyValue.toInt().toString()
                : frequencyValue.toDouble().toString();
          }
        } else {
          reading = '';

          value = 0;
          displayValue = item[2].toString();
        }

        if (reading != null) {
          writer.addFrequency(
            headingId: writer.headingId(term: term, reading: reading),
            value: value,
            displayValue: displayValue ?? '',
          );

          n++;
          params.send(t.import_write_frequency(count: n, total: count));
        }
      } else {
        continue;
      }
```

Remove any import that becomes unused.

- [ ] **Step 6: Port the Migaku format**

In `lib/src/dictionary/formats/migaku_dictionary_format.dart`, replace the Isar import with `import 'package:yuuna/database.dart';`. `prepareEntriesMigakuFormat` becomes `void prepareEntriesMigakuFormat({required PrepareDictionaryParams params, required DictionaryImportWriter writer}) {` (no `async`), and in its loop everything from `int headingId = DictionaryHeading.hash(...)` through `isar.dictionaryHeadings.putSync(heading);` becomes:

```dart
      writer.addEntry(
        headingId: writer.headingId(term: term, reading: reading),
        definitions: [definition],
        popularity: 0,
      );
```

The three empty functions become `void prepareTagsMigakuFormat({required PrepareDictionaryParams params, required DictionaryImportWriter writer}) {}` and likewise for pitches and frequencies (no `async`).

- [ ] **Step 7: Import and delete entry points**

In `lib/src/dictionary/dictionary_utils.dart`, add `import 'package:sqlite3/sqlite3.dart' show Database;` and `import 'package:yuuna/database.dart';`, and replace `depositDictionaryDataHelper`, `deleteDictionariesHelper` and `deleteDictionaryHelper` with:

```dart
/// Import the dictionary described by [params] in one transaction, and
/// return its new id. On failure nothing is written. Top-level for
/// `compute`.
Future<int> depositDictionaryDataHelper(PrepareDictionaryParams params) async {
  Database database = openRawDatabase(params.databasePath);
  try {
    database.execute('BEGIN IMMEDIATE');
    try {
      database.execute(
        'INSERT INTO dictionary (name, format_key, "order") VALUES '
        '(?, ?, (SELECT COALESCE(MAX("order"), 0) + 1 FROM dictionary))',
        [params.dictionaryName, params.dictionaryFormat.uniqueKey],
      );
      int dictionaryId = database.lastInsertRowId;

      DictionaryImportWriter writer = DictionaryImportWriter(
        database: database,
        dictionaryId: dictionaryId,
      );
      try {
        params.dictionaryFormat.prepareTags(params: params, writer: writer);
        params.dictionaryFormat.prepareEntries(params: params, writer: writer);
        params.dictionaryFormat.preparePitches(params: params, writer: writer);
        params.dictionaryFormat
            .prepareFrequencies(params: params, writer: writer);
      } finally {
        writer.close();
      }

      database.execute('COMMIT');
      return dictionaryId;
    } catch (_) {
      database.execute('ROLLBACK');
      rethrow;
    }
  } catch (e, stack) {
    debugPrint('$e');
    debugPrint('$stack');

    params.send('$stack');

    rethrow;
  } finally {
    database.close();
  }
}

/// Clears all data from the dictionary database.
Future<void> deleteDictionariesHelper(DeleteDictionaryParams params) async {
  AppDatabase database = AppDatabase.open(params.databasePath);
  try {
    await deleteAllDictionaryData(database);
  } finally {
    await database.close();
  }
}

/// Clears single dictionary data from the dictionary database.
Future<void> deleteDictionaryHelper(DeleteDictionaryParams params) async {
  AppDatabase database = AppDatabase.open(params.databasePath);
  try {
    await deleteDictionaryData(database, params.dictionaryId!);
  } finally {
    await database.close();
  }
}
```

Run the new tests: `flutter test test/dictionary/dictionary_utils_test.dart`. Expected: PASS once `AppModel` compiles (next steps). If the analyzer complains here about `AppModel`, carry on to Step 9 first.

- [ ] **Step 8: Dictionary list in the store**

Append to `AppStore` (add `import 'package:yuuna/dictionary.dart';`):

```dart
  /// The imported dictionaries, in the user's order.
  List<Dictionary> dictionaries() {
    return _select(
        db.dictionaries.map, 'SELECT * FROM dictionary ORDER BY "order"');
  }

  /// Save [dictionary]'s hidden and collapsed flags.
  Future<void> updateDictionaryFlags(Dictionary dictionary) async {
    await (db.update(db.dictionaries)
          ..where((table) => table.id.equals(dictionary.id)))
        .write(
      DictionariesCompanion(
        isHidden: Value(dictionary.isHidden),
        isCollapsed: Value(dictionary.isCollapsed),
      ),
    );
  }

  /// Save the order of [dictionaries], whose `order` fields hold their new
  /// positions. Positions are unique, so they pass through negative values
  /// first.
  Future<void> reorderDictionaries(List<Dictionary> dictionaries) async {
    await db.transaction(() async {
      for (Dictionary dictionary in dictionaries) {
        await _setDictionaryOrder(dictionary.id, -1 - dictionary.order);
      }
      for (Dictionary dictionary in dictionaries) {
        await _setDictionaryOrder(dictionary.id, dictionary.order);
      }
    });
  }

  Future<void> _setDictionaryOrder(int id, int order) async {
    await (db.update(db.dictionaries)..where((table) => table.id.equals(id)))
        .write(DictionariesCompanion(order: Value(order)));
  }
```

- [ ] **Step 9: `AppModel`**

In `lib/src/models/app_model.dart`:

1. Leave `globalSchemas` alone: the Isar search still queries the dictionary collections until Task 8.
2. `dictionaries`:

```dart
  /// Returns all dictionaries imported into the database. Sorted by the
  /// user-defined order in the dictionary menu.
  List<Dictionary> get dictionaries => _store.dictionaries();
```

3. Replace `updateDictionaryOrder`, `toggleDictionaryCollapsed` and `toggleDictionaryHidden`:

```dart
  /// Update the user-defined order of a given dictionary in the database.
  /// See the dictionary dialog's [ReorderableListView] for usage.
  Future<void> updateDictionaryOrder(List<Dictionary> newDictionaries) =>
      _store.reorderDictionaries(newDictionaries);
```

```dart
  /// Toggle a dictionary's between collapsed and expanded state. This will
  /// affect how a dictionary's search results are shown by default.
  Future<void> toggleDictionaryCollapsed(Dictionary dictionary) async {
    dictionary.isCollapsed = !dictionary.isCollapsed;
    await _store.updateDictionaryFlags(dictionary);
  }

  /// Toggle a dictionary's between hidden and shown state. This will
  /// affect how a dictionary's search results are shown by default.
  Future<void> toggleDictionaryHidden(Dictionary dictionary) async {
    dictionary.isHidden = !dictionary.isHidden;
    await _store.updateDictionaryFlags(dictionary);
  }
```

4. In `importDictionary`, replace the whole `try { ... } catch (e) { ... }` (keep the `finally { receivePort.close(); }`) with:

```dart
    Directory stagingDirectory =
        Directory(path.join(dictionaryResourceDirectory.path, 'importing'));
    try {
      if (stagingDirectory.existsSync()) {
        stagingDirectory.deleteSync(recursive: true);
      }
      stagingDirectory.createSync(recursive: true);

      PrepareDirectoryParams prepareDirectoryParams = PrepareDirectoryParams(
        file: file,
        directoryPath: _databaseDirectory.path,
        databasePath: databasePath,
        resourceDirectory: stagingDirectory,
        dictionaryFormat: dictionaryFormat,
        sendPort: receivePort.sendPort,
      );

      progressNotifier.value = t.import_extract;
      await dictionaryFormat.prepareDirectory(prepareDirectoryParams);

      String name = await dictionaryFormat.prepareName(prepareDirectoryParams);
      progressNotifier.value = t.import_name(name: name);

      if (dictionaries.any((dictionary) => dictionary.name == name)) {
        throw Exception(t.import_duplicate(name: name));
      }

      PrepareDictionaryParams prepareDictionaryParams = PrepareDictionaryParams(
        dictionaryName: name,
        dictionaryFormat: dictionaryFormat,
        resourceDirectory: stagingDirectory,
        directoryPath: _databaseDirectory.path,
        databasePath: databasePath,
        sendPort: receivePort.sendPort,
        alertSendPort: alertReceivePort.sendPort,
      );

      int id = await compute(depositDictionaryDataHelper, prepareDictionaryParams);

      Directory resourceDirectory =
          Directory(path.join(dictionaryResourceDirectory.path, '$id'));
      if (resourceDirectory.existsSync()) {
        resourceDirectory.deleteSync(recursive: true);
      }
      stagingDirectory.renameSync(resourceDirectory.path);

      progressNotifier.value = t.import_complete;
      onImportSuccess();
      await Future.delayed(const Duration(seconds: 1), () {});
    } catch (e) {
      if (stagingDirectory.existsSync()) {
        stagingDirectory.deleteSync(recursive: true);
      }
      progressNotifier.value = '$e';
      await Future.delayed(const Duration(seconds: 3), () {});
      progressNotifier.value = t.import_failed;
      await Future.delayed(const Duration(seconds: 1), () {});
    }
```

5. In `deleteDictionaries` and `deleteDictionary`, add `databasePath: databasePath,` to each `DeleteDictionaryParams(...)`.
6. In `searchDictionary`, add `databasePath: databasePath,` to `DictionarySearchParams(...)`.

- [ ] **Step 10: The dictionary dialog awaits its writes**

In `lib/src/pages/implementations/dictionary_dialog_page.dart`:
- both popup `action:` closures become `async` and `await` their toggle before flipping the notifier: `action: () async { await appModel.toggleDictionaryCollapsed(dictionary); ... }` and likewise for `toggleDictionaryHidden`;
- `onReorder: (oldIndex, newIndex) { ... }` becomes `onReorder: (oldIndex, newIndex) async { ... }` and `appModel.updateDictionaryOrder(cloneDictionaries);` becomes `await appModel.updateDictionaryOrder(cloneDictionaries);`, before the existing `setState(() {});`. If `flutter analyze` asks for it, add `if (!mounted) { return; }` after the `await`.

- [ ] **Step 11: Full verification**

```sh
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
```

Expected: no issues; all tests pass, including `test/dictionary/dictionary_utils_test.dart`.

- [ ] **Step 12: Commit**

```sh
jj status
jj commit -m "Import and delete dictionaries through Drift

Lookups still read Isar until the next change, so they find nothing
in between.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 8: Lookups on Drift

**Files:**
- Create: `lib/src/database/heading_loader.dart`, `test/database/heading_loader_test.dart`, `test/language/japanese_search_test.dart`
- Rewrite: `lib/src/dictionary/dictionary.dart`, `dictionary_heading.dart`, `dictionary_entry.dart`, `dictionary_pitch.dart`, `dictionary_frequency.dart`, `dictionary_tag.dart`, `dictionary_search_result.dart` (delete their `.g.dart` parts)
- Modify: `lib/src/language/implementations/japanese_language.dart`, `lib/src/dictionary/dictionary_utils.dart`, `lib/src/dictionary/dictionary_operations_params.dart`
- Modify: `lib/src/models/app_model.dart`, `lib/src/database/app_store.dart`, `test/database/app_store_test.dart`, `lib/src/media/stash_item.dart`
- Modify (pages and fields): `dictionary_history_page.dart`, `dictionary_result_page.dart`, `dictionary_term_page.dart`, `dictionary_entry_page.dart`, `dictionary_structured_content_page.dart`, `home_dictionary_page.dart`, `recursive_dictionary_page.dart`, `stash_page.dart`, `stash_item_page.dart`, `lib/src/pages/base_source_page.dart`, `lib/src/creator/fields/{meaning,hidden_meaning,expanded_meaning,collapsed_meaning,frequency,pitch_accent}_field.dart`, `lib/src/creator/actions/{share,add_to_stash}_action.dart`

**Interfaces:**
- Consumes: Task 6's queries; `writeTestDictionary` (Task 5); `AppStore._addRecentTerm` (Task 4).
- Produces: `Future<List<DictionaryHeading>> loadHeadings(AppDatabase database, List<int> headingIds)`; `Future<DictionarySearchResult?> searchDictionaryJapanese({required AppDatabase database, required String query, required int maximumHeadings, required int maximumTerms, required bool searchWithWildcards})`; `prepareSearchResultsJapaneseLanguage` returns `Future<DictionarySearchResult?>`; `DictionarySearchResult({required String searchTerm, int bestLength = 0, List<DictionaryHeading> headings = const []})`; `typedef ResolvedStashItem = ({DictionaryHeading heading, DictionaryEntry? entry, bool found})`; `AppModel.resolveStashItem` returns `Future<ResolvedStashItem>`; `AppModel.dictionaryHistory` is `List<String>`; `AppStore.dictionaryHistory()`, `addToDictionaryHistory(String, {required int maximum})`, `clearDictionaryHistory()`. Models: `DictionaryHeading({required String term, String reading = '', int? id})` with `entries`, `pitches`, `frequencies`, `tags`, `noReadingFrequencies` lists; `DictionaryEntry({required int id, required List<String> definitions, required double popularity, required Dictionary dictionary})` with `late final DictionaryHeading heading` and `tags`; `DictionaryPitch({required int id, required int downstep, required Dictionary dictionary})`; `DictionaryFrequency({required int id, required double value, required String displayValue, required Dictionary dictionary})`; `DictionaryTag({required int id, required int dictionaryId, required String name, required String category, required int sortingOrder, required String notes, required double popularity})`.

- [ ] **Step 1: Rewrite the dictionary models**

`lib/src/dictionary/dictionary.dart`: delete the Isar import, the `part` directive, `@Collection()`, the `@Index(...)` lines and the four `@Backlink` `IsarLinks` fields with their docs; change `final Id id;` to `final int id;`. Keep everything else.

`lib/src/dictionary/dictionary_heading.dart`:

```dart
import 'package:collection/collection.dart';
import 'package:yuuna/dictionary.dart';

/// A word: a term and its reading, shared by every dictionary that has
/// something to say about it. Built fully loaded by `loadHeadings`.
class DictionaryHeading {
  /// Create a heading. [id] is null for a stand-in that is not in the
  /// database.
  DictionaryHeading({
    required this.term,
    this.reading = '',
    this.id,
  });

  /// The database id; null for a stand-in.
  final int? id;

  /// The word as written.
  final String term;

  /// The word's reading; empty for kanji entries and words given no reading.
  final String reading;

  /// Entries for this word, one or more per dictionary defining it.
  final List<DictionaryEntry> entries = [];

  /// Pitch accents of this word.
  final List<DictionaryPitch> pitches = [];

  /// Frequencies of this word.
  final List<DictionaryFrequency> frequencies = [];

  /// Tags on this word as a whole.
  final List<DictionaryTag> tags = [];

  /// Frequencies that frequency dictionaries give for [term] without a
  /// reading. Empty when [reading] is empty: those are [frequencies].
  final List<DictionaryFrequency> noReadingFrequencies = [];

  /// The sum of the popularity of this word's entries.
  double get popularitySum {
    return entries.map((entry) => entry.popularity).sum;
  }

  @override
  bool operator ==(Object other) =>
      other is DictionaryHeading &&
      term == other.term &&
      reading == other.reading;

  @override
  int get hashCode => term.hashCode * reading.hashCode;
}
```

`lib/src/dictionary/dictionary_entry.dart`:

```dart
import 'package:yuuna/dictionary.dart';

/// One dictionary's definitions of a [DictionaryHeading].
class DictionaryEntry {
  /// Create an entry of [dictionary]. The loader sets [heading].
  DictionaryEntry({
    required this.id,
    required this.definitions,
    required this.popularity,
    required this.dictionary,
  });

  /// The database id.
  final int id;

  /// The definitions: plain text, or a structured content JSON document.
  final List<String> definitions;

  /// The dictionary's popularity score for this entry; higher is commoner.
  final double popularity;

  /// The dictionary giving the definitions.
  final Dictionary dictionary;

  /// The heading this entry defines.
  late final DictionaryHeading heading;

  /// Tags on this entry.
  final List<DictionaryTag> tags = [];

  /// The definitions as one text: bulleted lines when there are several.
  String get compactDefinitions {
    if (definitions.length > 1) {
      return definitions
          .map((definition) => '• ${definition.trim()}')
          .join('\n');
    }

    return definitions.join().trim();
  }

  @override
  bool operator ==(Object other) => other is DictionaryEntry && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

Before replacing `dictionary_entry.dart`, compare `compactDefinitions` with the current one and keep the current body if it differs from the above.

`lib/src/dictionary/dictionary_pitch.dart`:

```dart
import 'package:yuuna/dictionary.dart';

/// A pitch accent of a heading, from a pitch dictionary.
class DictionaryPitch {
  /// Create a pitch accent from [dictionary].
  DictionaryPitch({
    required this.id,
    required this.downstep,
    required this.dictionary,
  });

  /// The database id.
  final int id;

  /// The mora after which the pitch drops; 0 for a flat pattern.
  final int downstep;

  /// The pitch dictionary it comes from.
  final Dictionary dictionary;

  @override
  bool operator ==(Object other) => other is DictionaryPitch && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

`lib/src/dictionary/dictionary_frequency.dart`:

```dart
import 'package:yuuna/dictionary.dart';

/// A frequency rank of a heading, from a frequency dictionary.
class DictionaryFrequency {
  /// Create a frequency from [dictionary].
  DictionaryFrequency({
    required this.id,
    required this.value,
    required this.displayValue,
    required this.dictionary,
  });

  /// The database id.
  final int id;

  /// The rank, for sorting; lower is more frequent.
  final double value;

  /// The rank as the dictionary displays it.
  final String displayValue;

  /// The frequency dictionary it comes from.
  final Dictionary dictionary;

  @override
  bool operator ==(Object other) =>
      other is DictionaryFrequency && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

`lib/src/dictionary/dictionary_tag.dart`: replace everything except the `color` getter and its doc comment (keep that getter's body exactly) with:

```dart
import 'package:flutter/material.dart';

/// A label a dictionary defines, on its entries or on headings.
class DictionaryTag {
  /// Create a tag of the dictionary [dictionaryId].
  DictionaryTag({
    required this.id,
    required this.dictionaryId,
    required this.name,
    required this.category,
    required this.sortingOrder,
    required this.notes,
    required this.popularity,
  });

  /// The database id.
  final int id;

  /// The dictionary defining the tag.
  final int dictionaryId;

  /// The short label, such as `v1` or `P`.
  final String name;

  /// The kind of tag; picks its colour.
  final String category;

  /// Display order among tags.
  final int sortingOrder;

  /// What the label means.
  final String notes;

  /// The dictionary's score for the tag.
  final double popularity;

  // <the existing `color` getter, unchanged>

  @override
  bool operator ==(Object other) => other is DictionaryTag && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
```

(Keep whatever `package:flutter/...` import the `color` getter needed; `Color` comes from `package:flutter/material.dart` or `painting.dart`.) The unused `DictionaryTag.dictionary` factory and `hash` go.

`lib/src/dictionary/dictionary_search_result.dart`:

```dart
import 'package:yuuna/dictionary.dart';

/// The headings found for a search term, best first.
class DictionarySearchResult {
  /// Create a result. Empty [headings] mean nothing was found.
  DictionarySearchResult({
    required this.searchTerm,
    this.bestLength = 0,
    this.headings = const [],
  });

  /// The term searched.
  final String searchTerm;

  /// How many leading characters of [searchTerm] matched, for highlighting
  /// the selected word.
  final int bestLength;

  /// The headings found, fully loaded, best first.
  final List<DictionaryHeading> headings;
}
```

Delete the Isar part files:

```sh
rm -f lib/src/dictionary/dictionary.g.dart lib/src/dictionary/dictionary_heading.g.dart lib/src/dictionary/dictionary_entry.g.dart lib/src/dictionary/dictionary_pitch.g.dart lib/src/dictionary/dictionary_frequency.g.dart lib/src/dictionary/dictionary_tag.g.dart lib/src/dictionary/dictionary_search_result.g.dart
```

- [ ] **Step 2: Write the loader tests `test/database/heading_loader_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';

import 'test_database.dart';

void main() {
  late TestDatabase database;
  late int neko;
  late int inu;

  setUp(() async {
    database = await openTestDatabase();
    writeTestDictionary(database.raw, 'JMdict', (writer) {
      writer
        ..addTag(
            name: 'n',
            category: 'partOfSpeech',
            sortingOrder: 0,
            notes: 'noun',
            popularity: 0)
        ..addTag(
            name: 'P',
            category: 'popular',
            sortingOrder: -1,
            notes: 'popular',
            popularity: 10);
      neko = writer.headingId(term: '猫', reading: 'ねこ');
      inu = writer.headingId(term: '犬', reading: 'いぬ');
      writer
        ..addEntry(
            headingId: neko,
            definitions: ['cat'],
            popularity: 2,
            entryTagNames: ['n'],
            headingTagNames: ['P'])
        ..addEntry(headingId: inu, definitions: ['dog'], popularity: 1)
        ..addPitch(headingId: neko, downstep: 1);
    });
    writeTestDictionary(database.raw, 'Freq', (writer) {
      writer
        ..addFrequency(
            headingId: writer.headingId(term: '猫', reading: 'ねこ'),
            value: 10,
            displayValue: '10')
        ..addFrequency(
            headingId: writer.headingId(term: '猫', reading: ''),
            value: 20,
            displayValue: '20');
    });
  });

  tearDown(() => database.db.close());

  test('loads everything a heading links to, in the requested order',
      () async {
    List<DictionaryHeading> headings =
        await loadHeadings(database.db, [inu, neko, 999]);

    expect(headings.map((heading) => heading.term), ['犬', '猫']);

    DictionaryHeading cat = headings.last;
    DictionaryEntry entry = cat.entries.single;
    expect(entry.definitions, ['cat']);
    expect(entry.dictionary.name, 'JMdict');
    expect(entry.heading, same(cat));
    expect(entry.tags.map((tag) => tag.name), ['n']);
    expect(cat.tags.map((tag) => tag.name), ['P']);
    expect(cat.pitches.single.downstep, 1);
    expect(cat.frequencies.single.displayValue, '10');
    expect(cat.frequencies.single.dictionary.name, 'Freq');
    expect(cat.noReadingFrequencies.single.displayValue, '20');
    expect(cat.popularitySum, 2);
  });

  test('loads nothing for no ids', () async {
    expect(await loadHeadings(database.db, []), isEmpty);
  });
}
```

- [ ] **Step 3: Write the search tests `test/language/japanese_search_test.dart`**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';
import 'package:yuuna/language.dart';

import '../database/test_database.dart';

void main() {
  late TestDatabase database;

  setUp(() async {
    database = await openTestDatabase();
    writeTestDictionary(database.raw, 'JMdict', (writer) {
      writer.addTag(
          name: 'P',
          category: 'popular',
          sortingOrder: -1,
          notes: 'popular',
          popularity: 10);
      for ((String, String, double, bool) word in [
        ('食べる', 'たべる', 5, false),
        ('食べ物', 'たべもの', 3, false),
        ('食', 'しょく', 1, false),
        ('テスト', 'てすと', 1, false),
        ('生', '', 0, false),
        ('生', 'なま', 2, false),
        ('上手', 'じょうず', 1, true),
        ('上手', 'うわて', 5, false),
        ('方', 'かた', 1, false),
        ('方', 'ほう', 1, false),
        ('𠮟る', 'しかる', 1, false),
      ]) {
        writer.addEntry(
          headingId: writer.headingId(term: word.$1, reading: word.$2),
          definitions: ['${word.$1} meaning'],
          popularity: word.$3,
          headingTagNames: word.$4 ? ['P'] : [],
        );
      }
    });
    writeTestDictionary(database.raw, 'Freq', (writer) {
      writer
        ..addFrequency(
            headingId: writer.headingId(term: '方', reading: 'かた'),
            value: 50,
            displayValue: '50')
        ..addFrequency(
            headingId: writer.headingId(term: '方', reading: 'ほう'),
            value: 10,
            displayValue: '10');
    });
  });

  tearDown(() => database.db.close());

  Future<DictionarySearchResult?> search(
    String query, {
    bool wildcards = false,
    int maximumTerms = 10,
  }) {
    return searchDictionaryJapanese(
      database: database.db,
      query: query,
      maximumHeadings: 200,
      maximumTerms: maximumTerms,
      searchWithWildcards: wildcards,
    );
  }

  List<String> words(DictionarySearchResult? result) => result!.headings
      .map((heading) => '${heading.term}/${heading.reading}')
      .toList();

  test('finds a word from its inflected form', () async {
    DictionarySearchResult? result = await search('食べた');

    expect(words(result).first, '食べる/たべる');
    expect(result!.bestLength, 3);
  });

  test('finds a katakana word from its hiragana reading', () async {
    expect(words(await search('てすと')).first, 'テスト/てすと');
  });

  test('puts the kanji entry first for a single kanji', () async {
    expect(words(await search('生')), ['生/', '生/なま']);
  });

  test('ranks the reading tagged popular first', () async {
    expect(words(await search('上手')), ['上手/じょうず', '上手/うわて']);
  });

  test('ranks by frequency when the words share a term', () async {
    expect(words(await search('方')), ['方/ほう', '方/かた']);
  });

  test('adds longer words starting with the term, shortest first', () async {
    expect(words(await search('食', wildcards: true)),
        ['食/しょく', '食べる/たべる', '食べ物/たべもの']);
    expect(words(await search('食', wildcards: true, maximumTerms: 2)),
        ['食/しょく', '食べる/たべる']);
  });

  test('wildcards: ？ is one character, ※ any number', () async {
    expect(words(await search('食？？', wildcards: true)).toSet(),
        {'食べる/たべる', '食べ物/たべもの'});
    expect(words(await search('食※', wildcards: true)).toSet(),
        {'食/しょく', '食べる/たべる', '食べ物/たべもの'});
  });

  test('wildcards count characters outside the BMP as one', () async {
    expect(words(await search('𠮟？', wildcards: true)), ['𠮟る/しかる']);
  });

  test('a GLOB metacharacter in the selection does not break the search',
      () async {
    expect(await search('[*', wildcards: true), isNull);
    expect(await search('a[b'), isNull);
  });

  test('returns null when nothing matches', () async {
    expect(await search('ぬぬぬぬ'), isNull);
  });
}
```

- [ ] **Step 4: Run them to see them fail**

Run: `flutter test test/database/heading_loader_test.dart test/language/japanese_search_test.dart`
Expected: compilation fails (`loadHeadings`, `searchDictionaryJapanese` undefined; the Isar search and `AppModel` no longer compile against the new models, which the next steps fix).

- [ ] **Step 5: Write `lib/src/database/heading_loader.dart`**

```dart
import 'package:collection/collection.dart';
import 'package:yuuna/database.dart';
import 'package:yuuna/dictionary.dart';

/// Load the headings with these [headingIds], fully: entries with their
/// dictionaries and tags, pitches, frequencies, heading tags, and the
/// frequencies given for each term without a reading. Returns them in the
/// order of [headingIds]; ids with no heading are skipped. Usable from any
/// isolate.
Future<List<DictionaryHeading>> loadHeadings(
  AppDatabase database,
  List<int> headingIds,
) async {
  if (headingIds.isEmpty) {
    return [];
  }

  Map<int, Dictionary> dictionariesById = {
    for (Dictionary dictionary in await database.allDictionaries().get())
      dictionary.id: dictionary,
  };

  Map<int, DictionaryHeading> headingsById = {
    for (HeadingRow row in await database.headingsByIds(ids: headingIds).get())
      row.id: DictionaryHeading(
        id: row.id,
        term: row.term,
        reading: row.reading,
      ),
  };
  List<int> ids = headingsById.keys.toList();

  Map<int, DictionaryEntry> entriesById = {};
  for (EntryRow row in await database.entriesByHeadings(ids: ids).get()) {
    DictionaryHeading heading = headingsById[row.headingId]!;
    DictionaryEntry entry = DictionaryEntry(
      id: row.id,
      definitions: row.definitions,
      popularity: row.popularity,
      dictionary: dictionariesById[row.dictionaryId]!,
    )..heading = heading;
    heading.entries.add(entry);
    entriesById[row.id] = entry;
  }

  for (PitchRow row in await database.pitchesByHeadings(ids: ids).get()) {
    headingsById[row.headingId]!.pitches.add(DictionaryPitch(
          id: row.id,
          downstep: row.downstep,
          dictionary: dictionariesById[row.dictionaryId]!,
        ));
  }

  for (FrequencyRow row
      in await database.frequenciesByHeadings(ids: ids).get()) {
    headingsById[row.headingId]!
        .frequencies
        .add(_frequency(row, dictionariesById));
  }

  for (HeadingTagsByHeadingsResult row
      in await database.headingTagsByHeadings(ids: ids).get()) {
    headingsById[row.ownerId]!.tags.add(_tag(row.tag));
  }

  for (EntryTagsByEntriesResult row in await database
      .entryTagsByEntries(ids: entriesById.keys.toList())
      .get()) {
    entriesById[row.ownerId]!.tags.add(_tag(row.tag));
  }

  Map<String, List<DictionaryHeading>> headingsWithReadingByTerm = groupBy(
    headingsById.values.where((heading) => heading.reading.isNotEmpty),
    (heading) => heading.term,
  );
  for (NoReadingFrequenciesResult row in await database
      .noReadingFrequencies(terms: headingsWithReadingByTerm.keys.toList())
      .get()) {
    for (DictionaryHeading heading in headingsWithReadingByTerm[row.term]!) {
      heading.noReadingFrequencies
          .add(_frequency(row.frequency, dictionariesById));
    }
  }

  return headingIds.map((id) => headingsById[id]).nonNulls.toList();
}

DictionaryFrequency _frequency(
  FrequencyRow row,
  Map<int, Dictionary> dictionariesById,
) {
  return DictionaryFrequency(
    id: row.id,
    value: row.value,
    displayValue: row.displayValue,
    dictionary: dictionariesById[row.dictionaryId]!,
  );
}

DictionaryTag _tag(TagRow row) {
  return DictionaryTag(
    id: row.id,
    dictionaryId: row.dictionaryId,
    name: row.name,
    category: row.category,
    sortingOrder: row.sortingOrder,
    notes: row.notes,
    popularity: row.popularity,
  );
}
```

Add `export 'src/database/heading_loader.dart';` to `lib/database.dart`.

- [ ] **Step 6: Port the search**

In `lib/src/language/implementations/japanese_language.dart`, replace `import 'package:isar_community/isar.dart';` with `import 'package:yuuna/database.dart';`, then replace the whole `prepareSearchResultsJapaneseLanguage` function (from its doc comment to its closing brace, just before `/// Rules for word deinflection.`) with:

```dart
/// Top-level function for use in compute, running a dictionary search on a
/// connection of its own. Credits to Matthew Chan for their port of the
/// Yomichan parser to Dart.
Future<DictionarySearchResult?> prepareSearchResultsJapaneseLanguage(
    DictionarySearchParams params) async {
  AppDatabase database = AppDatabase.open(params.databasePath);
  DictionarySearchResult? result;
  try {
    result = await searchDictionaryJapanese(
      database: database,
      query: params.searchTerm,
      maximumHeadings: params.maximumDictionarySearchResults,
      maximumTerms: params.maximumDictionaryTermsInResult,
      searchWithWildcards: params.searchWithWildcards,
    );
  } finally {
    await database.close();
  }
  return result;
}

/// No upper bound on a word's length, for wildcard searches.
const int _unboundedLength = 1 << 30;

/// Search [database] for [query]: the heading lookup behind
/// [prepareSearchResultsJapaneseLanguage], usable on any connection. Finds at
/// most [maximumTerms] headings, ranked, fully loaded; [maximumHeadings]
/// bounds each intermediate query. Returns null when nothing is found.
Future<DictionarySearchResult?> searchDictionaryJapanese({
  required AppDatabase database,
  required String query,
  required int maximumHeadings,
  required int maximumTerms,
  required bool searchWithWildcards,
}) async {
  int bestLength = 0;
  String searchTerm = query.trim();
  const KanaKit kanaKit = KanaKit();
  if (kanaKit.isRomaji(searchTerm)) {
    searchTerm = kanaKit.toHiragana(searchTerm);
  }

  if (searchTerm.length > 20) {
    searchTerm = searchTerm.substring(0, 20);
  }

  if (searchTerm.isEmpty) {
    return null;
  }

  Map<int, HeadingRow> uniqueHeadingsById = {};

  int limit() {
    return maximumHeadings - uniqueHeadingsById.length;
  }

  void addHeadings(List<HeadingRow> rows) {
    uniqueHeadingsById.addEntries(rows.map((row) => MapEntry(row.id, row)));
  }

  bool shouldSearchWildcards = searchWithWildcards &&
      (searchTerm.contains('※') ||
          searchTerm.contains('？') ||
          searchTerm.contains('*') ||
          searchTerm.contains('?'));

  if (shouldSearchWildcards) {
    bool noExactMatches =
        await database.headingCountByTerm(term: searchTerm).getSingle() == 0;

    if (noExactMatches) {
      /// GLOB's wildcards are * and ?, each ? one character. A [ would open
      /// a character class, so it is escaped as [[].
      String matchesTerm =
          searchTerm.replaceAll('※', '*').replaceAll('？', '?');
      String pattern = matchesTerm.replaceAll('[', '[[]');

      String withoutWildcards =
          matchesTerm.replaceAll('?', '').replaceAll('*', '');
      bool matchTermIsKana = kanaKit.isKana(withoutWildcards);
      bool matchTermIsKatakana = kanaKit.isKatakana(withoutWildcards);
      bool questionMarkOnly = !matchesTerm.contains('*');

      /// SQLite's length() counts characters, not UTF-16 code units.
      int length = matchesTerm.runes.length;
      int minimumLength = matchesTerm.replaceAll('*', '').runes.length;

      if (maximumTerms > uniqueHeadingsById.length) {
        addHeadings(await database
            .headingsByTermGlob(
              pattern: pattern,
              minimumLength: questionMarkOnly ? length : minimumLength,
              maximumLength: questionMarkOnly ? length : _unboundedLength,
              limit: limit(),
            )
            .get());
      }

      if (maximumTerms > uniqueHeadingsById.length && matchTermIsKana) {
        addHeadings(await database
            .headingsByReadingGlob(
              pattern: pattern,
              alternativePattern:
                  matchTermIsKatakana ? kanaKit.toHiragana(pattern) : pattern,
              limit: limit(),
            )
            .get());
      }
    }
  } else {
    List<String> deinflectionsAlreadySearched = [];

    bool startsWithAdded = false;
    for (int i = 0; i < searchTerm.length; i++) {
      String partialTerm = searchTerm.substring(0, searchTerm.length - i);

      bool partialTermIsKana = kanaKit.isKana(partialTerm);
      bool partialTermIsHiragana = kanaKit.isHiragana(partialTerm);
      bool partialTermIsKatakana = kanaKit.isKatakana(partialTerm);

      List<String> possibleDeinflections = Deinflector.deinflect(partialTerm)
          .map((e) => e.term)
          .where((e) => !deinflectionsAlreadySearched.contains(e))
          .toList();
      possibleDeinflections.toSet().addAll(deinflectionsAlreadySearched);

      List<String> hiraganaDeinflections = partialTermIsKatakana
          ? Deinflector.deinflect(kanaKit.toHiragana(partialTerm))
              .map((e) => e.term)
              .toList()
          : [];

      List<HeadingRow> termExactResults = [];
      List<HeadingRow> termDeinflectedResults = [];
      List<HeadingRow> readingExactResults = [];
      List<HeadingRow> readingDeinflectedResults = [];
      List<HeadingRow> termExactKatakanaResults = [];

      if (maximumTerms > uniqueHeadingsById.length) {
        termExactResults = await database.headingsByTerms(terms: [
          partialTerm,
          if (partialTermIsKatakana) kanaKit.toHiragana(partialTerm),
        ]).get();
        addHeadings(termExactResults);
      }

      if (maximumTerms > uniqueHeadingsById.length && partialTermIsKana) {
        readingExactResults = await database.headingsByReadings(
          readings: [
            partialTerm,
            if (partialTermIsKatakana) kanaKit.toHiragana(partialTerm),
          ],
          limit: limit(),
        ).get();
        addHeadings(readingExactResults);
      }

      if (maximumTerms > uniqueHeadingsById.length) {
        termDeinflectedResults = await database.headingsByTermsByPopularity(
          terms: [...possibleDeinflections, ...hiraganaDeinflections],
        ).get();
        addHeadings(termDeinflectedResults);
      }

      if (maximumTerms > uniqueHeadingsById.length && partialTermIsKana) {
        readingDeinflectedResults = await database.headingsByReadings(
          readings: [...possibleDeinflections, ...hiraganaDeinflections],
          limit: limit(),
        ).get();
        addHeadings(readingDeinflectedResults);
      }

      if (maximumTerms > uniqueHeadingsById.length && partialTermIsHiragana) {
        termExactKatakanaResults = await database.headingsByTerms(
          terms: [kanaKit.toKatakana(partialTerm)],
        ).get();
        addHeadings(termExactKatakanaResults);
      }

      bool foundAny = [
        termExactResults,
        termDeinflectedResults,
        readingExactResults,
        readingDeinflectedResults,
        termExactKatakanaResults,
      ].any((results) => results.isNotEmpty);
      if (foundAny && bestLength < partialTerm.length) {
        bestLength = partialTerm.length;
      }

      if (maximumTerms > uniqueHeadingsById.length) {
        bool addStartsWith = searchWithWildcards
            ? i == 0
            : !startsWithAdded && uniqueHeadingsById.isNotEmpty;
        if (addStartsWith) {
          startsWithAdded = true;
          addHeadings(await database
              .headingsByTermPrefix(
                prefix: searchTerm,
                prefixEnd: '$searchTerm\u{10FFFF}',
                limit: limit(),
              )
              .get());
        }
      }
    }
  }

  List<DictionaryHeading> headings =
      await loadHeadings(database, uniqueHeadingsById.keys.toList());
  if (headings.isEmpty) {
    return null;
  }

  Map<DictionaryHeading, int> headingOrders = Map.fromEntries(
    headings.mapIndexed((index, heading) => MapEntry(heading, index)),
  );

  List<Dictionary> dictionaries = await database.allDictionaries().get();

  headings.sort((a, b) {
    if (a.term == b.term ||
        (a.reading.isNotEmpty && b.reading.isNotEmpty) &&
            a.reading == b.reading) {
      int hasPopularTag = (a.tags.any((e) => e.name == 'P') ? -1 : 1)
          .compareTo(b.tags.any((e) => e.name == 'P') ? -1 : 1);
      if (hasPopularTag != 0) {
        return hasPopularTag;
      }

      if (a.term != b.term) {
        int popularityCompare = b.popularitySum.compareTo(a.popularitySum);
        if (popularityCompare != 0) {
          return popularityCompare;
        }
      }

      List<DictionaryFrequency> aFrequencies = a.frequencies.toList();
      List<DictionaryFrequency> bFrequencies = b.frequencies.toList();
      aFrequencies
          .sort((a, b) => a.dictionary.order.compareTo(b.dictionary.order));
      bFrequencies
          .sort((a, b) => a.dictionary.order.compareTo(b.dictionary.order));

      Map<Dictionary, List<DictionaryFrequency>> aFrequenciesByDictionary =
          groupBy<DictionaryFrequency, Dictionary>(
              aFrequencies, (frequency) => frequency.dictionary);
      Map<Dictionary, List<DictionaryFrequency>> bFrequenciesByDictionary =
          groupBy<DictionaryFrequency, Dictionary>(
              bFrequencies, (frequency) => frequency.dictionary);
      Map<Dictionary, double> aValues = aFrequenciesByDictionary
          .map((k, v) => MapEntry(k, v.map((e) => e.value).min));
      Map<Dictionary, double> bValues = bFrequenciesByDictionary
          .map((k, v) => MapEntry(k, v.map((e) => e.value).min));

      Set<Dictionary> sharedDictionaries =
          aValues.keys.toSet().intersection(bValues.keys.toSet());

      if (aValues.keys.isNotEmpty || bValues.keys.isNotEmpty) {
        for (Dictionary dictionary in dictionaries) {
          if (aValues[dictionary] == null && bValues[dictionary] != null) {
            return 1;
          } else if (aValues[dictionary] != null &&
              bValues[dictionary] == null) {
            return -1;
          }
        }

        if (sharedDictionaries.isNotEmpty) {
          for (Dictionary dictionary in sharedDictionaries) {
            int freqCompare =
                aValues[dictionary]!.compareTo(bValues[dictionary]!);
            if (freqCompare != 0) {
              return freqCompare;
            }
          }
        }
      } else {
        int popularityCompare = b.popularitySum.compareTo(a.popularitySum);
        if (popularityCompare != 0) {
          return popularityCompare;
        }
      }

      int entriesCompare = b.entries.length.compareTo(a.entries.length);
      if (entriesCompare != 0) {
        return entriesCompare;
      }
    }

    return headingOrders[a]!.compareTo(headingOrders[b]!);
  });

  /// Prioritise kanji match.
  if (searchTerm.length == 1 && kanaKit.isKanji(searchTerm)) {
    HeadingRow? kanji = await database
        .headingWithEntries(term: searchTerm, reading: '')
        .getSingleOrNull();
    if (kanji != null) {
      DictionaryHeading heading =
          (await loadHeadings(database, [kanji.id])).single;
      headings.remove(heading);
      headings.insert(0, heading);
    }
  }

  headings = headings.sublist(0, min(headings.length, maximumTerms));

  return DictionarySearchResult(
    searchTerm: searchTerm,
    bestLength: bestLength,
    headings: headings,
  );
}
```

Compare this comparator with the one being replaced before deleting it: apart from `.dictionary.value!` becoming `.dictionary`, the two must be identical. If they differ anywhere else, keep the old logic.

- [ ] **Step 7: Run the loader and search tests**

These need the rest of the package to compile, so do Steps 8–12 first if they fail to compile, then:

Run: `flutter test test/database/heading_loader_test.dart test/language/japanese_search_test.dart`
Expected: PASS. If `finds a word from its inflected form` fails on `bestLength`, print `result.headings` and `bestLength` and compare with the same lookup on the Isar build at Task 0; adjust the test's expectation only if Isar gave the same value, and note it in the commit message.

- [ ] **Step 8: Remove the Isar search leftovers**

`lib/src/dictionary/dictionary_utils.dart`: delete `import 'package:isar_community/isar.dart';`, `fastHash`, `preloadResultSync` and `updateDictionaryHistoryHelper` (with their doc comments).

`lib/src/dictionary/dictionary_operations_params.dart`: delete the `UpdateDictionaryHistoryParams` class; delete `IsolateParams.directoryPath` (constructor parameter, field and doc) and every `required super.directoryPath,`. In `test/dictionary/dictionary_utils_test.dart`, delete the `directoryPath: directory.path,` argument.

- [ ] **Step 9: Dictionary history in the store**

Append to `AppStore`:

```dart
  /// The terms whose results the Dictionary tab shows, oldest first.
  List<String> dictionaryHistory() {
    return raw
        .select('SELECT search_term FROM dictionary_history ORDER BY id')
        .map((row) => row['search_term'] as String)
        .toList();
  }

  /// Make [searchTerm] the newest dictionary history item, keeping the
  /// [maximum] newest.
  Future<void> addToDictionaryHistory(
    String searchTerm, {
    required int maximum,
  }) =>
      _addRecentTerm(db.dictionaryHistoryItems, searchTerm, maximum);

  /// Forget the dictionary history.
  Future<void> clearDictionaryHistory() async {
    await db.delete(db.dictionaryHistoryItems).go();
  }
```

Append to `test/database/app_store_test.dart`, inside `main()`:

```dart
  group('dictionary history', () {
    test('keeps the newest terms, re-added terms last', () async {
      await store.addToDictionaryHistory('一', maximum: 2);
      await store.addToDictionaryHistory('二', maximum: 2);
      await store.addToDictionaryHistory('一', maximum: 2);
      await store.addToDictionaryHistory('三', maximum: 2);

      expect(store.dictionaryHistory(), ['一', '三']);

      await store.clearDictionaryHistory();
      expect(store.dictionaryHistory(), isEmpty);
    });
  });
```

- [ ] **Step 10: `AppModel`**

In `lib/src/models/app_model.dart`:

1. Delete `import 'package:isar_community/isar.dart';`, `globalSchemas` and its doc comment, the `_database` field, the `_dictionaryHistory` field, `watchDictionaryItem`, `getNoReadingFrequencies`, the `_dictionaryHistory = await Hive.openBox('dictionaryHistory');` line and the `_database = await Isar.open(...)` statement in `initialise()`.
2. `isDatabaseOpen` and `shutdown`:

```dart
  /// Check if the database is still open or has the app been flagged to be
  /// shutdown.
  bool get isDatabaseOpen => _isDatabaseOpen;
  bool _isDatabaseOpen = true;

  /// Safely shutdown and stop database operations.
  void shutdown() async {
    databaseCloseNotifier.notifyListeners();
    _isDatabaseOpen = false;
    await _db.close();
    FlutterExitApp.exitApp();
  }
```

3. `dictionaryHistory`:

```dart
  /// The terms whose results the Dictionary tab shows. Oldest is first.
  List<String> get dictionaryHistory => _store.dictionaryHistory();
```

4. In `addToDictionaryHistory`, replace everything after the `if (result.headings.isEmpty || result.searchTerm.isEmpty) { return; }` guard with:

```dart
    await _store.addToDictionaryHistory(result.searchTerm,
        maximum: maximumDictionaryHistoryItems);
```

and change the method's return type to `Future<void>`.

5. `clearDictionaryHistory`: replace `await _dictionaryHistory.clear();` with `await _store.clearDictionaryHistory();`. In `deleteDictionaries` and `deleteDictionary`, replace `await _dictionaryHistory.clear();` with `await _store.clearDictionaryHistory();`.
6. Remove every `directoryPath: _databaseDirectory.path,` argument (import, deletion and search parameters).
7. In `searchDictionary`, type the operation and use the returned result:

```dart
  /// Whether or not the app is currently searching.
  cancelable.ComputeOperation<DictionarySearchResult?>? _searchOperation;
```

and replace everything from `_searchOperation =` to the end of the method with:

```dart
    _searchOperation =
        cancelable.compute(prepareSearchResultsJapaneseLanguage, params);
    DictionarySearchResult? result = await _searchOperation?.value;

    if (result == null || result.headings.isEmpty) {
      return DictionarySearchResult(searchTerm: searchTerm);
    }

    _dictionarySearchCache['$searchTerm/$overrideMaximumTerms'] = result;
    return result;
  }
```

(delete the old comment block above `_searchOperation =` about persisting results in the database).

8. `resolveStashItem`:

```dart
  /// Find [item]'s word in the dictionaries for making a card. When the
  /// heading is gone, `heading` is a stand-in with no entries; when the
  /// stashed entry's dictionary is gone, `entry` is null (whole heading).
  /// `found` tells whether the stashed entry could be found.
  Future<ResolvedStashItem> resolveStashItem(StashItem item) async {
    HeadingRow? row = await _db
        .headingByTermAndReading(term: item.term, reading: item.reading)
        .getSingleOrNull();
    if (row == null) {
      return (
        heading: DictionaryHeading(term: item.term, reading: item.reading),
        entry: null,
        found: false,
      );
    }

    DictionaryHeading heading = (await loadHeadings(_db, [row.id])).single;
    DictionaryEntry? entry = item.dictionaryName == null
        ? null
        : heading.entries.firstWhereOrNull(
            (entry) => entry.dictionary.name == item.dictionaryName);

    return (
      heading: heading,
      entry: entry,
      found: heading.entries.isNotEmpty &&
          (item.dictionaryName == null || entry != null),
    );
  }
```

In `lib/src/media/stash_item.dart`, add `import 'package:yuuna/dictionary.dart';` and, after the class:

```dart
/// A stash item's word found in the dictionaries: `heading` is a stand-in
/// with no entries when the word is gone; `entry` is null when the stashed
/// entry's dictionary is gone or the whole heading was stashed; `found` tells
/// whether the stashed entry could be found.
typedef ResolvedStashItem = ({
  DictionaryHeading heading,
  DictionaryEntry? entry,
  bool found,
});
```

- [ ] **Step 11: Pages and fields**

Mechanical replacements first:

```sh
sed -i 's/\.dictionary\.value!/.dictionary/g; s/\.dictionary\.value?\./.dictionary./g; s/\.heading\.value!/.heading/g' \
  lib/src/creator/fields/hidden_meaning_field.dart \
  lib/src/creator/fields/frequency_field.dart \
  lib/src/creator/fields/expanded_meaning_field.dart \
  lib/src/creator/fields/collapsed_meaning_field.dart \
  lib/src/creator/fields/pitch_accent_field.dart \
  lib/src/creator/fields/meaning_field.dart \
  lib/src/creator/actions/add_to_stash_action.dart \
  lib/src/creator/actions/share_action.dart \
  lib/src/pages/implementations/dictionary_term_page.dart \
  lib/src/pages/implementations/dictionary_entry_page.dart \
  lib/src/pages/implementations/dictionary_structured_content_page.dart \
  lib/src/pages/implementations/dictionary_result_page.dart \
  lib/src/pages/implementations/dictionary_history_page.dart
grep -rn "\.value!\|\.value?\." lib/src/creator lib/src/pages | grep -i "dictionary\|heading"
```

Expected: the `grep` prints nothing related to dictionary links.

Then by hand:

- `dictionary_term_page.dart`: replace `frequencies += appModel.getNoReadingFrequencies(heading: heading);` with

```dart
    frequencies += heading.noReadingFrequencies
        .where((frequency) =>
            !dictionaryNamesByHidden[frequency.dictionary.name]!)
        .toList();
```

  If `appModel` in that `build` is now unused, delete its declaration.
- `dictionary_result_page.dart`: replace the `headingsById` map and the `headings` list built from `headingIds` with `List<DictionaryHeading> headings = widget.result.headings;`.
- `home_dictionary_page.dart`, `recursive_dictionary_page.dart` and `lib/src/pages/base_source_page.dart`: `.headingIds.length` becomes `.headings.length`.
- `dictionary_history_page.dart`: the page lists terms and each item searches again. In `_DictionaryHistoryPageState.build`, replace the `historyResults` list and its use with:

```dart
    List<String> historyTerms = appModel.dictionaryHistory.reversed.toList();
```

```dart
        ...historyTerms.map(
          (searchTerm) => _DictionaryHistoryScrollableItem(
            key: ValueKey(searchTerm),
            searchTerm: searchTerm,
            onSearch: widget.onSearch,
            onShare: widget.onShare,
            lastSelectedMapping: lastSelectedMapping,
          ),
        ),
```

  In `_DictionaryHistoryScrollableItem`, replace the `result` constructor parameter and field with:

```dart
  const _DictionaryHistoryScrollableItem({
    required this.searchTerm,
    required this.onSearch,
    required this.onShare,
    required this.lastSelectedMapping,
    super.key,
  });

  /// The term of this history item, searched again to show its result.
  final String searchTerm;
```

  In its state, add the search and a `FutureBuilder`, and move the old `build` body into `buildResult`:

```dart
  late final Future<DictionarySearchResult> _result =
      appModelNoUpdate.searchDictionary(
    searchTerm: widget.searchTerm,
    searchWithWildcards: false,
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return FutureBuilder<DictionarySearchResult>(
      future: _result,
      builder: (context, snapshot) {
        DictionarySearchResult? result = snapshot.data;
        if (result == null || result.headings.isEmpty) {
          return const SliverPadding(padding: EdgeInsets.zero);
        }

        return buildResult(result);
      },
    );
  }

  /// The first heading of [result], with a footer to open the rest.
  Widget buildResult(DictionarySearchResult result) {
    List<DictionaryHeading> headings = result.headings;
    // ...the rest of the old build body, from `List<Dictionary> dictionaries
    // = appModel.dictionaries;` to its `return DictionaryTermPage(...)`,
    // unchanged.
  }
```

  The old body's `headingsById` / `headingIds` lines are replaced by the `headings` line above; nothing else in it changes.
- `stash_page.dart`: `_open` resolves before pushing:

```dart
  Future<void> _open(StashItem item) async {
    ResolvedStashItem resolved =
        await appModelNoUpdate.resolveStashItem(item);
    if (!mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StashItemPage(
          item: item,
          mediaItem: widget.item,
          resolved: resolved,
        ),
      ),
    );
    _reload();
  }
```

- `stash_item_page.dart`: add the parameter and field

```dart
    required this.resolved,
```

```dart
  /// [item]'s word found in the dictionaries.
  final ResolvedStashItem resolved;
```

  replace the `late ({...}) _resolved;` field with `ResolvedStashItem get _resolved => widget.resolved;`, and delete `_resolved = appModelNoUpdate.resolveStashItem(item);` from `initState`.

- [ ] **Step 12: Full verification**

```sh
dart run build_runner build --delete-conflicting-outputs
flutter analyze
flutter test
grep -rn "isar" lib --include=*.dart | grep -v "\.g\.dart"
```

Expected: no analyzer issues; all tests pass; the `grep` finds only `fromIsar`/`toIsar` in the two converter classes (renamed in Task 9).

- [ ] **Step 13: Commit**

```sh
jj status
jj commit -m "Look words up in Drift

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 9: Remove Isar; documentation

**Files:**
- Modify: `pubspec.yaml`, `pubspec.lock`, regenerated `*.g.dart`
- Modify: `lib/src/utils/converters/quick_actions_converter.dart`, `enhancements_converter.dart`, `lib/src/database/converters.dart`
- Modify: `docs/TOOLCHAIN.md`, `CLAUDE.md`, `DEBT.md` (only if a fact in it changed)

**Interfaces:**
- Produces: no Isar dependency; `QuickActionsConverter.decode/encode`, `EnhancementsConverter.decode/encode`.

- [ ] **Step 1: Drop the packages**

In `pubspec.yaml` delete `isar_community`, `isar_community_flutter_libs` and the `isar_community_generator` entry with its comment.

```sh
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Expected: resolution succeeds; `jj diff --stat` shows `media_item.g.dart` and `anki_mapping.g.dart` unchanged or regenerated without any Isar section.

- [ ] **Step 2: Rename the converters' methods**

In `lib/src/utils/converters/quick_actions_converter.dart` and `enhancements_converter.dart`, rename `fromIsar` to `decode` and `toIsar` to `encode` (and fix their doc comments: "Decodes the JSON stored in the database." / "Encodes for the database as JSON."). Update the four call sites in `lib/src/database/converters.dart`.

- [ ] **Step 3: Find leftover mentions**

```sh
grep -rni "isar" lib test docs CLAUDE.md DEBT.md tool .github --include=* | grep -v "docs/superpowers/"
```

Fix every hit outside `docs/superpowers/`: code comments that say "Isar" become "the database"; documentation is handled in the next steps.

- [ ] **Step 4: Update `docs/TOOLCHAIN.md`**

- In the *Not verified on device* list, change `dictionary import and lookup (confirms isar_community opens the schema set)` to `dictionary import and lookup (confirms the SQLite database and its build hook work on the device)`.
- In *Held back on purpose*, fix the `dependency_validator` row if Step 1 changed which packages need analyzer ≥ 13.

- [ ] **Step 5: Update `CLAUDE.md`**

- *Commands*: after the `dart run build_runner build` line add

```sh
dart run drift_dev schema dump lib/src/database/app_database.dart drift_schemas/
dart run drift_dev schema generate drift_schemas/ test/database/generated/
```

  and change the `build_runner` comment to `# json, dart_mappable, Drift`.
- *CI* paragraph: mention that the schema dump and its test helpers are regenerated and diffed too.
- *Barrel imports*: "seven barrel files" becomes "eight barrel files", adding `database.dart` to the list.
- *Persistence*: replace the Isar bullet with a description of the SQLite database: Drift over `sqlite3` (FFI, SQLite bundled by the package's hook), one file `yomimoto.sqlite` in the support directory; `AppDatabase` (tables in `lib/src/database/tables.dart`, search and loader queries in `search.drift`); `AppStore` for app data, with synchronous raw reads and Drift writes over one shared connection; the rule that on the main isolate raw SQL is for reads only; the isolates (`search`, import with `DictionaryImportWriter`, deletion) opening their own connections; `loadHeadings` producing fully loaded headings. State that schema version 1 is the 1.0 baseline: until 1.0 ships, schema edits change version 1 and re-dump it; after 1.0, every change bumps `schemaVersion`, adds a migration, dumps a new snapshot and adds a migration test (`drift_dev make-migrations`).
- *Fork ground rules*, first bullet: "Isar and Hive start empty" becomes "the database and Hive start empty"; "Deleting a schema from `globalSchemas` is free" becomes "Changing schema version 1 is free until 1.0".
- *Reader internals*: "The Novels tab is an Isar mirror" becomes "a database mirror"; mention that `putMediaItem` upserts by source and identifier, keeps the row id (the stash refers to it) and orders the library by `last_opened_at`.
- *Toolchain*: drop "Isar" from the `dart_mappable_builder` mention if it is still there.

- [ ] **Step 6: Full verification**

```sh
flutter analyze
flutter test
flutter build apk --release --split-per-abi
```

Expected: no issues; all tests pass; the release APKs build.

- [ ] **Step 7: Commit**

```sh
jj status
jj commit -m "Remove Isar

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>"
```

---

### Task 10: Device verification (manual)

Done by the human with the release APK from Task 9, on a fresh install:

- [ ] Import JMdict, a pitch dictionary and a frequency dictionary; compare the times with Task 0.
- [ ] Look up words from long selections in a ttu book and in mokuro; compare latency with Task 0; check ranking on a few words with several readings.
- [ ] Wildcard searches (`食？？`, `食※`) on the Dictionary tab.
- [ ] Reader lookup → card creator → export to AnkiDroid, with an image and an audio enhancement.
- [ ] Stash a word, peek back into the book, make a card from the stash; delete the book from ttu and refresh: its stash goes.
- [ ] Open books in a different order: the Novels library lists the most recently opened first.
- [ ] Mokuro: open volumes, check the history order and that reopening keeps the page.
- [ ] Dictionary tab history after a few lookups; "show more" from a history card.
- [ ] Edit, reorder and delete profiles and catalogs; reorder, hide and collapse dictionaries.
- [ ] Delete JMdict: the database file (`adb shell run-as org.kaqui.yomimoto ls -l files/../app_flutter/` or wherever `getApplicationSupportDirectory` points) shrinks.
