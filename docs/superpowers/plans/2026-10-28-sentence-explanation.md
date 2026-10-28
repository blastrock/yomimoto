# Sentence Explanation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** An "Explain sentence" quick action in both readers' dictionary popup that asks Claude for a translation and a split of the current sentence into parts with readings and meanings, shown in a Flutter dialog.

**Architecture:** Pure Dart in `lib/src/utils/explanation/` builds the request, calls the Anthropic Messages API over `http` and parses the structured JSON answer. Each reader's `MediaSource` says what kind of text it shows and, for novels, supplies context through a new ttu bridge command `getContext`. A heading `QuickAction` gathers sentence, title and context and opens `SentenceExplanationDialogPage`.

**Tech Stack:** Flutter/Dart (`http`, `package:http/testing.dart` for tests, `ruby_text`, slang), the ttu fork in TypeScript/Svelte with Playwright end-to-end tests.

**Spec:** `docs/superpowers/specs/2026-10-28-sentence-explanation-design.md` (commit `d7ce104a`). Read it first: it holds the exact system prompts, schema and request body this plan refers to.

## Global Constraints

- Endpoint `https://api.anthropic.com/v1/messages`; headers `content-type: application/json`, `x-api-key`, `anthropic-version: 2026-10-21`.
- `max_tokens: 4000`; timeout 20 s.
- Presets: `sonnet` → `claude-sonnet-5-5`, `thinking: {type: "adaptive"}`, `output_config.effort: "low"` (default); `haiku` → `claude-haiku-5-5`, `thinking: {type: "disabled"}`, no `effort`.
- No `fallbacks`, no `temperature`/`top_p`/`top_k`, no streaming.
- System prompts and schema copied verbatim from the spec; the manga prompt is the novel prompt with the three changes the spec lists.
- Context: up to 3 paragraphs before the tapped one plus the tapped one, furigana as `kanji(reading)` per `<rt>`, `<rp>` dropped, never crossing the `.ttu-book-html-wrapper` (book section) boundary. Manga: no context.
- Protocol version 3 → 4, in `host-bridge.ts` and `TtuBridge.protocolVersion` together.
- No change to the manga reader's injected JavaScript.
- Project conventions from `CLAUDE.md`: barrel imports only, `package:` imports, `///` docs on every public member, British spelling, `showToast` not `Fluttertoast.showToast`, `unawaited(...)` for fire-and-forget, theme colours never from a brightness check, hand-formatting matching the file (no `dart format`), `flutter analyze` with zero issues, regenerate slang with `dart run slang` and commit the result.
- Version control: jj. One change per task: `jj describe -m "<message>"` then `jj new`. Never move bookmarks, never push. Commit messages end with the attribution lines from the session.

## Review Focus

1. **A reader with an empty current sentence** (after a dismiss tap, or a source that recorded none) — Explain must toast, never send an empty sentence. Test in Task 7 (`ExplainSentenceAction.canExplain`).
2. **The dialog closed before the answer arrives** — the late result must not call `setState` on an unmounted state. Guarded in Task 6, checked on device.
3. **A response whose `content` has a `thinking` block before the `text` block** (Sonnet with adaptive thinking) — only text blocks are parsed. Test in Task 2.
4. **A part with katakana or Latin text and no kanji** (`ステフと`, `ABC`) — no reading shown, part kept. Test in Task 2 (`ExplanationPart.showsReading`).
5. **Furigana that cannot be distributed** (reading not matching the kana around the kanji) — reading falls back over the whole part, no exception. Test in Task 2.

---

### Task 1: `getContext` in the ttu fork (protocol 4)

Repository: `/home/blastrock/work/ebook-reader-lite` (jj). Work in `apps/web`.

**Files:**
- Modify: `apps/web/src/lib/host/host-lookup.ts`
- Modify: `apps/web/src/lib/host/host-bridge.ts` (`PROTOCOL_VERSION = 4`)
- Create: `apps/web/e2e/context.spec.ts`

**Interfaces:**
- Produces: host command `getContext({ paragraphs: number }) → string[]`: up to `paragraphs` paragraphs before the last tapped one, then the tapped one, oldest first, each as `annotatedText`; `[]` when there is no last tapped paragraph (none yet, or the last tap was a dismiss).

- [ ] **Step 1: Write the failing e2e test** `context.spec.ts`, for each of `VIEW_MODES`, with the `beforeEach`/`afterEach` of `positions.spec.ts`. Call the command with `page.evaluate(() => window.ttuHost.getContext({ paragraphs: 3 }))` after a `tapCharacter`.
  - `'returns the tapped paragraph and the three before it, with furigana'`: tap `ABC`, index 0 (in `CHAPTER_1[5]`); expect `[CHAPTER_1[2], CHAPTER_1[3], CHAPTER_1[4], CHAPTER_1[5].replace('<ruby>漢字<rt>かんじ</rt></ruby>', '漢字(かんじ)')]`.
  - `'stops at the start of the section'`: tap `目標の言葉`, index 0 (in `CHAPTER_2[10]`), `paragraphs: 20`; expect `['第2章', ...CHAPTER_2.slice(0, 10), CHAPTER_2[10].replace('<ruby>謎<rt>なぞ</rt></ruby>', '謎(なぞ)')]`.
  - `'is empty before any tap'`: no tap; expect `[]`.

- [ ] **Step 2: Run it to verify it fails**

  Run (in `apps/web`): `pnpm build && pnpm test:e2e context.spec.ts`
  Expected: FAIL, `window.ttuHost.getContext is not a function` (or equivalent).

- [ ] **Step 3: Implement in `host-lookup.ts`**
  - Keep the tapped paragraph element: `lastParagraphElement: Element | undefined`, set with `lastParagraph` in `onClick`, cleared in `dismiss`.
  - `function annotatedText(paragraph: Element): string` — the paragraph's text nodes in order, `<rp>` content dropped, each `<rt>` element's text written as `(reading)` right after the base text before it.
  - `function previousParagraphs(paragraph: Element, count: number): Element[]` — walk text nodes backwards from `paragraph` with a `TreeWalker` rooted at `paragraph.closest('.ttu-book-html-wrapper')` (or `.book-content` if absent), skipping nodes inside `rt`/`rp`, mapping each through `findParagraph` and collecting distinct elements other than `paragraph` until `count` are found. Return them oldest first.
  - `function getContext({ paragraphs }: Record<string, unknown>): string[]`, registered in `initHostLookup` as `'getContext'`. Non-number `paragraphs` → treat as 0.

- [ ] **Step 4: Bump the protocol** — `PROTOCOL_VERSION = 4` in `host-bridge.ts`.

- [ ] **Step 5: Run the checks**

  Run (in `apps/web`): `pnpm build && pnpm test:e2e`; then from the repository root: `pnpm eslint .`
  Expected: all e2e tests pass (the new ones and the existing positions and peek suites); eslint reports nothing.

- [ ] **Step 6: Commit and tag** in the fork: `jj describe -m "Add the getContext host command"`, `jj new`. Create the tag `v4.1.0` on that commit locally (`jj tag set v4.1.0 -r @-`, or `git tag v4.1.0 <commit>`). Do not push: tell the user the commit and tag are ready to push, which triggers the fork's `release.yml`. Task 8 pins the release once it is published.

---

### Task 2: Explanation model, prompts and parsing

**Files:**
- Create: `lib/src/utils/explanation/explanation_prompts.dart`
- Create: `lib/src/utils/explanation/sentence_explanation.dart`
- Modify: `lib/utils.dart` (export both)
- Test: `test/utils/sentence_explanation_test.dart`

**Interfaces:**
- Produces, in `explanation_prompts.dart`:
  - `const String novelSystemPrompt`, `const String mangaSystemPrompt` — verbatim from the spec.
  - `const Map<String, dynamic> explanationSchema` — the spec's schema.
- Produces, in `sentence_explanation.dart`:
  - `enum ExplanationKind { novel, manga }`
  - `enum ExplanationPreset { sonnet, haiku }` with `String get model`, `Map<String, dynamic> get thinking`, `String? get effort`, and `static ExplanationPreset fromKey(String key)` (`name` is the key; unknown → `sonnet`).
  - `class ExplanationRequest { ExplanationRequest({required String title, required String sentence, required ExplanationKind kind, List<String> context = const []}); }` with `String get userMessage` and `Map<String, dynamic> bodyFor(ExplanationPreset preset)`.
  - `class ExplanationPart { final String text; final String reading; final String meaning; bool get showsReading; List<RubyTextData> get furigana; }`
  - `class SentenceExplanation { final String translation; final List<ExplanationPart> parts; factory SentenceExplanation.fromResponse(Map<String, dynamic> response); }`
  - `enum ExplanationFailure { noApiKey, network, timeout, rateLimited, server, badKey, request, refusal, truncated, unparseable }` with `bool get retryable` (true for `network`, `timeout`, `rateLimited`, `server`, `unparseable`).
  - `class ExplanationException implements Exception { ExplanationException(this.failure, [this.message]); final ExplanationFailure failure; final String? message; }`

- [ ] **Step 1: Write the failing tests** in `test/utils/sentence_explanation_test.dart`:
  - `'user message with context'`: `ExplanationRequest(title: '最後の魔法', sentence: '南雲桜子。', kind: ExplanationKind.novel, context: ['a', '南(な)雲(ぐも)桜子。']).userMessage` equals `'Book: 最後の魔法\n\nContext:\na\n南(な)雲(ぐも)桜子。\n\nSentence to explain:\n南雲桜子。'`.
  - `'user message without context omits the Context block'`: manga request → `'Book: T\n\nSentence to explain:\nS'`.
  - `'sonnet body'`: `bodyFor(ExplanationPreset.sonnet)` has `model == 'claude-sonnet-5-5'`, `max_tokens == 4000`, `system == novelSystemPrompt`, `thinking == {'type': 'adaptive'}`, `output_config == {'effort': 'low', 'format': {'type': 'json_schema', 'schema': explanationSchema}}`, `messages == [{'role': 'user', 'content': <userMessage>}]`, and no `temperature`, `top_p`, `top_k` or `fallbacks` key.
  - `'haiku body'`: `model == 'claude-haiku-5-5'`, `thinking == {'type': 'disabled'}`, `output_config` has no `effort`.
  - `'manga request uses the manga prompt'`: `system == mangaSystemPrompt`, and `mangaSystemPrompt` contains `'# Input\n- The manga\'s title.\n- The text of the speech bubble to explain.'` and no `'Context:'`.
  - `'preset from key'`: `fromKey('haiku') == haiku`, `fromKey('nonsense') == sonnet`.
  - `'parses text blocks and skips thinking'`: response `{'stop_reason': 'end_turn', 'content': [{'type': 'thinking', 'thinking': ''}, {'type': 'text', 'text': '{"translation": "T", "parts": [{"text": "本当の", "reading": "ほんとうの", "meaning": "real"}]}'}]}` → `translation == 'T'`, one part with those fields.
  - `'drops parts with no letters'`: parts `？`, `──`, `本を` → only `本を` kept.
  - `'refusal'`, `'max_tokens'`: `stop_reason` `refusal` / `max_tokens` throw `ExplanationException` with `ExplanationFailure.refusal` / `truncated`.
  - `'unparseable'`: text `'not json'`, and JSON missing `parts`, throw `ExplanationFailure.unparseable`.
  - `'readings only on parts with kanji'`: `showsReading` true for `本当の`, false for `ステフと`, `ABC`, `なくしかけた`.
  - `'furigana over the kanji only'`: `ExplanationPart(text: '本当の', reading: 'ほんとうの', meaning: '').furigana` maps to texts `['本当', 'の']` with rubies `['ほんとう', null]`.
  - `'furigana falls back over the whole part'`: `ExplanationPart(text: '本当の', reading: 'まったくちがう', meaning: '').furigana` is one `RubyTextData('本当の', ruby: 'まったくちがう')`.
  - `'retryable failures'`: `retryable` exactly for `network`, `timeout`, `rateLimited`, `server`, `unparseable`.

- [ ] **Step 2: Run them to verify they fail**

  Run: `flutter test test/utils/sentence_explanation_test.dart`
  Expected: FAIL, compilation errors on the missing names.

- [ ] **Step 3: Implement both files.** `furigana` goes through `LanguageUtils.distributeFurigana(heading: DictionaryHeading(term: text, reading: reading))`, which already falls back to the whole part. "Has kanji": any code point in the CJK ideograph ranges (`㐀-䶿`, `一-鿿`, `豈-﫿`) or `々`. "No letters": the text has no character outside Unicode punctuation, symbols and whitespace (`RegExp(r'^[\p{P}\p{S}\s]*$', unicode: true)`). Add the two `export` lines to `lib/utils.dart`.

- [ ] **Step 4: Run the tests and the analyser**

  Run: `flutter test test/utils/sentence_explanation_test.dart && flutter analyze`
  Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — `jj describe -m "Add the sentence explanation model and prompts"`, `jj new`.

---

### Task 3: Explanation client

**Files:**
- Create: `lib/src/utils/explanation/explanation_client.dart`
- Modify: `lib/utils.dart`
- Test: `test/utils/explanation_client_test.dart`

**Interfaces:**
- Consumes: Task 2's `ExplanationRequest`, `ExplanationPreset`, `SentenceExplanation`, `ExplanationException`, `ExplanationFailure`.
- Produces: `Future<SentenceExplanation> explainSentence({required String apiKey, required ExplanationPreset preset, required ExplanationRequest request, http.Client? client, Duration timeout = const Duration(seconds: 20)})`. Throws only `ExplanationException`.

- [ ] **Step 1: Write the failing tests** with `MockClient` from `package:http/testing.dart`:
  - `'sends the request'`: captures the request; method `POST`, URL `https://api.anthropic.com/v1/messages`, headers `x-api-key: k`, `anthropic-version: 2026-10-21`, `content-type` starting with `application/json`, body decoding to `request.bodyFor(preset)`. Reply 200 with a valid response → returns the parsed explanation.
  - `'empty key'`: `apiKey: '  '` → `noApiKey`, and the client is never called.
  - Status mapping, each a 200-less reply with body `{"type": "error", "error": {"type": "x", "message": "boom"}}`: 401 and 403 → `badKey`; 429 → `rateLimited`; 500 and 529 → `server`; 400 → `request`; each with `message == 'boom'`. A non-JSON error body still maps by status, `message` null.
  - `'network error'`: client throws `http.ClientException` (and a `SocketException`) → `network`.
  - `'timeout'`: client waits longer than `timeout: Duration(milliseconds: 10)` → `timeout`.
  - `'decodes UTF-8'`: a reply whose bytes are UTF-8 Japanese without a charset in `content-type` parses to the right text.

- [ ] **Step 2: Run them to verify they fail**

  Run: `flutter test test/utils/explanation_client_test.dart`
  Expected: FAIL, `explainSentence` not defined.

- [ ] **Step 3: Implement `explainSentence`.** Decode the body with `utf8.decode(response.bodyBytes)`. Close the client only when it was created inside the function. Export the file from `lib/utils.dart`.

- [ ] **Step 4: Run the tests and the analyser**

  Run: `flutter test test/utils/explanation_client_test.dart && flutter analyze`
  Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — `jj describe -m "Add the sentence explanation client"`, `jj new`.

---

### Task 4: Settings

**Files:**
- Modify: `lib/src/preferences/preferences.dart`
- Modify: `lib/src/pages/implementations/settings_page.dart`
- Modify: `lib/i18n/strings.i18n.json`, regenerate `lib/i18n/strings.g.dart`
- Test: none (settings UI; checked on device in Task 8)

**Interfaces:**
- Consumes: Task 2's `ExplanationPreset` (its `name` is the stored key).
- Produces: `Preferences.explanationApiKey` (`Preference<String>('explanation_api_key', defaultValue: '')`), `Preferences.explanationPreset` (`Preference<String>('explanation_preset', defaultValue: 'sonnet')`).

- [ ] **Step 1: Add the two preferences** to `Preferences`, in a new `// Sentence explanation.` group, with `///` docs.

- [ ] **Step 2: Add the settings section** after the mokuro section: `buildHeader(t.sentence_explanation)`, a text field for the key (obscured, no autocorrect, persisted on change with `appModel.preferences.set`; add a `buildTextField` helper beside `buildNumberField` if one is needed), and `buildChoice<ExplanationPreset>` over `ExplanationPreset.values` with labels `t.explanation_preset_sonnet` / `t.explanation_preset_haiku`, saving `preset.name`.

- [ ] **Step 3: Add strings and regenerate.** Keys: `sentence_explanation` ("Sentence explanation"), `explanation_api_key` ("Anthropic API key"), `explanation_model` ("Model"), `explanation_preset_sonnet` ("Sonnet 5.5 (better)"), `explanation_preset_haiku` ("Haiku 5.5 (cheaper)"). Run `dart run slang`.

- [ ] **Step 4: Verify**

  Run: `flutter analyze && flutter test`
  Expected: `No issues found!`; all tests pass.

- [ ] **Step 5: Commit** — `jj describe -m "Add the sentence explanation settings"`, `jj new`.

---

### Task 5: Context from the readers

**Files:**
- Modify: `lib/src/media/sources/ttu_bridge.dart`
- Modify: `lib/src/media/media_source.dart`
- Modify: `lib/src/media/sources/reader_ttu_source.dart`
- Modify: `lib/src/media/sources/reader_mokuro_source.dart`
- Modify: `lib/src/pages/implementations/reader_ttu_source_page.dart`
- Modify: `lib/src/pages/implementations/mokuro_catalog_browse_page.dart:~700`
- Test: `test/media/ttu_bridge_test.dart`

**Interfaces:**
- Consumes: Task 1's `getContext` command; Task 2's `ExplanationKind`.
- Produces:
  - `TtuBridge.protocolVersion == 4`; `Future<List<String>> getContext({int paragraphs = 3})`; `static List<String> parseContext(dynamic raw)` (null or non-list → `[]`, non-string items dropped).
  - On `MediaSource`: `ExplanationKind? get explanationKind` (null by default; `ReaderTtuSource` → `novel`, `ReaderMokuroSource` → `manga`) and `Future<List<String>> Function()? explanationContext` (a settable field, null by default).

- [ ] **Step 1: Update the failing test** in `test/media/ttu_bridge_test.dart`: the existing `expect(TtuBridge.protocolVersion, 3)` becomes `4`; add `'parses a context result'`: `parseContext(['a', 'b'])` → `['a', 'b']`, `parseContext(null)` → `[]`, `parseContext(['a', 1])` → `['a']`.

- [ ] **Step 2: Run it to verify it fails**

  Run: `flutter test test/media/ttu_bridge_test.dart`
  Expected: FAIL on the version and the missing `parseContext`.

- [ ] **Step 3: Implement.**
  - `TtuBridge`: bump the version, add `getContext` (calls `_call('getContext', args: {'paragraphs': paragraphs})` and `parseContext`).
  - `MediaSource`: the two members above, with docs saying the source page sets `explanationContext` while open.
  - `ReaderTtuSourcePage`: once the bridge exists, set `mediaSource.explanationContext = () => bridge.getContext()`; set it back to null in `dispose`.
  - `mokuro_catalog_browse_page.dart`: move the `mediaSource.setCurrentSentence(...)` call (and the selection computation it needs) out of the `if (mediaSource.highlightOnTap)` block so the bubble is recorded either way; leave `selectTextOnwards` inside it. Dart only, no JavaScript change.
  - Develop against the local fork build: `tool/fetch_ttu.sh --local ../ebook-reader-lite`. Do not commit `tool/ttu.lock` in this task.

- [ ] **Step 4: Verify**

  Run: `flutter test && flutter analyze`
  Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — `jj describe -m "Supply sentence explanation context from the readers"`, `jj new`.

---

### Task 6: Explanation dialog

**Files:**
- Create: `lib/src/pages/implementations/sentence_explanation_dialog_page.dart`
- Modify: `lib/pages.dart` (export)
- Modify: `lib/i18n/strings.i18n.json`, regenerate

**Interfaces:**
- Consumes: Task 2's `ExplanationRequest`, `SentenceExplanation`, `ExplanationPart.furigana`/`showsReading`, `ExplanationException`/`ExplanationFailure.retryable`; Task 3's `explainSentence`; Task 4's preferences.
- Produces: `class SentenceExplanationDialogPage extends BasePage { const SentenceExplanationDialogPage({required ExplanationRequest request, super.key}); }`

- [ ] **Step 1: Implement the page** as a `BasePage` dialog (an `AlertDialog`, as the other dialog pages):
  - In `initState`, start `explainSentence` with the key and preset read from `appModel.preferences` (`ExplanationPreset.fromKey`). Keep the future in state; `Retry` replaces it with a new call.
  - Waiting: `buildLoading()`.
  - Success: translation text, a divider, then a scrolling list with one row per part: left the part's `RubyText(part.furigana)` (plain text when `!part.showsReading`), right `part.meaning`. Each part its own widget (a later feature makes parts tappable).
  - Failure: `JidoujishoPlaceholderMessage` with a message per `ExplanationFailure`, the API's `message` appended for `badKey`, `request` and `server`; a `Retry` action only when `failure.retryable`.
  - Actions: `t.dialog_close` always; `t.retry` on retryable failures.
  - A result arriving after the dialog closed is dropped (`mounted` check before `setState`, or a `FutureBuilder` on the stored future).
  - Colours only from the theme.
- [ ] **Step 2: Add strings and regenerate.** `retry` ("Retry") if absent, and one message per failure: `explanation_no_api_key` ("Set an Anthropic API key in Settings"), `explanation_network` ("Could not reach the API"), `explanation_timeout` ("The API took too long to answer"), `explanation_rate_limited` ("Too many requests, try again shortly"), `explanation_server` ("The API had a problem"), `explanation_bad_key` ("The API key was rejected"), `explanation_request` ("The API rejected the request"), `explanation_refusal` ("The model declined to explain this sentence"), `explanation_truncated` ("The answer was cut off"), `explanation_unparseable` ("The answer could not be read"). `dart run slang`.
- [ ] **Step 3: Verify**

  Run: `flutter analyze && flutter test`
  Expected: `No issues found!`; all tests pass.

- [ ] **Step 4: Commit** — `jj describe -m "Add the sentence explanation dialog"`, `jj new`.

---

### Task 7: Explain sentence quick action

**Files:**
- Create: `lib/src/creator/actions/explain_sentence_action.dart`
- Modify: `lib/creator.dart` (export)
- Modify: `lib/src/models/app_model.dart` (`populateQuickActions`: append to `headingQuickActions` after `PlayAudioAction()`)
- Modify: `lib/i18n/strings.i18n.json`, regenerate
- Test: `test/creator/explain_sentence_action_test.dart`

**Interfaces:**
- Consumes: Task 2's `ExplanationRequest`, `ExplanationKind`; Task 5's `MediaSource.explanationKind`, `explanationContext`; Task 6's `SentenceExplanationDialogPage`.
- Produces: `class ExplainSentenceAction extends QuickAction` with `static const String key = 'explain_sentence'`, label `'Explain Sentence'`, icon `Icons.translate`, `closesPopup: true`; and `static bool canExplain({required ExplanationKind? kind, required String sentence})` — false when `kind` is null or `sentence.trim()` is empty.

- [ ] **Step 1: Write the failing test** `'can explain only a reader sentence'`: `canExplain(kind: null, sentence: 'x')` false; `canExplain(kind: ExplanationKind.novel, sentence: ' \n')` false; `canExplain(kind: ExplanationKind.manga, sentence: '南雲桜子。')` true.

- [ ] **Step 2: Run it to verify it fails**

  Run: `flutter test test/creator/explain_sentence_action_test.dart`
  Expected: FAIL, `ExplainSentenceAction` not defined.

- [ ] **Step 3: Implement `executeAction`.** Media source from `appModel.getCurrentMediaItem()?.getMediaSource(appModel: appModel)`. When `canExplain` is false: `showToast(msg: t.explain_unavailable)` and return. Title: the media item's `overrideTitle` if set, else `title`. Context: `await mediaSource.explanationContext?.call()`, falling back to `[]` on a `TtuBridgeException`. Then `showDialog` with `SentenceExplanationDialogPage(request: ...)`. String `explain_unavailable`: "Open a book to explain its sentences". Register in `populateQuickActions`; export from `lib/creator.dart`; `dart run slang`.

- [ ] **Step 4: Verify**

  Run: `flutter test && flutter analyze`
  Expected: all pass; `No issues found!`

- [ ] **Step 5: Commit** — `jj describe -m "Add the explain sentence quick action"`, `jj new`.

---

### Task 8: Pin the fork release, document, verify on a device

**Files:**
- Modify: `tool/ttu.lock`
- Modify: `CLAUDE.md`

- [ ] **Step 1: Pin the release** once the user has pushed Task 1's tag and `release.yml` has published `v4.1.0`: `tool/fetch_ttu.sh --update v4.1.0`. Expected: `tool/ttu.lock` names `v4.1.0` and the reader shows no protocol-mismatch snackbar.
- [ ] **Step 2: Document** in `CLAUDE.md`, under "Reader internals", a short paragraph: the Explain sentence quick action, `lib/src/utils/explanation/`, the `getContext` bridge command, `MediaSource.explanationKind`/`explanationContext`, and the settings keys. Keep the file's style.
- [ ] **Step 3: Verify the build**

  Run: `flutter analyze && flutter test && flutter build apk --release --split-per-abi`
  Expected: no issues; tests pass; APKs built.
- [ ] **Step 4: Device checks** (the user runs these with their key; report what was checked):
  - Novel: tap a word, Explain → spinner, then translation and parts in layout A within ~5 s; furigana over kanji only; closing during the spinner leaves no error.
  - Novel with furigana in context (e.g. 最後の魔法's 南雲桜子 paragraph) → reading なぐも.
  - Manga with "Highlight text on tap" off → Explain works on the tapped bubble.
  - Dictionary tab → the icon toasts "Open a book to explain its sentences".
  - No key → "Set an Anthropic API key in Settings", no Retry. Airplane mode → network message with Retry; Retry after reconnecting succeeds.
  - Haiku preset → answers, faster.
- [ ] **Step 5: Commit** — `jj describe -m "Pin ebook-reader-lite v4.1.0 and document sentence explanation"`, `jj new`.
