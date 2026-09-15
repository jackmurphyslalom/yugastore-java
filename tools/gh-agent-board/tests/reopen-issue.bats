#!/usr/bin/env bats
# Tests for scripts/reopen-issue.sh (FR-004).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/reopen-issue.sh"
}

@test "successful reopen logs a succeeded reopen_issue entry" {
  enqueue_gh_response 0 "" ""
  run "$SCRIPT" --issue 42 --agent-id a --session-id s
  [ "$status" -eq 0 ]
  [ "$(jq -r '.action' "$AUDIT_LOG_FILE")" = "reopen_issue" ]
  [ "$(jq -r '.result' "$AUDIT_LOG_FILE")" = "succeeded" ]
}

@test "reopening an already-open issue is an idempotent success" {
  enqueue_gh_response 0 "" ""
  run "$SCRIPT" --issue 42 --agent-id a --session-id s
  [ "$status" -eq 0 ]
}

@test "a nonexistent issue fails with a failed audit entry" {
  enqueue_gh_response 1 "" "issue not found"
  run "$SCRIPT" --issue 999 --agent-id a --session-id s
  [ "$status" -eq 1 ]
  [ "$(jq -r '.result' "$AUDIT_LOG_FILE")" = "failed" ]
}
