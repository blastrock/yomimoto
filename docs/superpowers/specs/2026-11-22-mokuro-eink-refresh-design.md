# E-ink refresh on manga page turns

## Intent

On a Supernote Nomad, the manga reader ghosts from the first page turn on,
and the ghosting builds up. When the theme is E-ink, every page turn should
clear it with a full refresh. The Nomad is the device this is for; other
e-ink devices get a portable fallback.

## Goals, non-goals

- Goal: in the E-ink theme, each page change in the manga reader ends with a
  clean panel.
- Goal: on a Supernote, use its own full refresh; elsewhere, a white flash.
- Non-goals: the novel reader (it could reuse this later), the other themes,
  a separate on/off setting (the E-ink theme is the switch), and any other
  e-ink tuning (animations, partial refresh).

## What the device taught us

- The Nomad's panel updates far slower than Android draws. Android composites
  at 60 Hz; Ratta's e-ink compositor starts a panel update with whatever frame
  is current and drops frames replaced meanwhile. A 150 ms black-then-white
  overlay never reached the panel; 300 ms showed only the white.
- The first version flashed after the page had drawn the new spread, so every
  turn spent one panel update on the ghosted new page before the flash.
- A single white frame of 300 ms, before the new page, clears the ghosting:
  black is not needed.
- The Supernote framework has `android.os.EinkManager`
  (`getSystemService("eink")`). `screenRefresh(boolean afterWindowHide, int
  resv)` asks the compositor for a full (GC) refresh: `resv == 1` at once
  (what the launcher's sidebar swipe uses), `resv == 0` on the next frame
  drawn. The method is flagged public SDK for hidden-API checks, the service
  checks no permission, and SELinux lets ordinary apps find it
  (`untrusted_app_all`). Calling it over binder from adb refreshed the panel.

## Approaches

- **A. Arm the native refresh, then draw (picked).** Call
  `screenRefresh(false, 0)` before the page draws the new spread, so the
  compositor draws the new page with the full waveform: one panel update per
  turn. Risk: if the next frame is not the finished page (an image not yet
  decoded), that turn still ghosts.
- **B. Draw, then refresh at once.** Call `screenRefresh(false, 1)` once the
  new spread is painted: a fast ghosted draw, then the full refresh, two
  panel updates per turn. Does not depend on what "next frame" means; the
  fallback if A misfires on the Nomad.

You picked A.

## Design

- **The page asks before drawing.** In `reader.js`, when `render()` is about
  to show a different spread, and it is not the first render, it sends a new
  `turn` message and awaits the app's reply before replacing the spread.
  `send` already awaits `callHandler`, which resolves when the Dart handler's
  `Future` completes. A turn asked for while one is awaited does not start a
  second wait: when the reply comes, the page draws whatever spread is
  current then. `page` stays as it is. Rotation re-pairing goes through
  `render()` too, so it refreshes as well.
- **The app answers.** `MokuroBridge` gains an `onTurn` callback returning a
  `Future`, which the handler returns so the page waits on it. Outside the
  E-ink theme it completes at once.
  - **Native:** in the E-ink theme, when the Supernote refresh is available,
    the app arms it (`screenRefresh(false, 0)`) and replies.
  - **Fallback:** otherwise, it covers the screen in white, waits 300 ms
    (a named constant), and replies; the page draws under the overlay, and
    the overlay goes once the new spread has been painted. The overlay is
    `IgnorePointer`, at the top of the page's `Stack`. The black step and
    the generation counter of the first version go.
- **Native side.** A method channel in `MainActivity.java`, beside the
  AnkiDroid one: one method says whether the refresh is available
  (`getSystemService("eink")` is non-null and has
  `screenRefresh(boolean, int)`, found by reflection), the other arms it.
  The app asks once and remembers the answer.
- **Protocol.** `PROTOCOL_VERSION` / `MokuroBridge.protocolVersion` go from
  1 to 2 in this change; the close-at-end change, which already bumped to 2,
  bumps to 3 instead.

## Left to the builder

- How the page knows the new spread is painted before the fallback overlay
  goes (for instance, `page` sent after two animation frames, or a separate
  message).
- What a native call that throws does (log it and fall back to the flash
  for that turn is fine).
- Names of the channel, its methods and the Dart wrapper; where the wrapper
  lives.

## Verification

Manual, on the Nomad, in the E-ink theme: turn pages by tap, by swipe, from
the bar and by jumping to a page; each turn should show the new page once,
with no ghosting and no flash. Then, on a device or emulator without the
Supernote service, in the E-ink theme: a white flash, then the new page.
Light and dark themes: no flash, no refresh, turns as fast as before. Unit
tests cover the protocol version; `turn` carries nothing to parse.
