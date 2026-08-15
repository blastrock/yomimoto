# material_floating_search_bar_2 (vendored)

| | |
|---|---|
| Source | `https://pub.dev/packages/material_floating_search_bar_2` |
| Version | `0.5.0` |
| Vendored | 2026-08-15, during the Flutter 3.13 -> 3.44 migration |

## History

The app previously used `material_floating_search_bar` via
`arianneorpilla/material_floating_search_bar@jidoujisho`. The original upstream
(`bnxm/material_floating_search_bar`) has been **deleted from GitHub**;
`material_floating_search_bar_2` is the community continuation and already
contains the fork's patches, so the fork is no longer needed. Only the import
path changed for the app (`..._2/material_floating_search_bar_2.dart`).

## Local changes

See `local-changes.patch` — a single line.

`ThemeData.appBarTheme` changed type from `AppBarTheme` to `AppBarThemeData` in
the Flutter 3.4x line, so the local variable annotation in
`lib/src/floating_search_app_bar.dart` no longer type-checks. Published 0.5.0
predates that rename.

## How to stop vendoring this

This is a one-line compatibility fix that upstream will almost certainly make
itself. Check whether a release after 0.5.0 compiles against current Flutter; if
it does, drop `vendor/` and go back to the hosted package.
