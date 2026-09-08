#!/usr/bin/env bash

# Exit immediately if a command exits with a non-zero status
set -euo pipefail

usage() {
  echo "Usage: $0 [--check]"
  echo "Transforms raw design assets into application launcher icons across Android, iOS, and Web."
  echo ""
  echo "Options:"
  echo "  --check     Verify that generated icons match checked-in icons without leaving diffs"
  echo "  -h, --help  Show this help message"
}

CHECK_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --check)
      CHECK_MODE=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: Unknown option $1" >&2
      usage
      exit 1
      ;;
  esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ICON_PATHS=(
  "$REPO_ROOT"/app/android/app/src/main/res/mipmap-*
  "$REPO_ROOT"/app/android/app/src/main/res/drawable-*/ic_launcher_foreground.png
  "$REPO_ROOT/app/android/app/src/main/res/drawable/ic_launcher_monochrome.xml"
  "$REPO_ROOT/app/android/app/src/main/res/values/colors.xml"
  "$REPO_ROOT/app/ios/Runner/Assets.xcassets/AppIcon.appiconset"
  "$REPO_ROOT/app/web/favicon.png"
  "$REPO_ROOT/app/web/icons"
  "$REPO_ROOT/app/web/manifest.json"
)

if [ "$CHECK_MODE" = true ]; then
  # Verify git is installed and directory is inside a git working tree
  if ! command -v git >/dev/null 2>&1; then
    echo "Error: 'git' was not found in PATH." >&2
    exit 1
  fi
  if ! git -C "$REPO_ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not in a git repository." >&2
    exit 1
  fi

  # In check mode, ensure working tree is restored to original state on exit
  restore_icons() {
    rm -f "$REPO_ROOT"/app/android/app/src/main/res/drawable-*/ic_launcher_monochrome.png
    git -C "$REPO_ROOT" checkout HEAD -- "${ICON_PATHS[@]}" >/dev/null 2>&1 || true
    git -C "$REPO_ROOT" clean -fd -- "${ICON_PATHS[@]}" >/dev/null 2>&1 || true
  }
  trap restore_icons EXIT
fi

# Verify environment dependencies
if command -v dart >/dev/null 2>&1; then
  LAUNCHER_CMD=(dart run flutter_launcher_icons)
elif command -v flutter >/dev/null 2>&1; then
  LAUNCHER_CMD=(flutter pub run flutter_launcher_icons)
else
  echo "Error: Neither 'dart' nor 'flutter' was found in PATH." >&2
  echo "Please install Flutter/Dart and ensure it is available in your PATH." >&2
  exit 1
fi

echo "Generating launcher icons from raw assets..."
(
  cd "$REPO_ROOT/app"
  "${LAUNCHER_CMD[@]}"
)

# Resolve Android monochrome discrepancy:
# flutter_launcher_icons generates raster monochrome PNGs (drawable-*/ic_launcher_monochrome.png),
# but TwelveStars uses a crisp vector drawable (drawable/ic_launcher_monochrome.xml, see PR #122)
# to avoid rendering issues on Android 13+. Remove generated raster monochrome PNGs.
echo "Cleaning up generated raster monochrome PNGs (preserving vector drawable)..."
rm -f "$REPO_ROOT"/app/android/app/src/main/res/drawable-*/ic_launcher_monochrome.png

if [ "$CHECK_MODE" = true ]; then
  echo "Checking for differences against checked-in icon files..."

  DIFF_OUTPUT=$(git -C "$REPO_ROOT" diff HEAD -- "${ICON_PATHS[@]}")
  STATUS_OUTPUT=$(git -C "$REPO_ROOT" status --porcelain -- "${ICON_PATHS[@]}")

  if [ -n "$DIFF_OUTPUT" ] || [ -n "$STATUS_OUTPUT" ]; then
    echo "Error: Generated icons differ from checked-in icons." >&2
    if [ -n "$DIFF_OUTPUT" ]; then
      echo "$DIFF_OUTPUT" >&2
    fi
    if [ -n "$STATUS_OUTPUT" ]; then
      echo "Untracked or modified icon files:" >&2
      echo "$STATUS_OUTPUT" >&2
    fi
    exit 1
  fi
  echo "Icon check passed: Checked-in icons match raw assets."
else
  echo "Icon generation complete!"
fi
