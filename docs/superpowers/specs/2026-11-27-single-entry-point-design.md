# Single entry point

## Intent

Make the launcher icon the app's only way in. The share, text-selection
and web-search entries are fragile (an intent with any other action, or
none, gives a black screen: `home` is an empty `Scaffold` unless the
launch was `MAIN`) and do not belong in a book reader.

## Goals

- `MainActivity` keeps only the `MAIN`/`LAUNCHER` intent filter.
- `main.dart` no longer reads intents: `home` is always `HomePage`, so
  any launch (`adb shell am start -n ...` included) shows the app.
- Everything that existed only for those entries goes: `handleIntent` and
  its actions, `killOnPop` (on `openRecursiveDictionarySearch`,
  `openCreator`, `openMedia`, `RecursiveDictionaryPage`, `CreatorPage`),
  `_shouldKillMediaOnPop`, `AppModel.shutdown()`, `isDatabaseOpen` and its
  guards, `databaseCloseNotifier`, and the `receive_intent` and
  `flutter_exit_app` packages.
- CLAUDE.md's list of removed upstream features names these intents.
- The "launch with the MAIN action" bullet is deleted from the
  dev-environment memory.

## Non-goals

- No replacement for looking up text selected in other apps: that
  capability is dropped on purpose.

## Approaches

One sensible way: delete the entries and their plumbing. Keeping the
filters but routing unknown actions to `HomePage` would fix the black
screen yet keep the entries the user wants gone.

## Left to the builder

Ordering of the removal into commits; verification is `flutter analyze`,
`flutter test`, and launching on the emulator both with and without the
`MAIN` action.
