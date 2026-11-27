# Single Entry Point Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the launcher icon the app's only entry point, so every launch shows `HomePage`.

**Architecture:** Delete the non-`MAIN` intent filters and `main.dart`'s intent handling, then delete the kill-on-pop/shutdown plumbing that only those entries used, then the docs and memory that describe them.

**Tech Stack:** Flutter/Dart, Android manifest, jj.

**Spec:** `docs/superpowers/specs/2026-11-27-single-entry-point-design.md`

## Global Constraints

- Work in the default workspace, on top of `Add the single entry point design`.
- No backward compatibility, no migration (CLAUDE.md ground rules).
- `flutter analyze` must report no issues, infos included; `flutter test` must pass.
- Format edited code by hand to match the file; do not run `dart format`.
- Android builds need `ANDROID_HOME=/home/blastrock/android/android-sdk-linux`; run `flutter clean` first if `GeneratedPluginRegistrant` fails with "cannot find symbol".
- No unit test can cover this (AppModel and the activity are device-tested only): each task's test is a check on emulator `emulator-5554`.
- Commit each task with `jj describe -m ...` then `jj new`; never move bookmarks.

## Review Focus

1. Closing the dictionary search (back button, or tapping outside the search bar) pops back to the page it came from — Task 2, step 4.
2. Closing the card creator, after exporting or by backing out, returns to the reader or dictionary — Task 2, step 4.
3. Leaving a reader returns to its library tab with the bars back — Task 2, step 4.
4. A launch without the `MAIN` action (`adb shell am start -n ...`) shows the home page, not black — Task 1, step 4.
5. Launching again while the app is open (`singleTask`) brings back the same screen, not a reset — Task 1, step 4.

---

### Task 1: Remove the intent entries

**Files:**
- Modify: `android/app/src/main/AndroidManifest.xml` (the `SEND`, `WEB_SEARCH`, `SEARCH`, `PROCESS_TEXT` filters and their comments)
- Modify: `lib/main.dart` (`_isMainIntent`, `_intentsSubscription`, the intent callbacks in `initState`, the cancel in `dispose`, `handleIntent`, `textContextMenuAction`, `textShareIntentAction`, `home`)
- Modify: `pubspec.yaml`, `pubspec.lock` (drop `receive_intent`)

**Interfaces:**
- Produces: no caller passes `killOnPop: true` any more (Task 2 relies on this).

- [ ] **Step 1: Delete the four non-`MAIN` intent filters**, keeping `MAIN`/`LAUNCHER` and everything else in the manifest.

- [ ] **Step 2: Delete the intent handling in `lib/main.dart`**: `home` returns `const HomePage()` unconditionally (or inline it into `MaterialApp` and drop the getter); remove the imports that become unused (`receive_intent`, likely `dart:convert` and `package:yuuna/creator.dart`). Keep `WidgetsBindingObserver` only if something else in the state still uses it.

- [ ] **Step 3: Remove `receive_intent` from `pubspec.yaml`, run `flutter pub get`, then `flutter analyze` and `flutter test`.**
Expected: `No issues found!`, all tests pass, `pubspec.lock` no longer lists `receive_intent`.

- [ ] **Step 4: Check on the emulator.** Build and install a debug APK (`flutter build apk --debug`, `adb install -r`), then:
  - `adb shell am force-stop org.kaqui.yomimoto && adb shell am start -n org.kaqui.yomimoto/app.arianneorpilla.yuuna.MainActivity` → the home page with the Novels tab, not black.
  - Open the Dictionary tab, run the launcher command with `-a android.intent.action.MAIN -c android.intent.category.LAUNCHER` → still on the Dictionary tab.
  - `adb shell cmd package query-activities -a android.intent.action.PROCESS_TEXT -t text/plain | grep yomimoto` → nothing.

- [ ] **Step 5: Commit** — `Make the launcher the only entry point`, its body saying the share and text-selection lookups from other apps are gone and that any launch now shows the home page.

### Task 2: Remove kill-on-pop and shutdown

**Files:**
- Modify: `lib/src/models/app_model.dart` (the `killOnPop` parameter of `openRecursiveDictionarySearch` ~1462, `openMedia` ~1509 and `openCreator` ~1618; `_shouldKillMediaOnPop` and its check in `closeMedia`; `databaseCloseNotifier` ~157; `isDatabaseOpen`/`_isDatabaseOpen`/`shutdown()` ~1949; the `flutter_exit_app` import)
- Modify: `lib/src/pages/implementations/recursive_dictionary_page.dart`, `creator_page.dart` (the `killOnPop` field and constructor parameter, and every `if (widget.killOnPop) … shutdown()` branch: keep the non-kill path, e.g. `Navigator.pop`/`return true`; the `isDatabaseOpen` guards)
- Modify: `lib/src/pages/implementations/home_page.dart` (the `databaseCloseNotifier` listener and `isDatabaseOpen` guard)
- Modify: every caller passing `killOnPop: false`: `base_page.dart`, `base_source_page.dart`, `home_page.dart`, `reader_mokuro_source_page.dart`, `reader_ttu_source_page.dart`, `card_creator_action.dart`, `search_dictionary_enhancement.dart`, plus the internal calls in `app_model.dart`, `recursive_dictionary_page.dart` and `creator_page.dart`
- Modify: `pubspec.yaml`, `pubspec.lock` (drop `flutter_exit_app`)
- Modify: `DEBT.md` (~line 20) and `docs/TOOLCHAIN.md` (~line 49): the built-in Kotlin holdouts become two plugins, `flutter_archive` and `flutter_image_compress_common`

**Interfaces:**
- Consumes: Task 1 (no `killOnPop: true` callers).
- Produces: `openRecursiveDictionarySearch`, `openMedia`, `openCreator`, `RecursiveDictionaryPage` and `CreatorPage` without `killOnPop`; no `AppModel.shutdown`, `isDatabaseOpen` or `databaseCloseNotifier`.

- [ ] **Step 1: Remove the parameter, field, branches and members above.** `grep -rn -E "killOnPop|shutdown\(|isDatabaseOpen|databaseCloseNotifier|FlutterExitApp" lib` → nothing.

- [ ] **Step 2: Remove `flutter_exit_app` from `pubspec.yaml`, run `flutter pub get`; fix the DEBT.md and TOOLCHAIN.md wording** (re-read each sentence: "three plugins" becomes "two").

- [ ] **Step 3: Run `flutter analyze` and `flutter test`.**
Expected: `No issues found!`, all tests pass.

- [ ] **Step 4: Check on the emulator** (rebuild and reinstall; `flutter clean` first if the registrant fails):
  - Dictionary tab: search a word, open a result's nested search, press back, then tap outside the search bar → each closes back to the previous page; the app stays open.
  - Open a book in Novels, tap a word, open the creator from the result, back out of it → back in the book; leave the book → the Novels tab with its bars.
  - Export a card to AnkiDroid from the creator → the creator closes back to the reader; the app stays open.

- [ ] **Step 5: Commit** — `Remove the kill-on-pop path and AppModel.shutdown`.

### Task 3: Docs, memory and cleanup

**Files:**
- Modify: `CLAUDE.md` line ~11 (the deleted-features list: replace "image share intents" with the share, text-selection and web-search entries, so the list says the launcher is the only way in)
- Modify: `/home/blastrock/.claude/projects/-home-blastrock-work-yomimoto/memory/dev-environment-pitfalls.md` (delete the "Launch the app with … MAIN action" bullet; drop "launch with the MAIN action" from its `description`)
- Modify: `/home/blastrock/.claude/projects/-home-blastrock-work-yomimoto/memory/MEMORY.md` (drop "launch the app with the MAIN action (else black screen)" from that line's hook)
- Delete: `docs/superpowers/specs/2026-11-27-single-entry-point-design.md`, this plan, and `docs/superpowers/` if it is then empty

- [ ] **Step 1: Edit CLAUDE.md and the two memory files as above.** `grep -rn -i "MAIN action\|PROCESS_TEXT\|share intent" CLAUDE.md /home/blastrock/.claude/projects/-home-blastrock-work-yomimoto/memory/` → nothing stale.

- [ ] **Step 2: Delete the design and plan.** `grep -rn "single-entry-point" .` (excluding `build/`) → nothing.

- [ ] **Step 3: Commit** — `Document the single entry point and remove its design and plan`.
