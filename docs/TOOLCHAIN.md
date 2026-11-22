# Toolchain

| | |
|---|---|
| Flutter | 3.47.7 (Dart 3.13.5) |
| JDK | 21 (Flutter's floor for 3.47 is 17) |
| Gradle | 9.3.1 |
| AGP | 9.1.0 |
| Kotlin Gradle Plugin | 2.4.0 |
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

## AGP 9 and its opt-out flags

Gradle, AGP and KGP are the versions `flutter create` emits on Flutter 3.47,
so its `DependencyVersionChecker` neither errors nor warns. Check its
thresholds (`packages/flutter_tools/gradle/src/main/kotlin/DependencyVersionChecker.kt`)
before upgrading Flutter.

`android/gradle.properties` sets three AGP flags back to their AGP 8
behaviour. AGP 9 prints a deprecation warning for each, and **AGP 10 removes
all three**:

- **`android.newDsl=false`**, as in Flutter's template: Flutter's Gradle
  plugin still uses the legacy variant API, as does
  `android/app/build.gradle`'s `applicationVariants.all`, which renames the
  APKs and sets their per-ABI version codes.
- **`android.builtInKotlin=false`**, as in Flutter's template: four plugins
  still apply the Kotlin Gradle Plugin themselves (`external_path`,
  `flutter_archive`, `flutter_exit_app`, `flutter_image_compress_common`),
  which AGP 9's built-in Kotlin rejects. Flutter prints a warning naming
  them on every build, and says a future release will refuse them. With
  the flag off, Flutter applies KGP to the plugins that have moved to
  built-in Kotlin.
- **`android.r8.proguardAndroidTxt.disallowed=false`**:
  `flutter_inappwebview_android` 1.1.3 calls
  `getDefaultProguardFile('proguard-android.txt')`, which AGP 9 rejects while
  evaluating the plugin's script, too early for the shim. A library's own
  `proguardFiles` never reach the app's R8 run, so this changes nothing in the
  APK.

The app itself is Java only and applies no Kotlin plugin.

**R8's strict keep rules.** AGP 9 turns on
`android.r8.strictFullModeForKeepRules`: a `-keep class X` rule without
members no longer keeps `X`'s no-arg constructor. A library whose keep rules
predate this, and which creates a class by reflection, crashes at runtime in
release builds only. WorkManager 2.8.1 did (through Room 2.5.0's
`WorkDatabase_Impl`), which is why `flutter_logs` was removed. When adding or
updating an Android dependency, compare R8's `seeds.txt`
(`build/app/outputs/mapping/release/`) between a normal release build and
one with `-Pandroid.r8.strictFullModeForKeepRules=false`: every no-arg
constructor only the second keeps must be one the app calls directly.

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
