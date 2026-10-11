# Stash — design

Date: 2026-10-11

## Purpose

While reading, the user finds words they want to learn but does not want to
break the reading flow to make Anki cards. The **stash** is a per-book list of
saved words. Each item keeps everything needed to make a card later — above
all the full sentence and the word's position in the book, so the user can
jump back to it for context.

The name was freed for this by commit `66b5fd68` ("Remove the Stash
feature"); nothing of upstream's string-only stash is reused.

## Scope

- **In:** novels (ttu reader). Adding words from the dictionary popup, a stash
  page per book, an item detail page with jump / Instant Export / Card Creator,
  multi-select deletion.
- **Out, but the data model must not prevent it:** mokuro (manga). Its
  position would be a page number, and its cards need the page image captured
  at add time; that capture is future work.
- **Out:** sorting by date (the date is stored for it), any automatic change
  to an item after a card is made from it, a "continue reading from here"
  action after a jump.

## Decisions

| Topic | Decision |
|---|---|
| Readers | Novels only now; model keyed by media source so mokuro fits later. |
| Dictionary data | Reference (term + reading + selected entry's dictionary name), resolved live at card time, plus a definitions snapshot for display and fallback. |
| Card context | Passed explicitly to fields instead of read from global reader state. |
| After card creation | Nothing happens to the item. |
| Duplicates | One item per word (term + reading) per book. A second add does nothing. |
| Ordering | By position in the book. Date added is stored for later sorting options. |
| Adding | A regular `QuickAction`, in the 6th default slot. |
| Jumping | "Peek" session: the reader opens at the word and does not save its bookmark for that whole session. |
| Feedback | `Fluttertoast` toasts, as everywhere else in the app. |

## Data model

New Isar collection, added to `globalSchemas` in `app_model.dart`:

```dart
@Collection()
class StashItem {
  Id id = Isar.autoIncrement;

  /// Unique composite index on
  /// (mediaSourceIdentifier, mediaIdentifier, term, reading).
  String mediaSourceIdentifier; // which reader: ttu now, mokuro later
  String mediaIdentifier;       // the book, e.g. 'b.html?id=42'

  String term;
  String reading;               // term + reading = DictionaryHeading identity

  String? dictionaryName;       // selected entry's dictionary; null = whole heading
  List<String> definitions;     // display snapshot

  String sentence;              // full sentence
  int wordStart;                // UTF-16 offset of the word in [sentence]
  int wordLength;               // UTF-16 length of the word

  int position;                 // source-defined: ttu = character count, mokuro = page
  DateTime dateAdded;
}
```

- `definitions` holds the selected entry's definitions, or, when the action
  was invoked on the whole heading, those of every non-hidden entry.
- `sentence`, `wordStart` and `wordLength` rebuild the
  `JidoujishoTextSelection` used by the Sentence and Cloze fields.
- Mokuro-specific fields (page image) are not reserved; the fork owes no
  migrations, so they can be added when mokuro support is built.
- Deleting a book deletes its stash, wherever the Novels mirror loses a row:
  the delete operation and `syncLibrary` reconciliation.

## ttu bridge (protocol v2 → v3)

Changes in ebook-reader-lite live in `apps/web/src/lib/host/`, with small
hooks in `routes/b/+page.svelte`.

1. **`tap` event gains `position`**: the absolute character count of the
   tapped character, in ttu's bookmark units (`getCharacterCount`, Japanese
   characters only) — the accumulated count of the paragraphs before the
   tapped one plus the count within it up to the tapped character. `-1` if it
   cannot be determined. Dart's `TtuTapEvent` gains a matching `position`.
2. **`peek=<position>` URL parameter** on `b.html?id=N&peek=12345`: the reader
   opens scrolled to that position instead of the saved bookmark, and saves no
   bookmark for the rest of the session — neither the exit-time save nor
   auto-bookmark. Leaving the reader therefore keeps the previous bookmark.
   A URL parameter rather than a command avoids racing ttu's initial scroll to
   its bookmark.

`PROTOCOL_VERSION` (`host-bridge.ts`) and `TtuBridge.protocolVersion` both go
to 3; a new fork release is pinned in `tool/ttu.lock`.

These two pieces are the only bookmark-related logic. They are meant to be
replaced when bookmark storage moves to the Flutter side (future work).

## Dart side

### Explicit card context

A value class `CreatorContext` holds `JidoujishoTextSelection sentence` and
`MediaItem? mediaItem`.

- `Field.onCreatorOpenAction` gains a required `creatorContext` parameter.
  `SentenceField` and the three Cloze fields read `creatorContext.sentence`
  instead of `appModel.getCurrentSentence()`; `ContextField` reads
  `creatorContext.mediaItem?.title` instead of `appModel.currentMediaItem`.
- `InstantExportAction` and `CardCreatorAction` each expose a public method
  taking a `CreatorContext` explicitly. Their `executeAction` builds the
  context from the current reader state and calls it, so popup behaviour is
  unchanged. The stash item page calls these methods with a context built
  from the item.
- The `overridesAutoImage` / `overridesAutoAudio` branch of Instant Export
  only runs while media is open, so it is skipped from the stash. That is
  correct for novels.

### Recording the position

`MediaSource.setCurrentSentence` also stores the tap's `position`, so the
reader's current state holds sentence and position together.
`JidoujishoTextSelection` is unchanged.

### `AddToStashAction`

A `QuickAction` with key `add_to_stash` and a bookmark-add icon.

- Registered in `AppModel.populateQuickActions`; added as slot 5 of
  `AnkiMapping`'s default actions.
- If no reader is open, or there is no current media item or no position, it
  does nothing but show a toast.
- Otherwise it builds a `StashItem` from the heading, the selected entry, the
  current sentence and position, and the current media item, and writes it.
  On a unique-index conflict it shows an "Already stashed" toast; on success
  "Added to stash".

### `AppModel` additions

- `putStashItem(StashItem)` — reports whether it was a duplicate.
- `getStashItems(MediaItem)` — sorted by `position` ascending.
- `deleteStashItems(List<int> ids)`.
- `deleteStashForMedia(MediaItem)` — called from the Novels delete path and
  from `syncLibrary` when a mirror row is removed.

### Resolving an item at card time

1. Fetch the heading by its id, the same hash of term and reading that
   `DictionaryHeading.id` computes. If
   absent, use a transient `DictionaryHeading(term, reading)` with no entries:
   Term, Reading, Sentence, Cloze and Context still fill; meaning fields come
   out empty.
2. Among the heading's entries, pick the one whose `dictionary.value.name`
   equals `dictionaryName`. If `dictionaryName` is null or no entry matches,
   use `null` (whole heading).

### Opening a book at a position

A `ReaderTtuSource` helper opens the item's `MediaItem` via
`appModel.openMedia`, as the Novels tab does, with the URL
`b.html?id=N&peek=<position>`.

## UI

### Entry point

The Novels long-press dialog gains a **Stash** button next to Delete, via
`ReaderTtuSourceHistoryPage.extraActions`. It pushes `StashPage(item)`.

### `StashPage`

Built after `SettingsPage`.

- App bar: "Stash", with the book title as subtitle.
- List in story order. Each tile: **term** with its reading, and all
  definitions from the snapshot on one ellipsised line.
- Empty state: a centred "No stashed words yet", with a hint to use the stash
  action in the dictionary popup.
- Multi-select: long-press an item to enter selection mode; tap toggles. The
  app bar shows "N selected" with **Select all** and **Delete**. Delete asks
  for confirmation ("Delete N items?"). Back or ✕ leaves selection mode.
- Tap outside selection mode opens `StashItemPage`.

### `StashItemPage`

A full page showing term with its reading, the source dictionary name (or
"All dictionaries"), the full definitions snapshot, the full sentence with the
word highlighted, and the date added.

Actions:

- **Jump to word** — opens the book with `peek`. Returning from the reader
  comes back to this page.
- **Instant export** and **Card creator** — call the explicit-context methods
  with the resolved heading and entry. Their icons turn red on an Anki
  duplicate via the existing `getIconColor`.
- **Delete** — confirms, then returns to the list.

If the dictionary entry can no longer be resolved, the page shows a small note
saying so; the actions still work through the fallbacks above.

### Strings

New keys in `lib/i18n/strings.i18n.json`, regenerated with `dart run slang`.

## Verification

There are no automated tests in this repository.

- `flutter analyze` stays at 77 infos, 0 errors, 0 warnings.
- In ebook-reader-lite: `pnpm eslint .` and `pnpm build` pass.
- Manual device checklist:
  - Add a word from the popup; add it again → "Already stashed".
  - Stash list is in story order.
  - Multi-select delete, including Select all.
  - Jump to word, read on, exit → reopening the book returns to the old
    bookmark.
  - Instant Export and Card Creator from the stash fill Sentence, Cloze and
    Context correctly; same actions from the popup still work.
  - Delete the item's dictionary, then make a card → term, reading and
    sentence still fill; the page shows the missing-entry note.
  - Delete a book → its stash is gone.

## Future work

- Mokuro support (page position, page image capture at add time).
- Date sorting toggle on `StashPage`.
- Bookmark storage moved to the Flutter side, replacing the `peek` mechanism.
