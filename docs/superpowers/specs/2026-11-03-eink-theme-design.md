# E-ink theme

## Intent

Yomimoto is being made into a book reader with first-class e-ink support. On
an e-ink screen, the light theme is almost right but has two problems:

- **Contrast where it matters.** You can't tell whether something that looks
  white is really white, or whether text is truly black. Most of the app's
  greys don't matter, but the text you read does: the book's text and the
  dictionary popup's text. Today both are "black at 87%" (Flutter's
  Material 2 default text colour, and ttu's light theme `fontColor`), which is
  dark grey.
- **Invisible edges.** Everything is white on white, so you can't see where a
  button or a window ends. This is the user's main concern.

E-ink screens also have poor touch accuracy, which is why the dictionary's
quick-action buttons are large. On a phone they are larger than they need to
be.

This is also the first step towards the app fully controlling ttu instead of
ttu's own settings: the app now chooses the book's colours.

## Goals

1. **A third theme, E-ink**, offered beside Light and Dark (and System) in
   Settings. It is a light theme: white backgrounds, black text.
2. **High contrast for reading text in E-ink**: pure black (`#000000`) on pure
   white (`#FFFFFF`) for
   - the book's text in the ttu reader;
   - dictionary results' text, in the reader's popup and in the dictionary
     tab and other dictionary pages.
3. **Thin black borders in E-ink** (1dp, black) around
   - **text buttons** (`TextButton`, about 83 uses: dialog and page actions),
     through the theme's `textButtonTheme`;
   - **the app's icon button, `JidoujishoIconButton`** (about 37 uses,
     including every quick action), in the component itself, reading the
     border from the theme. Both of its paths get it: its own `InkWell`
     rendering and the `IconButton` it builds when `isWideTapArea` is set.

   Deliberately left without a border, because they are rarely used: plain
   `IconButton`s (Material 2 ignores `IconButtonThemeData`, so each would
   need its own edit), `PopupMenuButton`s, the floating search bar's
   actions (`FloatingSearchBarAction`), and `InkWell`/`GestureDetector` tap
   areas;
   - **windows**: the reader's dictionary popup, dialogs, popup menus and
     bottom sheets.
4. **Opaque white dictionary popup in E-ink**: today it is `#F2F2F2` at 95%
   opacity (the book shows through faintly) and each entry sits on an
   `#F9F9F9` card. In E-ink the popup is fully opaque white and entries have
   no card tint. The quick-action buttons lose their 5% grey tint.
5. **Dictionary chips in E-ink**: every chip (`JidoujishoTag`) is black with
   white text, whatever its colour in the other themes (dictionary-name chips
   are `Colors.red.shade900`, tag chips use the tag's colour). The nested chip
   inside a chip (the frequencies part of a frequency chip, e.g.
   `[JPDB [123, 888ka]]`, today `Colors.red.shade400`) is inverted: white
   background, black text.
6. **Button size depends on the theme**: the quick-action buttons keep
   today's size in E-ink (a 25dp icon plus 8dp padding, about 41dp square)
   and shrink in Light and Dark (about 32dp square in the mockup: a 20dp icon
   plus 6dp padding — a starting point, to be judged on a device). "Large on
   e-ink devices" means "large when the E-ink theme is selected"; there is no
   device detection.
7. **The app sets the book's colours in ttu**, for every theme, through a new
   `TtuBridge` command:
   - E-ink: pure black text on pure white.
   - Light: ttu's own `light-theme` colours, so it looks as it does today.
   - Dark: ttu's `black-theme` colours, matching the app's black background.

   The command carries ttu's whole set of colours (`fontColor`,
   `backgroundColor`, `selectionFontColor`, `selectionBackgroundColor`,
   `hintFuriganaFontColor`, `hintFuriganaShadowColor`,
   `tooltipTextFontColor`), so the app owns all of them. They are sent when a
   book opens and again when the theme changes while a book is open. The
   theme chosen in ttu's own settings then has no effect inside the app.
8. **Remove ttu's `theme` event** from both sides of the bridge: the host
   overlay's `host-theme.ts` sender, `TtuThemeEvent`, `TtuBridge.onTheme`,
   its test cases in `test/media/ttu_bridge_test.dart`, and the
   "The ttu `theme` event has no listener" entry in `DEBT.md`. The app
   dictates colours, so ttu reporting its colours back is pointless.
9. **Delete the DEBT entry "Both colour schemes carry unchosen Material 3
   roles".** Decision: the colour scheme roles the app doesn't use are left
   at their defaults, in all three themes, E-ink included. They get real
   colours when a widget that uses them is added.

## Non-goals

- **No other greys change.** Minor greys (disabled icons, switch tracks,
  selected list rows, the search bar background, the image placeholder) may
  stay as they are in E-ink. The builder may make them white or black where
  that is the simpler code, but nothing requires it.
- **The red accent stays** in E-ink (spinner, switches, sliders, focused
  fields, labels). On a greyscale screen it shows as grey, which gives the
  buttons some style and doesn't need high contrast.
- **Light and Dark get no borders**, and nothing changes in them visually
  except the smaller quick-action buttons. (The ttu colours they send are
  ttu's own, see goal 7.)
- **ttu's settings page is not changed.** Its theme picker stays, even though
  it no longer has an effect in the app. The whole settings page will be
  hidden from the app at some later point; diverging from upstream ttu now
  is not wanted.
- **The manga reader is out of scope**: its text is in the page images.
- **No other e-ink tuning** (refresh behaviour, animation suppression). That
  is still a later pass; animations stay (see the e-ink-later rule).
- **No device detection.**

## Constraints

- Follow `CLAUDE.md`. In particular: colours that differ between themes come
  from the theme (a `ColorScheme` role, or a field of the `AppColors` theme
  extension), never from a brightness check. With three themes, "is this the
  E-ink theme" must not become a scattered check either: values that differ
  per theme (border, chip colours, popup opacity, button size) belong in the
  theme, most naturally in `AppColors` or a sibling `ThemeExtension`.
- **ttu side** (github.com/blastrock/ebook-reader-lite): the change lives in
  the host overlay under `apps/web/src/lib/host/`, with only small hooks in
  upstream files, so the fork can still be rebased onto upstream. It must
  stay inert outside the app. The protocol version goes up by one on both
  sides (`PROTOCOL_VERSION` in `host-bridge.ts`, `TtuBridge.protocolVersion`,
  currently 4). The new command must also be callable from the fake host
  (`localStorage.ttuHostDebug = '1'`, `window.ttuHost.<command>({...})`).
  CI's `pnpm eslint .`, `pnpm build` and the e2e tests must pass. A
  Playwright case covering the new command is wanted.
- **Release flow for the fork**: I (Claude) create the `vX.Y.Z` tag locally;
  the user pushes it. The app pins the new release with
  `tool/fetch_ttu.sh --update <tag>` and commits `tool/ttu.lock`. During
  development, iterate with `tool/fetch_ttu.sh --local ../ebook-reader-lite`.
- **Theme preference**: `Preferences.themeMode` is an
  `EnumPreference<ThemeMode>` keyed `theme_mode`, stored by enum value name.
  Flutter's `ThemeMode` has no fourth value, so the setting needs its own
  enum. Installs exist, so values already stored (`system`, `light`, `dark`)
  must still be read correctly; keeping the same value names under the same
  key does that without a migration.
- `flutter analyze` clean, `flutter test` green, generated files
  regenerated (new strings go through slang), British spelling, docs on
  every public member.
- Commit each approved step (`jj describe` + `jj new`); the user pushes.

## Decided by the user

- E-ink is a third theme option, not a replacement for Light and not
  detected.
- High contrast is required only for reading text (book, dictionary); other
  greys are unimportant.
- The red accent stays.
- Borders: thin, black, on text buttons, `JidoujishoIconButton` and
  windows; E-ink only. Other buttons are skipped.
- Quick-action buttons: large in E-ink, smaller in Light and Dark.
- Chips: black with white text; the nested chip inverted to black on white.
- The app pushes the book's colours to ttu for every theme; the `theme`
  event is removed.
- ttu's settings page stays unchanged.
- Unused colour scheme roles stay at their defaults; the DEBT entry about
  them is deleted.

## Calls made by Claude (check these)

- Light sends ttu's `light-theme` colours and Dark its `black-theme`
  colours, so neither changes visually.
- Windows that get a border include dialogs, popup menus and bottom sheets,
  not just the dictionary popup.
- E-ink selection, furigana hint and tooltip colours in ttu: the builder
  picks black/white values in the spirit of goal 2 (for example the hint
  furigana in black rather than 38% black, if it reads well).
- Links inside dictionary definitions count as reading text: black in
  E-ink (they use the red `error` role today). The underline is then the
  only thing marking them, so it is set explicitly and pinned by a test.
- When a book opens in E-ink, it should not visibly paint in other colours
  first: on e-ink, a flash costs a full refresh. How the colours get in
  before the first paint is the builder's call within the bridge rules
  (commands only, no injected JS).
- Light/Dark quick-action size of about 32dp is a starting point.

## Left to the builder

- How the theme is built (a third `ThemeData` getter beside `theme` and
  `darkTheme`, or a shared builder), and how `MaterialApp` is told to use
  it.
- The new enum's name and where it lives; the Settings label for E-ink.
- The bridge command's name and payload shape, and whether the colours are
  sent as ttu's `rgba()` strings or as numbers.
- How the ttu overlay applies the colours (overriding the theme the reader
  page computes from `theme$` without rewriting ttu's stored setting is the
  intent of the "settings unchanged" non-goal).
- How the border reaches the windows the theme cannot style (the reader's
  dictionary popup is a plain `Container`).
- Whether to update `CLAUDE.md` (it should mention the E-ink theme, the new
  bridge command and the removed event).
