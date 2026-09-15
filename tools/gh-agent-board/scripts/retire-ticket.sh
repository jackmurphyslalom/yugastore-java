#!/usr/bin/env bash
# Retires a ticket by setting its Status only; never closes the Issue (FR-009).
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
board_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$board_root/lib/gh-common.sh"
# shellcheck source=../lib/board-item.sh
source "$board_root/lib/board-item.sh"

issue=""
outcome=""
agent_id=""
session_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) issue="$2"; shift 2 ;;
    --outcome) outcome="$2"; shift 2 ;;
    --agent-id) agent_id="$2"; shift 2 ;;
    --session-id) session_id="$2"; shift 2 ;;
    *) echo "retire-ticket.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$issue" ]]; then
  echo "retire-ticket.sh: --issue is required" >&2
  exit 2
fi

mapped_status=""
case "$outcome" in
  done) mapped_status="Done" ;;
  wont-fix) mapped_status="Won't Fix" ;;
  *) echo "retire-ticket.sh: --outcome must be 'done' or 'wont-fix'" >&2; exit 2 ;;
esac

board_item_resolve --issue "$issue"
resolve_status=$?

if [[ "$resolve_status" -eq 2 ]]; then
  echo "retire-ticket.sh: --issue must be a positive integer" >&2
  exit 2
fi

if [[ "$resolve_status" -ne 0 ]]; then
  if [[ "${BOARD_ITEM_NOT_FOUND:-0}" -eq 1 ]]; then
    echo "retire-ticket.sh: ticket #$issue not found" >&2
    exit 1
  fi
  echo "retire-ticket.sh: failed to resolve ticket #$issue" >&2
  exit 1
fi

"$board_root/scripts/set-field.sh" --item-id "$BOARD_ITEM_ID" --field Status --value "$mapped_status" \
  --agent-id "$agent_id" --session-id "$session_id"
set_field_status=$?

if [[ "$set_field_status" -ne 0 ]]; then
  exit "$set_field_status"
fi

echo "retire-ticket.sh: Status set to '$mapped_status'. The Issue itself remains open — closing it is a human-only action outside this tooling." >&2

jq -nc --argjson issue_number "$issue" --arg status "$mapped_status" \
  '{issue_number: $issue_number, status: $status}'
