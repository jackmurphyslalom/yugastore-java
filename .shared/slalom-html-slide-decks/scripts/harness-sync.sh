#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
source_dir="${2:-}"
target_dir="${3:-}"

if [[ -z "$mode" || -z "$source_dir" || -z "$target_dir" ]]; then
  echo "Usage: harness-sync.sh restore|save <source_dir> <target_dir>" >&2
  exit 2
fi

if [[ "$mode" != "restore" && "$mode" != "save" ]]; then
  echo "Mode must be restore or save" >&2
  exit 2
fi

if [[ ! -d "$source_dir" ]]; then
  echo "Source directory not found: $source_dir" >&2
  exit 1
fi

source_real="$(cd "$source_dir" && pwd -P)"
mkdir -p "$target_dir"
target_real="$(cd "$target_dir" && pwd -P)"

if [[ "$source_real" == "$target_real" ]]; then
  echo "$mode skipped: source and target are the same directory ($source_real)"
  exit 0
fi

rsync -a --delete "$source_dir"/ "$target_dir"/
echo "$mode complete: $source_dir -> $target_dir"
