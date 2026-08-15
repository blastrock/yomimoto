# receive_intent (vendored)

| | |
|---|---|
| Source | `https://pub.dev/packages/receive_intent` (repo: `https://github.com/dhavalkansara51/receive_intent`) |
| Version | `0.2.7` |
| Vendored | 2026-08-15, during the Flutter 3.13 -> 3.44 migration |

## History

The app previously used `arianneorpilla/receive_intent@3854d07`, a fork of
**0.2.3**. Diffing that fork against upstream showed exactly one real patch —
everything else was commented-out logging churn — so this vendors the newer
upstream 0.2.7 and rebases that one patch onto it, rather than carrying a
four-years-stale fork.

## Local changes

See `local-changes.patch`.

1. **The rebased fork patch:** `setResult` takes a `required String action`,
   and the Android side builds `Intent(action).putExtras(jsonToBundle(json))`
   instead of `jsonToIntent(json)`. Without an action on the result Intent,
   external players (mpv, Jellyfin) do not recognise the playback-position
   result the app sends back. Upstream 0.2.7 already provides `jsonToBundle`,
   so the patch applied cleanly.
2. **Nullability fix in `Utils.kt`:** `PackageInfo.signingInfo` and
   `PackageInfo.signatures` are annotated `@Nullable` in the current SDK, so
   Kotlin rejects the unguarded dereferences in `getApplicationSignature`. Both
   now `?: return emptyList()`, which is what the surrounding `try`/`catch`
   already produced when the dereference threw.

## How to stop vendoring this

Upstream both changes. The nullability fix is uncontroversial; the `action`
parameter would need to be additive (optional) to be accepted.
