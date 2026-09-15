#!/usr/bin/env bash
# Appends a Spec Kit artifact reference to an Issue/PR body via comment (FR-006/008).
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
board_root="$(cd "$script_dir/.." && pwd)"
repo_root="$(cd "$board_root/../.." && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$board_root/lib/gh-common.sh"
# shellcheck source=../lib/audit-log.sh
source "$board_root/lib/audit-log.sh"

target_type=""
target=""
kind=""
path=""
agent_id=""
session_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target-type) target_type="$2"; shift 2 ;;
    --target) target="$2"; shift 2 ;;
    --kind) kind="$2"; shift 2 ;;
    --path) path="$2"; shift 2 ;;
    --agent-id) agent_id="$2"; shift 2 ;;
    --session-id) session_id="$2"; shift 2 ;;
    *) echo "link-artifacts.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$target_type" || -z "$target" || -z "$kind" || -z "$path" ]]; then
  echo "link-artifacts.sh: --target-type, --target, --kind, and --path are required" >&2
  exit 2
fi

if [[ ! -f "$repo_root/$path" ]]; then
  audit_log_write --action link_artifact --target "$target" --result failed \
    --reason "artifact path not found" --details "{\"kind\": \"$kind\", \"path\": \"$path\"}" \
    --agent-id "$agent_id" --session-id "$session_id"
  echo "link-artifacts.sh: path not found: $path" >&2
  exit 1
fi

comment_subcommand="issue"
[[ "$target_type" == "pr" ]] && comment_subcommand="pr"
comment_body="Linked ${kind}: ${path}"

gh_common_run "$comment_subcommand" comment "$target" --body "$comment_body"
if [[ "$GH_RUN_EXIT_CODE" -ne 0 ]]; then
  audit_log_write --action link_artifact --target "$target" --result failed \
    --reason "$GH_RUN_STDERR" --details "{\"kind\": \"$kind\", \"path\": \"$path\"}" \
    --agent-id "$agent_id" --session-id "$session_id"
  echo "$GH_RUN_STDERR" >&2
  exit 1
fi

audit_log_write --action link_artifact --target "$target" --result succeeded \
  --details "{\"kind\": \"$kind\", \"path\": \"$path\"}" \
  --agent-id "$agent_id" --session-id "$session_id"
