#!/usr/bin/env bats
# Confirms no script or audit action can close an Issue (FR-004: closing is human-only).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "no close-issue script exists in scripts/" {
  run bash -c "ls '$BOARD_ROOT/scripts' | grep -i close"
  [ "$status" -ne 0 ]
}

@test "no script or lib invokes gh issue close" {
  run bash -c "grep -rl 'issue close' '$BOARD_ROOT/scripts' '$BOARD_ROOT/lib'"
  [ "$status" -ne 0 ]
}

@test "no script or lib writes a close_issue audit action" {
  run bash -c "grep -rl 'close_issue' '$BOARD_ROOT/scripts' '$BOARD_ROOT/lib'"
  [ "$status" -ne 0 ]
}
