#!/usr/bin/env bash
# Opens a PR linked to an originating Issue via a closing keyword (FR-005).
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
board_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$board_root/lib/gh-common.sh"
# shellcheck source=../lib/audit-log.sh
source "$board_root/lib/audit-log.sh"

issue=""
title=""
base=""
head=""
extra_body=""
agent_id=""
session_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) issue="$2"; shift 2 ;;
    --title) title="$2"; shift 2 ;;
    --base) base="$2"; shift 2 ;;
    --head) head="$2"; shift 2 ;;
    --body) extra_body="$2"; shift 2 ;;
    --agent-id) agent_id="$2"; shift 2 ;;
    --session-id) session_id="$2"; shift 2 ;;
    *) echo "open-pr.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$issue" || -z "$title" || -z "$base" || -z "$head" ]]; then
  echo "open-pr.sh: --issue, --title, --base, and --head are required" >&2
  exit 2
fi

pr_body="Closes #${issue}"
[[ -n "$extra_body" ]] && pr_body="$pr_body"$'\n\n'"$extra_body"

gh_common_run pr create --title "$title" --base "$base" --head "$head" --body "$pr_body"
if [[ "$GH_RUN_EXIT_CODE" -ne 0 ]]; then
  audit_log_write --action open_pr --target unknown --result failed \
    --reason "$GH_RUN_STDERR" --details "{\"linked_issue\": $issue}" \
    --agent-id "$agent_id" --session-id "$session_id"
  echo "$GH_RUN_STDERR" >&2
  exit 1
fi

pr_url="$(printf '%s' "$GH_RUN_STDOUT" | tail -n1)"
pr_number="${pr_url##*/}"

audit_log_write --action open_pr --target "$pr_number" --result succeeded \
  --details "{\"linked_issue\": $issue}" \
  --agent-id "$agent_id" --session-id "$session_id"

jq -nc --argjson pr_number "$pr_number" '{pr_number: $pr_number}'
