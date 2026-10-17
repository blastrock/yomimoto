# Move Preferences from Hive to SQLite Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the Hive preference boxes with a `preference` table in the app's SQLite database, behind typed descriptors and a write-through `PreferenceStore`, and remove Hive.

**Architecture:** A `preference(key, value JSON)` Drift table. Constant `Preference<T>` descriptors name each setting and its default. `PreferenceStore` loads all rows into memory, reads from memory, and updates memory synchronously before writing through Drift. `AppModel` keeps only the accessors that add logic; everything else reads the descriptors directly.

**Tech Stack:** Flutter 3.44.8, Drift over `sqlite3` 3.5 (FFI), Riverpod, slang.

**Spec:** `docs/superpowers/specs/2026-10-17-hive-to-sqlite-preferences-design.md`. Read it first; its Preferences table lists every key, type and default.

## Global Constraints

- Follow `CLAUDE.md`: barrel imports only (`package:yuuna/<barrel>.dart`), `///` docs on every public member, British spelling, format new code by hand (do not run `dart format` on existing files).
- `flutter analyze` must report **no issues, infos included**, after every task. `flutter test` must pass.
- No backward compatibility, no migration code: schema version 1 is edited in place and re-dumped.
- Never edit generated files by hand. Regenerate with:
  `dart run build_runner build --delete-conflicting-outputs`,
  `dart run drift_dev schema dump lib/src/database/app_database.dart drift_schemas/`,
  `dart run drift_dev schema generate drift_schemas/ test/database/generated/`,
  `dart run slang`. Commit the results.
- Internal identifiers keep upstream names (`yuuna`, `Jidoujisho*`). Do not rename them.
- Every descriptor default is a constant.
- `PreferenceStore`'s cache carries a comment explaining that callers set without awaiting and read back immediately, as Hive's `put` allowed.
- Version control is jj (git-colocated). Commit with `jj commit -m "<message>"`; end each message with:
  ```
  Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_011enU2MXdUuspoZhtAkcC3K
  ```
- The zsh tool shell aliases `cp`/`mv` to interactive versions; use `command cp -f` / `command mv -f`.

## Review Focus

1. **A preference read during startup before `PreferenceStore` exists** (anything in `AppModel.initialise()` ahead of the database open) would throw `LateInitializationError` on launch. Expected: a fresh install starts. Pinned in Task 3, Step 6 (review the startup order) and Task 5 (fresh launch).
2. **Deleting the selected profile**, including the "model missing" flow in `AppModel` that calls `selectStandardProfile()` then `deleteMapping(mapping)`, must leave `selected_mapping_id` at 1, never a dangling id that makes `mappingById(id)!` throw. Pinned in Task 4, Step 3 (compare by id) and Task 5.
3. **Two readers' identically named settings** (`highlight_on_tap`, `volume_page_turning_*`, `extend_page_beyond_navbar`) must stay independent. Expected: toggling one reader's setting leaves the other's alone. Pinned in Task 4, Step 4 (prefixed keys) and Task 5.
4. **Changing the theme while other screens are on the navigator stack** must recolour them without a restart. Pinned in Task 5.
5. **A toggle tapped twice quickly** must end where it started, not stay put. With the write-through cache, the second tap reads the first tap's value. Pinned in Task 1's `toggle` test (two toggles without awaiting in between).

---

### Task 1: `preference` table, descriptors and `PreferenceStore`

**Files:**
- Modify: `lib/src/database/tables.dart` (add table), `lib/src/database/app_database.dart` (register it)
- Create: `lib/src/preferences/preference.dart`, `lib/src/preferences/preference_store.dart`, `lib/preferences.dart` (barrel)
- Regenerate: `lib/src/database/app_database.g.dart`, `drift_schemas/`, `test/database/generated/`
- Test: `test/preferences/preference_store_test.dart`

**Interfaces:**
- Produces:
  - Drift table class `PreferenceEntries` (`tableName` `'preference'`): `TextColumn key` (primary key), `TextColumn value`. Accessed as `db.preferenceEntries`.
  - `class Preference<T>`: `const Preference(String key, {required T defaultValue})`; `final String key`; `final T defaultValue`; `Object? toJson(T value)` (returns `value`); `T fromJson(Object? json)` (returns `json as T`).
  - `class StringListPreference extends Preference<List<String>>`: `const StringListPreference(String key, {required List<String> defaultValue})`; `fromJson` returns `(json as List).cast<String>().toList()`.
  - `class EnumPreference<E extends Enum> extends Preference<E>`: `const EnumPreference(String key, this.values, {required E defaultValue})`; `final List<E> values`; `toJson` returns `value.name`; `fromJson` returns `values.byName(json as String)`.
  - `class PreferenceStore`: `PreferenceStore({required AppDatabase db, required Database raw})` (loads every row synchronously); `T get<T>(Preference<T> preference)`; `Future<void> set<T>(Preference<T> preference, T value)`; `Future<void> toggle(Preference<bool> preference)`.
  - Barrel `package:yuuna/preferences.dart` exporting both files.

- [ ] **Step 1: Add the table and register it**

In `tables.dart`, add `PreferenceEntries` with `tableName => 'preference'`, `key` as `text()`, `value` as `text()`, and `primaryKey => {key}`. Doc comments: the key names a setting (prefixed with a source's `uniqueKey` and `/` for per-source settings); the value is JSON. Add `PreferenceEntries` to the `@DriftDatabase(tables: [...])` list in `app_database.dart`, last.

- [ ] **Step 2: Regenerate Drift code and the schema snapshot**

Run the `build_runner`, `schema dump` and `schema generate` commands from Global Constraints.
Expected: `drift_schemas/drift_schema_v1.json` and `test/database/generated/schema_v1.dart` now contain `preference`; `flutter test test/database/schema_test.dart` passes.

- [ ] **Step 3: Write the failing tests**

`test/preferences/preference_store_test.dart`, using `openTestDatabase()` from `test/database/test_database.dart` (import it relatively, as the database tests do). Declare test descriptors at the top of the file:

```dart
const _flag = Preference<bool>('flag', defaultValue: true);
const _count = Preference<int>('count', defaultValue: 10);
const _size = Preference<double>('size', defaultValue: 16.0);
const _name = Preference<String>('name', defaultValue: '');
const _path = Preference<String?>('path', defaultValue: null);
const _models = StringListPreference('models', defaultValue: ['Yomimoto']);
const _theme = EnumPreference<ThemeMode>('theme', ThemeMode.values,
    defaultValue: ThemeMode.system);
```

Tests (`store = PreferenceStore(db: database.db, raw: database.raw)` in `setUp`):
- `an unset key returns the default`: each descriptor's `get` equals its `defaultValue`.
- `set values round-trip`: set `_flag` false, `_count` 3, `_size` 18.5, `_name` 'x', `_path` '/sdcard', `_models` ['A', 'B'], `_theme` `ThemeMode.dark`, each awaited; `get` returns each value.
- `a nullable value can be set back to null`: set `_path` '/sdcard' then `null`; `get(_path)` is `null`.
- `set overwrites`: `_count` 3 then 4 → 4; `countRows(database.raw, 'preference')` is 1.
- `get sees a set before it is awaited`: `Future<void> write = store.set(_count, 5); expect(store.get(_count), 5); await write;`
- `toggle flips a bool, and two quick toggles cancel out`: `await store.toggle(_flag)` → false; then `Future<void> a = store.toggle(_flag); Future<void> b = store.toggle(_flag); await a; await b;` → false.
- `a new store reads what an earlier one wrote`: set `_count` 7, awaited; `PreferenceStore(db: database.db, raw: database.raw).get(_count)` is 7.
- `invalid JSON returns the default`: `database.raw.execute("INSERT INTO preference VALUES ('count', 'not json')")` before creating a new store; `get(_count)` is 10.
- `a value of the wrong type returns the default`: insert `('count', '"three"')`; `get(_count)` is 10.
- `an unknown enum name returns the default`: insert `('theme', '"sepia"')`; `get(_theme)` is `ThemeMode.system`.

- [ ] **Step 4: Run the tests to verify they fail**

Run: `flutter test test/preferences/preference_store_test.dart`
Expected: compilation failure, `Preference` / `PreferenceStore` not defined.

- [ ] **Step 5: Implement `preference.dart` and `preference_store.dart`, and the barrel**

`PreferenceStore` keeps `final Map<String, String> _cache` (key to JSON text), filled in the constructor by `raw.select('SELECT key, value FROM preference')`. Put the required comment on `_cache`: Hive updated memory before its first `await`, and about 20 callers (every settings switch, the creator's deck and close-on-export toggles, the dictionary format and model dropdowns) set a value without awaiting and read it back straight away, so `set` must update memory synchronously.
- `get`: no entry → `defaultValue`; else `fromJson(jsonDecode(text))` inside `try`; on any exception `debugPrint` the key and the error and return `defaultValue`.
- `set`: `_cache[key] = jsonEncode(preference.toJson(value))` first, then `await db.into(db.preferenceEntries).insertOnConflictUpdate(PreferenceEntriesCompanion.insert(key: ..., value: ...))`.
- `toggle`: `set(preference, !get(preference))`.
Add `lib/preferences.dart` exporting `src/preferences/preference.dart` and `src/preferences/preference_store.dart`.

- [ ] **Step 6: Run the tests and analysis**

Run: `flutter test && flutter analyze`
Expected: all tests pass; `No issues found!`

- [ ] **Step 7: Commit**

`jj commit -m "Add a preference table and a typed PreferenceStore"` (with the trailer lines).

---

### Task 2: Seed the Standard profile as id 1

**Files:**
- Modify: `lib/src/creator/anki_mapping.dart:157-160`, `lib/src/database/app_database.dart`, `lib/src/database/app_store.dart:165-240`, `lib/src/models/app_model.dart:730-760` (remove `populateDefaultMapping`), `lib/src/pages/implementations/home_page.dart:57`
- Test: `test/database/app_store_test.dart` (group `profiles`)

**Interfaces:**
- Produces:
  - `AnkiMapping.standardProfileId`: `static const int standardProfileId = 1;`. `standardModelName` and `standardProfileName` become `static const String`.
  - `AnkiMappingsCompanion ankiMappingCompanion(AnkiMapping mapping)`: a top-level function in `app_store.dart`, replacing the private `AppStore._mappingCompanion` (same body).
  - `AnkiMapping? AppStore.mappingById(int id)`.
  - `AppDatabase.migration`: a `MigrationStrategy` whose `onCreate` runs `m.createAll()` then inserts `ankiMappingCompanion(AnkiMapping.defaultMapping(order: 0)..id = AnkiMapping.standardProfileId)`.

- [ ] **Step 1: Rewrite the `profiles` tests for a seeded database**

Every test database now starts with Standard. In `group('profiles')`, keep the `profile(label, order)` helper and replace the tests with:
- `a fresh database holds the Standard profile at id 1`: `store.mappings().single` has `id` 1, `label` `AnkiMapping.standardProfileName`, `model` `AnkiMapping.standardModelName`, `order` 0, and `exportFieldKeys`, `creatorFieldKeys`, `tags`, `actions`, `enhancements` equal to `AnkiMapping.defaultMapping(order: 0)`'s; `useBrTags` is true.
- `the next profile added gets id 2`: `putMapping(profile('Mine', 1))` sets `id` 2.
- `mappingById finds a profile, or nothing`: `mappingById(1)!.label` is Standard; `mappingById(99)` is null.
- `putMapping on a saved profile replaces it`: `profile('Mine', 1)`, put, set `creatorFieldKeys = ['term']`, put again; `mappings().length` is 2 and `mappingById(mapping.id!)!.creatorFieldKeys` is `['term']`.
- `replaceMappings swaps orders and keeps ids`: put A (order 1) and B (order 2); swap orders; `replaceMappings([standard, b, a])` with `standard = store.mappingById(1)!`; labels in order are `[Standard, B, A]`; ids are 1, `b.id`, `a.id` as before.
- `nextMappingOrder and mappingLabelTaken`: `nextMappingOrder()` is 1; after `putMapping(profile('A', 1))` it is 2; `mappingLabelTaken(profile('A', 5))` true; `mappingLabelTaken(profile('A', 1))` false.

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/database/app_store_test.dart`
Expected: FAIL (no seeded row; `mappingById` undefined).

- [ ] **Step 3: Implement the constants, `ankiMappingCompanion`, `mappingById` and the `onCreate` seed**

`mappingById` follows `mappingByLabel` (`WHERE id = ?`). Document on `migration` that the Standard profile is always id 1 and cannot be deleted, so `AUTOINCREMENT` never hands out 1 again.

- [ ] **Step 4: Remove `populateDefaultMapping`**

Delete `AppModel.populateDefaultMapping` (including the "Legacy Standard" branch) and its call in `home_page.dart`'s post-frame callback, which keeps only the first-time-setup flag. Remove any slang strings that become unused (`info_standard_update`, `info_standard_update_content`) from `lib/i18n/strings.i18n.json` and run `dart run slang`.

- [ ] **Step 5: Run the tests and analysis**

Run: `flutter test && flutter analyze`
Expected: all pass; `No issues found!` (`schema_test.dart` still passes: seeding changes no schema).

- [ ] **Step 6: Commit**

`jj commit -m "Seed the Standard profile as id 1 when creating the database"`

---

### Task 3: Open the store at startup and use descriptors directly

The Hive `appModel` box stays for the accessors Task 4 handles. This task removes the pass-through accessors.

**Files:**
- Create: `lib/src/preferences/preferences.dart` (export it from `lib/preferences.dart`)
- Modify: `lib/src/models/app_model.dart`; callers in `settings_page.dart`, `creator_page.dart`, `instant_export_action.dart`, `home_page.dart`, `home_dictionary_page.dart`, `recursive_dictionary_page.dart`, `base_source_page.dart`, `dictionary_structured_content_page.dart`, `japanese_language.dart`, `tags_field.dart`, `clear_field_enhancement.dart`, `save_tags_enhancement.dart`, `creator_model.dart` (use `flutter analyze` to find any others)

**Interfaces:**
- Consumes: `Preference`, `StringListPreference`, `PreferenceStore` (Task 1); `AnkiMapping.standardModelName` as a `const` (Task 2).
- Produces:
  - `abstract final class Preferences` with `static const` descriptors, keys and defaults exactly as in the spec's table: `lastSelectedDeck` (`'last_selected_deck'`, `'Default'`), `currentHomeTabIndex` (`'current_home_tab_index'`, 0), `firstTimeSetup` (`'first_time_setup'`, true), `autoSearch` (`'auto_search'`, true), `searchDebounceDelay` (`'auto_search_debounce_delay'`, 100), `dictionaryFontSize` (`'dictionary_entry_font_size'`, 16.0), `maximumTerms` (`'maximum_terms'`, 10), `closeCreatorOnExport` (`'close_on_export'`, false), `savedTags` (`'saved_tags'`, `''`), `duplicateCheckModels` (`StringListPreference('duplicate_check_models', [AnkiMapping.standardModelName])`). Group them with section comments (app, dictionary search, card creation).
  - `PreferenceStore get preferences` on `AppModel`.

- [ ] **Step 1: Create `Preferences` with the descriptors above**

- [ ] **Step 2: Reorder `AppModel.initialise()` and build the store**

Add `late final PreferenceStore _preferenceStore` and the `preferences` getter (the existing Hive `_preferences` field keeps its name until Task 4). Move the directory setup (from `_temporaryDirectory` through the `createSync` calls) and the database open (`openRawDatabase`, `AppDatabase.fromRaw`, the `SELECT 1`, `AppStore`) to just after the package and device info. Build `_preferenceStore = PreferenceStore(db: _db, raw: raw)` right after `_store`. The permission requests follow. The dictionary preload stays last.

- [ ] **Step 3: Delete the pass-through accessors and their default fields**

From `AppModel`, delete: `lastSelectedDeckName`, `setLastSelectedDeck`, `currentHomeTabIndex`, `setCurrentHomeTabIndex`, `autoSearchEnabled`, `toggleAutoSearchEnabled`, `searchDebounceDelay`, `setSearchDebounceDelay`, `dictionaryFontSize`, `setDictionaryFontSize`, `closeCreatorOnExport`, `toggleCloseCreatorOnExport`, `isFirstTimeSetup`, `setFirstTimeSetupFlag`, `maximumTerms`, `setMaximumTerms`, `savedTags`, `setSavedTags`, `duplicateCheckModels`, `setDuplicateCheckModels`, and the fields `defaultMaximumDictionaryTermsInResult`, `defaultSearchDebounceDelay`, `defaultDictionaryFontSize`. Uses inside `AppModel` itself (`currentHomeTabIndex` in `addToDictionaryHistory`, `isFirstTimeSetup` in the permission request, `maximumTerms`, `duplicateCheckModels` in the duplicate check) switch to `_preferenceStore.get(...)`.

- [ ] **Step 4: Update the callers**

Run `flutter analyze` and fix each error. Reads become `appModel.preferences.get(Preferences.x)`, writes `appModel.preferences.set(Preferences.x, value)` (awaited where the old call was awaited, otherwise `unawaited(...)`), and toggles `appModel.preferences.toggle(Preferences.x)`. Settings-page resets use `Preferences.x.defaultValue`. Do not add `await`s or reorder code around these calls: the cache keeps the old read-after-set behaviour. Watch for local variables or parameters named `maximumTerms` that are not the accessor; leave them alone.

- [ ] **Step 5: Run the tests and analysis**

Run: `flutter analyze && flutter test`
Expected: `No issues found!`; all pass.

- [ ] **Step 6: Check the startup order**

Review `AppModel.initialise()` and everything it calls before the database open: no preference read (`_preferences`, `_preferenceStore`, `preferences`) may come before `_preferenceStore` is assigned. Record the finding in the task report.

- [ ] **Step 7: Commit**

`jj commit -m "Read app preferences through PreferenceStore descriptors"`

---

### Task 4: Move the remaining preferences, the theme and the readers off Hive

**Files:**
- Modify: `lib/src/preferences/preferences.dart`, `lib/src/models/app_model.dart`, `lib/src/media/media_source.dart`, `lib/src/media/sources/reader_ttu_source.dart`, `lib/src/media/sources/reader_mokuro_source.dart`, `lib/main.dart`, `lib/src/pages/implementations/settings_page.dart`, `lib/src/pages/implementations/creator_page.dart:715`, `lib/i18n/strings.i18n.json`, `pubspec.yaml`, `pubspec.lock`, `CLAUDE.md`

**Interfaces:**
- Consumes: Tasks 1–3, and `AppStore.mappingById` and `AnkiMapping.standardProfileId` (Task 2).
- Produces:
  - Descriptors in `Preferences`: `themeMode` (`EnumPreference<ThemeMode>('theme_mode', ThemeMode.values, defaultValue: ThemeMode.system)`), `selectedMappingId` (`Preference<int>('selected_mapping_id', defaultValue: AnkiMapping.standardProfileId)`), `lastSelectedDictionaryFormat` (`Preference<String>('last_selected_dictionary_format', defaultValue: 'yomichan')`), `lastSelectedModel` (`Preference<String?>('last_selected_model', defaultValue: null)`), and `static Preference<String?> lastPickedDirectory(String sourceKey)` (key `'$sourceKey/last_picked_directory'`, default `null`).
  - `AppModel`: `ThemeMode get themeMode`, `Future<void> setThemeMode(ThemeMode mode)` (sets, then `notifyListeners()`). `lastSelectedMapping`, `setLastSelectedMapping`, `selectStandardProfile`, `deleteMapping`, `lastSelectedDictionaryFormat`, `setLastSelectedDictionaryFormat`, `lastSelectedModel`, `setLastSelectedModelName`, `getLastPickedDirectory`, `setLastPickedDirectory` keep their signatures. `isDarkMode`, `toggleDarkMode`, `lastSelectedMappingName` are removed.
  - `MediaSource`: `Future<void> initialise(PreferenceStore preferences)`; `late final PreferenceStore preferences` (documented: for the source's own descriptors). `getPreference`, `setPreference`, `deletePreference` removed.

- [ ] **Step 1: Add the descriptors**

- [ ] **Step 2: Move the theme to `ThemeMode`**

Add `themeMode` and `setThemeMode` to `AppModel`. Remove `isDarkMode`, `toggleDarkMode` and the `restart_app` import. In `main.dart`, the `themeMode` getter returns `appModel.themeMode`. In `SettingsPage`, replace the dark-theme switch with a new `Widget buildChoice<T>({required String label, required List<T> options, required T value, required String Function(T) generateLabel, required Future<void> Function(T) onChanged})`: the label in `textTheme.bodyMedium` above a `JidoujishoDropdown<T>`, with the same horizontal padding as `buildNumberField`. Strings: replace `settings_dark_theme` with `settings_theme` "Theme", `theme_system` "System", `theme_light` "Light", `theme_dark` "Dark"; run `dart run slang`.

- [ ] **Step 3: Store the selected profile by id**

- `lastSelectedMapping` returns `_store.mappingById(_preferenceStore.get(Preferences.selectedMappingId))!`.
- `setLastSelectedMapping` stores `mapping.id!`.
- `selectStandardProfile` stores `AnkiMapping.standardProfileId`.
- `deleteMapping` resets to Standard when `mapping.id` equals the stored id, comparing ids, not labels.
- Delete `lastSelectedMappingName`; `creator_page.dart` shows `appModel.lastSelectedMapping.label`.

- [ ] **Step 4: Move the readers**

`MediaSource.initialise` takes the store, assigns `preferences`, and no longer opens a box; remove the `hive` import. `AppModel.initialise` passes `_preferenceStore`. In each reader source, declare one `static const` private descriptor per setting, keyed `'reader_ttu/<key>'` or `'reader_mokuro/<key>'` with the defaults from the spec's table. Getters become `preferences.get(_x)` and toggles `preferences.toggle(_x)`, keeping their public names.

- [ ] **Step 5: Move the rest of `AppModel` and remove Hive**

- `lastSelectedDictionaryFormat` resolves `dictionaryFormats[_preferenceStore.get(Preferences.lastSelectedDictionaryFormat)]!`, and its setter stores `uniqueKey`.
- `lastSelectedModel` and `setLastSelectedModelName` use `Preferences.lastSelectedModel`; the setter still notifies.
- `getLastPickedDirectory` / `setLastPickedDirectory` use `Preferences.lastPickedDirectory(mediaSource.uniqueKey)`. The getter returns `null` for `null`, keeps the existence check, and the setter wraps `set` in `unawaited`.
- Delete the Hive `_preferences` field, `Hive.initFlutter()`, `openBox`, `hiveDirectory` (field, getter, `createSync`) and the `hive_flutter` import.
- Rename `_preferenceStore` to `_preferences`.
- Remove `hive`, `hive_flutter` and `restart_app` from `pubspec.yaml`; run `flutter pub get`.

- [ ] **Step 6: Update `CLAUDE.md`**

- The Persistence section's Hive bullet becomes the `preference` table and `PreferenceStore`: descriptors in `Preferences` or in their source, prefixed per-source keys, the write-through cache and why, and changes to an existing key being data migrations after 1.0.
- The `AppModel` paragraph drops "the Hive preference boxes".
- "eight barrel files" becomes nine, with `preferences.dart`.
- The ground rules say "the database starts empty", without Hive.
- The `isDarkMode` example in Persistence is removed.

- [ ] **Step 7: Verify nothing references Hive and everything builds**

Run: `grep -rniE "hive|restart_app|isDarkMode|toggleDarkMode|lastSelectedMappingName|getPreference|setPreference" lib test pubspec.yaml CLAUDE.md`
Expected: no output.
Run: `flutter analyze && flutter test && flutter build apk --debug`
Expected: `No issues found!`; all tests pass; the APK builds.

- [ ] **Step 8: Commit**

`jj commit -m "Move the remaining preferences to SQLite and remove Hive"`

---

### Task 5: Device verification

No code. This needs a device or emulator with AnkiDroid installed. If none is available, hand the checklist to the user and report which checks were done.

- [ ] **Step 1: Install a fresh build** (uninstall first, so the database is new): `flutter run --release` or install the APK from Task 4.
- [ ] **Step 2: Fresh launch.** The first-launch permission explanation appears; after a restart it does not.
- [ ] **Step 3: Persistence.** Change auto search (switch), the debounce delay (number), the duplicate-check models (list) and the theme; kill and restart the app; all four keep their values.
- [ ] **Step 4: Theme.** With the settings page reached from the home tabs, switch System → Light → Dark: every screen on the stack recolours without a restart. With System, changing the OS dark mode recolours the app.
- [ ] **Step 5: Readers.** Turn off ttu's "highlight on tap"; mokuro's stays on. Each reader's volume-key setting applies in its own reader.
- [ ] **Step 6: Profiles.** Create a profile, select it, rename it: it stays selected. Delete it: Standard is selected and the creator opens normally.
- [ ] **Step 7: File picker.** Import a mokuro volume from a folder; the next import opens in that folder.
- [ ] **Step 8: Report** each check's result, with any failure described precisely, to the user.
