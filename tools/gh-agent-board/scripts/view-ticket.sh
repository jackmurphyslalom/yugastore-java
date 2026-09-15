#!/usr/bin/env bash
# Read-only ticket lookup: title, Status, Priority, assignees (FR-002). Writes no audit entry.
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
board_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$board_root/lib/gh-common.sh"
# shellcheck source=../lib/board-item.sh
source "$board_root/lib/board-item.sh"

issue=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) issue="$2"; shift 2 ;;
    *) echo "view-ticket.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$issue" ]]; then
  echo "view-ticket.sh: --issue is required" >&2
  exit 2
fi

board_item_resolve --issue "$issue"
resolve_status=$?

if [[ "$resolve_status" -eq 2 ]]; then
  echo "view-ticket.sh: --issue must be a positive integer" >&2
  exit 2
fi

if [[ "$resolve_status" -ne 0 ]]; then
  if [[ "${BOARD_ITEM_NOT_FOUND:-0}" -eq 1 ]]; then
    echo "view-ticket.sh: ticket #$issue not found" >&2
    exit 1
  fi
  echo "view-ticket.sh: failed to resolve ticket #$issue" >&2
  exit 1
fi

status_value="null"
[[ -n "$BOARD_ITEM_STATUS" ]] && status_value="\"$BOARD_ITEM_STATUS\""
priority_value="null"
[[ -n "$BOARD_ITEM_PRIORITY" ]] && priority_value="\"$BOARD_ITEM_PRIORITY\""

jq -nc --argjson issue_number "$issue" --arg title "$BOARD_ITEM_TITLE" \
  --argjson status "$status_value" --argjson priority "$priority_value" \
  --argjson assignees "${BOARD_ITEM_ASSIGNEES:-[]}" \
  '{issue_number: $issue_number, title: $title, status: $status, priority: $priority, assignees: $assignees}'
