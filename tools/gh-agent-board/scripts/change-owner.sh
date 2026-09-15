#!/usr/bin/env bash
# Changes a ticket's sole assignee, shared by the change-owner and reassign prompts (FR-004/005).
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
board_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$board_root/lib/gh-common.sh"
# shellcheck source=../lib/audit-log.sh
source "$board_root/lib/audit-log.sh"

issue=""
new_owner=""
agent_id=""
session_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) issue="$2"; shift 2 ;;
    --new-owner) new_owner="$2"; shift 2 ;;
    --agent-id) agent_id="$2"; shift 2 ;;
    --session-id) session_id="$2"; shift 2 ;;
    *) echo "change-owner.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if ! [[ "$issue" =~ ^[0-9]+$ ]] || [[ "$issue" -eq 0 ]] || [[ -z "$new_owner" ]]; then
  echo "change-owner.sh: --issue must be a positive integer and --new-owner is required" >&2
  exit 2
fi

gh_common_run issue view "$issue" --json number,assignees
if [[ "$GH_RUN_EXIT_CODE" -ne 0 ]]; then
  audit_log_write --action change_owner --target "$issue" --result failed \
    --reason "ticket not found" --details "{\"new_owner\": \"$new_owner\"}" \
    --agent-id "$agent_id" --session-id "$session_id"
  echo "change-owner.sh: ticket #$issue not found" >&2
  exit 1
fi

previous_assignees_json="$(jq -c '[.assignees[].login]' <<<"$GH_RUN_STDOUT")"

edit_args=(issue edit "$issue" --add-assignee "$new_owner")
previous_csv="$(jq -r 'join(",")' <<<"$previous_assignees_json")"
if [[ -n "$previous_csv" ]]; then
  edit_args+=(--remove-assignee "$previous_csv")
fi

gh_common_run "${edit_args[@]}"
if [[ "$GH_RUN_EXIT_CODE" -ne 0 ]]; then
  audit_log_write --action change_owner --target "$issue" --result failed \
    --reason "$GH_RUN_STDERR" \
    --details "{\"previous_assignees\": $previous_assignees_json, \"new_owner\": \"$new_owner\"}" \
    --agent-id "$agent_id" --session-id "$session_id"
  echo "$GH_RUN_STDERR" >&2
  exit 1
fi

audit_log_write --action change_owner --target "$issue" --result succeeded \
  --details "{\"previous_assignees\": $previous_assignees_json, \"new_owner\": \"$new_owner\"}" \
  --agent-id "$agent_id" --session-id "$session_id"

jq -nc --argjson issue_number "$issue" --argjson previous_assignees "$previous_assignees_json" \
  --arg new_owner "$new_owner" \
  '{issue_number: $issue_number, previous_assignees: $previous_assignees, new_owner: $new_owner}'
