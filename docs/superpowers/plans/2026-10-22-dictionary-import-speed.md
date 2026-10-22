# Faster Yomichan Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Import Yomichan dictionaries several times faster by letting SQLite parse the bank JSON straight from the zip, with the same database content and a determinate progress bar.

**Architecture:** A new raw-SQL importer, `importYomichanBanks` in `lib/src/database/yomichan_import.dart`, stages each bank file through STRICT temp tables with `json_each` and inserts set-based in chunks of 1000 rows. `DictionaryFormat`'s four per-phase hooks become one `importData` hook. Yomichan's version reads banks from the zip into memory and calls the importer; Migaku's wraps the existing `DictionaryImportWriter` path. Only non-bank archive entries are extracted, off the UI isolate.

**Tech Stack:** Dart/Flutter, `sqlite3` 3.5 (bundled SQLite 3.54: JSON functions, `->`/`->>`, `jsonb`, STRICT, `MATERIALIZED`), Drift for the schema, `async_zip` (`ZipFileReaderSync`), slang.

**Spec:** `docs/superpowers/specs/2026-10-22-dictionary-import-speed-design.md`. Its appendix holds the prototype SQL, validated against today's import; start from it.

## Global Constraints

- No schema change: `lib/src/database/tables.dart` and `drift_schemas/` stay untouched.
- Stored data equals today's import, except definitions keep the source's JSON escapes (`\u0026` where Dart wrote `&`); those decode to the same value.
- A wrongly typed value fails the whole import (one transaction, nothing written); lossless conversions by SQLite (a number into text, `"5"` into a real) are accepted.
- `flutter analyze` reports no issues, infos included; `flutter test` passes.
- Barrel imports only (`package:yuuna/<barrel>.dart`); every new file gets an `export` line in its barrel. Isolate entry points are top-level functions.
- Every public member has a `///` doc comment; British spelling (`initialise`); format new code by hand to match the file (do not run `dart format` on existing files).
- `async_zip`'s FFI is unavailable under `flutter test`: unit-tested code must not open a zip.
- Never install a debug build over the user's `org.kaqui.yomimoto` on the device: release-signed, a signature mismatch forces an uninstall and wipes their library. Device builds use `applicationId "org.kaqui.yomimoto.bench"` in a throwaway jj change.
- Commit after each task (`jj describe -m "<message>"` then `jj new`); messages are short imperative sentences like the repo's (`Put each quick action where it applies`), ending with the session's attribution lines.

## Review Focus

- **Archive entries escaping the resource directory** (`../x`, `/etc/x`): never extracted outside it; tested in Task 6.
- **A failed import followed by another on the same connection:** leftover temp tables must not break the second one; tested in Task 2.
- **An archive with no bank files** (only `index.json`): the import succeeds empty, with no progress call and no division by zero; tested in Task 2.
- **Meta banks listed before term banks in the archive:** terms still get headings first, as today; tested in Task 4.
- **Bank-named files in a subdirectory** (`sub/term_bank_1.json`): not imported (today's `listSync` is not recursive) but extracted as resources; tested in Task 6.

---

### Task 1: One `importData` hook per format

Pure refactor: behaviour and existing tests unchanged.

**Files:**
- Modify: `lib/src/dictionary/dictionary_format.dart` (hooks at lines 23–28, 83–113)
- Modify: `lib/src/dictionary/dictionary_operations_params.dart` (`PrepareDictionaryParams`)
- Modify: `lib/src/dictionary/dictionary_utils.dart:21-32`
- Modify: `lib/src/dictionary/formats/migaku_dictionary_format.dart`
- Modify: `lib/src/dictionary/formats/yomichan_dictionary_format.dart:30-38`
- Modify: `lib/src/models/app_model.dart:1015-1022` (pass `file`)
- Test: `test/dictionary/dictionary_utils_test.dart` (its `params()` helper)

**Interfaces:**
- Produces, on `DictionaryFormat`, replacing `prepareTags`, `prepareEntries`, `preparePitches`, `prepareFrequencies`:
  `void Function({required PrepareDictionaryParams params, required Database database, required int dictionaryId}) importData;`
  It writes dictionary `dictionaryId`'s data on `database`, inside the caller's transaction.
- Produces `PrepareDictionaryParams.file` (`final File file`, required): the archive picked by the user.
- Produces `importDataMigakuFormat` and `importDataYomichanFormat`, top-level, with that signature. For now both create a `DictionaryImportWriter`, run their existing per-phase functions in today's order (tags, entries, pitches, frequencies) and close the writer in `finally`. Migaku's three empty functions are deleted.
- `depositDictionaryDataHelper` calls `params.dictionaryFormat.importData(params: params, database: database, dictionaryId: dictionaryId)` in place of the writer block.

- [ ] **Step 1:** Make the changes above; in `dictionary_utils_test.dart`'s `params()`, pass `file: File(path.join(directory.path, 'unused.zip'))`.
- [ ] **Step 2:** Run `flutter test test/dictionary/ test/database/`; expected: all pass, unchanged.
- [ ] **Step 3:** Run `flutter analyze`; expected: `No issues found!`
- [ ] **Step 4:** Commit: `Give each dictionary format a single import hook`.

---

### Task 2: SQL import of tag and term banks

**Files:**
- Create: `lib/src/database/yomichan_import.dart`
- Modify: `lib/database.dart` (add the export)
- Test: `test/database/yomichan_import_test.dart`

**Interfaces:**
- Produces:
  ```dart
  /// A bank file of a Yomichan archive: its name, its uncompressed size and
  /// a way to read its bytes when its turn comes.
  typedef YomichanBank = ({String name, int size, Uint8List Function() read});

  /// Whether [name], an archive entry name, is a bank file this import reads:
  /// at the archive's root and starting with `tag_bank`, `term_bank`,
  /// `kanji_bank` or `term_meta_bank`.
  bool isYomichanBank(String name);

  /// Import [banks] as dictionary [dictionaryId] into [database], inside the
  /// caller's transaction. [onProgress] gets the fraction of the banks'
  /// total size done, after every chunk and at each bank's end.
  void importYomichanBanks({
    required Database database,
    required int dictionaryId,
    required List<YomichanBank> banks,
    required void Function(double fraction) onProgress,
  });
  ```
- Banks not matching `isYomichanBank` are ignored. Processing order: all tag banks, then term and kanji banks in list order, then meta banks in list order (Tasks 3–4 fill in kanji and meta).

Behaviour (spec §1–§3 and the appendix):
- Temp tables are created with `CREATE TEMP TABLE IF NOT EXISTS`, emptied before use and dropped at the end, so an earlier failed import on the same connection does not break this one.
- Tags go through a STRICT `tag_stage` (`name TEXT NOT NULL, category TEXT NOT NULL, sorting_order INTEGER NOT NULL, notes TEXT NOT NULL, popularity REAL NOT NULL`), then into `tag` with the appendix's upsert (a later definition of a name overwrites).
- Terms go through the appendix's STRICT `stage`, with an added `heading_id INTEGER` column. Per chunk (`n` range of 1000): insert headings, `UPDATE stage SET heading_id = …` for the chunk, then entries, entry tags and heading tags reading `s.heading_id` (no join on `entry`). Entry ids are `n` plus `MAX(entry.id)` taken before the bank.
- Definitions: the appendix's conversion, extended so a `{type: "text"}` element whose `text` exists but is not a string makes the whole value NULL (the import then fails on `NOT NULL`). Missing `text` drops the element, as today.
- Tag joins keep `stage` as the outer loop with `CROSS JOIN`, and escape `\` and `"` before splitting.
- Bank bytes are bound as is and read with `json_each(CAST(? AS TEXT))`.

- [ ] **Step 1: Write the failing tests**

Helpers at the top of the test file: `YomichanBank bank(String name, String json)` (bytes are `utf8.encode(json)`); `int importBanks(Database raw, String name, List<YomichanBank> banks, {List<double>? progress})`, which runs `insertTestDictionary` and `importYomichanBanks` inside `BEGIN`/`COMMIT`, does `ROLLBACK` on error and rethrows, and returns the dictionary id. Use `openTestDatabase()` from `test_database.dart`.

```dart
test('imports tags, terms, definitions and their tags', () {
  importBanks(raw, 'D', [
    bank('tag_bank_1.json', '[["n","partOfSpeech",-1,"noun",0],'
        '["P","popular",-10,"common",10],'
        '["n","partOfSpeech",-2,"noun again",1]]'),
    bank('term_bank_1.json', '[["猫","ねこ","n","",5,['
        '"cat",{"type":"text","text":"feline"},{"type":"text"},'
        '{"type":"structured-content","content":{"tag":"span","content":"neko"}},'
        '{"type":"image","path":"img/neko.png"},7,{"type":"unknown"}],1,"P"]]'),
  ]);
  expect(raw.select('SELECT name, sorting_order, notes FROM tag ORDER BY name'),
      [{'name': 'P', 'sorting_order': -10, 'notes': 'common'},
       {'name': 'n', 'sorting_order': -2, 'notes': 'noun again'}]);
  Row entry = raw.select('SELECT * FROM entry').single;
  expect(jsonDecode(entry['definitions'] as String),
      ['cat', 'feline', '{"tag":"span","content":"neko"}', 'null']);
  expect(entry['popularity'], 5.0);
  expect(raw.select('SELECT t.name FROM entry_tag JOIN tag t ON t.id = tag_id')
      .map((r) => r['name']), ['n']);
  expect(raw.select('SELECT t.name FROM heading_tag JOIN tag t ON t.id = tag_id')
      .map((r) => r['name']), ['P']);
});

test('shares headings across dictionaries and continues entry ids', ...);
// A: [["猫","ねこ",null,"",1,["cat"],1,""]]; B: same term with ["kitty"].
// heading count 1; entry ids [1, 2]; B's entry has dictionary_id of B.

test('splits tag names containing quotes and backslashes', ...);
// tags 'a"b' and r'c\d'; term def tags 'a"b c\d' -> 2 entry_tag rows.

test('a null or empty definition-tag string adds no entry tags', ...);

test('reports progress by bank size, rising to 1', ...);
// One term bank of 1500 rows plus a 1-row bank: progress values are
// non-decreasing, there are at least 3, the last is 1.0, and the first
// is below 1.0.

test('an archive without banks imports nothing and reports nothing', ...);
// banks: [] -> no throw, progress list empty, entry count 0.

test('popularity given as a numeric string is accepted', ...);
// "5" -> 5.0 (accepted leniency).

for (var (label, json) in [
  ('a popularity that is not a number',
      '[["猫","ねこ","","","abc",["cat"],1,""]]'),
  ('definitions that are not a list', '[["猫","ねこ","","",1,"cat",1,""]]'),
  ('a text definition whose text is a number', '[["猫","ねこ","","",1,[{"type":"text","text":5}],1,""]]'),
  ('a row without term tags', '[["猫","ねこ","","",1,["cat"],1]]'),
  ('broken JSON', '[["猫"'),
]) {
  test('fails on $label and writes nothing', ...);
  // importBanks throws SqliteException; dictionary, heading, entry counts 0.
}

test('a tag sorting order that is not an integer fails the import', ...);

test('an import after a failed one on the same connection works', ...);
// First importBanks with broken JSON throws; second with a valid bank
// succeeds and leaves 1 entry.
```

- [ ] **Step 2:** Run `flutter test test/database/yomichan_import_test.dart`; expected: compile failure, `importYomichanBanks` undefined.
- [ ] **Step 3:** Implement `isYomichanBank` and `importYomichanBanks` (tags and term banks; kanji and meta banks are skipped for now) in `lib/src/database/yomichan_import.dart`; add `export 'src/database/yomichan_import.dart';` to `lib/database.dart`.
- [ ] **Step 4:** Run the test file; expected: all pass.
- [ ] **Step 5:** Run `flutter analyze`; expected: `No issues found!`
- [ ] **Step 6:** Commit: `Import Yomichan term banks in SQL`.

---

### Task 3: Kanji banks

**Files:**
- Modify: `lib/src/database/yomichan_import.dart`
- Test: `test/database/yomichan_import_test.dart`

**Interfaces:** none new. Kanji banks are processed in the term pass, through the same `stage` and chunk statements, with reading `''`, null definition tags, popularity 0, term tags from element 3 and one definition string, built in SQL exactly as `prepareEntriesYomichanFormat` builds it today:

```
for each non-empty section, in order 音読み (element 1), 訓読み (element 2), 意味 (element 4):
  "<title>\n" + for each item: "  • <item>\n" + "\n"
then trim the whole
```

Readings are split on single spaces (empty pieces kept as empty bullets, as Dart's `split(' ')` does). A reading section is skipped when its pieces joined are empty after trimming, and the meanings section when the list is empty. Trimming uses space, `\t`, `\n`, `\r` and U+3000. Rows whose definition comes out empty are not staged: no heading, no entry, as today. Use `group_concat(… ORDER BY key)` over `json_each`.

- [ ] **Step 1: Write the failing tests**

```dart
test('imports a kanji with its readings and meanings', () {
  importBanks(raw, 'K', [
    bank('tag_bank_1.json', '[["jouyou","misc",0,"常用",0]]'),
    bank('kanji_bank_1.json',
        '[["猫","ビョウ ミョウ","ねこ","jouyou",["cat","feline"],{}]]'),
  ]);
  expect(raw.select('SELECT term, reading FROM heading').single,
      {'term': '猫', 'reading': ''});
  expect(jsonDecode(raw.select('SELECT definitions FROM entry').single
          ['definitions'] as String),
      ['音読み\n  • ビョウ\n  • ミョウ\n\n訓読み\n  • ねこ\n\n意味\n  • cat\n  • feline']);
  expect(countRows(raw, 'heading_tag'), 1);
});

test('skips empty kanji sections', ...);
// ["犬","","いぬ","",[],{}] -> definition '訓読み\n  • いぬ'.

test('skips a kanji with nothing to say', ...);
// ["丶","","","",[],{}] -> heading and entry counts 0.
```

- [ ] **Step 2:** Run the test file; expected: the kanji tests fail (no entry).
- [ ] **Step 3:** Implement kanji staging in `importYomichanBanks`.
- [ ] **Step 4:** Run the test file; expected: all pass.
- [ ] **Step 5:** Commit: `Import Yomichan kanji banks in SQL`.

---

### Task 4: Frequency and pitch banks

**Files:**
- Modify: `lib/src/database/yomichan_import.dart`
- Test: `test/database/yomichan_import_test.dart`

**Interfaces:** none new. Meta banks are processed after every term and kanji bank, through the appendix's `meta_stage` (`jsonb` and `MATERIALIZED` form), chunked like terms: insert headings, resolve heading ids into a `heading_id` column of `meta_stage`, then frequencies. Pitches go through a STRICT `pitch_stage (heading_id INTEGER NOT NULL, downstep INTEGER NOT NULL)` before `pitch`, so a non-integer position fails the import. `meta_stage` gets `CHECK (type <> 'pitch' OR data IS NOT NULL)`, with `data` set only when `pitches` is an array, so a pitch row without a pitch list fails, as Dart's `List.from(null)` does today.

- [ ] **Step 1: Write the failing tests**

```dart
test('imports every frequency shape as today', () {
  importBanks(raw, 'F', [
    bank('term_meta_bank_1.json', '['
        '["a","freq",5],["b","freq",2.5],["c","freq",3.0],'
        '["d","freq",{"reading":"でぃ","frequency":{"value":7,"displayValue":"7★"}}],'
        '["e","freq",{"value":8,"displayValue":"8㋕"}],'
        '["f","freq",{"reading":"えふ","value":9.7}],'
        '["g","freq",{"frequency":4}],["h","freq",{"frequency":4.5}],'
        '["i","freq",{"reading":"あい"}],["j","freq","rare"],'
        '["l","ipa",{}]]'),
  ]);
  expect(
      raw.select('SELECT h.term, h.reading, f.value, f.display_value '
          'FROM frequency f JOIN heading h ON h.id = f.heading_id ORDER BY f.id'),
      [
        {'term': 'a', 'reading': '', 'value': 5.0, 'display_value': '5'},
        {'term': 'b', 'reading': '', 'value': 2.5, 'display_value': '2.5'},
        {'term': 'c', 'reading': '', 'value': 3.0, 'display_value': '3'},
        {'term': 'd', 'reading': 'でぃ', 'value': 7.0, 'display_value': '7★'},
        {'term': 'e', 'reading': '', 'value': 8.0, 'display_value': '8㋕'},
        {'term': 'f', 'reading': 'えふ', 'value': 9.7, 'display_value': '9'},
        {'term': 'g', 'reading': '', 'value': 4.0, 'display_value': '4'},
        {'term': 'h', 'reading': '', 'value': 4.5, 'display_value': '4.5'},
        {'term': 'j', 'reading': '', 'value': 0.0, 'display_value': 'rare'},
      ]);
  expect(countRows(raw, 'heading'), 9); // 'i' and 'l' create none
});

test('imports pitches with their reading', ...);
// ["け","pitch",{"reading":"け","pitches":[{"position":0},{"position":2}]}]
// -> pitch downsteps [0, 2] on heading (け, け); without "reading" the
// heading reading is ''.

test('processes term banks before meta banks whatever their order', ...);
// banks [term_meta_bank_1 (freq of 犬), term_bank_1 (猫)] -> heading id 1
// is 猫, id 2 is 犬.

test('a pitch row without a pitch list fails the import', ...);
test('a pitch position that is not an integer fails the import', ...);
```

- [ ] **Step 2:** Run the test file; expected: the new tests fail.
- [ ] **Step 3:** Implement meta staging in `importYomichanBanks`.
- [ ] **Step 4:** Run the test file; expected: all pass.
- [ ] **Step 5:** Run `flutter analyze`; expected: `No issues found!`
- [ ] **Step 6:** Commit: `Import Yomichan frequency and pitch banks in SQL`.

---

### Task 5: Equivalence gate against today's import

This must happen while the old Yomichan code still exists. Nothing in this task is committed to the main line.

**Files:**
- Create (throwaway, in its own jj change on top of the current one, abandoned afterwards): `test/zz_equivalence/equivalence_test.dart`

The two zips are `/home/blastrock/Downloads/[Bilingual] JMdict (Recommended).zip` and `/home/blastrock/Downloads/[Freq] JPDB (Recommended).zip`. Extract each with `unzip` into its own directory under the session scratchpad (the test host cannot open zips).

- [ ] **Step 1:** Write the harness. It builds database **old** by running `depositDictionaryDataHelper` with `YomichanFormat`, whose `importData` is still the writer path from Task 1, over both extracted directories. It builds database **new** by running `importYomichanBanks` over the same directories, with banks in each directory's `listSync()` order and `read: file.readAsBytesSync`, each dictionary in its own transaction. Then it `ATTACH`es old and, for `dictionary`, `heading`, `tag`, `entry`, `entry_tag`, `heading_tag`, `pitch` and `frequency`, prints the row counts and both `EXCEPT` counts. For entries whose `definitions` differ, it checks that the two are equal once the list and each structured-content element are JSON-decoded (`DeepCollectionEquality`).
- [ ] **Step 2:** Run it (`flutter test test/zz_equivalence/`, ~2 min). Expected: every table's `EXCEPT` counts are 0 in both directions, except `entry` with 65,984 in each. All 65,984 are equal once decoded. Counts: heading 614,562, entry 513,033, entry_tag 809,708, heading_tag 74,610, frequency 515,231. Also report both timings; the new import should be about 3× faster on desktop.
- [ ] **Step 3:** If anything else differs, stop and fix Tasks 2–4 before going on. Then abandon the harness change (`jj abandon`) and return to the main line.

---

### Task 6: Yomichan reads its archive in the import isolate

**Files:**
- Modify: `lib/src/dictionary/formats/yomichan_dictionary_format.dart` (replace the per-phase functions and `processDefinition`)
- Modify: `lib/src/models/app_model.dart:957-1050` (`importDictionary`)
- Test: `test/dictionary/formats/yomichan_dictionary_format_test.dart`

**Interfaces:**
- Consumes `isYomichanBank`, `importYomichanBanks`, `YomichanBank` (Task 2), and `PrepareDictionaryParams.file` (Task 1).
- Produces, top-level in the format file:
  - `String? yomichanResourcePath(String resourceDirectory, String entryName)`: where to extract archive entry `entryName`. Returns null for `index.json`, for bank files (`isYomichanBank`), for directories (names ending in `/`), and for names that are absolute or resolve outside `resourceDirectory` (use `path.isWithin`). Otherwise returns `path.join(resourceDirectory, entryName)`.
  - `String readYomichanTitle(String archivePath)`: the trimmed `title` of the archive's `index.json`. It is the isolate entry for `prepareNameYomichanFormat`, which becomes `compute(readYomichanTitle, params.file.path)`.
  - `void extractYomichanResources(PrepareDirectoryParams params)`: extracts each entry with a non-null `yomichanResourcePath`, creating parent directories, and sends `t.import_extract_count(n: n)` per file. It is the isolate entry for `prepareDirectoryYomichanFormat`, which becomes `compute(extractYomichanResources, params)`.
  - `importDataYomichanFormat` now opens `ZipFileReaderSync` on `params.file`. It passes `importYomichanBanks` every non-directory entry where `isYomichanBank(entry.name)`, as `(name: entry.name, size: entry.size, read: () => reader.read(entry.name))`, with `onProgress: params.send`, and closes the reader in `finally`.
- Deletes `prepareEntriesYomichanFormat`, `prepareTagsYomichanFormat`, `preparePitchesYomichanFormat`, `prepareFrequenciesYomichanFormat` and `YomichanFormat.processDefinition`.
- `AppModel.importDictionary` reorders its steps: `prepareName`, then the duplicate check (today's `import_duplicate` message), then `prepareDirectory` (`t.import_extract` shown), then the deposit. A duplicate is therefore reported before anything is extracted. Migaku's `prepareName` reads only the file name, so it is unaffected.

- [ ] **Step 1: Write the failing tests**

```dart
group('yomichanResourcePath', () {
  const String dir = '/res';
  test('extracts images and other files, subdirectories included', () {
    expect(yomichanResourcePath(dir, 'img/a.png'), '/res/img/a.png');
    expect(yomichanResourcePath(dir, 'styles.css'), '/res/styles.css');
    expect(yomichanResourcePath(dir, 'sub/term_bank_1.json'),
        '/res/sub/term_bank_1.json');
  });
  test('skips the index, root bank files and directories', () {
    for (String name in ['index.json', 'term_bank_1.json', 'tag_bank_1.json',
        'kanji_bank_2.json', 'term_meta_bank_1.json', 'img/']) {
      expect(yomichanResourcePath(dir, name), isNull, reason: name);
    }
  });
  test('never extracts outside the directory', () {
    for (String name in ['../evil.png', 'img/../../evil.png', '/etc/evil']) {
      expect(yomichanResourcePath(dir, name), isNull, reason: name);
    }
  });
});
```

Also in `test/database/yomichan_import_test.dart`: `isYomichanBank` is true for `term_bank_1.json` and `term_meta_bank_3.json`, and false for `sub/term_bank_1.json`, `index.json` and `img/a.png`.

- [ ] **Step 2:** Run `flutter test test/dictionary/ test/database/yomichan_import_test.dart`; expected: the new tests fail.
- [ ] **Step 3:** Implement the interfaces above and the `AppModel` reordering.
- [ ] **Step 4:** Run `flutter test`; expected: all pass.
- [ ] **Step 5:** Run `flutter analyze`; expected: `No issues found!`
- [ ] **Step 6:** Commit: `Import Yomichan dictionaries straight from the archive`.

---

### Task 7: Determinate progress bar

**Files:**
- Modify: `lib/src/models/app_model.dart` (`importDictionary`)
- Modify: `lib/src/pages/implementations/dictionary_dialog_page.dart:158-215`
- Modify: `lib/src/pages/implementations/dictionary_dialog_import_page.dart`
- Modify: `lib/i18n/strings.i18n.json`, then regenerate `lib/i18n/strings.g.dart`

**Interfaces:**
- `AppModel.importDictionary` gains `required ValueNotifier<double?> fractionNotifier`. It is set to null when each dictionary starts. The port listener sets it when a message is a `double`, and sets `progressNotifier` (`'$message'`) otherwise.
- `DictionaryDialogImportPage` gains `required this.fractionNotifier` (`ValueNotifier<double?>`). The `CircularProgressIndicator` is removed. Under the texts, a `LinearProgressIndicator(value: fraction ?? 0)` sits next to `t.import_percent(percent: (fraction * 100).floor())`; the percentage is shown only when `fraction` is non-null. Nothing animates indefinitely (e-ink).
- `dictionary_dialog_page.dart` creates the notifier and passes it to both.
- Strings: add `"import_percent": "$percent%"`. Remove `import_found_tag`, `import_found_frequency`, `import_found_pitch`, `import_write_entry`, `import_write_tag`, `import_write_frequency` and `import_write_pitch`. Keep `import_found_entry` (Migaku) and `import_extract_count`.

- [ ] **Step 1:** Make the changes; run `dart run slang`.
- [ ] **Step 2:** Run `flutter analyze` and `flutter test`; expected: no issues, all pass. Check that `git diff --stat lib/i18n/strings.g.dart` shows only the string changes.
- [ ] **Step 3:** Commit: `Show dictionary import progress as a bar`.

---

### Task 8: Device verification and docs

**Files:**
- Modify: `CLAUDE.md`, persistence section (around line 177, "import with `DictionaryImportWriter` … the import writer is the one raw writer")
- Throwaway (own jj change, abandoned at the end): `android/app/build.gradle` applicationId, a bench entry point

- [ ] **Step 1:** Update `CLAUDE.md`: the import isolate writes raw SQL. Yomichan goes through `importYomichanBanks`, where SQLite parses the bank JSON from the archive. Migaku goes through `DictionaryImportWriter`. Mention the STRICT staging tables as the import's type check. Commit: `Describe the SQL Yomichan import`.
- [ ] **Step 2: Timing on the Supernote.** In a new throwaway change: set `applicationId "org.kaqui.yomimoto.bench"`. Add a bench entry point modelled on `realImport` in the earlier throwaway change `zktswukk` (`test/zz_bench/bench_main.dart`, read with `jj file show -r zktswukk`). It calls the format's `prepareName`, `prepareDirectory` and `compute(depositDictionaryDataHelper, …)` with `YomichanFormat` on `jmdict.zip` then `jpdb.zip` from `/sdcard/Download/yomibench/`, both already pushed. Build with `flutter build apk --profile --target-platform android-arm64 -t <entry>`, `adb install -r`, and grant the storage permissions as before. Expected: JMdict well under the 576 s baseline (about 130–150 s), JPDB well under 253 s (about 50–60 s), the total at least −70%.
- [ ] **Step 3: Manual check of the real app.** Build `lib/main.dart` (profile) with the same `.bench` applicationId, install, and import JMdict, JPDB and `/home/blastrock/Downloads/` jitendex through the UI. Check that the bar advances and the percentage shows; that a lookup shows JMdict structured content and jitendex images; that frequencies show; and that a card can be created. Take screenshots with `adb exec-out screencap -p`. Report to the user.
- [ ] **Step 4:** Ask the user before cleaning up the device and the jj history: uninstall `org.kaqui.yomimoto.bench`, delete `/sdcard/Download/yomibench/`, and abandon the throwaway changes (`zktswukk` and this task's).
