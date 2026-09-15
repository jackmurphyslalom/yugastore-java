#!/usr/bin/env bats
# Tests for scripts/link-artifacts.sh (FR-006/008).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/link-artifacts.sh"
  EXISTING_PATH="specs/copilot-agent-issue-board/plan.md"
}

@test "an existing path posts a comment and logs a succeeded entry" {
  enqueue_gh_response 0 "" ""
  run "$SCRIPT" --target-type issue --target 42 --kind plan --path "$EXISTING_PATH" --agent-id a --session-id s
  [ "$status" -eq 0 ]
  [ "$(jq -r '.result' "$AUDIT_LOG_FILE")" = "succeeded" ]
}

@test "a missing path exits 1, posts no comment, and logs a failed entry" {
  run "$SCRIPT" --target-type issue --target 42 --kind plan --path "specs/does/not/exist.md" --agent-id a --session-id s
  [ "$status" -eq 1 ]
  [ ! -s "$GH_STUB_LOG" ]
  [ "$(jq -r '.reason' "$AUDIT_LOG_FILE")" = "artifact path not found" ]
}
