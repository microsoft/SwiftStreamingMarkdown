#!/usr/bin/env bash
set -euo pipefail

fallback="platform=iOS Simulator,name=iPhone 17"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "$fallback"
  exit 0
fi

destination="$(
  xcrun simctl list devices available 2>/dev/null | awk '
    /^[[:space:]]+iPhone / {
      split($0, parts, "[()]")
      selected = parts[2]
    }
    END {
      if (selected != "") {
        print "platform=iOS Simulator,id=" selected
      }
    }
  '
)"

if [ -n "$destination" ]; then
  echo "$destination"
else
  echo "$fallback"
fi
