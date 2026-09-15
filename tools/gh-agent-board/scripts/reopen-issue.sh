#!/usr/bin/env bash
# Reopens an Issue an agent is resuming work on. Closing is human-only; no close action exists (FR-004).
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
board_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$board_root/lib/gh-common.sh"
# shellcheck source=../lib/audit-log.sh
source "$board_root/lib/audit-log.sh"

issue=""
agent_id=""
session_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) issue="$2"; shift 2 ;;
    --agent-id) agent_id="$2"; shift 2 ;;
    --session-id) session_id="$2"; shift 2 ;;
    *) echo "reopen-issue.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$issue" ]]; then
  echo "reopen-issue.sh: --issue is required" >&2
  exit 2
fi

gh_common_run issue reopen "$issue"
if [[ "$GH_RUN_EXIT_CODE" -ne 0 ]]; then
  audit_log_write --action reopen_issue --target "$issue" --result failed \
    --reason "$GH_RUN_STDERR" --agent-id "$agent_id" --session-id "$session_id"
  echo "$GH_RUN_STDERR" >&2
  exit 1
fi

audit_log_write --action reopen_issue --target "$issue" --result succeeded \
  --agent-id "$agent_id" --session-id "$session_id"
