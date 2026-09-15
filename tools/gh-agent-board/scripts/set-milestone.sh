#!/usr/bin/env bash
# Assigns an Issue to an existing milestone; does not create milestones (FR-007).
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
board_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$board_root/lib/gh-common.sh"
# shellcheck source=../lib/audit-log.sh
source "$board_root/lib/audit-log.sh"

issue=""
milestone=""
agent_id=""
session_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --issue) issue="$2"; shift 2 ;;
    --milestone) milestone="$2"; shift 2 ;;
    --agent-id) agent_id="$2"; shift 2 ;;
    --session-id) session_id="$2"; shift 2 ;;
    *) echo "set-milestone.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$issue" || -z "$milestone" ]]; then
  echo "set-milestone.sh: --issue and --milestone are required" >&2
  exit 2
fi

gh_common_run issue edit "$issue" --milestone "$milestone"
if [[ "$GH_RUN_EXIT_CODE" -ne 0 ]]; then
  audit_log_write --action set_milestone --target "$issue" --result failed \
    --reason "$GH_RUN_STDERR" --details "{\"milestone\": \"$milestone\"}" \
    --agent-id "$agent_id" --session-id "$session_id"
  echo "$GH_RUN_STDERR" >&2
  exit 1
fi

audit_log_write --action set_milestone --target "$issue" --result succeeded \
  --details "{\"milestone\": \"$milestone\"}" \
  --agent-id "$agent_id" --session-id "$session_id"
