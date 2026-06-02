#!/usr/bin/env bash
#
# Dev environment precheck for SwiftStreamingMarkdown.
#
# Required:
#   - Xcode (xcodebuild) at or above the version in .xcode-version
#   - swiftlint
#   - xcodegen
#   - cloc
#   - diff-image (and imagemagick, which it shells out to) — used as the git
#     diff driver for snapshot PNGs.
#
# Run this once after cloning the repo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
XCODE_VERSION_FILE="$REPO_ROOT/.xcode-version"
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
DIFF_IMAGE_REPO_URL="https://github.com/ewanmellor/git-diff-image"

echo "🔍 Running SwiftStreamingMarkdown dev environment precheck..."

missing_items=()

has_cmd() {
  command -v "$1" >/dev/null 2>&1
}

log_pass() {
  echo "✅ $1"
}

prompt_to_run() {
  local prompt="$1"
  shift
  local cmd=("$@")

  local response=""
  if [ -t 0 ]; then
    read -r -p "$prompt [y/N] " response
  fi

  if [[ "$response" =~ ^[Yy]$ ]]; then
    "${cmd[@]}"
    return $?
  fi

  return 1
}

ensure_brew_on_path() {
  if has_cmd brew; then
    return 0
  fi

  if [ -x /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    return 0
  fi

  if [ -x /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv)"
    return 0
  fi

  return 1
}

# Compare two dot-separated version strings.
# Returns 0 if $1 >= $2, 1 otherwise.
version_at_least() {
  local have="$1"
  local want="$2"
  local highest
  highest="$(printf '%s\n%s\n' "$have" "$want" | sort -V | tail -n1)"
  [ "$highest" = "$have" ]
}

# Homebrew (optional helper for installing the required tools below).
if ! ensure_brew_on_path; then
  if prompt_to_run "❌ Homebrew not found. Install Homebrew now?" \
      /bin/bash -c "$(curl -fsSL "$HOMEBREW_INSTALL_URL")"; then
    ensure_brew_on_path || missing_items+=("Homebrew (brew not on PATH after install)")
  else
    echo "⚠️  Homebrew not installed; the precheck will not be able to auto-install required tools."
  fi
fi
if ensure_brew_on_path; then
  log_pass "Homebrew available"
fi

# Xcode + minimum version.
if [ ! -r "$XCODE_VERSION_FILE" ]; then
  echo "❌ Required Xcode version file is missing or unreadable: $XCODE_VERSION_FILE"
  exit 1
fi
MIN_XCODE_VERSION="$(tr -d '[:space:]' < "$XCODE_VERSION_FILE")"
if [ -z "$MIN_XCODE_VERSION" ]; then
  echo "❌ Required Xcode version file is empty: $XCODE_VERSION_FILE"
  exit 1
fi

if ! has_cmd xcodebuild; then
  echo "❌ Xcode (xcodebuild) not found. Install Xcode $MIN_XCODE_VERSION or newer from the App Store"
  echo "   or via 'xcodes install $MIN_XCODE_VERSION', then run 'xcode-select -s /Applications/Xcode.app'."
  missing_items+=("Xcode $MIN_XCODE_VERSION or newer")
else
  XCODE_VERSION="$(xcodebuild -version | awk 'NR==1 {print $2}')"
  if version_at_least "$XCODE_VERSION" "$MIN_XCODE_VERSION"; then
    log_pass "Xcode $XCODE_VERSION (minimum $MIN_XCODE_VERSION)"
  else
    echo "❌ Xcode $XCODE_VERSION is older than the required minimum $MIN_XCODE_VERSION."
    echo "   Install/select a newer Xcode (App Store, or 'xcodes install $MIN_XCODE_VERSION')."
    missing_items+=("Xcode $MIN_XCODE_VERSION or newer (currently $XCODE_VERSION)")
  fi
fi

# SwiftLint (required).
if ! has_cmd swiftlint; then
  if ensure_brew_on_path && prompt_to_run "❌ swiftlint not found. Install via 'brew install swiftlint' now?" \
      brew install swiftlint; then
    :
  fi
fi
if has_cmd swiftlint; then
  log_pass "swiftlint $(swiftlint version 2>/dev/null)"
else
  missing_items+=("swiftlint (brew install swiftlint)")
fi

# XcodeGen (required for the generated sample app project).
if ! has_cmd xcodegen; then
  if ensure_brew_on_path && prompt_to_run "❌ xcodegen not found. Install via 'brew install xcodegen' now?" \
      brew install xcodegen; then
    :
  fi
fi
if has_cmd xcodegen; then
  log_pass "$(xcodegen --version 2>/dev/null)"
else
  missing_items+=("xcodegen (brew install xcodegen)")
fi

# cloc (required for make cloc).
if ! has_cmd cloc; then
  if ensure_brew_on_path && prompt_to_run "❌ cloc not found. Install via 'brew install cloc' now?" \
      brew install cloc; then
    :
  fi
fi
if has_cmd cloc; then
  log_pass "cloc $(cloc --version 2>/dev/null)"
else
  missing_items+=("cloc (brew install cloc)")
fi

# diff-image (required) + imagemagick that backs it.
if ! has_cmd magick && ! has_cmd compare; then
  if ensure_brew_on_path && prompt_to_run "❌ ImageMagick not found (needed by diff-image). Install via 'brew install imagemagick' now?" \
      brew install imagemagick; then
    :
  fi
fi
if has_cmd magick || has_cmd compare; then
  log_pass "ImageMagick available"
else
  missing_items+=("imagemagick (brew install imagemagick)")
fi

if ! has_cmd diff-image; then
  echo "❌ diff-image not found. This tool wires git into a PNG snapshot diff renderer."
  echo "   Install with:"
  echo "     git clone $DIFF_IMAGE_REPO_URL"
  echo "     cd git-diff-image && make install"
  echo "   Then enable it for this clone:"
  echo "     git config diff.image.command diff-image"
  echo "     echo '*.png diff=image' >> .git/info/attributes"
  missing_items+=("diff-image ($DIFF_IMAGE_REPO_URL)")
else
  log_pass "diff-image available"
fi

if [ ${#missing_items[@]} -ne 0 ]; then
  echo ""
  echo "❌ Precheck failed. Missing requirements:"
  for item in "${missing_items[@]}"; do
    echo "  - $item"
  done
  exit 1
fi

echo ""
echo "✅ Precheck passed."
