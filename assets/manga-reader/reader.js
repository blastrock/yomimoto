// The manga reader page. It shows one volume, served at ../volume/
// (volume.mokuro and images/<img_path>), and talks to the app through the
// `mokuroHost` JavaScript handler (events) and `window.mokuroHost`
// (commands). See MokuroBridge in the app. It stores nothing: the app
// says which page to open and is told about every page change.
//
// Outside the app, `?debug=1` logs events to the console instead; commands
// can be called as `await mokuroHost.<command>({...})`.

import {
  createCanvasMeasurer,
  layoutLines,
  lineTransform,
  processLine,
} from './mokuro-layout.js';

/** Must equal MokuroBridge.protocolVersion in the app. */
export const PROTOCOL_VERSION = 3;

const params = new URLSearchParams(location.search);
const debug = params.get('debug') === '1';

document.documentElement.dataset.theme =
  params.get('theme') === 'dark' ? 'dark' : 'light';

// ---------------------------------------------------------------------------
// Talking to the app

let platformReady;

function whenPlatformReady() {
  platformReady ??= new Promise((resolve) => {
    if (window.flutter_inappwebview?._platformReady) {
      resolve();
      return;
    }
    window.addEventListener('flutterInAppWebViewPlatformReady', () => resolve(), {
      once: true,
    });
  });
  return platformReady;
}

async function send(message) {
  if (!window.flutter_inappwebview) {
    if (debug) {
      console.log('mokuroHost', JSON.stringify(message));
    }
    return;
  }
  await whenPlatformReady();
  try {
    await window.flutter_inappwebview.callHandler('mokuroHost', message);
  } catch (error) {
    console.error('mokuroHost: failed to send', message.type, error);
  }
}

// ---------------------------------------------------------------------------
// Text

/** The overlay's font, as reader.css sets it. */
const FONT = "'Noto Sans JP', 'Noto Sans CJK JP', sans-serif";

let measurer;

/** Text advance in em, for mokuro-reader's line layout. */
function measure(text) {
  measurer ??= createCanvasMeasurer(FONT);
  return measurer(text);
}

/** The rendered lines of a block and where each starts in their join. */
function blockText(block) {
  const lines = (block.lines ?? []).map(processLine);
  const starts = [];
  let length = 0;
  for (const line of lines) {
    starts.push(length);
    length += line.length;
  }
  return { lines, starts, text: lines.join('') };
}

// ---------------------------------------------------------------------------
// Volume and spreads

let volume;
let spreads = [];
let current = 0;
// The page the reader is on, which a spread does not tell: the page opened
// or gone to, or the first page of the spread turned to. Rotating the
// device re-pairs the pages around it.
let anchor = 0;
let shownPages = [];
let shownBlock;
// Whether a render is under way, and whether another was asked for
// meanwhile.
let rendering = false;
let renderAgain = false;

function isLandscape() {
  return matchMedia('(orientation: landscape)').matches;
}

/** Portrait: one page per spread. Landscape: the cover alone, then pairs. */
function pairPages(count, landscape) {
  if (!landscape) {
    return Array.from({ length: count }, (_, i) => [i]);
  }
  const result = [[0]];
  for (let i = 1; i < count; i += 2) {
    result.push(i + 1 < count ? [i, i + 1] : [i]);
  }
  return result;
}

function spreadOf(page) {
  const index = spreads.findIndex((spread) => spread.includes(page));
  return index === -1 ? 0 : index;
}

function imageUrl(imgPath) {
  return '../volume/images/' + imgPath.split('/').map(encodeURIComponent).join('/');
}

function buildPage(index) {
  const data = volume.pages[index];
  const page = document.createElement('div');
  page.className = 'page';
  page.style.width = `${data.img_width}px`;
  page.style.height = `${data.img_height}px`;

  const img = document.createElement('img');
  img.alt = '';
  img.decoding = 'async';
  img.addEventListener('error', () => (img.style.visibility = 'hidden'));
  img.src = imageUrl(data.img_path);
  page.append(img);

  for (const block of data.blocks ?? []) {
    page.append(buildBlock(block, index));
  }
  return page;
}

function buildBlock(block, pageIndex) {
  const [x1, y1, x2, y2] = block.box;
  const element = document.createElement('div');
  element.className = 'block';
  element.style.left = `${x1}px`;
  element.style.top = `${y1}px`;
  element.style.width = `${x2 - x1}px`;
  element.style.height = `${y2 - y1}px`;
  element.style.fontSize = `${block.font_size}px`;
  element.style.writingMode = block.vertical ? 'vertical-rl' : 'horizontal-tb';

  const { lines, starts, text } = blockText(block);
  // Each line on its printed line, as mokuro-reader lays it out; null when
  // the block has no usable line quads, which keeps the block-level layout.
  const layouts = block.lines_coords ? layoutLines(block, lines, measure) : null;
  if (layouts) {
    element.classList.add('perLine');
  }

  const paragraph = document.createElement('p');
  lines.forEach((line, i) => {
    const span = document.createElement('span');
    span.className = 'line';
    span.dataset.start = String(starts[i]);
    span.textContent = line;
    if (layouts) {
      placeLine(span, layouts[i]);
    }
    paragraph.append(span);
  });
  element.append(paragraph);

  element.mokuro = { page: pageIndex, text };
  return element;
}

/** Give [span] its size and spacing from [layout]; where it goes is set by
 * positionLines once it is laid out. A hidden line (a duplicate the OCR
 * captured twice) keeps its text, so that offsets in the block's text do not
 * shift, but takes no room. */
function placeLine(span, layout) {
  span.classList.add('positionedLine');
  if (layout.hidden) {
    span.style.display = 'none';
    return;
  }
  span.style.fontSize = `${layout.fontSize}px`;
  if (layout.letterSpacing) {
    span.style.letterSpacing = `${layout.letterSpacing}px`;
  }
  if (layout.wrap) {
    span.classList.add('wrappedLine');
    span.style.width = `${layout.width}px`;
    span.style.height = `${layout.height}px`;
  }
  span.dataset.targetLeft = String(layout.left);
  span.dataset.targetTop = String(layout.top);
  span.dataset.inset = String(layout.inset || 0);
  span.dataset.rotation = String(layout.rotation || 0);
  span.dataset.boxWidth = String(layout.width);
  span.dataset.boxHeight = String(layout.height);
}

/** Move every positioned line of [container] onto its quad: mokuro-reader's
 * positionPerLine. Offsets are layout values in image px, untouched by the
 * page's scale and by a transform already set, so this can run again. All
 * lines are measured before any is moved. */
function positionLines(container) {
  const spans = [...container.querySelectorAll('.positionedLine')].filter(
    (span) => span.style.display !== 'none'
  );
  const naturals = spans.map((span) => ({
    left: span.offsetLeft,
    top: span.offsetTop,
    width: span.offsetWidth,
    height: span.offsetHeight,
  }));
  spans.forEach((span, i) => {
    const data = span.dataset;
    const rotation = Number(data.rotation) || 0;
    const { transform, origin } = lineTransform({
      natural: naturals[i],
      target: { left: Number(data.targetLeft), top: Number(data.targetTop) },
      box: rotation
        ? { width: Number(data.boxWidth), height: Number(data.boxHeight) }
        : undefined,
      inset: Number(data.inset) || 0,
      rotation,
      vertical: span.closest('.block').style.writingMode === 'vertical-rl',
    });
    span.style.transform = transform;
    span.style.transformOrigin = origin;
  });
}

/**
 * Lay the current spread out, fitted to the viewport, off the page. `decoded`
 * settles once its images are decoded, or have failed to.
 */
function buildSpread() {
  const pages = spreads[current];
  const height = Math.max(...pages.map((i) => volume.pages[i].img_height));
  const widths = pages.map(
    (i) => (volume.pages[i].img_width * height) / volume.pages[i].img_height
  );
  const totalWidth = widths.reduce((a, b) => a + b, 0);
  const viewportWidth = document.documentElement.clientWidth;
  const viewportHeight = document.documentElement.clientHeight;
  const fit = Math.min(viewportWidth / totalWidth, viewportHeight / height);

  const slots = pages.map((index) => {
    const data = volume.pages[index];
    const scale = (fit * height) / data.img_height;
    const slot = document.createElement('div');
    slot.className = 'slot';
    slot.style.width = `${data.img_width * scale}px`;
    slot.style.height = `${data.img_height * scale}px`;
    const page = buildPage(index);
    page.style.transform = `scale(${scale})`;
    slot.append(page);
    return slot;
  });
  const decoded = Promise.allSettled(
    slots.map((slot) => slot.querySelector('img').decode())
  );
  return { pages, slots, decoded };
}

/**
 * Show the current spread. A different spread than the one shown waits for
 * the app's reply to `turn` first, so that an e-ink panel can be readied
 * for it: its images are decoded before, so the frame drawn after the reply
 * is the whole spread. A render asked for meanwhile is folded into this one,
 * without a second `turn`.
 */
async function render() {
  if (rendering) {
    renderAgain = true;
    return;
  }
  rendering = true;
  try {
    let turned = false;
    let spread;
    do {
      renderAgain = false;
      spread = buildSpread();
      await spread.decoded;
      const isTurn =
        shownPages.length > 0 && spread.pages.join() !== shownPages.join();
      if (isTurn && !turned && !renderAgain) {
        turned = true;
        await send({ type: 'turn' });
      }
    } while (renderAgain);
    showSlots(spread);
  } finally {
    rendering = false;
  }
}

function showSlots({ pages, slots }) {
  const container = document.getElementById('spread');
  hideBlock();
  container.replaceChildren(...slots);

  requestAnimationFrame(() => positionLines(container));
  document.fonts.ready.then(() => positionLines(container));

  preload(current + 1);
  preload(current - 1);

  if (pages.join() !== shownPages.join()) {
    shownPages = pages;
    // Once painted, so that the app can uncover the screen.
    requestAnimationFrame(() =>
      requestAnimationFrame(() =>
        send({ type: 'page', pages, count: volume.pages.length })
      )
    );
  }
}

function preload(spreadIndex) {
  for (const index of spreads[spreadIndex] ?? []) {
    new Image().src = imageUrl(volume.pages[index].img_path);
  }
}

function showSpread(index, page) {
  const clamped = Math.max(0, Math.min(spreads.length - 1, index));
  anchor = page ?? spreads[clamped][0];
  if (clamped === current && shownPages.length > 0) {
    return;
  }
  current = clamped;
  render();
}

function relayout() {
  spreads = pairPages(volume.pages.length, isLandscape());
  current = spreadOf(anchor);
  render();
}

// ---------------------------------------------------------------------------
// The overlay

function showBlock(block) {
  if (shownBlock === block) {
    return;
  }
  hideBlock();
  shownBlock = block;
  block.classList.add('shown');
}

function hideBlock() {
  shownBlock?.classList.remove('shown');
  shownBlock = undefined;
}

/** The text node and offset of the character under (x, y), if any. */
function caretFromPoint(x, y) {
  const range = document.caretRangeFromPoint(x, y);
  if (!range || range.startContainer.nodeType !== Node.TEXT_NODE) {
    return undefined;
  }
  const node = range.startContainer;
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

/** Where [offset] of a block's joined text is in its line spans. */
function locate(block, offset, isEnd) {
  const spans = [...block.querySelectorAll('.line')];
  for (const span of spans) {
    const start = Number(span.dataset.start);
    const node = span.firstChild;
    const length = node?.data.length ?? 0;
    if (node && (isEnd ? offset <= start + length : offset < start + length)) {
      return { node, offset: offset - start };
    }
  }
  return undefined;
}

// ---------------------------------------------------------------------------
// Input

function screenPoint(event) {
  const viewport = window.visualViewport;
  const scale = viewport?.scale ?? 1;
  return {
    x: Math.round((event.clientX - (viewport?.offsetLeft ?? 0)) * scale),
    y: Math.round((event.clientY - (viewport?.offsetTop ?? 0)) * scale),
  };
}

function onClick(event) {
  const { x, y } = screenPoint(event);
  const block = event.target instanceof Element ? event.target.closest('.block') : null;
  const caret = block ? caretFromPoint(event.clientX, event.clientY) : undefined;
  const line = caret?.node.parentElement?.closest('.line');

  if (block && line && block.contains(line)) {
    const offset = Number(line.dataset.start) + caret.offset;
    if (offset < block.mokuro.text.length) {
      showBlock(block);
      send({
        type: 'tap',
        text: block.mokuro.text,
        offset,
        page: block.mokuro.page,
        x,
        y,
      });
      return;
    }
  }

  if (shownBlock) {
    hideBlock();
    window.getSelection()?.removeAllRanges();
    send({ type: 'tap', text: '', offset: -1, page: -1, x, y });
    return;
  }

  const width = document.documentElement.clientWidth;
  const viewport = window.visualViewport;
  // Zones are on the screen, not the zoomed page.
  const screenX = viewport ? (event.clientX - viewport.offsetLeft) / viewport.width : event.clientX / width;
  if (screenX < 0.25) {
    nextPage();
  } else if (screenX > 0.75) {
    prevPage();
  } else {
    send({ type: 'menu' });
  }
}

let touchStart;

function onTouchStart(event) {
  touchStart =
    event.touches.length === 1
      ? { x: event.touches[0].clientX, y: event.touches[0].clientY }
      : undefined;
}

function onTouchEnd(event) {
  if (!touchStart || event.changedTouches.length !== 1) {
    touchStart = undefined;
    return;
  }
  const dx = event.changedTouches[0].clientX - touchStart.x;
  const dy = event.changedTouches[0].clientY - touchStart.y;
  touchStart = undefined;
  if ((window.visualViewport?.scale ?? 1) >= 1.01) {
    return;
  }
  if (Math.abs(dx) > 50 && Math.abs(dx) > 2 * Math.abs(dy)) {
    // Right to left: the next page is on the left, brought in by a swipe
    // towards the right.
    if (dx > 0) {
      nextPage();
    } else {
      prevPage();
    }
  }
}

function onSelectionChange() {
  const selection = window.getSelection();
  if (!selection || selection.isCollapsed || !selection.anchorNode) {
    return;
  }
  const anchor =
    selection.anchorNode instanceof Element
      ? selection.anchorNode
      : selection.anchorNode.parentElement;
  const block = anchor?.closest('.block');
  if (block) {
    showBlock(block);
  }
}

// ---------------------------------------------------------------------------
// Commands

async function nextPage() {
  // Past the last spread, the app closes the volume: the spread shown, not
  // one a turn is still on its way to.
  const last = spreads.length - 1;
  if (current === last && spreadOf(shownPages[0]) === last) {
    send({ type: 'end' });
    return;
  }
  showSpread(current + 1);
}

async function prevPage() {
  showSpread(current - 1);
}

async function goToPage({ page }) {
  showSpread(spreadOf(Number(page)), Number(page));
}

async function highlight({ start, length }) {
  if (!shownBlock) {
    return;
  }
  const from = locate(shownBlock, Number(start), false);
  const to = locate(shownBlock, Number(start) + Number(length), true);
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

async function clearSelection() {
  window.getSelection()?.removeAllRanges();
}

async function clearOverlay() {
  window.getSelection()?.removeAllRanges();
  hideBlock();
}

async function getSelectedText() {
  return (window.getSelection()?.toString() ?? '').replace(/\n/g, '').trim();
}

window.mokuroHost = {
  nextPage,
  prevPage,
  goToPage,
  highlight,
  clearSelection,
  clearOverlay,
  getSelectedText,
};

// ---------------------------------------------------------------------------
// Start

async function start() {
  const response = await fetch('../volume/volume.mokuro');
  volume = await response.json();
  send({ type: 'ready', protocolVersion: PROTOCOL_VERSION });

  spreads = pairPages(volume.pages.length, isLandscape());
  const page = Math.max(0, Math.min(volume.pages.length - 1, Number(params.get('page')) || 0));
  current = spreadOf(page);
  anchor = page;
  render();

  document.addEventListener('click', onClick);
  document.addEventListener('touchstart', onTouchStart, { passive: true });
  document.addEventListener('touchend', onTouchEnd, { passive: true });
  document.addEventListener('selectionchange', onSelectionChange);
  window.addEventListener('resize', relayout);
}

start().catch((error) => console.error('mokuro reader:', error));
