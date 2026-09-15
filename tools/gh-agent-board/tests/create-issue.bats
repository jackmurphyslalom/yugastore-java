#!/usr/bin/env bats
# Tests for scripts/create-issue.sh (FR-001).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/create-issue.sh"
}

@test "missing --title exits 2 before any gh call and writes no audit entry" {
  run "$SCRIPT" --agent-id a --session-id s
  [ "$status" -eq 2 ]
  [ ! -s "$GH_STUB_LOG" ]
  [ ! -s "$AUDIT_LOG_FILE" ]
}

@test "successful create-issue and item-add prints result and logs one succeeded entry" {
  enqueue_gh_response 0 'https://github.com/o/r/issues/42' ""
  enqueue_gh_response 0 '{"id":"ITEM_1"}' ""
  run "$SCRIPT" --title "New feature" --agent-id a --session-id s
  [ "$status" -eq 0 ]
  [[ "$output" == *'"issue_number":42'* ]]
  [ "$(jq -r '.action' "$AUDIT_LOG_FILE")" = "create_issue" ]
  [ "$(jq -r '.result' "$AUDIT_LOG_FILE")" = "succeeded" ]
}

@test "issue created but item-add fails exits 1 and logs a failed entry referencing the issue" {
  enqueue_gh_response 0 'https://github.com/o/r/issues/42' ""
  enqueue_gh_response 1 "" "board not found"
  run "$SCRIPT" --title "New feature" --agent-id a --session-id s
  [ "$status" -eq 1 ]
  [ "$(jq -r '.result' "$AUDIT_LOG_FILE")" = "failed" ]
  [ "$(jq -r '.target' "$AUDIT_LOG_FILE")" = "42" ]
}
