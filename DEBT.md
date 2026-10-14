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
