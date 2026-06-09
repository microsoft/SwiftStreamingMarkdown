#!/usr/bin/env bash
set -euo pipefail

fallback="platform=iOS Simulator,name=iPhone 17"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "$fallback"
  exit 0
fi

xcode_major="$(
  (xcodebuild -version 2>/dev/null || true) | awk '
    /^Xcode / {
      split($2, version, ".")
      print version[1]
      exit
    }
  '
)"

simctl_output="$(xcrun simctl list devices available 2>/dev/null || true)"

destination="$(
  printf "%s\n" "$simctl_output" | awk -v preferred_major="$xcode_major" '
    $1 == "--" && $2 == "iOS" {
      split($3, version, ".")
      current_major = version[1]
      next
    }

    /^[[:space:]]+iPhone / {
      split($0, parts, "[()]")
      fallback = parts[2]

      if (preferred_major != "" && current_major == preferred_major) {
        selected = parts[2]
      }
    }

    END {
      if (selected == "") {
        selected = fallback
      }

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
