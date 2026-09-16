#!/usr/bin/env bash
set -euo pipefail

skill_dir="${1:-}"
harness_dir="${2:-}"

if [[ -z "$skill_dir" || -z "$harness_dir" ]]; then
  echo "Usage: refresh-harness-support.sh <skill_dir> <harness_dir>" >&2
  exit 2
fi

starter_dir="$skill_dir/assets/slalom-html-deck-starter"

if [[ ! -d "$starter_dir" ]]; then
  echo "Starter directory not found: $starter_dir" >&2
  exit 1
fi

mkdir -p "$harness_dir"
cp "$starter_dir/base.css" "$harness_dir/base.css"
cp "$starter_dir/base-light.css" "$harness_dir/base-light.css"
cp "$starter_dir/deck.js" "$harness_dir/deck.js"
rm -rf "$harness_dir/components"
cp -R "$starter_dir/components" "$harness_dir/components"
cp "$skill_dir/scripts/render.js" "$harness_dir/render.js"
cp "$skill_dir/scripts/visual-qa.js" "$harness_dir/visual-qa.js"
cp "$skill_dir/scripts/build-deck.js" "$harness_dir/build-deck.js"

echo "harness support refreshed: $harness_dir"
