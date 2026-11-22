# Close a manga volume past its last page — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** In the manga reader, turning forward from the last spread closes the reader; volume keys turn one page per press.

**Architecture:** `reader.js`'s `nextPage()` sends a new `end` message when already on the last spread; `MokuroBridge` dispatches it to an `onEnd` callback; `ReaderMokuroSourcePage` pops through `Navigator.maybePop`, the same path as Back. Separately, the page's key handler stops turning on `KeyRepeatEvent`.

**Tech Stack:** Flutter/Dart, `flutter_inappwebview`, hand-written JS in `assets/manga-reader/`.

**Spec:** `docs/superpowers/specs/2026-11-22-mokuro-close-at-end-design.md`

## Global Constraints

- Manga reader only: `reader_ttu_source_page.dart` is not touched; novel volume keys keep autorepeating.
- Two separate jj commits, autorepeat first.
- `PROTOCOL_VERSION` in `assets/manga-reader/reader.js` and `MokuroBridge.protocolVersion` both go from 1 to 2.
- Every public member has a `///` doc comment; `flutter analyze` reports no issues; format new code by hand (no `dart format`); British spelling.
- No unit tests: this is WebView and page code, verified on a device (CLAUDE.md). `flutter test` must still pass.

## Review Focus

- Holding a volume key: one page turn, and the system volume does not change (repeats are handled, not ignored).
- Volume key on the last spread: closes, once; a held key does not do anything further after the pop.
- Peek mode (opened from a stash item) on its last spread: closes without saving a position.
- A dictionary popup shown on the last spread: the volume key first clears it (existing behaviour), and a tap on the left zone still closes.
- Landscape, where the last spread may be a pair: closing happens only when the spread shown is the final one, not on reaching it.

---

### Task 1: Volume keys do not autorepeat

**Files:**
- Modify: `lib/src/pages/implementations/reader_mokuro_source_page.dart:168-180`

- [ ] **Step 1:** In `onKeyEvent`, only `KeyDownEvent` turns a page. A `KeyRepeatEvent` whose `logicalKey` is `audioVolumeUp` or `audioVolumeDown` returns `KeyEventResult.handled` without turning. Key-ups still pass through (`ignored`). Rewrite the comment above to say so.
- [ ] **Step 2:** Run `flutter analyze` — expected: `No issues found!`
- [ ] **Step 3:** On a device: hold volume up in a manga volume — expected: one page turn, no volume overlay.
- [ ] **Step 4:** Commit: `jj commit -m "Stop volume keys autorepeating in the manga reader"` (with the Co-Authored-By trailer).

### Task 2: Close the reader past the last page

**Files:**
- Modify: `assets/manga-reader/reader.js` (`PROTOCOL_VERSION` line 18, `nextPage()` line 456)
- Modify: `lib/src/media/sources/mokuro_bridge.dart` (constructor, `protocolVersion`, `_dispatch`)
- Modify: `lib/src/pages/implementations/reader_mokuro_source_page.dart` (`MokuroBridge(...)` in `onWebViewCreated`)

**Interfaces:**
- Produces: JS message `{ type: 'end' }`; `MokuroBridge({..., void Function()? onEnd})` with field `final void Function()? onEnd;` documented "Called when the next page is asked for on the last spread."

- [ ] **Step 1:** `reader.js`: `PROTOCOL_VERSION = 2`. `nextPage()` sends `{ type: 'end' }` when `current === spreads.length - 1`, otherwise calls `showSpread(current + 1)` as now. `prevPage()` is unchanged.
- [ ] **Step 2:** `MokuroBridge`: `protocolVersion = 2`; add `onEnd` as above; `_dispatch` maps `case 'end': onEnd?.call();`.
- [ ] **Step 3:** `ReaderMokuroSourcePage`: pass `onEnd: () => unawaited(Navigator.maybePop(context))`, as the bar's `onExit` does (guard on `mounted`).
- [ ] **Step 4:** Run `flutter analyze` and `flutter test` — expected: no issues, all tests pass.
- [ ] **Step 5:** On a device, walk the Review Focus list: left tap zone, swipe and volume key on the last spread each return to the Manga library; reopening shows the last page; peek closes; landscape closes only from the final spread.
- [ ] **Step 6:** Commit: `jj commit -m "Close the manga reader when turning past the last page"` (with the Co-Authored-By trailer).
