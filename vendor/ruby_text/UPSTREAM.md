# ruby_text (vendored)

| | |
|---|---|
| Source | `https://github.com/arianneorpilla/RubyText` |
| Ref | `cb723f87c9ac575aa735b40016c0ffb3242d921e` |
| Upstream of that fork | `https://github.com/YeungKC/RubyText` (hosted as `ruby_text`) |
| Vendored | 2026-08-15, during the Flutter 3.13 -> 3.44 migration |

## Why the fork, not hosted `ruby_text`

The fork is not a stale mirror — it adds `indexStyle` and `indexAction` to
`RubySpanWidget`/`RubyText` and rebuilds the body as a per-character
`Text.rich`, so each character carries its own `TextStyle` and tap recognizer.
That is what makes tapping a single character inside furigana text open a
dictionary lookup. Hosted `ruby_text` 3.0.3 has none of it, so switching to it
would silently drop character-level lookup in ruby text.

## Local changes

See `local-changes.patch`.

1. `MediaQuery.boldTextOverride(context)` -> `MediaQuery.boldTextOf(context)`.
   The old accessor was removed from Flutter. Hosted `ruby_text` 3.0.3 already
   made this exact change, so it is upstream's fix, not an invention.
2. `environment.sdk` upper bound widened from `<3.0.0` to `<4.0.0`.

## How to stop vendoring this

Upstream the `indexStyle`/`indexAction` feature to YeungKC/RubyText (or to a
maintained continuation), then depend on the hosted release.
