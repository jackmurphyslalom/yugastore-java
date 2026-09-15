#!/usr/bin/env bats
# Confirms Status transitions never touch the Issue's open/closed state (FR-003).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/set-field.sh"
}

@test "Status can move across all four allowed values without invoking gh issue close" {
  for value in "Todo" "In Progress" "In Review" "Done"; do
    enqueue_gh_response 0 "" ""
    run "$SCRIPT" --item-id ITEM_1 --field Status --value "$value" --agent-id a --session-id s
    [ "$status" -eq 0 ]
  done
  run grep -c "issue close" "$GH_STUB_LOG"
  [ "$status" -ne 0 ]
}

@test "each field write only ever targets the single field it was given" {
  enqueue_gh_response 0 "" ""
  run "$SCRIPT" --item-id ITEM_1 --field Status --value "In Progress" --agent-id a --session-id s
  [ "$status" -eq 0 ]
  enqueue_gh_response 0 "" ""
  run "$SCRIPT" --item-id ITEM_1 --field Priority --value "P1" --agent-id a --session-id s
  [ "$status" -eq 0 ]
  [ "$(grep -c 'field-id' "$GH_STUB_LOG")" -eq 2 ]
}
