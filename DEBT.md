# Debt

Shortcuts taken on purpose that will bite back if the assumption behind them
stops holding. Each entry says what was done, what it relies on, and what has
to change when that stops being true. Remove an entry once it is paid off.

## Mokuro history trimming can delete stashes

**Since:** the Drift migration (`docs/superpowers/specs/2026-10-14-drift-migration-design.md`).

`stash_item.media_item_id` references `media_item` with `ON DELETE CASCADE`.
Mokuro volumes are stored as a reading history capped at the 100 most
recently opened (`AppModel.addMediaItem`, ordered by `last_opened_at`), so
opening a 101st volume deletes the oldest `media_item` row, and the cascade
would delete its stash with it.

This is harmless only because mokuro cannot stash yet: the mokuro reader calls
`setCurrentSentence` without a position, so `AddToStashAction` refuses.

**When stashing from mokuro is added**, which is planned, the trimming
must spare items that have a stash (or mokuro must stop being a capped history
and become a library like Novels). Do not ship mokuro stashing without this.

## Un-awaited futures are not linted

**Since:** the Drift migration (`docs/superpowers/specs/2026-10-14-drift-migration-design.md`).

Moving `AppModel` from Isar's synchronous writes to Drift turned many mutators
into `Future`s. Their callers were found by hand, and a review caught seven
that had been missed: none was flagged, because `analysis_options.yaml`
enables neither `unawaited_futures` (a Future dropped inside an `async` body)
nor `discarded_futures` (an async call from a non-async block, such as a
plain `onTap` closure). Neither is in `flutter_lints`.

**To pay it off**, go over the lint rules not yet enabled that would have
caught this class of bug, starting with those two. Enable them, and mark the
deliberate fire-and-forget calls with `unawaited(...)` (for instance
`populateDefaultMapping` in `home_page.dart`, `addToSearchHistory` in the
dictionary pages, and `putMediaItem` in `reader_ttu_source_page.dart`'s
`initState`, already wrapped).

## The dictionary import holds the write lock throughout

**Since:** the Drift migration (`docs/superpowers/specs/2026-10-14-drift-migration-design.md`).

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
