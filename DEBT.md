# Debt

Shortcuts taken on purpose that will bite back if the assumption behind them
stops holding. Each entry says what was done, what it relies on, and what has
to change when that stops being true. Remove an entry once it is paid off.

## The analyzer's strict modes are off

`strict-casts`, `strict-inference` and `strict-raw-types` (under
`analyzer: language:`) are not enabled. Together they report about 250
diagnostics, mostly implicit `dynamic` casts and inferences that silently fell
back to `dynamic`, so a type error there only shows at runtime.

**To pay it off**, enable them one at a time and add the explicit types or
casts they ask for.

## The dictionary import holds the write lock throughout

**Since:** the Drift migration.

`depositDictionaryDataHelper` imports a dictionary in one `BEGIN IMMEDIATE`
transaction, so nothing is written if it fails. That holds the database's
write lock for the whole import, which can take minutes. A Drift write from
the main isolate meanwhile waits up to the 10 s `busy_timeout`, freezing the
UI, and then fails with "database is locked". Reads are unaffected (WAL).

This is harmless only because the import dialog is modal
(`DictionaryDialogImportPage` is a `PopScope(canPop: false)` dialog shown
with `barrierDismissible: false`), so nothing in the app writes during an
import.

**If imports become non-modal** (running in the background while the user
reads), either queue main-isolate writes until the import ends, or commit
the import in batches and mark the dictionary incomplete until its last
batch, deleting incomplete dictionaries on failure and at startup.

## The ttu `theme` event has no listener

**Since:** the dictionary popup stopped adapting to the reader's theme.

The app now dictates the theme, so the popup no longer follows the book's page
colours. ttu still sends a `theme` event on load and on every theme change,
and `TtuBridge` still parses it into a `TtuThemeEvent` (covered by
`test/media/ttu_bridge_test.dart`), but nothing passes an `onTheme` callback,
so it is dropped. It was kept to leave the protocol and the pinned ttu build
untouched.

**When ttu is made to follow the app's theme** (a host command pushing the
app's colours), rework the event or remove it from both sides of the bridge
and bump the protocol version.

## Lone surrogate escapes in dictionary banks are stored as invalid UTF-8

**Since:** the SQL dictionary import.

`importYomichanBanks` hands each bank's bytes to SQLite's JSON functions. The
bytes are validated as UTF-8 in Dart first, but a JSON escape for a lone
surrogate (`"\ud800"`) is valid UTF-8 source that SQLite decodes to the bytes
`ED A0 80`, which are not valid UTF-8. The old Dart import stored U+FFFD
there. `sqlite3` decodes text strictly, so such a row would import and then
throw a `FormatException` when it is looked up.

This relies on no real dictionary containing a lone surrogate escape, which
JMdict and the other dictionaries tried do not.

**To pay it off**, reject (or replace) such text after staging, for example with
a check on the staged text columns for the bytes `ED A0`..`ED BF`, or scan the
bank for `\ud[89a-f]` escapes that are not part of a surrogate pair.
