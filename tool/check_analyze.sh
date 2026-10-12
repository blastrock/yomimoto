#!/usr/bin/env bash
# Runs `flutter analyze` and fails on any error or warning, or on more infos
# than the pre-existing baseline. Infos are not fatal to `flutter analyze`
# here (--no-fatal-infos), so the count below is the only gate on them.
#
# The baseline only ever goes down: when you fix infos, lower it.
set -uo pipefail

max_infos=76

out="$(flutter analyze --no-fatal-infos 2>&1)"
rc=$?
infos="$(grep -cE '^ *info • ' <<<"$out")"
bad="$(grep -cE '^ *(error|warning) • ' <<<"$out")"
echo "analyze: rc=$rc infos=$infos (max $max_infos) errors+warnings=$bad"

if [[ $rc -ne 0 || $bad -ne 0 || $infos -gt $max_infos ]]; then
  echo "$out"
  exit 1
fi
