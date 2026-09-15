#!/usr/bin/env bats
# Tests for scripts/set-field.sh (FR-002/003/016).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/set-field.sh"
}

@test "valid Status value succeeds and logs an audit entry" {
  enqueue_gh_response 0 "" ""
  run "$SCRIPT" --item-id ITEM_1 --field Status --value "In Progress" --agent-id a --session-id s
  [ "$status" -eq 0 ]
  [ "$(jq -r '.result' "$AUDIT_LOG_FILE")" = "succeeded" ]
}

@test "invalid field/value combination exits 2 with no gh call and no audit entry" {
  run "$SCRIPT" --item-id ITEM_1 --field Status --value "Not A Real Status" --agent-id a --session-id s
  [ "$status" -eq 2 ]
  [ ! -s "$GH_STUB_LOG" ]
}

@test "a field missing from board.json config fails with reason field not configured" {
  run "$SCRIPT" --item-id ITEM_1 --field Unknown --value "Whatever" --agent-id a --session-id s
  [ "$status" -eq 2 ]
  [ "$(jq -r '.reason' "$AUDIT_LOG_FILE")" = "field not configured" ]
}
