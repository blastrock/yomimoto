# filesystem_picker (vendored)

| | |
|---|---|
| Source | `https://github.com/arianneorpilla/filesystem_picker` (branch `jidoujisho`, subdirectory `package/`) |
| Ref | `aedba6189cd6e995c1ff0f8451d1d5e31c2ce7c1` |
| Upstream of that fork | `https://github.com/andyduke/filesystem_picker` (hosted as `filesystem_picker`) |
| Vendored | 2026-08-15, during the Flutter 3.13 -> 3.44 migration |

## Why the fork, not hosted `filesystem_picker`

The fork is a feature rewrite off a 2.0.0 base, not a patch set: multi-root
browsing, `usedFiles` highlighting, marquee filenames and custom icons. The app
depends on those at every call site. Hosted `filesystem_picker` 4.1.0 is a
different lineage and does not have them, so it is not a drop-in.

## Local changes

See `local-changes.patch`. All of it is Flutter API renames — no behaviour
change intended.

1. `TextTheme` 2018 names -> 2021 names, using Flutter's own mapping:
   `bodyText1` -> `bodyLarge`, `headline6` -> `titleLarge`. Applies to both
   `textTheme` and `primaryTextTheme` accesses.
2. `TextTheme(button:)` -> `TextTheme(labelLarge:)` — same rename, constructor
   side.
3. `TextButton.styleFrom(primary:)` -> `foregroundColor:` (3 sites). `primary`
   was removed when `styleFrom` split it into foreground/background.
4. `environment.sdk` upper bound widened from `<3.0.0` to `<4.0.0`.
5. Dropped the `pedantic` dependency — discontinued, and nothing in `lib/`
   imports it.

## How to stop vendoring this

Either port the fork's four features onto current upstream `filesystem_picker`
and upstream them, or replace the picker outright. Until then this stays here;
the git ref it came from is a 2023 commit on a dormant third-party account.
