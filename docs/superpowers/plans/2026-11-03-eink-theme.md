# E-ink Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a third theme, E-ink, with pure black reading text on white, thin black borders on windows and buttons, and have the app set the book's colours in ttu for every theme.

**Architecture:** The three `ThemeData`s move out of `AppModel` into a pure `AppThemes` class so they can be unit tested. Everything that differs per theme lives in the theme: colours in `AppColors`, the border, sizes and popup opacity in a new `AppStyle` extension, and the book's colours in a `TtuColours` value held by `AppColors`. The reader page pushes `TtuColours` through a new `setTheme` bridge command; the fork's overlay keeps the last pushed colours in its own `localStorage` key so a book opens in the right colours before the app has spoken.

**Tech Stack:** Flutter/Dart (Material 2), Riverpod; ebook-reader-lite (Svelte, RxJS, Playwright).

**Spec:** `docs/superpowers/specs/2026-11-03-eink-theme-design.md`

## Global Constraints

- E-ink reading text is pure black `#000000` on pure white `#FFFFFF`.
- Border is 1dp, black, E-ink only: `BorderSide(color: Colors.black, width: 1)`.
- Light and Dark change visually only in the smaller quick-action buttons, and in the reader's background before the page paints (Task 6).
- Quick actions: E-ink 25dp icon + 8dp padding; Light and Dark 20dp icon + 6dp padding.
- Unused `ColorScheme` roles stay at their defaults, in all three themes.
- Stored `theme_mode` values `system`, `light`, `dark` keep reading correctly, under the same key, with no migration.
- Protocol version goes from 4 to 5 on both sides.
- ttu's settings page is not changed. The fork's change stays in `apps/web/src/lib/host/`, with small hooks in upstream files, and inert outside the app.
- No brightness checks and no scattered "is E-ink" checks: per-theme values come from the theme.
- `flutter analyze` reports no issues; `flutter test` passes; British spelling; `///` on every public member; `package:` barrel imports; format by hand to match the file.
- Commits, in both repositories: `jj describe -m "<message>" && jj new`, ending the message with these two lines. Never push, never move bookmarks.

  ```
  Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01HHbqLNkYp4mJ98XsSpGe5p
  ```

## Review Focus

- Stored theme values from before this change still load as the same theme (test in Task 1).
- Light and Dark show no borders on dialogs, text buttons or icon buttons (tests in Tasks 2 and 3).
- A theme chosen in ttu's own settings loses to the app's colours, even a dark one (e2e in Task 5).
- A malformed `setTheme` call is refused and leaves the reader working in its current colours (e2e in Task 5).
- Changing the theme while a book is open recolours the book without reopening it (device check in Task 6).

---

### Task 1: Themes move to `AppThemes`, E-ink becomes selectable

**Files:**
- Create: `lib/src/utils/misc/app_theme_mode.dart`, `lib/src/utils/misc/app_themes.dart`
- Modify: `lib/utils.dart`, `lib/src/utils/misc/app_colors.dart`, `lib/src/models/app_model.dart` (remove `textStyle`, `textTheme`, `theme`, `darkTheme`; retype `themeMode`, `setThemeMode`), `lib/src/preferences/preferences.dart:12-14`, `lib/main.dart:215-217,238-239`, `lib/src/pages/implementations/settings_page.dart:99-109`, `lib/i18n/strings.i18n.json`, `lib/i18n/strings.g.dart` (regenerated), `DEBT.md`
- Test: `test/utils/app_themes_test.dart`

**Interfaces:**
- Produces:
  - `enum AppThemeMode { system, light, dark, eink }` with `ThemeMode get materialMode` (`eink` gives `ThemeMode.light`).
  - `abstract final class AppThemes` with `static ThemeData light()`, `static ThemeData dark()`, `static ThemeData eink()`, and `static ThemeData lightFor(AppThemeMode mode)` (`eink()` for `AppThemeMode.eink`, else `light()`).
  - `AppColors.eink`.
  - `Preferences.themeMode` as `EnumPreference<AppThemeMode>`.

- [ ] **Step 1: Write the failing tests in `test/utils/app_themes_test.dart`**

```dart
test('stored theme names still read as the same theme', () {
  expect(Preferences.themeMode.key, 'theme_mode');
  expect(Preferences.themeMode.fromJson('system'), AppThemeMode.system);
  expect(Preferences.themeMode.fromJson('light'), AppThemeMode.light);
  expect(Preferences.themeMode.fromJson('dark'), AppThemeMode.dark);
  expect(Preferences.themeMode.toJson(AppThemeMode.eink), 'eink');
});

test('e-ink is a light theme to MaterialApp', () {
  expect(AppThemeMode.eink.materialMode, ThemeMode.light);
  expect(AppThemeMode.system.materialMode, ThemeMode.system);
  expect(AppThemes.lightFor(AppThemeMode.eink).appColors, AppColors.eink);
  expect(AppThemes.lightFor(AppThemeMode.dark).appColors, AppColors.light);
});

test('e-ink text and icons are pure black on white', () {
  ThemeData theme = AppThemes.eink();
  expect(theme.brightness, Brightness.light);
  expect(theme.textTheme.bodyMedium!.color, Colors.black);
  expect(theme.textTheme.titleLarge!.color, Colors.black);
  expect(theme.textTheme.bodySmall!.color, Colors.black);
  expect(theme.iconTheme.color, Colors.black);
  expect(theme.colorScheme.onSurface, Colors.black);
  expect(theme.scaffoldBackgroundColor, Colors.white);
});

test('the e-ink dictionary surfaces are white', () {
  expect(AppColors.eink.dictionaryPopup, Colors.white);
  expect(AppColors.eink.dictionaryCard, Colors.white);
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/utils/app_themes_test.dart`
Expected: FAIL, `AppThemeMode` and `AppThemes` are not defined.

- [ ] **Step 3: Add `AppThemeMode`, and move the themes into `AppThemes`**

Move `textStyle`, `textTheme`, `theme` and `darkTheme` from `AppModel` unchanged (`textStyle` and `textTheme` become private to `AppThemes`). Build `eink()` as `light().copyWith(...)`: `textTheme: light().textTheme.apply(bodyColor: Colors.black, displayColor: Colors.black)`, `iconTheme: const IconThemeData(color: Colors.black)`, `colorScheme` with `onSurface: Colors.black`, `extensions: const [AppColors.eink]`. `AppColors.eink` is `AppColors.light` with `dictionaryCard` and `dictionaryPopup` white. Export both new files from `lib/utils.dart`.

- [ ] **Step 4: Wire it in**

`AppModel.themeMode` and `setThemeMode` use `AppThemeMode`. `main.dart` passes `themeMode: themeMode.materialMode`, `theme: AppThemes.lightFor(themeMode)`, `darkTheme: AppThemes.dark()`. Settings uses `buildChoice<AppThemeMode>` over `AppThemeMode.values`, with `AppThemeMode.eink => t.theme_eink`. Add `"theme_eink": "E-ink"` after `theme_dark`, then run `dart run slang`.

- [ ] **Step 5: Delete the DEBT entry "Both colour schemes carry unchosen Material 3 roles"**

- [ ] **Step 6: Verify**

Run: `flutter test && flutter analyze`
Expected: all tests pass, `No issues found!`

- [ ] **Step 7: Commit**

Message: `Add the E-ink theme option`

---

### Task 2: Window and text-button borders, opaque popup

**Files:**
- Create: `lib/src/utils/misc/app_style.dart`
- Modify: `lib/utils.dart`, `lib/src/utils/misc/app_themes.dart`, `lib/src/pages/base_source_page.dart:60-61,321-325`
- Test: `test/utils/app_themes_test.dart`

**Interfaces:**
- Consumes: `AppThemes` from Task 1.
- Produces: `class AppStyle extends ThemeExtension<AppStyle>` with `final BorderSide border`, `final double dictionaryPopupOpacity`, `final double quickActionIconSize`, `final double quickActionPadding`; constants `AppStyle.standard` (`BorderSide.none`, 0.95, 20, 6) and `AppStyle.eink` (1dp black, 1, 25, 8); `extension AppStyleTheme on ThemeData { AppStyle get appStyle }`. `lerp` returns `t < 0.5 ? this : other`.

- [ ] **Step 1: Add the failing tests**

```dart
const BorderSide einkBorder = BorderSide(color: Colors.black, width: 1);

test('e-ink windows and text buttons have a thin black border', () {
  ThemeData theme = AppThemes.eink();
  expect((theme.dialogTheme.shape! as RoundedRectangleBorder).side, einkBorder);
  expect((theme.popupMenuTheme.shape! as RoundedRectangleBorder).side, einkBorder);
  expect((theme.bottomSheetTheme.shape! as RoundedRectangleBorder).side, einkBorder);
  expect(theme.textButtonTheme.style!.side!.resolve({}), einkBorder);
  expect(theme.textButtonTheme.style!.foregroundColor!.resolve({}), Colors.black);
});

test('light and dark have no borders', () {
  for (ThemeData theme in [AppThemes.light(), AppThemes.dark()]) {
    expect(theme.appStyle.border, BorderSide.none);
    expect((theme.dialogTheme.shape! as RoundedRectangleBorder).side, BorderSide.none);
    expect(theme.textButtonTheme.style!.side, isNull);
  }
});

test('the popup is opaque in e-ink only, and buttons are large in e-ink only', () {
  expect(AppThemes.eink().appStyle.dictionaryPopupOpacity, 1);
  expect(AppThemes.eink().appStyle.quickActionIconSize, 25);
  expect(AppThemes.eink().appStyle.quickActionPadding, 8);
  for (ThemeData theme in [AppThemes.light(), AppThemes.dark()]) {
    expect(theme.appStyle.dictionaryPopupOpacity, 0.95);
    expect(theme.appStyle.quickActionIconSize, 20);
    expect(theme.appStyle.quickActionPadding, 6);
  }
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/utils/app_themes_test.dart`
Expected: FAIL, `appStyle` is not defined.

- [ ] **Step 3: Implement `AppStyle` and add it to the three themes' `extensions`**

E-ink's `copyWith` also sets `dialogTheme`, `popupMenuTheme` and `bottomSheetTheme` with `RoundedRectangleBorder(side: AppStyle.eink.border)`, keeping the white backgrounds, and `textButtonTheme` with `TextButton.styleFrom(foregroundColor: Colors.black, side: AppStyle.eink.border, shape: const RoundedRectangleBorder())`.

- [ ] **Step 4: Update the dictionary popup in `base_source_page.dart`**

Remove the `dictionaryBackgroundOpacity` getter (nothing overrides it). `buildDictionaryResult`'s `Container` uses `decoration: BoxDecoration(color: theme.appColors.dictionaryPopup.withValues(alpha: theme.appStyle.dictionaryPopupOpacity), border: Border.fromBorderSide(theme.appStyle.border))`.

- [ ] **Step 5: Verify**

Run: `flutter test && flutter analyze`
Expected: all tests pass, `No issues found!`

- [ ] **Step 6: Commit**

Message: `Add borders to windows and text buttons in the E-ink theme`

---

### Task 3: Icon button border, quick-action sizes

**Files:**
- Modify: `lib/src/utils/components/jidoujisho_icon_button.dart`, `lib/src/pages/implementations/dictionary_term_page.dart:262-273`, `lib/src/utils/misc/app_colors.dart`
- Test: `test/utils/jidoujisho_icon_button_test.dart`

**Interfaces:**
- Consumes: `AppStyle.border`, `quickActionIconSize`, `quickActionPadding` from Task 2.
- Produces: `AppColors.quickActionBackground` (light `Color(0x0D000000)`, dark `Color(0x0DFFFFFF)`, e-ink `Colors.transparent`). `JidoujishoIconButton.shapeBorder` becomes `OutlinedBorder`.

- [ ] **Step 1: Write the failing widget tests**

Pump each case with a helper wrapping the button in `MaterialApp(theme: ..., home: Material(child: Spacing(dataBuilder: (_) => SpacingData.generate(10), child: button)))`, and have `buttonShape` return the `shape` of the first `DecoratedBox` under `JidoujishoIconButton` whose decoration is a `ShapeDecoration`.

```dart
testWidgets('draws the e-ink border', (tester) async {
  await pumpButton(tester, AppThemes.eink());
  expect(buttonShape(tester).side, const BorderSide(color: Colors.black, width: 1));
});

testWidgets('draws the e-ink border on a wide tap area', (tester) async {
  await pumpButton(tester, AppThemes.eink(), isWideTapArea: true);
  expect(buttonShape(tester).side, const BorderSide(color: Colors.black, width: 1));
});

testWidgets('keeps the given shape', (tester) async {
  await pumpButton(tester, AppThemes.eink(), shapeBorder: const RoundedRectangleBorder());
  expect(buttonShape(tester), isA<RoundedRectangleBorder>());
});

testWidgets('has no border in the light and dark themes', (tester) async {
  for (ThemeData theme in [AppThemes.light(), AppThemes.dark()]) {
    await pumpButton(tester, theme);
    expect(buttonShape(tester).side, BorderSide.none);
  }
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/utils/jidoujisho_icon_button_test.dart`
Expected: FAIL, no `DecoratedBox` under the button.

- [ ] **Step 3: Draw the border in both paths of `JidoujishoIconButton`**

The `InkWell` path replaces its `ColoredBox` with a `DecoratedBox` whose `ShapeDecoration` has `color: widget.backgroundColor ?? Colors.transparent` and `shape: widget.shapeBorder.copyWith(side: border)`. The `isWideTapArea` path wraps its `IconButton` in a `DecoratedBox` with the same `shape`. `border` is `Theme.of(context).appStyle.border`.

- [ ] **Step 4: Update the quick-action row**

`backgroundColor: theme.appColors.quickActionBackground`, `size: theme.appStyle.quickActionIconSize`, `padding: EdgeInsets.all(theme.appStyle.quickActionPadding)`.

- [ ] **Step 5: Verify**

Run: `flutter test && flutter analyze`
Expected: all tests pass, `No issues found!`

- [ ] **Step 6: Commit**

Message: `Add the icon button border and size quick actions per theme`

---

### Task 4: Chips and dictionary links

**Files:**
- Modify: `lib/src/utils/components/jidoujisho_tag.dart`, `lib/src/utils/misc/app_colors.dart`, `lib/src/pages/implementations/dictionary_structured_content_page.dart:69`
- Test: `test/utils/jidoujisho_tag_test.dart`, `test/utils/app_themes_test.dart`, `test/pages/dictionary_structured_content_test.dart`

**Interfaces:**
- Produces, on `AppColors`: `Color? chipBackground`, `Color? chipForeground`, `Color nestedChipBackground`, `Color? nestedChipForeground`. Light and dark: null, null, `Color(0xFFEF5350)` (`Colors.red.shade400`, which is not const), null. E-ink: black, white, white, black. A null falls back to the tag's own colour (for the nested text, to the chip's foreground).
- Produces, on `AppColors`: `Color? dictionaryLink`. Light and dark: null, which falls back to `colorScheme.error` as today. E-ink: black, because links in definitions are reading text and red shows as grey.
- Produces: top-level `Map<String, Style> dictionaryHtmlStyle({required Color textColor, required Color linkColor, required FontSize fontSize, required Style tableStyle})` in `dictionary_structured_content_page.dart`: the `style` map of its `Html` widget, moved out unchanged except that `'a'` also sets `textDecoration: TextDecoration.underline`. In E-ink the underline is the only thing marking a link, so it is set here instead of relying on flutter_html, which only underlines an `<a>` that has an `href`.

- [ ] **Step 1: Write the failing widget tests**

Pump `JidoujishoTag(text: 'JPDB', trailingText: '123, 888ka', backgroundColor: Colors.blue)` under `Spacing`, as in Task 3.

```dart
testWidgets('e-ink: black chip, inverted nested chip', (tester) async {
  await pumpTag(tester, AppThemes.eink());
  expect(textColour(tester, 'JPDB'), Colors.white);
  expect(boxColour(tester, 'JPDB'), Colors.black);
  expect(textColour(tester, '123, 888ka'), Colors.black);
  expect(boxColour(tester, '123, 888ka'), Colors.white);
});

testWidgets('light: keeps the tag colour', (tester) async {
  await pumpTag(tester, AppThemes.light());
  expect(textColour(tester, 'JPDB'), Colors.white);
  expect(boxColour(tester, 'JPDB'), Colors.blue);
  expect(textColour(tester, '123, 888ka'), Colors.white);
  expect(boxColour(tester, '123, 888ka'), const Color(0xFFEF5350));
});
```

`boxColour` reads the nearest `Container` ancestor of the text. In `app_themes_test.dart`:

```dart
test('dictionary links are black in e-ink only', () {
  expect(AppColors.eink.dictionaryLink, Colors.black);
  expect(AppColors.light.dictionaryLink, isNull);
  expect(AppColors.dark.dictionaryLink, isNull);
});
```

In `test/pages/dictionary_structured_content_test.dart`, pump `Html(data: html, shrinkWrap: true, style: dictionaryHtmlStyle(textColor: Colors.black, linkColor: Colors.black, fontSize: FontSize(16), tableStyle: Style()))` and read the rendered `TextSpan` holding the text from the `RichText`s:

```dart
for (String html in [
  '<a href="?query=語">語</a>',
  '<a href="?query=語"><span>語</span></a>',
  '<span><a href="?query=語"><span lang="ja"><span>語</span></span></a></span>',
  '<a>語</a>',
]) {
  testWidgets('a link is black and underlined: $html', (tester) async {
    await pumpDefinition(tester, html);
    expect(renderedStyle(tester, '語').decoration, TextDecoration.underline);
    expect(renderedStyle(tester, '語').color, Colors.black);
  });
}

testWidgets('other text is not underlined', (tester) async {
  await pumpDefinition(tester, '<span>語</span>');
  expect(renderedStyle(tester, '語').decoration, isNot(TextDecoration.underline));
});
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `flutter test test/utils/jidoujisho_tag_test.dart test/utils/app_themes_test.dart test/pages/dictionary_structured_content_test.dart`
Expected: FAIL, `dictionaryLink` and `dictionaryHtmlStyle` are not defined.

- [ ] **Step 3: Resolve the colours once at the top of `JidoujishoTag.build`**

Use the resolved colours for the container, icon, texts and the toast. In `dictionary_structured_content_page.dart`, `linkColor` becomes `theme.appColors.dictionaryLink ?? theme.colorScheme.error`, and `Html` takes its `style` from `dictionaryHtmlStyle`.

- [ ] **Step 4: Verify**

Run: `flutter test && flutter analyze`
Expected: all tests pass, `No issues found!`

- [ ] **Step 5: Commit**

Message: `Make dictionary chips and links black and white in the E-ink theme`

---

### Task 5: ttu fork: the `setTheme` command

Work in `/home/blastrock/work/ebook-reader-lite`.

**Files:**
- Modify: `apps/web/src/lib/host/host-theme.ts` (rewrite), `apps/web/src/lib/host/host-bridge.ts:11`, `apps/web/src/routes/b/+page.svelte:404-411`, `CLAUDE.md` (the `host-theme.ts` row, the Events list, a `setTheme` paragraph)
- Test: `apps/web/e2e/theme.spec.ts`

**Interfaces:**
- Produces:
  - Host command `setTheme(args)`: `args` is a full `ThemeOption` (seven CSS colour strings: `fontColor`, `backgroundColor`, `selectionFontColor`, `selectionBackgroundColor`, `hintFuriganaShadowColor`, `hintFuriganaFontColor`, `tooltipTextFontColor`). A missing or non-string key throws `setTheme: <key> must be a string` and changes nothing.
  - `withHostTheme(own$: Observable<ThemeOption>): Observable<ThemeOption>`.
  - `PROTOCOL_VERSION = 5`. The `theme` event no longer exists.

- [ ] **Step 1: Write the failing tests in `e2e/theme.spec.ts`**

Every case runs in both view modes (`VIEW_MODES`, as `context.spec.ts` does). Use `installRecordingHost`, `ensureFixtureBook` and `openBook`, with `page.addInitScript` setting `localStorage.theme = 'black-theme'` first so ttu's own setting disagrees with the host. `EINK` holds the seven values, with `fontColor: 'rgba(0, 0, 0, 1.000)'` and `backgroundColor: 'rgba(255, 255, 255, 1.000)'`.

```ts
test('setTheme overrides the theme chosen in ttu', async ({ page }) => {
  expect(await bodyBackground(page)).toBe('rgb(0, 0, 0)');
  await page.evaluate((theme) => window.ttuHost!.setTheme(theme), EINK);
  await expect.poll(() => bodyBackground(page)).toBe('rgb(255, 255, 255)');
  expect(await bookColour(page)).toBe('rgb(0, 0, 0)');
});

test('the last theme applies on the next load, before any command', async ({ page }) => {
  await page.evaluate((theme) => window.ttuHost!.setTheme(theme), EINK);
  await openBook(page, id);
  expect(await bodyBackground(page)).toBe('rgb(255, 255, 255)');
});

test('an incomplete theme is refused and changes nothing', async ({ page }) => {
  await expect(
    page.evaluate(() => window.ttuHost!.setTheme({ fontColor: 'red' }))
  ).rejects.toThrow(/backgroundColor must be a string/);
  expect(await bodyBackground(page)).toBe('rgb(0, 0, 0)');
});

test('no theme event is sent', async ({ page }) => {
  const events = await page.evaluate(() => window.__hostEvents);
  expect(events.some((event) => event.type === 'theme')).toBe(false);
});
```

`bodyBackground` is `getComputedStyle(document.body).backgroundColor`; `bookColour` is the computed `color` of `.book-content`.

- [ ] **Step 2: Run them to verify they fail**

Run, in `apps/web`: `pnpm build && pnpm test:e2e theme`
Expected: FAIL, `setTheme` is not a function.

- [ ] **Step 3: Rewrite `host-theme.ts`**

`initHostTheme()` registers `setTheme`, which validates the keys in the order listed above, writes the JSON to `localStorage.ttuHostTheme` and calls `hostTheme$.next(option)`. `hostTheme$` is a `BehaviorSubject<ThemeOption | undefined>`. `withHostTheme` always combines (`host ?? own`), so the debug fake host works too, and seeds `hostTheme$` from `localStorage.ttuHostTheme` only when `isHost()`: it runs during the page's init, before `initHost` in the layout's `onMount`. Unreadable JSON seeds nothing.

- [ ] **Step 4: Hook the reader page and bump the protocol**

In `routes/b/+page.svelte`, wrap the existing pipeline: `const themeOption$ = withHostTheme(theme$.pipe(...))`. Set `PROTOCOL_VERSION = 5`.

- [ ] **Step 5: Verify**

Update the fork's `CLAUDE.md`. Then run `pnpm eslint .` and `pnpm exec prettier --check` on the changed files at the fork's root, then `pnpm build && (cd apps/web && pnpm test:e2e)`.
Expected: no lint or format errors, every e2e test passes.

- [ ] **Step 6: Commit in the fork**

Message: `feat(host): let the app set the reader's colours` (Conventional Commits; jj runs no commitlint hook).

---

### Task 6: The app sets the book's colours

**Files:**
- Create: `lib/src/media/sources/ttu_colours.dart`
- Modify: `lib/media.dart`, `lib/src/utils/misc/app_colors.dart`, `lib/src/media/sources/ttu_bridge.dart`, `lib/src/pages/implementations/reader_ttu_source_page.dart`, `test/media/ttu_bridge_test.dart` (delete the `TtuThemeEvent` group), `DEBT.md`, `CLAUDE.md`
- Test: `test/media/ttu_colours_test.dart`, `test/utils/app_themes_test.dart`

**Interfaces:**
- Consumes: the `setTheme` command from Task 5.
- Produces:
  - `@immutable class TtuColours` with `Color` fields `font`, `background`, `selectionFont`, `selectionBackground`, `hintFuriganaFont`, `hintFuriganaShadow`, `tooltipTextFont`; `==` and `hashCode`; `Map<String, String> toJson()` keyed by ttu's `ThemeOption` names, each value `rgba(R, G, B, A)` with `A` from `toStringAsFixed(3)`.
  - Constants, in the field order above:
    - `TtuColours.light`: `0xDE000000`, `0xFFFFFFFF`, `0xFFF5F5F5`, `0xFF979797`, `0x54000000`, `0x4D222231`, `0x99000000`
    - `TtuColours.black`: `0xDEFFFFFF`, `0xFF000000`, `0x99555A5C`, `0xCCD4D9DC`, `0x54FFFFFF`, `0x4DF0F0F1`, `0x99FFFFFF`
    - `TtuColours.eink`: `0xFF000000`, `0xFFFFFFFF`, `0xFFFFFFFF`, `0xFF000000`, `0x61000000`, `0x4D000000`, `0xFF000000`
  - `AppColors.ttu` (`TtuColours.light`, `.black`, `.eink`); its `lerp` takes `t < 0.5 ? ttu : other.ttu`.
  - `TtuBridge.setTheme(TtuColours colours)`, `TtuBridge.protocolVersion = 5`.

E-ink's furigana hint stays at ttu's 38%: it marks hidden furigana rather than being reading text, so full black would defeat it.

- [ ] **Step 1: Write the failing tests**

```dart
test('e-ink colours go on the wire in full', () {
  expect(TtuColours.eink.toJson(), {
    'fontColor': 'rgba(0, 0, 0, 1.000)',
    'backgroundColor': 'rgba(255, 255, 255, 1.000)',
    'selectionFontColor': 'rgba(255, 255, 255, 1.000)',
    'selectionBackgroundColor': 'rgba(0, 0, 0, 1.000)',
    'hintFuriganaFontColor': 'rgba(0, 0, 0, 0.380)',
    'hintFuriganaShadowColor': 'rgba(0, 0, 0, 0.302)',
    'tooltipTextFontColor': 'rgba(0, 0, 0, 1.000)',
  });
});

test('light keeps ttu\'s own text colour', () {
  expect(TtuColours.light.toJson()['fontColor'], 'rgba(0, 0, 0, 0.871)');
});

test('each theme carries its book colours', () {
  expect(AppThemes.light().appColors.ttu, TtuColours.light);
  expect(AppThemes.dark().appColors.ttu, TtuColours.black);
  expect(AppThemes.eink().appColors.ttu, TtuColours.eink);
});
```

- [ ] **Step 2: Run them to verify they fail**

Run: `flutter test test/media/ttu_colours_test.dart test/utils/app_themes_test.dart`
Expected: FAIL, `TtuColours` is not defined.

- [ ] **Step 3: Add `TtuColours` and `AppColors.ttu`; update `TtuBridge`**

Remove `TtuThemeEvent`, `onTheme` and the `'theme'` case, and delete the group from `ttu_bridge_test.dart`.

- [ ] **Step 4: Push the colours from `reader_ttu_source_page.dart`**

Add `bool _bridgeReady = false` and `TtuColours? _pushedColours`, and a `void _pushColours(TtuColours colours)` that returns when `colours == _pushedColours`, records them, and calls `setTheme`, catching `TtuBridgeException` with `debugPrint`. `_onBridgeReady`, on a compatible event, sets `_bridgeReady = true`, clears `_pushedColours` and pushes. Override `didChangeDependencies`, reading `Theme.of(context).appColors.ttu` unconditionally (that registers the dependency) and pushing when `_bridgeReady`. The `Scaffold`'s `backgroundColor` becomes `theme.appColors.ttu.background`, so E-ink doesn't flash black while the page loads. ttu's Settings page opens in this same page and is not affected: its `body` is an opaque `#ECEFF1` with dark text under every ttu theme, and the WebView isn't transparent, so this colour only shows before the page paints and in the strip above the `SafeArea`. `setTheme` is also sent there, and only stores the colours, since `withHostTheme` is hooked into the reader page alone.

- [ ] **Step 5: Update the docs**

Delete the DEBT entry "The ttu `theme` event has no listener". In `CLAUDE.md`: replace the `AppModel` theme mention under Pages with `AppThemes`, `AppStyle` and `AppThemeMode`; state under ttu that the app sets the reader's colours with `setTheme` from `AppColors.ttu`, that ttu's own theme setting has no effect in the app, and that the overlay keeps the last colours in `localStorage.ttuHostTheme`. Replace the "E-ink UI tuning is a later pass that has not started" line: the theme exists, refresh and animation tuning are still to come.

- [ ] **Step 6: Verify**

Run: `tool/fetch_ttu.sh --local ../ebook-reader-lite && flutter test && flutter analyze`
Expected: all tests pass, `No issues found!`

- [ ] **Step 7: Check on a device or the emulator**

With `ANDROID_HOME=/home/blastrock/android/android-sdk-linux`, run the app. Check:
- no protocol snackbar, on a book and on ttu's Settings page;
- a book opens black on white in E-ink;
- switching the system to dark with the app on System recolours the open book;
- Light and Dark look as they did;
- ttu's Settings page opens and reads normally in Light, Dark and E-ink, with `extendPageBeyondNavigationBar` on and off, and the status bar icons stay visible when swiped into view over the new background;
- a link in a real definition (a JMdict cross-reference) is black and underlined in E-ink, and tapping it still searches.

- [ ] **Step 8: Commit**

Message: `Set the book's colours from the app's theme`

---

### Task 7: Release the fork and pin it

- [ ] **Step 1: Tag the fork's Task 5 commit locally**

Run, in the fork: `git tag v4.3.0 <commit>`. This is a minor release, as earlier protocol changes were.

- [ ] **Step 2: Stop and ask the user to push the fork's commits and the tag**

Wait until the release asset is published.

- [ ] **Step 3: Pin the release**

Run: `tool/fetch_ttu.sh --update v4.3.0 && flutter test && flutter analyze`
Expected: `tool/ttu.lock` names v4.3.0, all tests pass, `No issues found!`

- [ ] **Step 4: Commit**

Message: `Pin ebook-reader-lite v4.3.0`
