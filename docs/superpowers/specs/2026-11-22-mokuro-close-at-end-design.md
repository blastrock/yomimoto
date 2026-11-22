# Close a manga volume when turning past its last page

## Intent

In the manga reader, turning forward from the last spread does nothing.
It should leave the reader and return to the Manga library, as Back does.
There is no way to open the next volume today, so the library is the
right place to land.

Holding a volume key repeats page turns, which would race straight out of
the book; volume keys stop autorepeating, in a separate commit.

## Goals and non-goals

- Goal: next page on the last spread closes the reader, whether by tap
  zone, swipe or volume key, in normal and peek mode.
- Goal: in the manga reader, one volume key press turns one page.
- Non-goal: the novel (ttu) reader; its keys keep autorepeating.
- Non-goal: anything at the first page; previous page there stays a no-op.
- Non-goal: opening the next volume.

## Approaches

- **The page reports the end (chosen).** `nextPage()` in `reader.js`
  sends an `end` message when already on the last spread; the app pops.
  It sees every way of turning a page.
- Detect it in Flutter from the last `page` event: rejected, tap zones and
  swipes are handled in the page, and a turn that turns nothing never
  reaches the app.
- Close from the page: impossible, only the app can leave the screen.

## Design

**Commit 1: no autorepeat.** In `reader_mokuro_source_page.dart`'s
`onKeyEvent`, only `KeyDownEvent` turns a page. A `KeyRepeatEvent` of a
volume key is still returned as handled, doing nothing, so holding the
key does not change the system volume.

**Commit 2: close at the end.**
- `reader.js`: `nextPage()` on the last spread sends `{type: 'end'}`;
  `PROTOCOL_VERSION` goes up by one.
- `MokuroBridge`: an `onEnd` callback for that message; `protocolVersion`
  goes up to match.
- `ReaderMokuroSourcePage`: `onEnd` runs `Navigator.maybePop(context)`,
  the same path as Back and the bar's exit button, so the position is
  saved as it is today.

## Left to the builder

Naming, and whether the bridge test (if any covers message parsing) gains
a case for `end`.
