#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "$0")/.." && pwd)"
output_dir="$project_root/dist"
app_dir="$output_dir/MacroPilot.app"
developer_dir="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"

DEVELOPER_DIR="$developer_dir" swift build -c release --package-path "$project_root"

if [[ -e "$app_dir" ]]; then
  echo "Refusing to overwrite existing $app_dir. Move it aside, then run again." >&2
  exit 1
fi
mkdir -p "$app_dir/Contents/MacOS" "$app_dir/Contents/Resources"
cp "$project_root/.build/release/MacroPilot" "$app_dir/Contents/MacOS/MacroPilot"
cp "$project_root/MacApp/Info.plist" "$app_dir/Contents/Info.plist"

# This optional Apache-licensed helper enables the three verified LED modes.
# It is intentionally not checked into this repository as a platform binary.
if [[ -x "$project_root/tools/ch57x-keyboard-tool" ]]; then
  cp "$project_root/tools/ch57x-keyboard-tool" "$app_dir/Contents/Resources/ch57x-keyboard-tool"
fi

codesign --force --sign - "$app_dir"
echo "Built $app_dir"
