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
    local entry="assets/ttu-ebook-reader/"
    if [[ "$dir" != "." ]]; then
      entry="$entry${dir#./}/"
    fi
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
