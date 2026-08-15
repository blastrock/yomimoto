# Toolchain

Migrated from Flutter 3.13.5 / Dart 3.0 / JDK 11 / AGP 7.1.2 in August 2026.

| | |
|---|---|
| Flutter | 3.44.8 (Dart 3.12.2) |
| JDK | 21 (Flutter's floor for 3.44 is 17) |
| Gradle | 8.14.3 |
| AGP | 8.11.1 |
| Kotlin Gradle Plugin | 2.2.20 |
| compileSdk / targetSdk / minSdk | 36 / 32 / 24 |
| NDK | 29.0.14206865 |

Build: `flutter build apk --release --split-per-abi`. Outputs land in
`build/app/outputs/apk/release/` as `jidoujisho_yuuna_<version>-<abi>.apk`, with
version codes `100 * pubspecBuildNumber + {armeabi 1, arm64 2, x86_64 3}`.

## Why AGP 8, not AGP 9

`flutter create` on 3.44 emits Gradle 9.1.0 / AGP 9.0.1. We are on the versions
Flutter's own `DependencyVersionChecker` treats as current instead (it warns
below AGP 8.11.1 / Gradle 8.14 / KGP 2.2.20 and errors below AGP 8.6 / Gradle
8.7 / Java 17). Two things in this project depend on staying below 9:

- `android/app/build.gradle` renames APK outputs and offsets per-ABI version
  codes through the **legacy variant API** (`applicationVariants.all`), which
  AGP 9 removed.
- Several plugins still call **`jcenter()`** in their own buildscript blocks.
  Gradle 9 removed the method, so those projects fail to configure at all.

Moving to 9 is a real project: it needs a replacement version-code scheme and
those plugins vendored or dropped.

## Legacy-plugin shim

`android/settings.gradle` carries a `gradle.beforeProject` hook that, for every
subproject, seeds buildscript repositories and then fills in `namespace`,
`compileSdk`, `minSdk` and the Java/Kotlin target. Several plugins in this graph
predate all of those requirements.

**This shim exists so those packages can stay hosted.** Patching each one into
`vendor/` would freeze it at today's source; the shim keeps working as they
update. Reach for `vendor/` only when a package needs actual *source* changes —
see `vendor/README.md`.

It lives in `beforeProject` rather than the root `build.gradle` because
`evaluationDependsOn(":app")` makes some subprojects finish evaluating before the
root project does, and by then AGP has read `compileSdk` and rejects a write.

## Held back on purpose

Each of these is pinned below its latest release, with the reason in a comment
at the constraint itself:

| Thing | Held at | Why | What it would take to move |
|---|---|---|---|
| `targetSdk` | 32 | Raising it changes runtime behaviour, not just the build | audio_service foreground-service manifest, granular media permissions, predictive back, edge-to-edge, 16 KB page-size audit |
| Material 3 | off (`useMaterial3: false`) | M3 has been the default since 3.16 and restyles AppBar tint, ListTile density, Dialog shape, Switch geometry | A deliberate restyling pass. The flag is itself deprecated, so this is a stay of execution, not a decision |
| `infinite_scroll_pagination` | 4.x | 5.0 replaced `PagingController` wholesale (`firstPageKey`/`addPageRequestListener`/`appendPage` -> `fetchPage` + `state`) | A UI rewrite across 4 files |
| `permission_handler` | 12.x | 13 pulls an Android implementation compiling against SDK 37 | compileSdk 37, or waiting for the platform to land |
| `web_socket_channel` | 2.x | `flutter_gpt_tokenizer` -> `flutter_rust_bridge` 1.x pins it | Replacing `flutter_gpt_tokenizer` |
| `dart_mappable_builder` | < 4.8 | Its analyzer range must overlap `isar_community_generator`'s (`>=8 <11`) | Whichever generator widens first |
| `dependency_validator` | removed | Needs analyzer < 13, `dart_mappable_builder` needs ^13 | Same |
| Text selection | deprecated `TextSelectionControls.buildToolbar` | `contextMenuBuilder` means rewriting the selection -> dictionary-lookup flow, the app's core interaction | Its own change, with device testing |

`dependency_overrides` holds four entries, each documented in `pubspec.yaml`:
`mecab_dart` and `path` break constraint collisions with dormant packages,
`mime` reconciles `local_assets_server` with `share_plus` 13, and
`freezed_annotation`/`gap` exist only to satisfy the `spaces` fork.

## Known debt

- **`spaces`** is imported in 69 files and is a dead package pinned to a
  third-party git ref, declaring `flutter: ">=2.0.0 <3.0.0"`. It is the sole
  reason for the `freezed_annotation` and `gap` overrides. Its API is thin
  (`SpacedColumn`, `Space.*`) and maps onto `Gap`/`SizedBox`. Biggest single
  cleanup available.
- **Remaining third-party git refs**: `blurrycontainer`, `subtitle`, `ve_dart`,
  `spaces`. Each is a build dependency on someone else's account staying alive —
  which is how `material_floating_search_bar` became a problem when its upstream
  was deleted. Mirror or vendor them.
- **`change_notifier_builder`** is discontinued (-> `multi_listenable_builder`).
- **`flutter_gpt_tokenizer`** sits on `flutter_rust_bridge` 1.x, four majors
  behind, and is what holds `web_socket_channel` back.
- 144 `flutter_lints` 6 style infos on pre-existing code (`unnecessary_underscores`,
  `use_build_context_synchronously`, ...). No deprecations remain.

## Not verified on device

The migration is verified only as far as *it builds*: `flutter analyze` is clean
of errors and deprecations, and both debug and release APKs link. Nothing has
been run on hardware. Before trusting a build, back up (Isar and Hive live in
internal storage — take a full in-app export off-device) and check at minimum:

- dictionary import and lookup (confirms `isar_community` reads the existing DB)
- text selection -> dictionary lookup in reader and player
- embedded-subtitle extraction and Anki MP3 clips (the ffmpeg-kit swap)
- audio output during playback (VLC moved from a fork to upstream 7.4.4)
- volume-key page turning in the TTU reader and mokuro browse (the
  `onKey` -> `onKeyEvent` change)
- back-button behaviour on player, reader, browser and creator pages
  (`WillPopScope` -> `PopScope` inverts the control flow)
- the playback-position hand-off to and from mpv/Jellyfin (`receive_intent`)
- blur settings surviving an upgrade (the persisted colour format was preserved
  by hand)
- both light and dark themes, to confirm `useMaterial3: false` held the look
