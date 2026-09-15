#!/usr/bin/env bats
# Confirms link-artifacts.sh covers checklist and ADR artifact kinds (FR-008).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/link-artifacts.sh"
}

@test "a checklist path links successfully" {
  enqueue_gh_response 0 "" ""
  run "$SCRIPT" --target-type issue --target 42 --kind checklist --path "specs/copilot-agent-issue-board/checklists/requirements.md" --agent-id a --session-id s
  [ "$status" -eq 0 ]
}

@test "an ADR path links successfully" {
  enqueue_gh_response 0 "" ""
  run "$SCRIPT" --target-type issue --target 42 --kind adr --path "docs/architecture/adr/README.md" --agent-id a --session-id s
  [ "$status" -eq 0 ]
}
