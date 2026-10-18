#!/usr/bin/env bash
# Builds the signed release APKs. Signing reads the keystore path and alias
# from android/key.properties and the password from KEYSTORE_PASSWORD, which
# this script prompts for unless it is already set. Extra arguments are passed
# to `flutter build apk`.
#
#   tool/build_release.sh
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"

if [[ ! -f "$root/android/key.properties" ]]; then
  echo "android/key.properties is missing; see docs/TOOLCHAIN.md." >&2
  exit 1
fi

if [[ -z "${KEYSTORE_PASSWORD:-}" ]]; then
  read -rsp 'Keystore password: ' KEYSTORE_PASSWORD
  echo
fi
export KEYSTORE_PASSWORD

cd "$root"
flutter build apk --release --split-per-abi "$@"
