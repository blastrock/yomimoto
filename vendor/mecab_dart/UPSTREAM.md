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
missing `namespace`, its `compileSdkVersion 33`, its `minSdkVersion 16` and the
`jcenter()` in its buildscript.

## Local changes

See `local-changes.patch`.

1. Deleted the `companion object { registerWith(Registrar) }` block and its
   import. Dead code under the v2 embedding — the app registers this plugin
   through `GeneratedPluginRegistrant`, which calls `onAttachedToEngine`.
2. `example/` (54 MB sample app) is not vendored. Nothing in the plugin build
   references it.

## How to stop vendoring this

The upstream repo has had no release since 0.1.6. Either send the deletion
upstream, or — the better long-term answer — replace the package: it is an FFI
binding to MeCab plus a trivial method channel that only implements
`getPlatformVersion`, and the app calls MeCab through the FFI side, not the
channel.

## Note on the version

`ve_dart` pins `mecab_dart: 0.1.3` exactly, which wants `ffi ^1` and declares an
sdk upper bound of `<3.0.0`. This vendored copy is forced in through
`dependency_overrides` for that reason as well as the compile fix.
