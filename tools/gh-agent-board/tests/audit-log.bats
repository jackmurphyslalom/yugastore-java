#!/usr/bin/env bats
# Tests for lib/audit-log.sh: every write must be logged before the caller's exit code returns.

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  source "$BOARD_ROOT/lib/audit-log.sh"
}

@test "writes one JSON line with required fields" {
  audit_log_write --action create_issue --target 42 --result succeeded --agent-id agent-a --session-id sess-1
  [ -f "$AUDIT_LOG_FILE" ]
  [ "$(jq -r '.action' "$AUDIT_LOG_FILE")" = "create_issue" ]
}

@test "agent_id and session_id fall back to AGENT_SESSION_ID env var when flags are omitted" {
  export AGENT_SESSION_ID="env-agent"
  audit_log_write --action set_field --target abc --result succeeded
  [ "$(jq -r '.agent_id' "$AUDIT_LOG_FILE")" = "env-agent" ]
  [ "$(jq -r '.session_id' "$AUDIT_LOG_FILE")" = "env-agent" ]
}

@test "agent_id falls back to literal unknown when nothing is set" {
  unset AGENT_SESSION_ID
  audit_log_write --action set_field --target abc --result succeeded
  [ "$(jq -r '.agent_id' "$AUDIT_LOG_FILE")" = "unknown" ]
}

@test "a failed result records a reason" {
  audit_log_write --action set_field --target abc --result failed --reason "gh exploded" --agent-id a --session-id s
  [ "$(jq -r '.reason' "$AUDIT_LOG_FILE")" = "gh exploded" ]
}

@test "missing required arguments fails without writing a partial entry" {
  run audit_log_write --action set_field
  [ "$status" -ne 0 ]
  [ ! -s "$AUDIT_LOG_FILE" ]
}

@test "a failure to write the log file itself is a hard failure" {
  export AUDIT_LOG_FILE="/nonexistent-root-only-dir/agent-actions.jsonl"
  run audit_log_write --action set_field --target abc --result succeeded --agent-id a --session-id s
  [ "$status" -ne 0 ]
}
