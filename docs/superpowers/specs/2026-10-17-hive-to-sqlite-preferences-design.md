# Move preferences from Hive to SQLite

## Goal

Hive (`hive` 2.2.3, last released in 2022) holds the app's preferences in
three boxes: `appModel` and one per reader source. It is the same kind of
unmaintained dependency that Isar was, and it splits persisted state across
two stores. Move every preference into the SQLite database, behind a typed
preference API, before 1.0, and remove Hive.

Success means:

- Every preference persists across restarts as it does today, with the same
  defaults, except for the two deliberate changes below.
- `hive` and `hive_flutter` are gone from `pubspec.yaml`, and so is
  `restart_app`.
- Preferences are covered by unit tests against in-memory SQLite.
- `flutter analyze` and `flutter test` are clean; the schema dump, its test
  helpers and slang output are regenerated.

Two behaviour changes ride along:

- **Theme** becomes three-state (system / light / dark), defaulting to
  system, and switches live without restarting the app.
- **The selected Anki profile** is stored by id instead of by label. This
  fixes a bug: renaming the selected profile currently makes
  `lastSelectedMapping` fall back to the first profile.

No data is carried over from Hive: there is no backward compatibility owed
before 1.0.

## Decisions

- **One key/value table**, not one column per setting. Adding a setting
  needs no schema change. Renaming a key, or changing a value's type or
  meaning, is a data migration: after 1.0 it bumps `schemaVersion` with no
  table change and rewrites rows in the upgrade step, tested with
  `drift_dev make-migrations`. Before 1.0 the descriptor is simply edited.
- **Defaults are constants.** Anything that used to depend on runtime state
  is either reshaped (theme, profile id) or nullable with a `null` default
  meaning "unset".
- **No cache.** Every `get` is a synchronous raw read, as `AppStore` does
  for its other reads. A cache can be added inside `PreferenceStore` later
  without touching callers.
- **No scope column.** Per-source preferences use keys prefixed with the
  source's `uniqueKey` and `/`.
- **A value that does not decode falls back to the default**, logged, rather
  than throwing. One bad row must not break startup.
- **Pass-through accessors on `AppModel` are removed.** Callers use the
  descriptors directly. Accessors that combine a preference with other
  `AppModel` state, or notify listeners, stay. The wider split of `AppModel`
  is out of scope.

## Components

### Table

In `lib/src/database/tables.dart`, part of schema version 1:

```
preference(key TEXT PRIMARY KEY, value TEXT NOT NULL)   -- value is JSON
```

A missing row means the default. The table starts empty.

### Descriptors

New folder `lib/src/preferences/`, exported by a new barrel
`lib/preferences.dart`.

```dart
class Preference<T> {
  const Preference(this.key, {required this.defaultValue});
  final String key;
  final T defaultValue;
  Object? toJson(T value) => value;
  T fromJson(Object? json) => json as T;
}

class StringListPreference extends Preference<List<String>> { … }  // casts each element
class EnumPreference<E extends Enum> extends Preference<E> { … }    // stored by name, given E.values
```

`bool`, `int`, `double` and `String`, nullable or not, use the base class.
A `double` is always written from a `double`, so it decodes as one.

App-wide descriptors are `static const` fields of `abstract final class
Preferences`, grouped with section comments. Each reader source declares
its own as `static const` fields next to the getters that use them. The
last picked directory is the one key built at runtime, a non-const
`Preference<String?>`.

### `PreferenceStore`

In `lib/src/preferences/`, built over the same `AppDatabase` and raw
`sqlite3.Database` as `AppStore`:

```dart
T get<T>(Preference<T> preference);                     // synchronous raw read
Future<void> set<T>(Preference<T> preference, T value);  // Drift upsert
```

`get` reads the row, `jsonDecode`s it and calls `fromJson`. Any exception
in decoding is logged with the key and the default is returned. `set` is an
`insertOnConflictUpdate` through Drift, so main-isolate writes still all go
through Drift. It is the only code that touches the `preference` table.

### Preferences

| Key | Type | Default | Read through |
|---|---|---|---|
| `theme_mode` | `ThemeMode` (enum) | `ThemeMode.system` | `AppModel.themeMode` / `setThemeMode` |
| `selected_mapping_id` | `int` | `AnkiMapping.standardProfileId` (1) | `AppModel.lastSelectedMapping` / `setLastSelectedMapping` |
| `last_selected_dictionary_format` | `String` | `'yomichan'` | `AppModel.lastSelectedDictionaryFormat` (resolves the registry) |
| `last_selected_model` | `String?` | `null` | `AppModel.lastSelectedModel` / setter (notifies) |
| `<source uniqueKey>/last_picked_directory` | `String?` | `null` | `AppModel.getLastPickedDirectory` / setter (checks it exists) |
| `last_selected_deck` | `String` | `'Default'` | direct |
| `current_home_tab_index` | `int` | `0` | direct |
| `first_time_setup` | `bool` | `true` | direct |
| `auto_search` | `bool` | `true` | direct |
| `auto_search_debounce_delay` | `int` | `100` | direct |
| `dictionary_entry_font_size` | `double` | `16.0` | direct |
| `maximum_terms` | `int` | `10` | direct |
| `close_on_export` | `bool` | `false` | direct |
| `saved_tags` | `String` | `''` | direct |
| `duplicate_check_models` | `List<String>` | `[AnkiMapping.standardModelName]` | direct |
| `reader_ttu/volume_page_turning_enabled` | `bool` | `true` | `ReaderTtuSource` getter |
| `reader_ttu/volume_page_turning_inverted` | `bool` | `false` | `ReaderTtuSource` getter |
| `reader_ttu/extend_page_beyond_navbar` | `bool` | `false` | `ReaderTtuSource` getter |
| `reader_ttu/adapt_ttu_theme` | `bool` | `true` | `ReaderTtuSource` getter |
| `reader_ttu/highlight_on_tap` | `bool` | `true` | `ReaderTtuSource` getter |
| `reader_mokuro/volume_page_turning_enabled` | `bool` | `true` | `ReaderMokuroSource` getter |
| `reader_mokuro/volume_page_turning_inverted` | `bool` | `false` | `ReaderMokuroSource` getter |
| `reader_mokuro/extend_page_beyond_navbar` | `bool` | `false` | `ReaderMokuroSource` getter |
| `reader_mokuro/highlight_on_tap` | `bool` | `true` | `ReaderMokuroSource` getter |
| `reader_mokuro/use_dark_theme` | `bool` | `false` | `ReaderMokuroSource` getter |

Keys keep their Hive names except where the meaning changes: `theme_mode`
(was `is_dark_mode`), `selected_mapping_id` (was `last_selected_mapping`, a
label), and `last_picked_directory` (was `last_picked_file`, which always
held a directory).

For the constant defaults, `AnkiMapping.standardModelName` and
`standardProfileName` become `static const`. `AppModel`'s
`defaultMaximumDictionaryTermsInResult`, `defaultSearchDebounceDelay` and
`defaultDictionaryFontSize` are removed; the settings page resets to the
descriptors' `defaultValue`.

### `AppModel`

- `Box _preferences` becomes `PreferenceStore _preferences`, exposed as a
  documented `preferences` getter.
- "Direct" rows in the table above lose their `AppModel` getter/setter
  pair. Callers write `appModel.preferences.get(Preferences.maximumTerms)`
  and `await appModel.preferences.set(...)`. These setters do not notify,
  as today; the settings page keeps calling `setState`.
- The other rows keep their accessors, rewritten over the store.
- `isDarkMode`, `toggleDarkMode`, `lastSelectedMappingName` and
  `populateDefaultMapping` are removed.

### Sources

`MediaSource` loses its Hive box and `getPreference`, `setPreference` and
`deletePreference`. `initialise()` becomes
`initialise(PreferenceStore preferences)` and keeps the store in a
protected field. The two reader sources read their descriptors through it.
Their public getters and toggles keep their names.

### Startup

`AppModel.initialise()` currently opens Hive first and the database last,
and the permission requests read `first_time_setup` in between. New order:

1. Package and device info.
2. Directories, including `_databaseDirectory`.
3. Open the database, build `AppStore` and `PreferenceStore`.
4. Permission requests.
5. The rest as before, with media sources initialised with the store, and
   the dictionary preload last.

`Hive.initFlutter()`, `hiveDirectory` and its `createSync` are removed.

## Theme

- `Preferences.themeMode`: `EnumPreference<ThemeMode>('theme_mode',
  ThemeMode.values, defaultValue: ThemeMode.system)`.
- `AppModel.setThemeMode` writes it and calls `notifyListeners()`.
  `main.dart` passes `appModel.themeMode` to `MaterialApp`, which already
  has `theme` and `darkTheme`.
- No restart: colours come from the theme, so rebuilding `MaterialApp` is
  enough. `restart_app` has no other user and is removed. If a device check
  shows a screen that does not update live, stop and report it rather than
  bringing the restart back.
- The settings switch becomes a "Theme" row: a `JidoujishoDropdown` with
  System, Light and Dark, built by a new `buildChoice` helper in
  `SettingsPage` next to `buildSwitch`. New strings `settings_theme`,
  `theme_system`, `theme_light`, `theme_dark` replace `settings_dark_theme`.

## Standard profile

- `AnkiMapping.standardProfileId = 1`, a `static const`.
- `AppDatabase` gets a `MigrationStrategy` whose `onCreate` runs
  `createAll()` and inserts `AnkiMapping.defaultMapping(order: 0)` with
  `id: 1`. With `AUTOINCREMENT`, SQLite then gives the next profile id 2.
  The Standard profile cannot be deleted, so id 1 is never reused.
- `populateDefaultMapping` and its "Legacy Standard" branch (upstream
  handling of a renamed note type) are removed, with its call in
  `home_page.dart`.
- `AppStore` gains `mappingById(int id)`, beside `mappingByLabel`.
  `lastSelectedMapping` is `_store.mappingById(id)!`: no fallback, the
  invariant holds by construction. `deleteMapping` of the selected profile
  and `selectStandardProfile` set the id to 1.
- `creator_page.dart` shows `lastSelectedMapping.label` instead of
  `lastSelectedMappingName`. `mappingByLabel` stays where the duplicate-name
  check needs it.

## Testing

Unit tests, against in-memory SQLite:

- `test/preferences/preference_store_test.dart`:
  - an unset key returns the default;
  - round trips for `bool`, `int`, `double`, `String`, `String?` (including
    writing `null`), `List<String>` and an enum; overwriting a value;
  - invalid JSON, a wrong type (a string for an `int`) and an unknown enum
    name each return the default.
- `test/database/`:
  - a fresh database has the Standard profile at id 1;
  - the next profile added gets id 2;
  - `replaceMappings` keeps ids.

Manual device checks:

- one setting of each kind (switch, number, list, theme) survives a restart;
- the theme switches live in all three modes, and System follows the OS;
- ttu and mokuro reader settings still apply;
- renaming the selected profile keeps it selected; deleting it selects
  Standard;
- the first-launch permission explanation shows once;
- the last picked directory is remembered when importing.

## Documentation

`CLAUDE.md`: the Persistence section replaces the Hive bullet with the
`preference` table and `PreferenceStore`, the `AppModel` paragraph drops
"the Hive preference boxes", the barrel list gains `preferences.dart` (nine barrels), and
the ground rules' "the database and Hive start empty" drops Hive.

## Out of scope

- Splitting `AppModel` beyond removing pass-through accessors.
- Caching preference reads.
- Settings export or backup.
