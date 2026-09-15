#!/usr/bin/env bash
# Resolves a ticket, then delegates the Status/Priority write to set-field.sh (FR-003).
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
board_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$board_root/lib/gh-common.sh"
# shellcheck source=../lib/board-item.sh
source "$board_root/lib/board-item.sh"

issue=""
field=""
value=""
agent_id=""
session_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) issue="$2"; shift 2 ;;
    --field) field="$2"; shift 2 ;;
    --value) value="$2"; shift 2 ;;
    --agent-id) agent_id="$2"; shift 2 ;;
    --session-id) session_id="$2"; shift 2 ;;
    *) echo "update-ticket.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$issue" || -z "$field" || -z "$value" ]]; then
  echo "update-ticket.sh: --issue, --field, and --value are required" >&2
  exit 2
fi

board_item_resolve --issue "$issue"
resolve_status=$?

if [[ "$resolve_status" -eq 2 ]]; then
  echo "update-ticket.sh: --issue must be a positive integer" >&2
  exit 2
fi

if [[ "$resolve_status" -ne 0 ]]; then
  if [[ "${BOARD_ITEM_NOT_FOUND:-0}" -eq 1 ]]; then
    echo "update-ticket.sh: ticket #$issue not found" >&2
    exit 1
  fi
  echo "update-ticket.sh: failed to resolve ticket #$issue" >&2
  exit 1
fi

previous_value=""
case "$field" in
  Status) previous_value="$BOARD_ITEM_STATUS" ;;
  Priority) previous_value="$BOARD_ITEM_PRIORITY" ;;
esac

"$board_root/scripts/set-field.sh" --item-id "$BOARD_ITEM_ID" --field "$field" --value "$value" \
  --agent-id "$agent_id" --session-id "$session_id"
set_field_status=$?

if [[ "$set_field_status" -ne 0 ]]; then
  exit "$set_field_status"
fi

previous_json="null"
[[ -n "$previous_value" ]] && previous_json="\"$previous_value\""

jq -nc --argjson issue_number "$issue" --arg field "$field" --argjson previous_value "$previous_json" \
  --arg new_value "$value" \
  '{issue_number: $issue_number, field: $field, previous_value: $previous_value, new_value: $new_value}'
