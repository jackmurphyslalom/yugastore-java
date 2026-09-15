#!/usr/bin/env bats
# Tests for scripts/set-milestone.sh (FR-007).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/set-milestone.sh"
}

@test "successful assignment logs a succeeded set_milestone entry" {
  enqueue_gh_response 0 "" ""
  run "$SCRIPT" --issue 42 --milestone "v1.0" --agent-id a --session-id s
  [ "$status" -eq 0 ]
  [ "$(jq -r '.action' "$AUDIT_LOG_FILE")" = "set_milestone" ]
}

@test "a nonexistent milestone causes a gh failure and a failed audit entry" {
  enqueue_gh_response 1 "" "milestone not found"
  run "$SCRIPT" --issue 42 --milestone "does-not-exist" --agent-id a --session-id s
  [ "$status" -eq 1 ]
  [ "$(jq -r '.result' "$AUDIT_LOG_FILE")" = "failed" ]
}
