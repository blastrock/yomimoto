# Sentence explanation — design

## Intent

A learner reading a novel or a manga in Yomimoto, on an e-ink tablet (the
target is a Supernote Nomad), hits a long sentence they cannot parse. In two
taps they get an English translation of the sentence and the sentence split
into short parts, each part with its reading and what it means in this
sentence. The point is to make long sentences followable piece by piece: which
words go together and what each group contributes. It is not a grammar course.

The explanation is produced by an LLM through the Anthropic API, with the
user's own API key.

A first version existed outside this tree (commit `0fb36c0e`, March 2026, on
the pre-fork code): a long-press "Explain" menu item sending the selected text
to Claude Haiku 4.5 with a plain-text template. Its translations were mediocre.
This design replaces it; do not port that code, it predates the current
architecture.

## Goals

- From the dictionary popup of either reader, one tap explains the sentence
  around the word just looked up.
- The answer arrives within **5 seconds** in normal conditions.
- Every part carries a reading, in kana. Readings are essential to the learner
  and are never in romaji.
- The translation and part meanings use the surrounding context: who speaks,
  what was just said, which meaning of a word fits.

## Non-goals (first version)

- Explaining from anywhere but the two readers: not from the Dictionary tab,
  the stash, recursive search pages, or the card creator.
- Dictionary lookups from the explanation dialog. Tapping a part to look it up
  is a likely later feature; nothing here should make it hard (keep parts as
  separate widgets), but it is not built now.
- Streaming the response.
- Saving, caching or re-showing explanations. Closing the dialog discards it.
- Putting the translation on an Anki card.
- Telling names apart. An earlier iteration asked the model to flag proper
  nouns and keep them in Japanese script; Haiku did not follow it reliably, and
  the rule was dropped to keep the output light.
- E-ink-specific tuning beyond what is stated here (the e-ink pass has not
  started, see `CLAUDE.md`).

## Anti-goals

- **Grammar lectures.** No per-part grammar notes, no "の marks possession".
  The research run that had them found almost none worth reading.
- **A parse tree.** Nested constituents were tried and judged overkill: a flat
  list of parts is the breakdown.
- **Romaji** anywhere in readings.
- **More untested JavaScript in the manga reader.** Its injected JS is already
  fragile; this feature must not change it.

## How it behaves

### Trigger

A new heading quick action, **Explain sentence** (`ExplainSentenceAction`,
Material icon `Icons.translate`), registered in
`AppModel.populateQuickActions` in `headingQuickActions` next to copy and
audio. It explains the reader's current sentence
(`MediaSource.currentSentence`), whichever heading's icon was tapped.

Like `AddToStashAction`, the icon appears wherever dictionary results show,
including the Dictionary tab. Where there is no current sentence (outside a
reader, or a reader that recorded none), tapping it shows a short toast and
does nothing else.

`closesPopup: true`: the dictionary popup closes, as it does after stashing
or creating a card, and the explanation dialog opens over the page.

### The dialog

A Flutter dialog page (a `BasePage`, like the other dialogs in
`lib/src/pages/implementations/`). Layout:

1. While waiting: a spinner (`BasePage.buildLoading`).
2. On success:
   - the English translation, at the top;
   - a divider;
   - one row per part: on the left the part's text with furigana **over the
     kanji only**, on the right its meaning. The list scrolls when long.
3. On failure: a message in the dialog (`JidoujishoPlaceholderMessage` or
   similar) for: no API key set, network error, timeout, an API error (show
   the API's message), a refusal, an unparseable response. Failures that may
   pass on their own also get a **Retry** button, which sends the same
   request again in the same dialog, with the spinner back: network errors,
   timeouts, HTTP 429 (rate limited), 5xx including 529 (overloaded), and an
   unparseable response (the model can produce a good one on a second try).
   The others get no Retry, since the same request would fail the same way:
   no key, 401/403 (bad key), other 4xx, and refusals.
4. A close action. Closing while the request runs discards its result.

Furigana over kanji only: the model gives each part's reading for the whole
part (`本当の` → `ほんとうの`). Split it the way dictionary headings already are
(`LanguageUtils.distributeFurigana`, displayed with `RubyText`). If a part has
no kanji, show no reading. Drop parts whose text contains no letters (the
model occasionally emits a part that is only `？` or `──`). A part whose
reading cannot be distributed falls back to the reading over the whole part.

### Settings

One section in the app-wide `SettingsPage`, both readers sharing it:

- **API key**, a text field. Stored as an app-wide `Preference<String>` in
  `Preferences` (the `preference` table; no special secret storage).
- **Model**, a choice between two presets. Each preset carries its own request
  settings, which is why the setting is a choice and not a free model name:

  | Preset | Model | Request settings |
  |---|---|---|
  | Sonnet 5.5 (default) | `claude-sonnet-5-5` | `thinking: {type: "adaptive"}`, `output_config.effort: "low"` |
  | Haiku 5.5 | `claude-haiku-5-5` | `thinking: {type: "disabled"}` |

Persist the preset by a stable key, not its display name.

## The request

One `POST https://api.anthropic.com/v1/messages`, raw HTTP through the
`http` package already in `pubspec.yaml` (there is no official Anthropic Dart
SDK). Headers: `content-type: application/json`, `x-api-key`,
`anthropic-version: 2026-10-21`. The research ran on `2023-06-01`; what
`2026-10-21` breaks (sampling parameters, documents in assistant turns,
citations in user turns, some Admin API fields) is nothing this request
sends. Body:

```json
{
  "model": "<preset model>",
  "max_tokens": 4000,
  "system": "<system prompt below>",
  "messages": [{"role": "user", "content": "<user message below>"}],
  "thinking": {"type": "<per preset>"},
  "output_config": {
    "effort": "low",
    "format": {"type": "json_schema", "schema": <schema below>}
  }
}
```

(`effort` only for the Sonnet preset.) The text of the response is the
concatenation of its `text` content blocks; skip any `thinking` blocks. Check
`stop_reason` before parsing: `refusal` and `max_tokens` are errors to show,
not JSON to parse. Time out after about 20 s.

Refusals: novels have violence and worse, and the models' safety classifiers
may decline (HTTP 200, `stop_reason: "refusal"`). Show it as an error, like
the others. No server-side `fallbacks`: on Sonnet 5.5 the `"default"` form
only reroutes the `cyber` and `frontier_llm` categories, not the
`general_harms` refusals fiction would trigger, and it was never tried with
structured outputs. No client-side retry on another model either, for now.

### Response schema

Structured outputs do not accept recursive schemas; this one is flat.

```json
{
  "type": "object",
  "additionalProperties": false,
  "required": ["translation", "parts"],
  "properties": {
    "translation": {"type": "string"},
    "parts": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["text", "reading", "meaning"],
        "properties": {
          "text": {"type": "string"},
          "reading": {"type": "string"},
          "meaning": {"type": "string"}
        }
      }
    }
  }
}
```

`translation` comes first so that streaming, if added later, shows it first.

### User message

```
Book: <title>

Context:
<context paragraphs, one per line>

Sentence to explain:
<sentence>
```

- Title: the `MediaItem`'s title (its override title if the user set one).
- The sentence: `currentSentence.text`, without furigana.
- Furigana in the context are written `kanji(reading)`, one parenthesis per
  `<rt>` as the book marks it up: `<ruby>南<rt>な</rt>雲<rt>ぐも</rt></ruby>`
  becomes `南(な)雲(ぐも)`. `<rp>` content is dropped.

What goes in the context depends on the reader:

- **Novels (ttu):** the three paragraphs before the tapped one, then the
  tapped paragraph itself, all with furigana. Fewer at the start of a chapter.
- **Manga (mokuro):** no context: the sentence is the whole bubble, and the
  `Context:` block is omitted. The system prompt for manga is the novel one
  with the input section changed (below).

### System prompt (novels)

Use it as is. It is the run 2 prompt minus the name rules: the `name` field
(also removed from the schema and the example) and the instruction to keep
names in Japanese script. That last edit was not rerun, by the user's choice;
the measurements below come from the version that still had them. Building
needs no live API calls: the request and parsing are unit-tested, and the
user checks real answers on the device.

````
You help an English-speaking learner of Japanese read a book. You get one sentence from the book, with the paragraphs before it for context. Translate it, then split it into short parts, each with its reading and its meaning in this sentence, so the learner can follow a long sentence piece by piece.

# Input
- The book's title.
- Context: the paragraphs before the sentence, then the paragraph that contains it.
- Furigana from the book appear as kanji(reading), e.g. 南(な)雲(ぐも). They are the author's readings: always use them. They are not part of the text: never copy them into `text`.
- The sentence to explain.

# Output
- `translation`: a natural English translation that fits the context.
- `parts`: the sentence split into parts, in order. Every character of the sentence except punctuation and brackets belongs to exactly one part.
  - A part is a word or a short phrase with the particles and endings attached to it (待っていた, 美咲に). A compound noun or a set expression can stay one part (声をかけると).
  - `text`: the exact characters of the sentence, without furigana.
  - `reading`: the reading of the whole `text`, in kana. Required for every part. Use the book's furigana when there are some.
  - `meaning`: what this part means in this sentence, in a few English words. Translate the part, do not explain grammar.

# Example
Input:
Book: (example)

Context:
「今日は一緒に帰ろうって約束してたんだよな」
放課後、図書室で待っていた美(み)咲(さき)に声をかけると、彼女は読みかけの本を慌(あわ)てて閉じた。

Sentence to explain:
放課後、図書室で待っていた美咲に声をかけると、彼女は読みかけの本を慌てて閉じた。

Output:
{"translation": "After school, when I called out to Misaki, who had been waiting in the library, she hurriedly closed the book she was partway through.", "parts": [{"text": "放課後", "reading": "ほうかご", "meaning": "after school"}, {"text": "図書室で", "reading": "としょしつで", "meaning": "in the library"}, {"text": "待っていた", "reading": "まっていた", "meaning": "who had been waiting"}, {"text": "美咲に", "reading": "みさきに", "meaning": "to Misaki"}, {"text": "声をかけると", "reading": "こえをかけると", "meaning": "when (I) called out"}, {"text": "彼女は", "reading": "かのじょは", "meaning": "she"}, {"text": "読みかけの", "reading": "よみかけの", "meaning": "half-read"}, {"text": "本を", "reading": "ほんを", "meaning": "the book"}, {"text": "慌てて", "reading": "あわてて", "meaning": "hurriedly"}, {"text": "閉じた", "reading": "とじた", "meaning": "closed"}]}
````

### System prompt (manga)

Untested. The novel prompt with three changes, everything else identical:

- First paragraph: "You get the text of one speech bubble from a manga.
  Translate it, then split it into short parts, …" (the rest of the sentence
  unchanged).
- `# Input` becomes:
  ```
  # Input
  - The manga's title.
  - The text of the speech bubble to explain.
  ```
- The example input drops its `Context:` block.

## Getting the context

### Novels: a new ttu bridge command

Today the `tap` event carries the tapped paragraph with furigana removed, and
the app talks to ttu only through `TtuBridge` (`CLAUDE.md`, "Reader
internals"). Add a command to the fork's host overlay
(`apps/web/src/lib/host/host-lookup.ts`, which already keeps the last tapped
paragraph), e.g. `getContext({ paragraphs: 3 })`, returning the tapped
paragraph and up to that many paragraphs before it, each as text with
furigana written `kanji(reading)` as above. Paragraph boundaries follow
`findParagraph` as the tap code does. Context stops at the boundary of the
book section (the xhtml file) in both view modes: continuous mode has the
whole book in the DOM, paginated mode only the current section, and the
research took its context from within one file.

This is a protocol change: bump `PROTOCOL_VERSION` in `host-bridge.ts` and
`TtuBridge.protocolVersion` together, add the command to `TtuBridge`, add a
Playwright case in `apps/web/e2e/` (both view modes) for paragraphs before the
tapped one and for furigana markup, release a fork tag and pin it with
`tool/fetch_ttu.sh --update <tag>`. Tags are created locally; the user pushes
them.

The quick action runs outside the reader page, but the bridge belongs to the
page. How the action reaches it (a context getter the reader page registers
on its media source, a callback, …) is the builder's call; keep it so that
the manga reader can supply its context the same way.

### Manga

No JavaScript change. The sentence the reader already records
(`setCurrentSentence` with the bubble's text, lines joined) is the whole
input.

Fix on the way, Dart side only: `mokuro_catalog_browse_page.dart` records the
current sentence only inside `if (mediaSource.highlightOnTap)`, so with
highlighting off there is no sentence to explain. Record it regardless.

## Research behind the numbers

Two comparison runs on 2026-10-27, kept out of tree (jj changes `qwrkkqlr`,
`mynmqvow`, `zmvrrpsz` on top of `ownqyvwk`). Ten real sentences from the
user's books, with their real context and furigana.

- With the flat-parts prompt, Haiku 5.5 without thinking answered in a median
  2.3 s (max 3.6 s, 30 calls), Sonnet 5.5 at low effort in a median 3.3 s
  (max 4.4 s). About $0.0004 and $0.007 per sentence respectively.
- Sonnet 5.5 was clearly better on context (お嬢ちゃん addressing the
  narrator → "you, little miss") and names (Haiku translated 南雲桜子 as "Kumo
  Sakurako" in all three runs). Hence Sonnet as the default; Haiku stays as
  the cheaper preset.
- Thinking at low effort on Haiku occasionally ran to 3,000 tokens and 14 s,
  with no way to cap it; thinking off is what keeps Haiku under 5 s.
- Readings were right in all but one Haiku run once every part had a
  required reading.

## Testing

`flutter test` covers pure code, so:

- building the request body for each preset (model, thinking, effort, schema);
- building the user message, with and without context;
- parsing a response: text blocks joined, `stop_reason` handling, malformed
  JSON, parts that are only punctuation dropped;
- which failures are retryable;
- the furigana display split for a part, including the fallback;
- `TtuBridge`'s parsing of the new command's result.

The fork's Playwright suite covers `getContext`. The dialog, the quick action
and the settings are verified on a device (`CLAUDE.md`: anything touching
`AppModel` or the WebView is).

## Left to the builder

- File and class names beyond those given, and where the request code lives
  (the `utils` barrel is a natural home; add `export` lines to the barrels).
- How the quick action reaches the reader's context (see above).
- i18n strings (slang, `lib/i18n/strings.i18n.json`) and their wording.
- The dialog's exact styling, within layout A above and the theme rules in
  `CLAUDE.md` (colours from the theme, never a brightness check).

## Builder's calls already made by the designer

These were not discussed with the user; change them if they get in the way.

- Three paragraphs of context before the tapped one, as in the research.
- 20 s timeout, `max_tokens` 4000.
- Errors shown in the dialog; which ones get Retry (see "The dialog").
- Toast when tapped outside a reader, as stash does.
- Refusals shown as errors, with no fallback or retry on another model.
- Context stops at the section boundary.
