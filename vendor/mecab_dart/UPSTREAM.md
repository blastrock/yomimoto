# mecab_dart (vendored)

| | |
|---|---|
| Source | `https://pub.dev/packages/mecab_dart` (repo: `https://github.com/dttvn0010/mecab_dart`) |
| Version | `0.1.6` (latest release) |
| Vendored | 2026-08-15, during the Flutter 3.13 -> 3.44 migration |

## Why

`MecabDartPlugin.kt` still carried the `registerWith(Registrar)` companion
object from the pre-Flutter-1.12 v1 Android embedding. Flutter has since removed
that embedding entirely, so `io.flutter.plugin.common.PluginRegistry.Registrar`
no longer resolves and the plugin fails to compile:

```
e: MecabDartPlugin.kt:9:48 Unresolved reference 'Registrar'.
```

This is a source problem, so the Gradle shim in `android/settings.gradle` cannot
reach it — hence the vendoring. The shim does still handle this package's
missing `namespace`, its `compileSdkVersion 33` and its `minSdkVersion 16`.

## Local changes

See `local-changes.patch`.

1. Deleted the `companion object { registerWith(Registrar) }` block and its
   import. Dead code under the v2 embedding — the app registers this plugin
   through `GeneratedPluginRegistrant`, which calls `onAttachedToEngine`.
2. `android/CMakeLists.txt` compiles MeCab as C++14: its sources use the
   `register` storage class, which C++17 removed and the current NDK rejects.
3. `android/build.gradle` lists `mavenCentral()` instead of `jcenter()`, which
   Gradle 9 removed.
4. `example/` (54 MB sample app), `analysis_options.yaml` and `mecab_dart.iml`
   are not vendored. Nothing in the plugin build references them.

## How to stop vendoring this

The upstream repo has had no release since 0.1.6. Either send the deletion
upstream, or — the better long-term answer — replace the package: it is an FFI
binding to MeCab plus a trivial method channel that only implements
`getPlatformVersion`, and the app calls MeCab through the FFI side, not the
channel.

## Note on the override

`ve_dart` asks for the hosted `mecab_dart`, and pub refuses one package from two
sources, so this copy is also forced in through `dependency_overrides`.
