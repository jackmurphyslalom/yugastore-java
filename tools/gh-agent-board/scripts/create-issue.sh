#!/usr/bin/env bash
# Creates an Issue for one Spec Kit feature and adds it to the Projects (v2) board (FR-001).
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
board_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$board_root/lib/gh-common.sh"
# shellcheck source=../lib/audit-log.sh
source "$board_root/lib/audit-log.sh"

title=""
body=""
agent_id=""
session_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) title="$2"; shift 2 ;;
    --body) body="$2"; shift 2 ;;
    --agent-id) agent_id="$2"; shift 2 ;;
    --session-id) session_id="$2"; shift 2 ;;
    *) echo "create-issue.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$title" ]]; then
  echo "create-issue.sh: --title is required and must be non-empty" >&2
  exit 2
fi

board_config="${BOARD_CONFIG:-$board_root/config/board.json}"
project_number="$(jq -r '.project_number' "$board_config")"
owner="$(jq -r '.owner' "$board_config")"

# gh issue create has no --json support; it prints the created issue URL as plain text.
gh_common_run issue create --title "$title" --body "$body"
if [[ "$GH_RUN_EXIT_CODE" -ne 0 ]]; then
  audit_log_write --action create_issue --target unknown --result failed \
    --reason "gh issue create failed: $GH_RUN_STDERR" \
    --agent-id "$agent_id" --session-id "$session_id"
  echo "$GH_RUN_STDERR" >&2
  exit 1
fi

issue_url="$(printf '%s' "$GH_RUN_STDOUT" | tail -n1)"
issue_number="${issue_url##*/}"

# gh project item-add takes the project *number* + --owner, unlike item-edit which takes --project-id (node ID).
gh_common_run project item-add "$project_number" --owner "$owner" --url "$issue_url" --format json
if [[ "$GH_RUN_EXIT_CODE" -ne 0 ]]; then
  audit_log_write --action create_issue --target "$issue_number" --result failed \
    --reason "issue #$issue_number created but gh project item-add failed: $GH_RUN_STDERR" \
    --agent-id "$agent_id" --session-id "$session_id"
  echo "$GH_RUN_STDERR" >&2
  exit 1
fi

item_id="$(jq -r '.id' <<<"$GH_RUN_STDOUT")"

audit_log_write --action create_issue --target "$issue_number" --result succeeded \
  --details "{\"item_id\": \"$item_id\"}" \
  --agent-id "$agent_id" --session-id "$session_id"

jq -nc --argjson issue_number "$issue_number" --arg item_id "$item_id" \
  '{issue_number: $issue_number, item_id: $item_id}'
