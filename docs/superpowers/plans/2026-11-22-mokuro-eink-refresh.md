# E-ink refresh on manga page turns Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** In the E-ink theme, every manga page change ends with a clean panel: the Supernote's own full refresh when available, a 300 ms white flash otherwise.

**Architecture:** Before drawing a different spread, `reader.js` decodes the new images off-DOM, sends `turn`, and awaits the app's reply. The app's `onTurn` arms `EinkManager.screenRefresh(false, 0)` through a new method channel, or puts up a white overlay for 300 ms, then replies; the page then swaps the spread in. The overlay goes on the next `page` event, which the page now sends once the new spread is painted.

**Tech Stack:** Flutter/Dart, flutter_inappwebview 6 (an async JavaScript handler's `Future` is awaited before `callHandler` resolves), plain JS, Java (`MainActivity`).

**Spec:** `docs/superpowers/specs/2026-11-22-mokuro-eink-refresh-design.md`

## Global Constraints

- This rewrites existing, unpushed commits. Tasks 1–3 amend `kntwylzx`
  ("Flash the screen on manga page turns…"): `jj edit kntwylzxlwlv`, work,
  and descendants rebase themselves. Task 4 edits `klpnmpkx` (close-at-end).
  Do not move bookmarks.
- Only in the E-ink theme (`appModel.themeMode == AppThemeMode.eink`) does a
  turn refresh or flash; other themes reply at once.
- Native: `screenRefresh(false, 0)` (full refresh on the next frame). Fallback:
  white only, `Duration(milliseconds: 300)`, a named constant.
- Protocol: 1 → 2 in `kntwylzx`; 2 → 3 in `klpnmpkx`.
- Internal identifiers keep upstream naming: the channel is
  `app.arianneorpilla.yuuna/eink`.
- `flutter analyze` must report no issues; `///` docs on public members;
  British spelling; format new Dart by hand (no `dart format` on existing
  files).
- Unit tests cover pure code only (no mocks): the channel wrapper and the
  page are verified on the device.

## Review Focus

- Tapping again while the page awaits a turn reply: no second `turn`, no
  stuck page; the spread drawn is the one current when the reply comes.
- A turn that ends on the same pages (forward then back during the wait, or
  rotation keeping the pages): no `page` event, so the fallback overlay must
  still go (safety timeout).
- Leaving the reader during a turn: no `setState` after dispose, timer
  cancelled; a reply the page never gets is harmless.
- An image that fails to load: `decode()` rejects; the turn must still
  happen.
- The first render and the debug page (`?debug=1`, no app): no `turn` wait
  that never resolves.

---

### Task 1: Native refresh channel

**Files:**
- Modify: `android/app/src/main/java/app/arianneorpilla/yuuna/MainActivity.java`
- Create: `lib/src/utils/misc/eink_refresh.dart`
- Modify: `lib/utils.dart` (export it, alphabetical among `misc/`)

**Interfaces:**
- Produces: `EinkRefresh.instance`; `Future<bool> get isAvailable` (asked
  once, cached; any `PlatformException` / `MissingPluginException` → `false`);
  `Future<void> refreshNextFrame()` (throws `PlatformException` on failure).

- [ ] **Step 1:** In `configureFlutterEngine`, register a second
  `MethodChannel` on `app.arianneorpilla.yuuna/eink` with methods
  `isRefreshAvailable` (→ `Boolean`) and `refreshNextFrame` (→ `null`, or
  `result.error("eink", message, null)` on failure). Resolve once, lazily,
  by reflection: `getSystemService("eink")`, then
  `getClass().getMethod("screenRefresh", boolean.class, int.class)`; any
  failure or null means unavailable. `refreshNextFrame` invokes it with
  `(false, 0)`.
- [ ] **Step 2:** Write `EinkRefresh` in `eink_refresh.dart`: a
  private-constructor singleton over a `const MethodChannel`, matching the
  interface above, with the reason for the reflection in its class doc (the
  Supernote framework's `android.os.EinkManager`, not in the SDK).
- [ ] **Step 3:** Run `flutter analyze`. Expected: `No issues found!`

### Task 2: The `turn` handshake

**Files:**
- Modify: `assets/manga-reader/reader.js`
- Modify: `lib/src/media/sources/mokuro_bridge.dart`
- Test: `test/media/mokuro_bridge_test.dart`

**Interfaces:**
- Produces: `MokuroBridge({…, Future<void> Function()? onTurn})`; the
  `mokuroHost` handler returns `onTurn`'s `Future` for `turn` (so the page
  awaits it), `null` for other messages. `MokuroBridge.protocolVersion == 2`.
- Wire: page → app `{type: 'turn'}`, no payload, awaited.

- [ ] **Step 1: Update the protocol test** in `mokuro_bridge_test.dart`:
  `expect(MokuroBridge.protocolVersion, 2)`, version 2 compatible, version 1
  not.
- [ ] **Step 2:** Run `flutter test test/media/mokuro_bridge_test.dart`.
  Expected: FAIL (version is 1).
- [ ] **Step 3:** In `mokuro_bridge.dart`: `protocolVersion = 2`, add
  `onTurn` (doc: called before the page draws a different spread; the page
  waits until the returned future completes), make `_dispatch` return
  `Future<void>?` and return `onTurn?.call()` for `'turn'`.
- [ ] **Step 4:** In `reader.js`: `PROTOCOL_VERSION = 2`. Split `render()`:
  - `buildSpread()` builds the slots for `spreads[current]` off-DOM and
    returns them with a promise of their images decoded
    (`Promise.allSettled(imgs.map((img) => img.decode()))`, so a broken
    image does not block).
  - `render()` (async): if a turn is already awaited, return. Otherwise build
    and await the decode; if the spread's pages differ from `shownPages` and
    `shownPages` is not empty, set the awaiting flag, `await send({ type:
    'turn' })`, clear the flag in `finally`, and, if `current` changed during
    the wait, rebuild for the current spread (and await its decode). Then swap
    the slots in (`hideBlock()`, `replaceChildren`), position lines, preload,
    update `shownPages` at once, and send `page` after two
    `requestAnimationFrame`s (painted).
  - Callers (`showSpread`, `relayout`, `start`) keep calling `render()`
    without awaiting it.
- [ ] **Step 5:** Run `flutter test test/media/mokuro_bridge_test.dart`.
  Expected: PASS.
- [ ] **Step 6:** Check the page in a desktop browser with `?debug=1`
  (see CLAUDE.md, "manga"): turns log `turn` then `page`, the first render
  logs only `page`, rotation (resize) still re-pairs.

### Task 3: Refresh or flash on turn

**Files:**
- Modify: `lib/src/pages/implementations/reader_mokuro_source_page.dart`
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `EinkRefresh.instance` (Task 1), `MokuroBridge.onTurn` (Task 2).

- [ ] **Step 1:** Remove the first version: `_flashBlackDuration`,
  `_flashWhiteDuration`, `_flashColour`, `_flashGeneration`, `_flash()`, and
  the flash call in `_onPage`.
- [ ] **Step 2:** Add `static const Duration _flashDuration =
  Duration(milliseconds: 300)`, `static const Duration _flashTimeout =
  Duration(seconds: 1)`, `bool _flashShown`, `Timer? _flashTimer`, and
  `Future<void> _onTurn()`, passed as `onTurn`:
  - not E-ink → return;
  - `await EinkRefresh.instance.isAvailable` → `refreshNextFrame()` and
    return; if it throws, `debugPrint` and fall through;
  - show the white overlay, wait `_flashDuration`, return if unmounted, then
    start `_flashTimer = Timer(_flashTimeout, _hideFlash)` and return.
- [ ] **Step 3:** `_hideFlash()` cancels the timer and clears `_flashShown`
  if mounted; `_onPage` calls it; `dispose` cancels the timer. The overlay
  is `if (_flashShown) const IgnorePointer(child: ColoredBox(color:
  Colors.white))`, last in the `Stack`.
- [ ] **Step 4:** In `CLAUDE.md`, "manga": one or two sentences on the
  `turn` handshake and the E-ink refresh (native via `EinkRefresh`, white
  flash otherwise). Fix the "What this is" line saying refresh behaviour is
  not started: the manga reader's is done.
- [ ] **Step 5:** Run `flutter analyze` (expect no issues) and `flutter test`
  (expect pass).
- [ ] **Step 6:** Reword `kntwylzx`: "Refresh the e-ink panel on manga page
  turns", body: Supernote `EinkManager` full refresh armed for the new page,
  300 ms white flash elsewhere, protocol 2. Keep the Co-Authored-By line.
- [ ] **Step 7:** Device check (the user builds with
  `tool/build_release.sh`; install with `adb install -r`): the spec's
  Verification. A debug build on the emulator (no `eink` service) covers
  the fallback flash.

### Task 4: Close-at-end on protocol 3

**Files:**
- Modify (in `klpnmpkx`): `assets/manga-reader/reader.js`,
  `lib/src/media/sources/mokuro_bridge.dart`,
  `test/media/mokuro_bridge_test.dart`

- [ ] **Step 1:** `jj log -r 'kntwylzxlwlv::'` for conflicts; resolve any in
  the descendants (expect `reader.js` and `mokuro_bridge.dart` near
  `nextPage` / the bridge callbacks), keeping both changes.
- [ ] **Step 2:** `jj edit klpnmpkxlwuk`; set the protocol to 3 in the three
  files (test: 3 compatible, 2 not).
- [ ] **Step 3:** Run `flutter analyze` and `flutter test`. Expected: no
  issues, pass. Then `jj new` on the top of the stack (`twoooxyq`) to leave
  the working copy there.
