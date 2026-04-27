#!/usr/bin/env bash
set -euo pipefail

HTML_PATH="$(realpath "$1")"
OUTPUT_DIR="${2:-.}"

mkdir -p "$OUTPUT_DIR"

declare -A VIEWPORTS=(
  ["desktop"]="1440,900"
  ["tablet"]="768,1024"
  ["mobile"]="375,812"
)

for name in "${!VIEWPORTS[@]}"; do
  chromium \
    --headless \
    --disable-gpu \
    --no-sandbox \
    --screenshot="$OUTPUT_DIR/${name}.png" \
    --window-size="${VIEWPORTS[$name]}" \
    "file://$HTML_PATH"
done
