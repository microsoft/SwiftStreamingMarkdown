#!/usr/bin/env bash
#
# PostToolUse hook: run SwiftLint on the file Claude just edited.
#
# Behavior:
# - No-op for non-Swift files or when the file does not exist on disk.
# - No-op when swiftlint is not installed (so the hook never breaks editing
#   for contributors who haven't run `scripts/dev-setup.sh`).
# - Exits 2 with violations on stderr when SwiftLint reports issues, so
#   Claude sees the output and can fix them.
#
set -u

input=$(cat)

file_path=$(printf '%s' "$input" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    print(data.get("tool_input", {}).get("file_path", ""), end="")
except Exception:
    pass
' 2>/dev/null)

[[ -z "$file_path" ]] && exit 0
[[ "$file_path" == *.swift ]] || exit 0
[[ -f "$file_path" ]] || exit 0

cd "${CLAUDE_PROJECT_DIR:-.}" || exit 0

if ! command -v swiftlint >/dev/null 2>&1; then
  exit 0
fi

output=$(swiftlint lint --strict --quiet "$file_path" 2>&1)
status=$?
if [[ $status -ne 0 ]]; then
  printf 'SwiftLint reported violations in %s:\n%s\n' "$file_path" "$output" >&2
  exit 2
fi
exit 0
