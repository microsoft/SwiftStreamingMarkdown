#!/usr/bin/env bash
#
# Dev environment precheck for SwiftStreamingMarkdown.
#
# Required:
#   - Xcode (xcodebuild) at or above the version in .xcode-version
#   - swiftlint
#   - xcodegen
#
# Optional:
#   - diff-image (and imagemagick, which it shells out to) — used as a local
#     visual diff helper for snapshot PNGs. If missing, this script offers to
#     download diff-image into ~/.local/bin.
#
# Run this once after cloning the repo.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
XCODE_VERSION_FILE="$REPO_ROOT/.xcode-version"
HOMEBREW_INSTALL_URL="https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh"
DIFF_IMAGE_REPO_URL="https://github.com/ewanmellor/git-diff-image"
DIFF_IMAGE_RAW_URL="https://raw.githubusercontent.com/ewanmellor/git-diff-image/master/diff-image"
LOCAL_BIN_DIR="$HOME/.local/bin"

echo "🔍 Running SwiftStreamingMarkdown dev environment precheck..."

missing_items=()
optional_items=()

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

# Install the standalone diff-image CLI by copying it into the user's local bin.
# Mirrors https://github.com/ewanmellor/git-diff-image/blob/master/diff-image.
install_diff_image() {
  local dest="$LOCAL_BIN_DIR/diff-image"

  if ! mkdir -p "$LOCAL_BIN_DIR"; then
    echo "❌ Could not create $LOCAL_BIN_DIR"
    return 1
  fi

  echo "⬇️  Downloading diff-image into $dest ..."
  if ! curl -fsSL "$DIFF_IMAGE_RAW_URL" -o "$dest"; then
    echo "❌ Failed to download diff-image from $DIFF_IMAGE_RAW_URL"
    rm -f "$dest"
    return 1
  fi

  chmod +x "$dest"
  echo "✅ Installed diff-image to $dest"
  return 0
}

# Snapshot diff helper presence checks.
has_imagemagick() {
  has_cmd magick || has_cmd compare
}

has_diff_image() {
  has_cmd diff-image || [ -x "$LOCAL_BIN_DIR/diff-image" ]
}

# Install whichever snapshot diff helpers are missing: ImageMagick (via Homebrew)
# and/or diff-image (downloaded into ~/.local/bin).
install_snapshot_diff_helpers() {
  local ok=0

  if ! has_imagemagick; then
    if ensure_brew_on_path; then
      brew install imagemagick || ok=1
    else
      echo "   ⚠️  Homebrew not available; cannot install ImageMagick automatically."
      ok=1
    fi
  fi

  if ! has_diff_image; then
    install_diff_image || ok=1
  fi

  return "$ok"
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

# Snapshot diff helpers (optional): ImageMagick + the diff-image CLI that shells
# out to it. Prompt once to install whichever are missing.
if ! has_imagemagick || ! has_diff_image; then
  echo "⚠️  Snapshot diff helpers are missing (ImageMagick and/or diff-image)."
  echo "   They provide a visual diff for local PNG snapshot failures. Prefer a different"
  echo "   image diff tool? You can skip this and configure your own later via"
  echo "   SnapshotTesting.diffTool to work on snapshot tests."
  prompt_to_run "   Install the missing helpers now?" \
    install_snapshot_diff_helpers || true
fi

if has_imagemagick; then
  log_pass "ImageMagick available"
else
  optional_items+=("imagemagick (brew install imagemagick)")
fi

if has_cmd diff-image; then
  log_pass "diff-image available"
elif [ -x "$LOCAL_BIN_DIR/diff-image" ]; then
  log_pass "diff-image installed at $LOCAL_BIN_DIR/diff-image"
  case ":$PATH:" in
    *":$LOCAL_BIN_DIR:"*) ;;
    *)
      echo "   ⚠️  $LOCAL_BIN_DIR is not on your PATH. Add it so 'diff-image' is found, e.g.:"
      echo "     echo 'export PATH=\"\$HOME/.local/bin:\$PATH\"' >> ~/.zshrc && source ~/.zshrc"
      ;;
  esac
else
  optional_items+=("diff-image ($DIFF_IMAGE_REPO_URL)")
fi

if [ ${#optional_items[@]} -ne 0 ]; then
  echo ""
  echo "⚠️  Optional snapshot diff helpers missing:"
  for item in "${optional_items[@]}"; do
    echo "  - $item"
  done
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
