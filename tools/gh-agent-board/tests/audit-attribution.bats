#!/usr/bin/env bats
# Confirms different agent/session pairs produce distinguishable audit entries (FR-012/FR-018).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/reopen-issue.sh"
}

@test "two different agent/session pairs produce two distinguishable audit entries" {
  enqueue_gh_response 0 "" ""
  run "$SCRIPT" --issue 1 --agent-id agent-a --session-id sess-1
  [ "$status" -eq 0 ]
  enqueue_gh_response 0 "" ""
  run "$SCRIPT" --issue 2 --agent-id agent-b --session-id sess-2
  [ "$status" -eq 0 ]

  [ "$(sed -n '1p' "$AUDIT_LOG_FILE" | jq -r '.agent_id')" = "agent-a" ]
  [ "$(sed -n '2p' "$AUDIT_LOG_FILE" | jq -r '.agent_id')" = "agent-b" ]
}
