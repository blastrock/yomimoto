# nowplaying (vendored)

| | |
|---|---|
| Source | `https://github.com/arianneorpilla/nowplaying` |
| Ref | `290ee1097d67cafc50f3aba1ba5bba01e758d877` (fork of `nowplaying` 2.0.6) |
| Upstream of that fork | `https://github.com/shinyford/nowplaying` (hosted as `nowplaying`) |
| Vendored | 2026-08-15, during the Flutter 3.13 -> 3.44 migration |

## Why the fork, not hosted `nowplaying` 3.0.3

Two reasons, and the first is the one that matters:

1. The fork carries an **unupstreamed crash fix**. In
   `NowPlayingListenerService.java`, upstream calls
   `controller.getPlaybackState().getState()` with no null check;
   `getPlaybackState()` returns null whenever a media session exists but has
   published no playback state yet, and the notification listener dies with an
   NPE. The fork null-checks it, and also guards `getSmallIcon()` behind an API
   23 check. Hosted 3.0.3 (2024) still has neither.
2. Hosted 3.0.3 is an API rewrite off a different line — Spotify controller,
   image resolvers, a reshaped `NowPlaying` class. Adopting it is feature work,
   not a toolchain migration.

## Local changes

See `local-changes.patch`.

1. `package_info` -> `package_info_plus`. The old package is discontinued and
   its Android side still declares `registerWith(Registrar)` from the removed
   v1 embedding, so it no longer compiles. Only two call sites are involved,
   both `PackageInfo.fromPlatform().packageName`, which is identical in
   `package_info_plus`. This is what dragged the dead package into the graph.
2. Declared `namespace 'com.gomes.NowPlaying'` in `android/build.gradle` and
   removed `package=` from the library manifest, as AGP 8 requires. (Hosted
   3.0.3 made the same change, so the namespace value is upstream's.)
3. `environment.sdk` upper bound widened from `<3.0.0` to `<4.0.0`.

Note the app's own `AndroidManifest.xml` registers
`com.gomes.nowplaying.NowPlayingListenerService` — lowercase, matching the Java
package, which is deliberately not the same string as the Gradle namespace.

## How to stop vendoring this

Send the NPE and API-23 guards to `shinyford/nowplaying`, then migrate the app
to the 3.x API and depend on the hosted release.
