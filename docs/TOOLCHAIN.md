# Toolchain

| | |
|---|---|
| Flutter | 3.47.7 (Dart 3.13.5) |
| JDK | 21 (Flutter's floor for 3.47 is 17) |
| Gradle | 8.14.3 |
| AGP | 8.11.1 |
| Kotlin Gradle Plugin | 2.2.20 |
| compileSdk / targetSdk / minSdk | 36 / 32 / 24 |
| NDK | 29.0.14206865 |

Release APKs land in `build/app/outputs/apk/release/` as
`yomimoto_<version>-<abi>.apk`, with version codes
`100 * pubspecBuildNumber + {armeabi 1, arm64 2, x86_64 3}`.

Signed release builds go through `tool/build_release.sh`, which prompts for
the keystore password and passes it to Gradle as `KEYSTORE_PASSWORD` (set it
beforehand to skip the prompt); the password is never stored. The keystore
must be PKCS12, with one password for the store and the key. Its location
and alias come from `android/key.properties`, which is gitignored and never
committed:

```properties
storeFile=/absolute/path/to/release.keystore
keyAlias=yomimoto
```

A relative `storeFile` resolves against `android/app/`. Without the file or
the password, release builds fail; debug builds are unaffected. Check a
published APK with `apksigner verify --print-certs`.

## Why AGP 8, not AGP 9

`flutter create` on 3.47 emits Gradle 9.3.1 / AGP 9.1.0 / KGP 2.4.0. Flutter's
own `DependencyVersionChecker` warns below AGP 9.0.1 / Gradle 9.1.0 / KGP
2.3.20 ("support … will soon be dropped", printed on every build) and errors
below AGP 8.11.1 / Gradle 8.14 / KGP 2.2.20 / Java 17. **We are exactly on that
error floor**: the next Flutter release that raises it breaks the build, short
of `--android-skip-build-dependency-validation`. Check its thresholds
(`packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt`)
before upgrading Flutter. Two things in this project depend on staying below 9:

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
update.

It lives in `beforeProject` rather than the root `build.gradle` because
`evaluationDependsOn(":app")` makes some subprojects finish evaluating before the
root project does, and by then AGP has read `compileSdk` and rejects a write.

## Held back on purpose

Each of these is pinned below its latest release, with the reason in a comment
at the constraint itself:

| Thing | Held at | Why | What it would take to move |
|---|---|---|---|
| `targetSdk` | 32 | Raising it changes runtime behaviour, not just the build | granular media permissions, predictive back, edge-to-edge, 16 KB page-size audit |
| Material 3 | off (`useMaterial3: false`) | M3 has been the default since 3.16 and restyles AppBar tint, ListTile density, Dialog shape, Switch geometry | A deliberate restyling pass. The flag is itself deprecated, so this is a stay of execution, not a decision |
| `permission_handler` | 12.x | 13 pulls an Android implementation compiling against SDK 37 | compileSdk 37, or waiting for the platform to land |
| `dependency_validator` | removed | Needs analyzer < 13; drift_dev and dart_mappable_builder need ≥ 13 | A dependency_validator release supporting analyzer ≥ 13 |
| Text selection | deprecated `TextSelectionControls.buildToolbar` | `contextMenuBuilder` means rewriting the selection -> dictionary-lookup flow, the app's core interaction | Its own change, with device testing |
