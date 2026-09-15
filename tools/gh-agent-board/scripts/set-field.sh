#!/usr/bin/env bash
# Sets the Status or Priority custom field on a Project Item (FR-002/003/016).
set -uo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
board_root="$(cd "$script_dir/.." && pwd)"
# shellcheck source=../lib/gh-common.sh
source "$board_root/lib/gh-common.sh"
# shellcheck source=../lib/audit-log.sh
source "$board_root/lib/audit-log.sh"

item_id=""
field=""
value=""
agent_id=""
session_id=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --item-id) item_id="$2"; shift 2 ;;
    --field) field="$2"; shift 2 ;;
    --value) value="$2"; shift 2 ;;
    --agent-id) agent_id="$2"; shift 2 ;;
    --session-id) session_id="$2"; shift 2 ;;
    *) echo "set-field.sh: unknown argument: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$item_id" || -z "$field" || -z "$value" ]]; then
  echo "set-field.sh: --item-id, --field, and --value are required" >&2
  exit 2
fi

board_config="${BOARD_CONFIG:-$board_root/config/board.json}"
field_id="$(jq -r --arg field "$field" '.fields[$field].field_id // empty' "$board_config")"
option_id="$(jq -r --arg field "$field" --arg value "$value" '.fields[$field].options[$value] // empty' "$board_config")"
project_id="$(jq -r '.project_id' "$board_config")"

if [[ -z "$field_id" || -z "$option_id" ]]; then
  audit_log_write --action set_field --target "$item_id" --result failed \
    --reason "field not configured" --details "{\"field\": \"$field\", \"value\": \"$value\"}" \
    --agent-id "$agent_id" --session-id "$session_id"
  echo "set-field.sh: field '$field' or value '$value' not configured in board.json" >&2
  exit 2
fi

# Only the single named field is touched here; Status/Priority updates never affect each other
# or the Issue's open/closed state (FR-003).
gh_common_run project item-edit --id "$item_id" --field-id "$field_id" --project-id "$project_id" \
  --single-select-option-id "$option_id"
if [[ "$GH_RUN_EXIT_CODE" -ne 0 ]]; then
  audit_log_write --action set_field --target "$item_id" --result failed \
    --reason "$GH_RUN_STDERR" --details "{\"field\": \"$field\", \"value\": \"$value\"}" \
    --agent-id "$agent_id" --session-id "$session_id"
  echo "$GH_RUN_STDERR" >&2
  exit 1
fi

audit_log_write --action set_field --target "$item_id" --result succeeded \
  --details "{\"field\": \"$field\", \"value\": \"$value\"}" \
  --agent-id "$agent_id" --session-id "$session_id"
