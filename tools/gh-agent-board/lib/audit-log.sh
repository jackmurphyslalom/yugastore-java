#!/usr/bin/env bash
# Append-only JSONL audit writer. Every gh-agent-board write action must log here before exit (FR-010).

_audit_log_default_file() {
  local lib_dir repo_root
  lib_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  repo_root="$(cd "$lib_dir/../../.." && pwd)"
  printf '%s' "$repo_root/docs/context/audit/agent-actions.jsonl"
}

AUDIT_LOG_FILE="${AUDIT_LOG_FILE:-$(_audit_log_default_file)}"

# audit_log_write --action <action> --target <target> --result <succeeded|failed>
#                  [--reason "<text>"] [--details '<json>'] [--agent-id <id>] [--session-id <id>]
audit_log_write() {
  local action="" target="" result="" reason="" details="{}" agent_id="" session_id=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --action) action="$2"; shift 2 ;;
      --target) target="$2"; shift 2 ;;
      --result) result="$2"; shift 2 ;;
      --reason) reason="$2"; shift 2 ;;
      --details) details="$2"; shift 2 ;;
      --agent-id) agent_id="$2"; shift 2 ;;
      --session-id) session_id="$2"; shift 2 ;;
      *) echo "audit_log_write: unknown argument: $1" >&2; return 2 ;;
    esac
  done

  if [[ -z "$action" || -z "$target" || -z "$result" ]]; then
    echo "audit_log_write: --action, --target, and --result are required" >&2
    return 2
  fi

  # Same fallback source (AGENT_SESSION_ID) covers both agent_id and session_id, per data-model.md.
  agent_id="${agent_id:-${AGENT_SESSION_ID:-unknown}}"
  session_id="${session_id:-${AGENT_SESSION_ID:-unknown}}"

  local timestamp entry
  timestamp="$(date -u +%Y-%m-%dT%H:%M:%SZ)"

  entry="$(jq -nc \
    --arg timestamp "$timestamp" \
    --arg agent_id "$agent_id" \
    --arg session_id "$session_id" \
    --arg action "$action" \
    --arg target "$target" \
    --arg result "$result" \
    --arg reason "$reason" \
    --argjson details "$details" \
    '{timestamp: $timestamp, agent_id: $agent_id, session_id: $session_id, action: $action,
      target: $target, result: $result,
      reason: (if $reason == "" then null else $reason end), details: $details}')" || return 1

  mkdir -p "$(dirname "$AUDIT_LOG_FILE")" || return 1
  printf '%s\n' "$entry" >> "$AUDIT_LOG_FILE" || return 1
}
