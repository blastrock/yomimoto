# ttu bridge — phase 1 implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the injected-JS integration between the app and ttu with a typed bridge living in the `ebook-reader-lite` fork, built from latest upstream and fetched into the app instead of committed.

**Architecture:** The fork gains a small overlay under `apps/web/src/lib/host/` that is inert outside the app. It talks to Flutter through `flutter_inappwebview`'s `callHandler('ttuHost', …)` (events) and a `window.ttuHost` command object driven by `callAsyncJavaScript` (commands). On the Dart side a `TtuBridge` class wraps that protocol, and `ReaderTtuSourcePage` is rewritten on top of it. ttu's own manager still serves as the library in this phase (phase 2 replaces it).

**Tech Stack:** SvelteKit 2 / Svelte 4 / TypeScript / rxjs (fork); Flutter 3.44, `flutter_inappwebview` 6.1.5, Riverpod (app); jj for version control in both repos; GitHub Actions for releases.

**Spec:** `docs/superpowers/specs/2026-10-10-ttu-bridge-and-native-library-design.md` (sections 1–9, 11–14; section 10 is phase 2 and has its own plan later).

## Global Constraints

- jj filesets treat some characters specially: quote paths containing `+` as `'"path"'` (e.g. `'"apps/web/src/routes/+layout.svelte"'`).
- Two repositories: the app at `/home/blastrock/work/jidoujisho` (called **APP** below) and the fork at `/home/blastrock/work/ebook-reader-lite` (called **FORK**). Both are git-colocated jj repos: commit with `jj commit <paths> -m "<message>"`, never `git commit`.
- Every commit message ends with the two lines:
  ```
  Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
  Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk
  ```
  (separated from the body by a blank line).
- FORK commits use conventional-commit subjects (`feat(host): …`, `ci: …`). APP commits use this repo's style (`TTU: …` for reader work).
- FORK overlay: new code only in new files under `apps/web/src/lib/host/`; edits to upstream files are limited to the hooks listed per task. Everything is inert unless `window.flutter_inappwebview` exists (or the debug stub is enabled).
- FORK files need the license header enforced by eslint, exactly:
  ```ts
  /**
   * @license BSD-3-Clause
   * Copyright (c) 2026, ッツ Reader Authors
   * All rights reserved.
   */
  ```
  followed by one blank line.
- APP: `flutter analyze` must stay at **0 errors, 0 warnings**, and the info count must not grow above its value at the start of Task 7 (record it then). New Dart code: `///` doc comment on every public member, `package:` imports via barrels (`package:yuuna/media.dart` etc.), single quotes, British spelling.
- APP has no automated tests and FORK has none either (by project convention). Verification is: FORK `pnpm check`, `pnpm eslint .`, `pnpm build` in `apps/web`; APP `flutter analyze`; plus **manual checks on a device done by the user**. When a step says "ask the user to verify on device", stop, list the exact checks, and wait for their answer before committing.
- Bridge protocol version is `1` on both sides.
- Pushing to GitHub and creating tags/releases are outward-facing: confirm with the user immediately before each push.
- `document_file_save_plus`, `local_assets_server` (if the hosting spike succeeds) and the `volume_button_turning_speed` setting are removed; no migration code (fresh installs only).

## Review Focus

1. **Tap on a ruby base / near furigana** — the lookup must start at the tapped base character and the highlight must cover exactly the matched characters, never `rt` text. Pinned by Task 3 Step 6 (debug-stub checks) and Task 10 Step 6 (device).
2. **Tap while a word is already highlighted** — must dismiss the popup and clear the highlight (parity with the old app), not start a new lookup. Pinned by Task 3 Step 6 and Task 10 Step 6.
3. **Volume keys in continuous mode and in vertical paginated mode** — volume-up is "next page", volume-down "previous page", swapped when inverted (parity with the old wheel-event hack, which mapped volume-up to `deltaY > 0` → `flipPage(1)`). Pinned by Task 9 Step 5.
4. **Client-side navigation inside the WebView** (manager → book → settings → book) — the bridge must keep working after SvelteKit route changes without a page reload, and the page manager reference must not go stale. Pinned by Task 2 Step 4 and Task 9 Step 5.
5. **Bridge version skew** — an app built against a different fork release must say so instead of silently misbehaving. Pinned by Task 9 Step 1 (mismatch log + snackbar) and Step 5.

---

## Task 0: Prerequisites (no commits)

**Files:** none.

- [ ] **Step 1: Make pnpm available**

The fork's CI uses pnpm 12.3.4 and Node 24.21.0. Node 24 is installed. Run:

```bash
corepack enable --install-directory ~/.local/bin pnpm && pnpm --version
```

If that fails or prints a different major than 12, ask the user how they want pnpm installed (do not run `sudo` or global npm installs without asking).

- [ ] **Step 2: Install the fork's dependencies and check a clean build**

```bash
cd /home/blastrock/work/ebook-reader-lite && pnpm install && cd apps/web && pnpm svelte-kit sync && pnpm check && pnpm build
```

Expected: build succeeds and creates `apps/web/build/`. Record the output of:

```bash
cd /home/blastrock/work/ebook-reader-lite/apps/web/build && find . -type d | sort
```

(it is needed in Task 7).

- [ ] **Step 3: Record the APP analyzer baseline**

```bash
cd /home/blastrock/work/jidoujisho && flutter analyze 2>&1 | tail -3
```

Note the info count; it is the ceiling for the whole plan.

---

## Task 1: FORK — bridge transport, debug stub, host styles

**Files:**
- Create: `apps/web/src/lib/host/host-bridge.ts`
- Create: `apps/web/src/lib/host/host-debug.ts`
- Create: `apps/web/src/lib/host/host-styles.ts`
- Create: `apps/web/src/lib/host/host-init.ts`
- Modify: `apps/web/src/routes/+layout.svelte` (script block: two imports, one `onMount`)

**Interfaces:**
- Produces (TS, used by every later FORK task):
  - `PROTOCOL_VERSION: number` (= 1)
  - `isHost(): boolean`
  - `sendToHost(type: string, payload?: Record<string, unknown>): Promise<void>`
  - `registerHostCommand(name: string, command: HostCommand): void` where `type HostCommand = (args: Record<string, unknown>) => unknown`
  - `initHost(): void` (in `host-init.ts`; later tasks add calls to it)
- Produces (wire): event `{type: 'ready', protocolVersion: 1, route: string}` sent through `callHandler('ttuHost', …)`; `window.ttuHost` is the command registry object.

- [ ] **Step 1: Create `host-bridge.ts`**

```ts
/**
 * @license BSD-3-Clause
 * Copyright (c) 2026, ッツ Reader Authors
 * All rights reserved.
 */

import { browser } from '$app/environment';
import { logger } from '$lib/data/logger';

/** Bumped whenever an event or command changes shape. Mirrored in the app. */
export const PROTOCOL_VERSION = 1;

export type HostCommand = (args: Record<string, unknown>) => unknown;

interface FlutterInAppWebView {
  _platformReady?: boolean;
  callHandler(name: string, ...args: unknown[]): Promise<unknown>;
}

declare global {
  interface Window {
    flutter_inappwebview?: FlutterInAppWebView;
    ttuHost?: Record<string, HostCommand>;
  }
}

const commands: Record<string, HostCommand> = {};

let platformReady: Promise<void> | undefined;

export function isHost() {
  return browser && !!window.flutter_inappwebview;
}

function whenPlatformReady() {
  platformReady ??= new Promise<void>((resolve) => {
    if (window.flutter_inappwebview?._platformReady) {
      resolve();
      return;
    }
    window.addEventListener('flutterInAppWebViewPlatformReady', () => resolve(), {
      once: true
    });
  });

  return platformReady;
}

export async function sendToHost(type: string, payload: Record<string, unknown> = {}) {
  if (!isHost()) {
    return;
  }

  await whenPlatformReady();

  try {
    await window.flutter_inappwebview?.callHandler('ttuHost', { type, ...payload });
  } catch (error) {
    logger.error(`ttuHost: failed to send ${type}`, error);
  }
}

export function registerHostCommand(name: string, command: HostCommand) {
  commands[name] = command;
}

export function exposeHostCommands() {
  window.ttuHost = commands;
}
```

- [ ] **Step 2: Create `host-debug.ts`**

```ts
/**
 * @license BSD-3-Clause
 * Copyright (c) 2026, ッツ Reader Authors
 * All rights reserved.
 */

/**
 * Lets the host bridge be exercised in a desktop browser: with
 * `localStorage.ttuHostDebug = '1'`, a fake `flutter_inappwebview` logs every
 * event, and commands can be called from the console via `window.ttuHost`.
 */
export function installDebugHost() {
  if (window.flutter_inappwebview) {
    return;
  }

  let enabled = false;

  try {
    enabled = window.localStorage.getItem('ttuHostDebug') === '1';
  } catch (_error) {
    enabled = false;
  }

  if (!enabled) {
    return;
  }

  window.flutter_inappwebview = {
    _platformReady: true,
    callHandler(name: string, ...args: unknown[]) {
      // eslint-disable-next-line no-console
      console.info('[ttuHost]', name, ...args);
      return Promise.resolve(null);
    }
  };
}
```

- [ ] **Step 3: Create `host-styles.ts`**

These are the rules the app used to inject into `<head>`.

```ts
/**
 * @license BSD-3-Clause
 * Copyright (c) 2026, ッツ Reader Authors
 * All rights reserved.
 */

const hostStyles = `
.ttu-host rt,
.ttu-host rp {
  -webkit-touch-callout: none;
  -webkit-user-select: none;
  user-select: none;
}

.ttu-host ::selection {
  color: white;
  background: rgba(255, 0, 0, 0.6);
}
`;

export function installHostStyles() {
  document.documentElement.classList.add('ttu-host');

  const style = document.createElement('style');
  style.id = 'ttu-host-styles';
  style.textContent = hostStyles;
  document.head.append(style);
}
```

- [ ] **Step 4: Create `host-init.ts`**

```ts
/**
 * @license BSD-3-Clause
 * Copyright (c) 2026, ッツ Reader Authors
 * All rights reserved.
 */

import { exposeHostCommands, isHost, PROTOCOL_VERSION, sendToHost } from '$lib/host/host-bridge';
import { installDebugHost } from '$lib/host/host-debug';
import { installHostStyles } from '$lib/host/host-styles';

let initialised = false;

export function initHost() {
  if (initialised) {
    return;
  }

  installDebugHost();

  if (!isHost()) {
    return;
  }

  initialised = true;

  exposeHostCommands();
  installHostStyles();

  sendToHost('ready', {
    protocolVersion: PROTOCOL_VERSION,
    route: window.location.pathname
  });
}
```

- [ ] **Step 5: Hook it into `routes/+layout.svelte`**

In the `<script lang="ts">` block, add after the existing `import { MetaTags } from 'svelte-meta-tags';` line:

```ts
  import { onMount } from 'svelte';
  import { initHost } from '$lib/host/host-init';
```

and after the existing `page.subscribe((p) => (path = p.url.pathname));` line:

```ts

  onMount(initHost);
```

(The layout is mounted once per document, so `ready` is sent once per page load; SvelteKit client-side navigation does not re-send it.)

- [ ] **Step 6: Static checks**

```bash
cd /home/blastrock/work/ebook-reader-lite/apps/web && pnpm check && pnpm eslint src/lib/host src/routes/+layout.svelte && pnpm build
```

Expected: all pass with no new errors.

- [ ] **Step 7: Manual check in a desktop browser**

```bash
cd /home/blastrock/work/ebook-reader-lite/apps/web && pnpm dev
```

Open the printed URL in Chrome, run `localStorage.ttuHostDebug = '1'` in the console, reload. Expected: console shows `[ttuHost] ttuHost {type: 'ready', protocolVersion: 1, route: '/'}`; `document.documentElement.classList.contains('ttu-host')` is `true`; `window.ttuHost` is an object. Then `localStorage.removeItem('ttuHostDebug')`, reload: no `[ttuHost]` line, no `ttu-host` class.

- [ ] **Step 8: Commit**

```bash
cd /home/blastrock/work/ebook-reader-lite && jj commit apps/web/src/lib/host '"apps/web/src/routes/+layout.svelte"' -m "feat(host): add host bridge transport and host styles

Inert outside the jidoujisho app: everything is gated on
window.flutter_inappwebview, or on localStorage.ttuHostDebug for
debugging in a desktop browser.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 2: FORK — page turning commands

**Files:**
- Create: `apps/web/src/lib/host/host-page.ts`
- Modify: `apps/web/src/lib/host/host-init.ts` (call `initHostPage()`)
- Modify: `apps/web/src/routes/b/+page.svelte` (one import, one reactive statement, one line in the existing `onDestroy`)

**Interfaces:**
- Consumes: `registerHostCommand` (Task 1).
- Produces: commands `nextPage` and `prevPage` (no args, no result); `setHostPageManager(pageManager: PageManager | undefined): void`.

- [ ] **Step 1: Create `host-page.ts`**

```ts
/**
 * @license BSD-3-Clause
 * Copyright (c) 2026, ッツ Reader Authors
 * All rights reserved.
 */

import type { PageManager } from '$lib/components/book-reader/types';
import { registerHostCommand } from '$lib/host/host-bridge';

let currentPageManager: PageManager | undefined;

export function setHostPageManager(pageManager: PageManager | undefined) {
  currentPageManager = pageManager;
}

export function initHostPage() {
  registerHostCommand('nextPage', () => currentPageManager?.nextPage());
  registerHostCommand('prevPage', () => currentPageManager?.prevPage());
}
```

- [ ] **Step 2: Register it in `host-init.ts`**

Add the import `import { initHostPage } from '$lib/host/host-page';` and, in `initHost()`, call `initHostPage();` right after `installHostStyles();`.

- [ ] **Step 3: Hook the reader route**

In `apps/web/src/routes/b/+page.svelte`:
- next to the other `$lib` imports (e.g. after `import { onKeydownReader } from './on-keydown-reader';`), add
  `import { setHostPageManager } from '$lib/host/host-page';`
- after the line `let pageManager: PageManager | undefined;` (around line 193), add
  `$: setHostPageManager(pageManager);`
- inside the existing `onDestroy(() => { … })` (around line 578), add as its first statement
  `setHostPageManager(undefined);`

- [ ] **Step 4: Static and browser checks**

```bash
cd /home/blastrock/work/ebook-reader-lite/apps/web && pnpm check && pnpm eslint src/lib/host src/routes/b && pnpm build
```

Then with `pnpm dev` and `ttuHostDebug = '1'`: import any EPUB through ttu's manager, open it, and in the console run `await window.ttuHost.nextPage({})` and `await window.ttuHost.prevPage({})` in paginated mode and in continuous mode (switch in ttu's settings). Expected: the page moves forward/back. Navigate manager → book → manager → another book (client-side, no reload) and repeat: commands still act on the open book.

- [ ] **Step 5: Commit**

```bash
cd /home/blastrock/work/ebook-reader-lite && jj commit apps/web/src/lib/host '"apps/web/src/routes/b/+page.svelte"' -m "feat(host): expose page turning to the host

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 3: FORK — tap-to-lookup, highlight, selection

**Files:**
- Create: `apps/web/src/lib/host/host-lookup.ts`
- Modify: `apps/web/src/lib/host/host-init.ts` (call `initHostLookup()`)

**Interfaces:**
- Consumes: `registerHostCommand`, `sendToHost` (Task 1); upstream `getParagraphNodes` (`$lib/components/book-reader/get-paragraph-nodes`).
- Produces (wire):
  - event `{type: 'tap', text: string, offset: number, x: number, y: number}` — `text` is the ruby-stripped paragraph, `offset` a UTF-16 index into it, `-1` (with `text: ''`) meaning "dismiss";
  - command `highlight({start: number, length: number})` — offsets into the last `tap`'s `text`;
  - command `clearSelection()`;
  - command `getSelectedText()` → `string` (ruby text excluded, trimmed).

- [ ] **Step 1: Create `host-lookup.ts`**

```ts
/**
 * @license BSD-3-Clause
 * Copyright (c) 2026, ッツ Reader Authors
 * All rights reserved.
 */

import { getParagraphNodes } from '$lib/components/book-reader/get-paragraph-nodes';
import { registerHostCommand, sendToHost } from '$lib/host/host-bridge';

interface ParagraphMap {
  text: string;
  nodes: Text[];
  starts: number[];
}

let lastParagraph: ParagraphMap | undefined;

function isInRubyAnnotation(node: Node) {
  return !!node.parentElement?.closest('rt, rp');
}

function findParagraph(node: Node): Element | undefined {
  let element: Element | null = node instanceof Element ? node : node.parentElement;

  const paragraph = element?.closest('p');
  if (paragraph) {
    return paragraph;
  }

  while (element && !element.classList.contains('book-content')) {
    const { display } = getComputedStyle(element);
    if (!display.startsWith('inline') && !display.startsWith('ruby')) {
      return element;
    }
    element = element.parentElement;
  }

  return undefined;
}

function mapParagraph(paragraph: Element): ParagraphMap {
  const nodes = getParagraphNodes(paragraph).filter(
    (node): node is Text => node.nodeType === Node.TEXT_NODE && !isInRubyAnnotation(node)
  );
  const starts: number[] = [];
  let text = '';

  for (const node of nodes) {
    starts.push(text.length);
    text += node.data;
  }

  return { text, nodes, starts };
}

function caretFromPoint(x: number, y: number) {
  const range = document.caretRangeFromPoint(x, y);

  if (!range || range.startContainer.nodeType !== Node.TEXT_NODE) {
    return undefined;
  }

  const node = range.startContainer as Text;
  let offset = range.startOffset;

  // The caret lands *after* a character when its second half is tapped.
  if (offset > 0) {
    const previous = new Range();
    previous.setStart(node, offset - 1);
    previous.setEnd(node, offset);

    const box = previous.getBoundingClientRect();
    if (box.left <= x && box.right >= x && box.top <= y && box.bottom >= y) {
      offset -= 1;
    }
  }

  return { node, offset };
}

function locate(map: ParagraphMap, position: number, isEnd: boolean) {
  for (let i = 0; i < map.nodes.length; i += 1) {
    const end = map.starts[i] + map.nodes[i].data.length;
    if (isEnd ? position <= end : position < end) {
      return { node: map.nodes[i], offset: position - map.starts[i] };
    }
  }

  return undefined;
}

function dismiss(x: number, y: number) {
  lastParagraph = undefined;
  sendToHost('tap', { text: '', offset: -1, x, y });
}

function onClick(event: MouseEvent) {
  const { target } = event;

  if (!(target instanceof Element) || !target.closest('.book-content')) {
    return;
  }

  const x = Math.round(event.clientX);
  const y = Math.round(event.clientY);
  const selection = window.getSelection();

  if ((selection && !selection.isCollapsed) || target.classList.contains('book-content')) {
    dismiss(x, y);
    return;
  }

  const caret = caretFromPoint(event.clientX, event.clientY);
  const paragraph = caret && findParagraph(caret.node);

  if (!caret || !paragraph) {
    dismiss(x, y);
    return;
  }

  const map = mapParagraph(paragraph);
  const nodeIndex = map.nodes.indexOf(caret.node);
  const offset = nodeIndex === -1 ? -1 : map.starts[nodeIndex] + caret.offset;

  if (offset < 0 || offset >= map.text.length) {
    dismiss(x, y);
    return;
  }

  lastParagraph = map;
  sendToHost('tap', { text: map.text, offset, x, y });
}

function highlight({ start, length }: Record<string, unknown>) {
  if (!lastParagraph || typeof start !== 'number' || typeof length !== 'number') {
    return;
  }

  const end = Math.min(start + length, lastParagraph.text.length);
  const from = locate(lastParagraph, start, false);
  const to = locate(lastParagraph, end, true);

  if (!from || !to) {
    return;
  }

  const range = new Range();
  range.setStart(from.node, from.offset);
  range.setEnd(to.node, to.offset);

  const selection = window.getSelection();
  selection?.removeAllRanges();
  selection?.addRange(range);
}

function clearSelection() {
  const selection = window.getSelection();

  if (selection && !selection.isCollapsed) {
    selection.removeAllRanges();
  }
}

function getSelectedText() {
  const selection = window.getSelection();

  if (!selection || selection.isCollapsed || !selection.rangeCount) {
    return '';
  }

  const fragment = selection.getRangeAt(0).cloneContents();
  fragment.querySelectorAll('rt, rp').forEach((element) => element.remove());

  return (fragment.textContent ?? '').trim();
}

export function initHostLookup() {
  document.addEventListener('click', onClick, true);

  registerHostCommand('highlight', highlight);
  registerHostCommand('clearSelection', clearSelection);
  registerHostCommand('getSelectedText', getSelectedText);
}
```

- [ ] **Step 2: Register it in `host-init.ts`**

Add `import { initHostLookup } from '$lib/host/host-lookup';` and call `initHostLookup();` after `initHostPage();`.

- [ ] **Step 3: Static checks**

```bash
cd /home/blastrock/work/ebook-reader-lite/apps/web && pnpm check && pnpm eslint src/lib/host && pnpm build
```

- [ ] **Step 4: Browser check — taps**

With `pnpm dev` and `ttuHostDebug = '1'`, open a Japanese EPUB with furigana (ask the user for one if none is at hand). Tap (click) in turn:
1. a plain kanji mid-paragraph → `tap` with the full paragraph `text` and `offset` pointing at that kanji (`text[offset]` in the logged object equals the clicked character);
2. the right half of a character → same character, not the next one;
3. a ruby base character → `text` contains no furigana, `text[offset]` is the base character;
4. the furigana itself → a `tap` whose `offset` points at a base character of that ruby or a dismiss; never furigana text in `text`;
5. the page margin → `{text: '', offset: -1}`.

- [ ] **Step 5: Browser check — commands**

After tapping a word, run in the console:
`await ttuHost.highlight({start: <offset>, length: 3})` → three base characters selected, spanning ruby boundaries correctly; `await ttuHost.getSelectedText({})` → those three characters without furigana; `await ttuHost.clearSelection({})` → selection gone.

- [ ] **Step 6: Browser check — Review Focus items 1 and 2**

Tap a ruby word, `highlight` across it (length covering the whole ruby base plus one following character): selection must not include `rt` text (check `getSelectedText`). Then with the selection still present, click another word: expect a dismiss (`offset: -1`), not a new lookup.

- [ ] **Step 7: Commit**

```bash
cd /home/blastrock/work/ebook-reader-lite && jj commit apps/web/src/lib/host -m "feat(host): tap-to-lookup, highlight and selection commands

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 4: FORK — theme reporting

**Files:**
- Create: `apps/web/src/lib/host/host-theme.ts`
- Modify: `apps/web/src/lib/host/host-init.ts` (call `initHostTheme()`)

**Interfaces:**
- Consumes: `sendToHost` (Task 1); upstream `theme$`, `customThemes$` (`$lib/data/store`), `availableThemes` (`$lib/data/theme-option`).
- Produces (wire): event `{type: 'theme', backgroundColor: Rgba, fontColor: Rgba}` with `Rgba = {r: number, g: number, b: number, a: number}` (0–255 for r/g/b, 0–1 for a), sent on init and on every theme change.

- [ ] **Step 1: Create `host-theme.ts`**

```ts
/**
 * @license BSD-3-Clause
 * Copyright (c) 2026, ッツ Reader Authors
 * All rights reserved.
 */

import { combineLatest } from 'rxjs';
import { customThemes$, theme$ } from '$lib/data/store';
import { availableThemes } from '$lib/data/theme-option';
import { sendToHost } from '$lib/host/host-bridge';

function toRgba(color: string) {
  const probe = document.createElement('div');
  probe.style.color = color;
  document.body.append(probe);
  const computed = getComputedStyle(probe).color;
  probe.remove();

  const [r = 0, g = 0, b = 0, a = 1] = (computed.match(/[\d.]+/g) ?? []).map(Number);

  return { r, g, b, a };
}

export function initHostTheme() {
  combineLatest([theme$, customThemes$]).subscribe(([theme, customThemes]) => {
    const option =
      availableThemes.get(theme) || customThemes[theme] || availableThemes.get('light-theme');

    if (!option) {
      return;
    }

    sendToHost('theme', {
      backgroundColor: toRgba(option.backgroundColor),
      fontColor: toRgba(option.fontColor)
    });
  });
}
```

(The lookup expression mirrors `themeOption$` in `routes/b/+page.svelte:390`.)

- [ ] **Step 2: Register it in `host-init.ts`**

Add `import { initHostTheme } from '$lib/host/host-theme';` and call `initHostTheme();` after `initHostLookup();`.

- [ ] **Step 3: Checks**

```bash
cd /home/blastrock/work/ebook-reader-lite/apps/web && pnpm check && pnpm eslint src/lib/host && pnpm build
```

Browser (`ttuHostDebug = '1'`): on load a `theme` event follows `ready`; changing the theme in ttu's settings logs a new `theme` event with the new background (e.g. dark theme → r/g/b near 18). Create a custom theme in settings and select it: its colours are reported.

- [ ] **Step 4: Commit**

```bash
cd /home/blastrock/work/ebook-reader-lite && jj commit apps/web/src/lib/host -m "feat(host): report theme colours to the host

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 5: FORK — Exit header entry

**Files:**
- Modify: `apps/web/src/lib/components/merged-header-icon/merged-entries.ts` (one import name, one entry)
- Modify: `apps/web/src/lib/components/book-reader/book-reader-header.svelte` (one import, one `push`, one `else if`)

**Interfaces:**
- Consumes: `isHost`, `sendToHost` (Task 1).
- Produces (wire): event `{type: 'exit'}`.

- [ ] **Step 1: Add the entry**

In `merged-entries.ts`, add `faDoorOpen` to the `@fortawesome/free-solid-svg-icons` import list (keep it alphabetical: after `faCog`), and add to `mergeEntries`, after `SETTINGS`:

```ts
  EXIT: { routeId: '', label: 'Exit', icon: faDoorOpen, title: 'Exit the reader' },
```

- [ ] **Step 2: Show and handle it in the reader header**

In `book-reader-header.svelte`:
- add `import { isHost, sendToHost } from '$lib/host/host-bridge';` with the other `$lib` imports;
- in the `$: { const items = []; … }` block, replace
  `items.push(mergeEntries.SETTINGS, mergeEntries.MANAGE);`
  with
  ```ts
    items.push(mergeEntries.SETTINGS, mergeEntries.MANAGE);

    if (isHost()) {
      items.push(mergeEntries.EXIT);
    }
  ```
- in the `on:action` handler of `<MergedHeaderIcon …>`, add a final branch after the `MANAGE` one:
  ```ts
        } else if (detail === mergeEntries.EXIT.label) {
          sendToHost('exit');
  ```

- [ ] **Step 3: Checks**

```bash
cd /home/blastrock/work/ebook-reader-lite/apps/web && pnpm check && pnpm eslint src/lib/components src/lib/host && pnpm build
```

Browser: without `ttuHostDebug`, the reader header has no Exit entry. With it, Exit appears both in the narrow popover (window < 640 px wide) and as a door icon on wide windows, and clicking it logs `{type: 'exit'}`.

- [ ] **Step 4: Commit**

```bash
cd /home/blastrock/work/ebook-reader-lite && jj commit apps/web/src/lib/components -m "feat(host): add Exit header entry in host mode

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 6: FORK — release workflow

**Files:**
- Create: `.github/workflows/release.yml`

**Interfaces:**
- Produces: on a pushed tag `vX.Y.Z`, a GitHub Release named after the tag with asset `ebook-reader-lite-vX.Y.Z.zip` whose root is the content of `apps/web/build/` (i.e. `index.html` at the zip root).

- [ ] **Step 1: Create the workflow**

Action and tool versions are copied from `.github/workflows/ci.yml` (`actions/checkout@v7.0.1`, `pnpm/action-setup@v6.1.0` with pnpm `12.3.4`, `actions/setup-node@v7.0.0` with Node `24.21.0`). Re-check them against `ci.yml` when writing the file and use whatever it has.

```yaml
name: Release
on:
  push:
    tags:
      - 'v[0-9]+.[0-9]+.[0-9]+'
permissions:
  contents: write
jobs:
  release:
    name: Build and release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v7.0.1

      - name: Install pnpm
        uses: pnpm/action-setup@v6.1.0
        with:
          version: 12.3.4
          run_install: false

      - name: Install Node.js
        uses: actions/setup-node@v7.0.0
        with:
          node-version: 24.21.0
          cache: pnpm

      - name: Install dependencies
        run: pnpm install --frozen-lockfile

      - name: Postinstall steps
        run: pnpm svelte-kit sync
        working-directory: apps/web

      - name: Build
        run: pnpm build
        working-directory: apps/web

      - name: Package
        run: |
          cd apps/web/build
          zip -r "$GITHUB_WORKSPACE/ebook-reader-lite-${GITHUB_REF_NAME}.zip" .

      - name: Publish release
        env:
          GH_TOKEN: ${{ github.token }}
        run: >-
          gh release create "$GITHUB_REF_NAME"
          "ebook-reader-lite-${GITHUB_REF_NAME}.zip"
          --title "$GITHUB_REF_NAME"
          --notes "ebook-reader-lite $GITHUB_REF_NAME"
```

- [ ] **Step 2: Lint the YAML**

```bash
cd /home/blastrock/work/ebook-reader-lite && pnpm prettier --check .github/workflows/release.yml
```

Expected: passes (run `pnpm prettier --write` on the file if not).

- [ ] **Step 3: Commit (no push, no tag yet — that is Task 14)**

```bash
cd /home/blastrock/work/ebook-reader-lite && jj commit .github/workflows/release.yml -m "ci: add release workflow

Builds apps/web on vX.Y.Z tags and attaches the zipped build to a GitHub
release, for the jidoujisho app to download.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 7: APP — fetch script, untracked assets

**Files:**
- Create: `tool/fetch_ttu.sh` (executable)
- Create: `tool/ttu.lock`
- Modify: `.gitignore` (add `/assets/ttu-ebook-reader/`)
- Delete from version control: `assets/ttu-ebook-reader/` (the old 2023 build)
- Modify: `pubspec.yaml` (`flutter: assets:` ttu entries)
- Modify: `CLAUDE.md` (Commands section)

**Interfaces:**
- Produces: `tool/fetch_ttu.sh [--local <fork-path>] [--update <tag>]`; `assets/ttu-ebook-reader/` populated with the fork's build. Later tasks run `tool/fetch_ttu.sh --local ../ebook-reader-lite` after every FORK change.
- `tool/ttu.lock` format (shell-sourceable, three lines):
  ```
  TTU_TAG=<tag or empty>
  TTU_URL=<release asset url or empty>
  TTU_SHA256=<sha256 or empty>
  ```

- [ ] **Step 1: Create `tool/ttu.lock`** (empty pin until the first release in Task 14)

```
TTU_TAG=
TTU_URL=
TTU_SHA256=
```

- [ ] **Step 2: Create `tool/fetch_ttu.sh`**

```bash
#!/usr/bin/env bash
# Populates assets/ttu-ebook-reader/ with the ebook-reader-lite build.
#
#   tool/fetch_ttu.sh                  download the release pinned in tool/ttu.lock
#   tool/fetch_ttu.sh --local <path>   build a local ebook-reader-lite checkout instead
#   tool/fetch_ttu.sh --update <tag>   download release <tag> and re-pin tool/ttu.lock
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
lock="$root/tool/ttu.lock"
dest="$root/assets/ttu-ebook-reader"
repo="blastrock/ebook-reader-lite"

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

install_build() {
  local src="$1"
  rm -rf "$dest"
  mkdir -p "$dest"
  cp -R "$src/." "$dest/"
}

check_pubspec() {
  local missing=0
  while IFS= read -r dir; do
    local entry="assets/ttu-ebook-reader/${dir#./}"
    entry="${entry%/.}/"
    entry="${entry//\/\//\/}"
    if ! grep -qxF "    - $entry" "$root/pubspec.yaml"; then
      echo "pubspec.yaml does not list asset directory: $entry" >&2
      missing=1
    fi
  done < <(cd "$dest" && find . -type d | sort)
  if [[ $missing -ne 0 ]]; then
    echo "Add the directories above under flutter: assets: in pubspec.yaml." >&2
    exit 1
  fi
}

download() {
  local url="$1" sha="$2"
  curl -fsSL "$url" -o "$work/build.zip"
  if [[ -n "$sha" ]]; then
    echo "$sha  $work/build.zip" | sha256sum -c - >/dev/null
  fi
  mkdir -p "$work/build"
  unzip -q "$work/build.zip" -d "$work/build"
  install_build "$work/build"
}

case "${1:-}" in
  --local)
    fork="${2:?usage: tool/fetch_ttu.sh --local <path>}"
    (cd "$fork/apps/web" && pnpm svelte-kit sync && pnpm build)
    install_build "$fork/apps/web/build"
    ;;
  --update)
    tag="${2:?usage: tool/fetch_ttu.sh --update <tag>}"
    url="https://github.com/$repo/releases/download/$tag/ebook-reader-lite-$tag.zip"
    download "$url" ""
    sha="$(sha256sum "$work/build.zip" | cut -d' ' -f1)"
    printf 'TTU_TAG=%s\nTTU_URL=%s\nTTU_SHA256=%s\n' "$tag" "$url" "$sha" > "$lock"
    echo "Pinned $tag ($sha)."
    ;;
  "")
    # shellcheck source=/dev/null
    source "$lock"
    if [[ -z "$TTU_URL" ]]; then
      echo "tool/ttu.lock has no release pinned; use --local <path>." >&2
      exit 1
    fi
    download "$TTU_URL" "$TTU_SHA256"
    ;;
  *)
    echo "unknown argument: $1" >&2
    exit 2
    ;;
esac

check_pubspec
echo "Installed ttu build into assets/ttu-ebook-reader/."
```

Run `chmod +x tool/fetch_ttu.sh`.

- [ ] **Step 3: Untrack the old build and ignore the directory**

Append to `.gitignore`:

```
# ebook-reader-lite build, populated by tool/fetch_ttu.sh
/assets/ttu-ebook-reader/
```

Then remove the old build from the working copy (jj will record the deletion; the directory is now ignored, so the next fetch does not re-add it):

```bash
cd /home/blastrock/work/jidoujisho && rm -rf assets/ttu-ebook-reader && jj status | head
```

Expected: `jj status` lists the old files as deleted (`D assets/ttu-ebook-reader/...`).

- [ ] **Step 4: Fetch the local build**

```bash
cd /home/blastrock/work/jidoujisho && tool/fetch_ttu.sh --local ../ebook-reader-lite
```

Expected: it builds, installs, then fails in `check_pubspec` listing the new directories (the old list in `pubspec.yaml` is for the 2023 layout).

- [ ] **Step 5: Rewrite the pubspec asset list**

In `pubspec.yaml`, replace every `assets/ttu-ebook-reader/...` line under `flutter: assets:` with exactly the directories printed by `cd assets/ttu-ebook-reader && find . -type d | sort`, each as `    - assets/ttu-ebook-reader/<dir>/` (`.` becomes `assets/ttu-ebook-reader/`). Put this comment line directly above them:

```yaml
    # ebook-reader-lite build (tool/fetch_ttu.sh). Flutter asset directories
    # are not recursive: every directory of the build must be listed, and
    # fetch_ttu.sh fails if one is missing.
```

Re-run `tool/fetch_ttu.sh --local ../ebook-reader-lite`. Expected: `Installed ttu build into assets/ttu-ebook-reader/.`

- [ ] **Step 6: Document the step in `CLAUDE.md`**

In the `## Commands` code block, add as the first line:

```sh
tool/fetch_ttu.sh                                          # ebook-reader-lite build → assets/ttu-ebook-reader/ (--local <path> to build a checkout)
```

and in the "Reader internals" bullet for ttu, replace "is a 57 MB prebuilt SvelteKit app," with "is the build of the `ebook-reader-lite` fork (github.com/blastrock/ebook-reader-lite), not committed: `tool/fetch_ttu.sh` downloads the release pinned in `tool/ttu.lock`. It is".

- [ ] **Step 7: Verify the app still builds and runs as before**

```bash
cd /home/blastrock/work/jidoujisho && flutter analyze 2>&1 | tail -3 && flutter build apk --debug
```

Expected: analyzer unchanged; build succeeds. Ask the user to verify on device: the Novels tab and ttu's manager open, a book can be imported and opened with the new ttu. (Lookup still works through the old injected JS, which still matches upstream's DOM: `.book-content` and the header popover.) If the old injection does not work against the new ttu, note it and continue; Tasks 9–11 replace it.

- [ ] **Step 8: Commit**

```bash
cd /home/blastrock/work/jidoujisho && jj commit .gitignore tool pubspec.yaml CLAUDE.md assets/ttu-ebook-reader -m "TTU: fetch the ebook-reader-lite build instead of committing it

The bundled 2023 build was a patched ttu whose source is not available.
The reader now comes from the ebook-reader-lite fork: tool/fetch_ttu.sh
downloads the release pinned in tool/ttu.lock, or builds a local checkout.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 8: APP — `TtuBridge`

**Files:**
- Create: `lib/src/media/sources/ttu_bridge.dart`
- Modify: `lib/media.dart` (export it)

**Interfaces:**
- Consumes: wire protocol from Tasks 1–5.
- Produces (Dart, used by Tasks 9–11):
  ```dart
  class TtuBridge {
    TtuBridge({
      required InAppWebViewController controller,
      void Function(TtuReadyEvent)? onReady,
      void Function(TtuTapEvent)? onTap,
      void Function(TtuThemeEvent)? onTheme,
      void Function()? onExit,
    });
    static const int protocolVersion = 1;
    Future<void> nextPage();
    Future<void> prevPage();
    Future<void> highlight({required int start, required int length});
    Future<void> clearSelection();
    Future<String> getSelectedText();
  }
  class TtuReadyEvent { final int protocolVersion; final String route; bool get isCompatible; }
  class TtuTapEvent { final String text; final int offset; final int x; final int y; bool get isDismiss; }
  class TtuThemeEvent { final Color backgroundColor; final Color fontColor; }
  class TtuBridgeException implements Exception { final String command; final String message; }
  ```

- [ ] **Step 1: Create `ttu_bridge.dart`**

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Sent once per page load when the ebook-reader-lite host bridge is up.
class TtuReadyEvent {
  /// Create the event from its wire form.
  TtuReadyEvent.fromJson(Map<String, dynamic> json)
      : protocolVersion = json['protocolVersion'] as int,
        route = json['route'] as String? ?? '';

  /// Protocol version spoken by the web side.
  final int protocolVersion;

  /// Path of the page that loaded.
  final String route;

  /// Whether the web side speaks the same protocol as [TtuBridge].
  bool get isCompatible => protocolVersion == TtuBridge.protocolVersion;
}

/// A tap on book content.
class TtuTapEvent {
  /// Create the event from its wire form.
  TtuTapEvent.fromJson(Map<String, dynamic> json)
      : text = json['text'] as String? ?? '',
        offset = json['offset'] as int? ?? -1,
        x = (json['x'] as num).round(),
        y = (json['y'] as num).round();

  /// The tapped paragraph with furigana removed.
  final String text;

  /// UTF-16 index of the tapped character in [text], or -1.
  final int offset;

  /// Tap position in logical pixels from the left of the WebView.
  final int x;

  /// Tap position in logical pixels from the top of the WebView.
  final int y;

  /// Whether the tap hit no character and should close the popup.
  bool get isDismiss => offset < 0 || text.isEmpty;
}

/// The reader's current theme colours.
class TtuThemeEvent {
  /// Create the event from its wire form.
  TtuThemeEvent.fromJson(Map<String, dynamic> json)
      : backgroundColor = _colour(json['backgroundColor']),
        fontColor = _colour(json['fontColor']);

  /// Page background colour.
  final Color backgroundColor;

  /// Text colour.
  final Color fontColor;

  static Color _colour(dynamic json) {
    Map<String, dynamic> rgba = Map<String, dynamic>.from(json as Map);
    return Color.fromRGBO(
      (rgba['r'] as num).round(),
      (rgba['g'] as num).round(),
      (rgba['b'] as num).round(),
      (rgba['a'] as num? ?? 1).toDouble(),
    );
  }
}

/// A bridge command failed on the web side or timed out.
class TtuBridgeException implements Exception {
  /// Create the exception.
  TtuBridgeException(this.command, this.message);

  /// The command that failed.
  final String command;

  /// The JavaScript error or a description of the failure.
  final String message;

  @override
  String toString() => 'TtuBridgeException($command): $message';
}

/// Typed access to the host bridge of ebook-reader-lite running in a WebView.
///
/// Events arrive through the `ttuHost` JavaScript handler; commands are
/// methods on `window.ttuHost`, called with [InAppWebViewController.callAsyncJavaScript].
class TtuBridge {
  /// Attach a bridge to [controller]. Call from `onWebViewCreated`, before
  /// the page loads, so that no event is missed.
  TtuBridge({
    required InAppWebViewController controller,
    this.onReady,
    this.onTap,
    this.onTheme,
    this.onExit,
  }) : _controller = controller {
    _controller.addJavaScriptHandler(
      handlerName: 'ttuHost',
      callback: _dispatch,
    );
  }

  /// Must equal `PROTOCOL_VERSION` in ebook-reader-lite's `host-bridge.ts`.
  static const int protocolVersion = 1;

  /// Timeout applied to every command.
  static const Duration commandTimeout = Duration(seconds: 10);

  final InAppWebViewController _controller;

  /// Called when a page with the bridge has loaded.
  final void Function(TtuReadyEvent)? onReady;

  /// Called when book content is tapped.
  final void Function(TtuTapEvent)? onTap;

  /// Called with the current theme on load and on every theme change.
  final void Function(TtuThemeEvent)? onTheme;

  /// Called when the reader's Exit entry is chosen.
  final void Function()? onExit;

  void _dispatch(List<dynamic> arguments) {
    if (arguments.isEmpty || arguments.first is! Map) {
      return;
    }

    Map<String, dynamic> message =
        Map<String, dynamic>.from(arguments.first as Map);

    switch (message['type']) {
      case 'ready':
        onReady?.call(TtuReadyEvent.fromJson(message));
        break;
      case 'tap':
        onTap?.call(TtuTapEvent.fromJson(message));
        break;
      case 'theme':
        onTheme?.call(TtuThemeEvent.fromJson(message));
        break;
      case 'exit':
        onExit?.call();
        break;
      default:
        debugPrint('ttuHost: unknown event ${message['type']}');
    }
  }

  Future<dynamic> _call(
    String command, [
    Map<String, dynamic> args = const {},
  ]) async {
    CallAsyncJavaScriptResult? result;
    try {
      result = await _controller.callAsyncJavaScript(
        functionBody: 'return await window.ttuHost[command](args);',
        arguments: {'command': command, 'args': args},
      ).timeout(commandTimeout);
    } on TimeoutException {
      throw TtuBridgeException(command, 'timed out');
    }

    if (result == null) {
      throw TtuBridgeException(command, 'no result');
    }
    if (result.error != null) {
      throw TtuBridgeException(command, result.error!);
    }

    return result.value;
  }

  /// Turn to the next page (paginated) or scroll one screen (continuous).
  Future<void> nextPage() => _call('nextPage');

  /// Turn to the previous page.
  Future<void> prevPage() => _call('prevPage');

  /// Select [length] characters from [start] in the last tapped paragraph.
  Future<void> highlight({required int start, required int length}) =>
      _call('highlight', {'start': start, 'length': length});

  /// Remove any selection in the reader.
  Future<void> clearSelection() => _call('clearSelection');

  /// The current selection with furigana removed, trimmed.
  Future<String> getSelectedText() async =>
      (await _call('getSelectedText') as String?) ?? '';
}
```

- [ ] **Step 2: Export it**

In `lib/media.dart`, after `export 'src/media/sources/reader_ttu_source.dart';`, add:

```dart
export 'src/media/sources/ttu_bridge.dart';
```

- [ ] **Step 3: Analyse**

```bash
cd /home/blastrock/work/jidoujisho && flutter analyze lib/src/media/sources/ttu_bridge.dart lib/media.dart
```

Expected: `No issues found!` (fix any lint, e.g. ordering, before committing).

- [ ] **Step 4: Commit**

```bash
cd /home/blastrock/work/jidoujisho && jj commit lib/src/media/sources/ttu_bridge.dart lib/media.dart -m "TTU: add a typed bridge to ebook-reader-lite

Not used yet; the reader page moves onto it in the following commits.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 9: APP — reader page: bridge, exit, page turns; drop the speed setting

**Files:**
- Modify: `lib/src/pages/implementations/reader_ttu_source_page.dart`
- Modify: `lib/src/media/sources/reader_ttu_source.dart` (remove `defaultScrollingSpeed`, `volumePageTurningSpeed`, `setVolumePageTurningSpeed`)
- Modify: `lib/src/pages/implementations/settings_page.dart` (remove `_speedController` and the speed number field)
- Modify: `lib/i18n/strings.i18n.json` (remove `volume_button_turning_speed`), then regenerate `lib/i18n/strings.g.dart`

**Interfaces:**
- Consumes: `TtuBridge`, `TtuReadyEvent` (Task 8).
- Produces: `_ReaderTtuSourcePageState._bridge` (`TtuBridge?`, set in `onWebViewCreated`), used by Tasks 10–11.

- [ ] **Step 1: Create the bridge in the page**

In `_ReaderTtuSourcePageState`:
- add a field `TtuBridge? _bridge;` next to `_controller`;
- in `onWebViewCreated`, after `_controllerInitialised = true;`, add:
  ```dart
          _bridge = TtuBridge(
            controller: controller,
            onReady: _onBridgeReady,
            onExit: _onBridgeExit,
          );
  ```
- add the two handlers:
  ```dart
  void _onBridgeReady(TtuReadyEvent event) {
    if (event.isCompatible) {
      return;
    }

    debugPrint(
      'ttuHost: protocol ${event.protocolVersion}, app expects '
      '${TtuBridge.protocolVersion}. Run tool/fetch_ttu.sh.',
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.ttu_bridge_mismatch)),
      );
    }
  }

  /// Exit goes through [PopScope], so the exit confirmation and
  /// [MediaSource.onSourceExit] run exactly as for the back button.
  void _onBridgeExit() {
    if (mounted) {
      Navigator.maybePop(context);
    }
  }
  ```
- add to `lib/i18n/strings.i18n.json`, next to `ttu_no_books_added`:
  `"ttu_bridge_mismatch": "The reader build does not match this app version",`

- [ ] **Step 2: Remove the injected Exit entry**

Delete `_exitMenuItemJs`, `_injectExitMenuItem`, both `await _injectExitMenuItem(controller);` calls (in `onLoadStop` and `onTitleChanged`), and the `case 'exit':` branch of `onConsoleMessage`.

- [ ] **Step 3: Volume keys through the bridge**

In `onKeyEvent`, replace the two volume branches with:

```dart
            if (isPress && event.logicalKey == LogicalKeyboardKey.audioVolumeUp) {
              _turnPage(forward: !mediaSource.volumePageTurningInverted);
              return KeyEventResult.handled;
            }
            if (isPress &&
                event.logicalKey == LogicalKeyboardKey.audioVolumeDown) {
              _turnPage(forward: mediaSource.volumePageTurningInverted);
              return KeyEventResult.handled;
            }
```

and add:

```dart
  /// Volume up is "next page" unless inverted, as with the old wheel-event
  /// implementation (a positive wheel delta flipped forward).
  Future<void> _turnPage({required bool forward}) async {
    TtuBridge? bridge = _bridge;
    if (bridge == null) {
      return;
    }

    await unselectWebViewTextSelection(_controller);
    if (forward) {
      await bridge.nextPage();
    } else {
      await bridge.prevPage();
    }
  }
```

Delete the `leftArrowSimulateJs` and `rightArrowSimulateJs` getters.

- [ ] **Step 4: Remove the speed setting**

- `reader_ttu_source.dart`: delete `defaultScrollingSpeed`, `volumePageTurningSpeed` and `setVolumePageTurningSpeed` (with their doc comments).
- `settings_page.dart`: delete the `_speedController` field, its initialisation in `initState`, its `dispose()` call, and the whole `buildNumberField(controller: _speedController, …)` block in the ttu section.
- `strings.i18n.json`: delete the `volume_button_turning_speed` entry.
- Regenerate: `dart run slang`.

- [ ] **Step 5: Analyse, build, and verify on device**

```bash
cd /home/blastrock/work/jidoujisho && dart run slang && flutter analyze 2>&1 | tail -3 && flutter build apk --debug
```

Expected: 0 errors, 0 warnings, info count ≤ baseline. Ask the user to verify on device:
1. Open a book; header menu shows **Exit**; Exit shows the usual exit confirmation and returns to the Novels tab.
2. Volume up → next page, volume down → previous page, in paginated vertical, paginated horizontal and continuous modes; with "invert volume buttons" on, reversed.
3. Go reader → manager → another book via ttu's own UI (no reload), volume keys and Exit still work there.
4. No mismatch snackbar appears.
5. The settings page no longer has "Continuous scrolling speed".

- [ ] **Step 6: Commit**

```bash
cd /home/blastrock/work/jidoujisho && jj commit lib/src/pages/implementations/reader_ttu_source_page.dart lib/src/pages/implementations/settings_page.dart lib/src/media/sources/reader_ttu_source.dart lib/i18n -m "TTU: exit and turn pages through the bridge

Volume keys call ttu's own page manager instead of faking wheel events,
which makes the continuous scrolling speed setting meaningless; it is
removed. The Exit entry is now part of ttu's header in host mode instead
of being injected.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 10: APP — lookup, highlight, context menu through the bridge

**Files:**
- Modify: `lib/src/pages/implementations/reader_ttu_source_page.dart`

**Interfaces:**
- Consumes: `TtuBridge.highlight`, `clearSelection`, `getSelectedText`, `TtuTapEvent` (Task 8); `_bridge` (Task 9); `JapaneseLanguage.instance.getGuessHighlightLength`, `getFinalHighlightLength`, `getSentenceFromParagraph` (unchanged).

- [ ] **Step 1: Wire the tap event**

In the `TtuBridge(...)` constructor call in `onWebViewCreated`, add `onTap: _onTap,`.

- [ ] **Step 2: Move the lookup logic into `_onTap`**

Add this method; it is the body of the old `case 'lookup':` branch, rewritten for absolute paragraph offsets:

```dart
  Future<void> _onTap(TtuTapEvent event) async {
    FocusScope.of(context).unfocus();
    _focusNode.requestFocus();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (event.isDismiss) {
      clearDictionaryResult();
      mediaSource.clearCurrentSentence();
      return;
    }

    late JidoujishoPopupPosition position;
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      position = event.y < MediaQuery.of(context).size.height / 2
          ? JidoujishoPopupPosition.bottomHalf
          : JidoujishoPopupPosition.topHalf;
    } else {
      position = event.x < MediaQuery.of(context).size.width / 2
          ? JidoujishoPopupPosition.rightHalf
          : JidoujishoPopupPosition.leftHalf;
    }

    String text = event.text;
    int index = event.offset;

    try {
      /// If we cut off at a lone surrogate, offset the index back by 1. The
      /// selection meant to select the index before.
      RegExp loneSurrogate = RegExp(
        '[\uD800-\uDBFF](?![\uDC00-\uDFFF])|(?:[^\uD800-\uDBFF]|^)[\uDC00-\uDFFF]',
      );
      if (index != 0 && text.substring(index).startsWith(loneSurrogate)) {
        index = index - 1;
      }

      String searchTerm = text.substring(index);
      int whitespaceOffset = searchTerm.length - searchTerm.trimLeft().length;
      int start = index + whitespaceOffset;

      int length = JapaneseLanguage.instance.getGuessHighlightLength(
        searchTerm: searchTerm,
      );

      if (mediaSource.highlightOnTap) {
        await _highlight(start: start, length: length);
      }

      await searchDictionaryResult(
        searchTerm: searchTerm,
        position: position,
      );

      length = JapaneseLanguage.instance.getFinalHighlightLength(
        result: currentResult,
      );

      if (mediaSource.highlightOnTap) {
        await _highlight(start: start, length: length);

        if (!dictionaryPopupShown) {
          await unselectWebViewTextSelection(_controller);
        }
      }

      JidoujishoTextSelection selection =
          JapaneseLanguage.instance.getSentenceFromParagraph(
        paragraph: text,
        index: index,
        startOffset: start,
        endOffset: start + length,
      );

      mediaSource.setCurrentSentence(selection: selection);
    } catch (e) {
      clearDictionaryResult();
    }
  }

  /// Select text without the native selection menu flashing up.
  Future<void> _highlight({required int start, required int length}) async {
    TtuBridge? bridge = _bridge;
    if (bridge == null) {
      return;
    }

    await _controller.setContextMenu(emptyContextMenu);
    await bridge.highlight(start: start, length: length);
    await _controller.setContextMenu(contextMenu);
  }
```

Note one behaviour change from the old code: `searchDictionaryResult` is now awaited instead of chained with `.then`. If `flutter analyze` or the device check shows the popup appearing later than before, revert to the `.then` form; the logic inside is the same.

- [ ] **Step 3: Selection through the bridge**

Replace the body of `unselectWebViewTextSelection` with:

```dart
  Future<void> unselectWebViewTextSelection(
      InAppWebViewController webViewController) async {
    await _bridge?.clearSelection();
  }
```

and the body of `getSelectedText` with:

```dart
  Future<String> getSelectedText() async {
    return await _bridge?.getSelectedText() ?? '';
  }
```

In `creatorMenuAction`, the `.replaceAll('\\n', '\n')` on the result is no longer needed; replace
`String text = (await getSelectedText()).replaceAll('\\n', '\n');` with `String text = await getSelectedText();`.

- [ ] **Step 4: Delete the old lookup code**

Delete: `javascriptToExecute`, `selectTextOnwards`, `sanitizeWebViewTextSelection`, `getWebViewTextSelection`, the two `await controller.evaluateJavascript(source: javascriptToExecute);` calls, the whole `case 'lookup':` branch, and then `onConsoleMessage`'s debounce (`lastMessageTime`, `consoleMessageDebounce`) and JSON parsing. `onConsoleMessage` becomes:

```dart
  void onConsoleMessage(
    InAppWebViewController controller,
    ConsoleMessage message,
  ) {
    debugPrint('ttu: ${message.message}');
  }
```

Remove imports that become unused (`dart:convert` stays only if still used by download handling — Task 12 removes that).

- [ ] **Step 5: Analyse and build**

```bash
cd /home/blastrock/work/jidoujisho && flutter analyze 2>&1 | tail -3 && tool/fetch_ttu.sh --local ../ebook-reader-lite && flutter build apk --debug
```

- [ ] **Step 6: Verify on device**

Ask the user to check, in vertical and in horizontal writing mode:
1. Tap plain text mid-paragraph: popup shows the word at the tapped character; highlight first shows the guess, then the final matched length.
2. Tap the right half of a character: lookup starts at that character.
3. Tap a ruby base and tap furigana: lookup is on the base text; the highlight never covers furigana.
4. Tap the first and the last character of a paragraph.
5. Tap empty space / margin: popup closes, highlight clears.
6. With a word highlighted and the popup open, tap another word: popup closes (no new lookup); a second tap looks it up.
7. Card creator from the popup: the sentence field holds the right sentence.
8. Long-press to select text: Search, Stash, Copy, Share, Creator each act on the selected text, without furigana.
9. "Highlight on tap" off: lookups work without highlight.

- [ ] **Step 7: Commit**

```bash
cd /home/blastrock/work/jidoujisho && jj commit lib/src/pages/implementations/reader_ttu_source_page.dart -m "TTU: look up and highlight through the bridge

ttu now reports taps with the ruby-stripped paragraph and offset, and
maps highlight ranges back onto its own DOM. The ~350 lines of injected
JavaScript, the console.log channel and its message-dropping debounce
are gone.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 11: APP — dictionary theme from the bridge

**Files:**
- Modify: `lib/src/pages/implementations/reader_ttu_source_page.dart`

**Interfaces:**
- Consumes: `TtuThemeEvent` (Task 8), `appModel.setOverrideDictionaryTheme`, `appModel.setOverrideDictionaryColor`, `dictionaryEntryOpacity` (existing).

- [ ] **Step 1: Replace `setDictionaryColors`**

Delete `setDictionaryColors()` and its two call sites (`onLoadStop`, `onTitleChanged`). Add `onTheme: _onTheme,` to the `TtuBridge(...)` call and:

```dart
  /// Match the dictionary popup to the reader's page colour.
  void _onTheme(TtuThemeEvent event) {
    if (!mediaSource.adaptTtuTheme) {
      return;
    }

    Color background = event.backgroundColor;
    bool isDark = background.computeLuminance() < 0.5;

    appModel.setOverrideDictionaryTheme(
      isDark ? appModel.darkTheme : appModel.theme,
    );
    appModel.setOverrideDictionaryColor(
      Color.fromRGBO(
        (background.r * 255).round(),
        (background.g * 255).round(),
        (background.b * 255).round(),
        dictionaryEntryOpacity,
      ),
    );

    if (mounted) {
      clearDictionaryResult();
      setState(() {});
    }
  }
```

(`Color.r/g/b` are 0–1 doubles in current Flutter; if `flutter analyze` reports them missing, use `background.red/green/blue` instead.)

If `onTitleChanged` is now empty, delete it.

- [ ] **Step 2: Analyse, build, verify on device**

```bash
cd /home/blastrock/work/jidoujisho && flutter analyze 2>&1 | tail -3 && flutter build apk --debug
```

Ask the user: for each built-in ttu theme (light, ecru, water, gray, dark, black) and one custom theme, the popup background matches the page and its text is readable (dark themes use the dark app theme). With "Adapt dictionary popup to theme" off, the popup keeps the app theme.

- [ ] **Step 3: Commit**

```bash
cd /home/blastrock/work/jidoujisho && jj commit lib/src/pages/implementations/reader_ttu_source_page.dart -m "TTU: take the popup colours from the reader's theme event

Replaces the hard-coded table of six theme names, so custom themes now
work too.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 12: APP — remove download, popup-window and other dead code

**Files:**
- Modify: `lib/src/pages/implementations/reader_ttu_source_page.dart`
- Modify: `lib/src/media/sources/reader_ttu_source.dart`
- Modify: `pubspec.yaml` (remove `document_file_save_plus`)
- Modify: `lib/i18n/strings.i18n.json` (remove `file_downloaded`), regenerate

- [ ] **Step 1: Page**

Delete: the `blobToBase64Handler` registration, `createFileFromBase64`, `onDownloadStartRequest`, `_suggestedFilename`, `_mimeType`, `downloadFileJs`, the `onCreateWindow` callback, `onDownloadStartRequest:` and `useOnDownloadStart`, `supportMultipleWindows`, `javaScriptCanOpenWindowsAutomatically` from `InAppWebViewSettings`, and imports left unused (`document_file_save_plus`, `fluttertoast`, `spaces`, `dart:convert` if unused).

- [ ] **Step 2: Source**

In `reader_ttu_source.dart` delete `importBackup`, `getIndexedDBKey` (if still present), `showClearPrompt`, the commented-out `// await exportBackup(appModel: appModel);` line, and the duplicate `get` JS string constant. Keep `getHistoryJs` and `getBooksHistory` (phase 2 removes them).

In `getBooksHistory`, delete the whole `case 'empty':` branch's localStorage writes and keep only `items = [];` (ttu's defaults apply).

- [ ] **Step 3: Dependency and string**

Remove `document_file_save_plus: ^2.0.0` from `pubspec.yaml`, `file_downloaded` from `strings.i18n.json`, then:

```bash
cd /home/blastrock/work/jidoujisho && flutter pub get && dart run slang && flutter analyze 2>&1 | tail -3 && flutter build apk --debug
```

Expected: 0 errors/warnings, info count ≤ baseline.

- [ ] **Step 4: Verify on device**

Ask the user: the Novels tab still lists books; opening, lookup and exit still work. (No new behaviour; this is a regression check.)

- [ ] **Step 5: Commit**

```bash
cd /home/blastrock/work/jidoujisho && jj commit lib pubspec.yaml pubspec.lock -m "TTU: remove download, popup-window and backup leftovers

They only served ttu's export and cloud sign-in flows, which the app no
longer uses.

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

---

## Task 13: APP — hosting: spike, then WebViewAssetLoader (or fallback)

**Files:**
- Create: `lib/src/media/sources/ttu_asset_path_handler.dart` (if the spike succeeds)
- Modify: `lib/media.dart`
- Modify: `lib/src/media/sources/reader_ttu_source.dart`
- Modify: `lib/src/pages/implementations/reader_ttu_source_page.dart`
- Modify: `lib/src/pages/implementations/reader_ttu_source_history_page.dart`
- Modify: `pubspec.yaml`, `docs/TOOLCHAIN.md`, `lib/i18n/strings.i18n.json` (if the spike succeeds)

**Interfaces:**
- Produces: `ReaderTtuSource.url(String path) → WebUri` and `ReaderTtuSource.webViewSettings → InAppWebViewSettings` (base settings both WebViews use). Phase 2 relies on both.

- [ ] **Step 1: Centralise the origin first (both outcomes need it)**

In `reader_ttu_source.dart` add:

```dart
  /// Origin the reader is served from. IndexedDB is tied to it, so it must
  /// never change between releases.
  static const String origin = 'http://localhost:$port';

  /// Absolute URL of a reader page, e.g. `url('b.html?id=3')`.
  WebUri url(String path) => WebUri('$origin/$path');
```

and replace every `'http://localhost:$port/…'` / `'http://localhost:${server.boundPort}/…'` string in `reader_ttu_source.dart` and `reader_ttu_source_page.dart` with `url('…')` (`url('')` for the root, `url('manage.html')`, `url('settings.html')`, `url('b.html?id=$id&?title=$title')`). Analyse, build, quick device check that books open, then commit:

```bash
cd /home/blastrock/work/jidoujisho && jj commit lib -m "TTU: build reader URLs in one place

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

- [ ] **Step 2: Spike (throwaway — do not commit)**

Create `lib/src/media/sources/ttu_asset_path_handler.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:mime/mime.dart';

/// Serves the ebook-reader-lite build from Flutter assets at the root of the
/// WebView asset loader's origin.
class TtuAssetPathHandler extends CustomPathHandler {
  /// Create the handler.
  TtuAssetPathHandler() : super(path: '/');

  static const String _root = 'assets/ttu-ebook-reader';

  @override
  Future<WebResourceResponse?> handle(String path) async {
    String clean = path.split('?').first.split('#').first;
    List<String> candidates = clean.isEmpty
        ? ['index.html']
        : [clean, '$clean.html', '$clean/index.html'];

    for (String candidate in candidates) {
      try {
        ByteData data = await rootBundle.load('$_root/$candidate');
        return WebResourceResponse(
          contentType: lookupMimeType(candidate) ?? 'application/octet-stream',
          data: data.buffer.asUint8List(),
        );
      } catch (_) {
        continue;
      }
    }

    return null;
  }
}
```

Temporarily change `origin` to `'https://appassets.androidplatform.net'`, and in the reader page's and the history headless WebView's `InAppWebViewSettings` add:

```dart
        webViewAssetLoader: WebViewAssetLoader(
          pathHandlers: [TtuAssetPathHandler()],
        ),
```

Build and ask the user to check on device: manager page loads with styles and fonts; a book can be imported and opened; navigating manager → book → settings works (client-side and after a reload via Exit + reopen); the Novels tab lists the imported book (headless WebView); bridge works (lookup, Exit). Also check `adb logcat | grep -i "service worker\|chromium"` for service worker errors.

- [ ] **Step 3: Decide**

- **All checks pass** → go to Step 4.
- **Service worker errors break loading** → in FORK, set `kit: { serviceWorker: { register: false }, … }` in `apps/web/svelte.config.js`, commit `fix(host): do not register the service worker` (it is not used inside the app), rebuild with `tool/fetch_ttu.sh --local ../ebook-reader-lite`, and repeat Step 2's checks.
- **Paths fail in a way the handler cannot fix, or anything else blocks within one more attempt** → revert the spike (`jj restore lib`), keep `local_assets_server`, skip to Step 5 and record the outcome there. Tell the user which check failed.

- [ ] **Step 4: Switch for real (spike succeeded)**

1. Keep `ttu_asset_path_handler.dart`; export it in `lib/media.dart`.
2. `origin` becomes `'https://appassets.androidplatform.net'`; update its doc comment.
3. Add to `ReaderTtuSource`:
   ```dart
   /// Settings shared by every WebView that loads the reader.
   InAppWebViewSettings get webViewSettings => InAppWebViewSettings(
         webViewAssetLoader: WebViewAssetLoader(
           pathHandlers: [TtuAssetPathHandler()],
         ),
       );
   ```
   and use it in the headless history WebView (`initialSettings: webViewSettings`); in the reader page, start from `mediaSource.webViewSettings` and set the page-specific fields on it (`verticalScrollBarEnabled`, scrollbar colours, etc.) before passing it.
4. Delete: `ttuServerProvider`, `serveLocalAssets`, `_lastServeFailed`, `port`, `ttuInternalVersion`, `currentTtuInternalVersion`, `setTtuInternalVersion`, the reader page's `cacheMode` getter and `cacheMode:`/`appCachePath:` settings, `onReceivedServerTrustAuthRequest`, and the server `AsyncValue` wrappers in `buildBody` and in `reader_ttu_source_history_page.dart` (its port-in-use countdown UI, `_tryAgainCountdownNotifier`, `_timer`). The history page builds `ttuBooksProvider` directly.
5. `strings.i18n.json`: remove `server_port_in_use` and `retrying_in`; `dart run slang`.
6. `pubspec.yaml`: remove `local_assets_server`; move `mime: ^2.0.0` from `dependency_overrides` to `dependencies` (alphabetical, after `material_floating_search_bar_2`) with the comment `# lookupMimeType for TtuAssetPathHandler.`, and delete the override and its comment. Update the `local_assets_server` mention in `docs/TOOLCHAIN.md`.
7. `CLAUDE.md` "Reader internals": replace "served over localhost by `local_assets_server`" with "served by a `WebViewAssetLoader` (`TtuAssetPathHandler`) on `https://appassets.androidplatform.net`", and the sentence about the fixed port with "The origin (`ReaderTtuSource.origin`) must stay fixed: IndexedDB is tied to it."
8. `flutter pub get && dart run slang && flutter analyze && flutter build apk --debug`; repeat Step 2's device checks on a fresh install (uninstall first: the origin changed).
9. Commit:
   ```bash
   cd /home/blastrock/work/jidoujisho && jj commit lib pubspec.yaml pubspec.lock docs/TOOLCHAIN.md CLAUDE.md -m "TTU: serve the reader with WebViewAssetLoader

   Drops the localhost server, its port-in-use retry screen and the cache
   versioning hack. The origin changes, which is free: installs are fresh.

   Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
   Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
   ```

- [ ] **Step 5: Record a failed spike (only if Step 3 chose the fallback)**

Add one paragraph under §7 of the spec (`docs/superpowers/specs/2026-10-10-ttu-bridge-and-native-library-design.md`) stating which check failed and that `local_assets_server` stays; commit it as `Spec: record the hosting spike outcome`.

---

## Task 14: Release v3.0.0 and pin it

**Files:**
- Modify: `tool/ttu.lock`
- Modify: `CLAUDE.md` (Reader internals, final wording)

- [ ] **Step 1: Push the fork (confirm first)**

Show the user `jj log -r 'upstream/main..main'`-equivalent for FORK (`cd ../ebook-reader-lite && jj log -r 'main@origin..@-'` or the overlay commits since `upstream`), and ask for confirmation to push. Then:

```bash
cd /home/blastrock/work/ebook-reader-lite && jj bookmark set main -r @- && jj git push --bookmark main
```

Ask the user to disable upstream's `deploy.yml` workflow in the fork's GitHub Actions settings if not done already.

- [ ] **Step 2: Tag and release (confirm first)**

```bash
cd /home/blastrock/work/ebook-reader-lite && git tag v3.0.0 main && git push origin v3.0.0
```

Wait for the Release workflow to finish: `gh run watch -R blastrock/ebook-reader-lite` (or ask the user to check the Actions page). Expected: release `v3.0.0` exists with `ebook-reader-lite-v3.0.0.zip`.

- [ ] **Step 3: Pin it in the app**

```bash
cd /home/blastrock/work/jidoujisho && tool/fetch_ttu.sh --update v3.0.0 && cat tool/ttu.lock && tool/fetch_ttu.sh && flutter build apk --debug
```

Expected: `tool/ttu.lock` has the tag, URL and sha256; the plain fetch verifies the hash and installs.

- [ ] **Step 4: Final device pass**

Ask the user to run the full phase 1 checklist from the spec (§13) on a fresh install of this build.

- [ ] **Step 5: Commit**

```bash
cd /home/blastrock/work/jidoujisho && jj commit tool/ttu.lock CLAUDE.md -m "TTU: pin ebook-reader-lite v3.0.0

Co-Authored-By: Claude Opus 5.5 (1M context) <noreply@anthropic.com>
Claude-Session: https://claude.ai/code/session_01Jqv6j5nH9oLyCCAdxHHUKk"
```

(Only include `CLAUDE.md` if Task 13 or this task changed it after Task 7.)
