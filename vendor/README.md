# `vendor/`

Packages we have to patch, kept in-repo as `path:` dependencies.

Vendoring is the fallback, not the default. A package belongs here only when it
needs **source** changes — Dart or native code that no longer compiles, or a
fork carrying features this app actually uses. Problems that are purely about
Gradle configuration (a missing `namespace`, a compileSdk pinned too low, a
plugin buildscript that only lists the dead `jcenter()`) are handled globally by
the shim in `android/settings.gradle`, which leaves those packages hosted and
free to update on their own.

Every directory here carries:

- `UPSTREAM.md` — where the source came from, the exact ref, why we patched it,
  and what would let us stop.
- `local-changes.patch` — `diff -ruN` of pristine upstream against what is
  checked in. This is the whole point of the layout: refreshing a vendored
  package is *fetch the new upstream, apply the patch, resolve conflicts*,
  rather than reconstructing from memory what was changed and why.

## Refreshing one

```sh
# 1. Fetch the new upstream into a scratch directory (see the package's
#    UPSTREAM.md for the source and current ref).
# 2. Replace vendor/<pkg>/ with it, keeping UPSTREAM.md and local-changes.patch.
# 3. Re-apply and regenerate:
cd vendor/<pkg> && patch -p1 < local-changes.patch
#    ...fix any rejects, then regenerate the patch against the new pristine copy
#    and update the ref recorded in UPSTREAM.md.
```

If a refresh applies cleanly with an empty diff, the patch has landed upstream —
delete the directory and go back to the hosted package.

## Why not git dependencies

The pre-migration `pubspec.yaml` pointed ten dependencies at third-party GitHub
forks pinned to 2023 commits. One of those upstreams
(`material_floating_search_bar`) has since been deleted outright, and the rest
are dormant. A `git:` ref is a build dependency on someone else's account
staying alive and their history staying stable; an in-repo copy is not.
