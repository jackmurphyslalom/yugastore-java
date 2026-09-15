#!/usr/bin/env bats
# Tests for scripts/open-pr.sh (FR-005).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/open-pr.sh"
}

@test "PR body contains a Closes keyword and a succeeded audit entry is logged" {
  enqueue_gh_response 0 'https://github.com/o/r/pull/7' ""
  run "$SCRIPT" --issue 42 --title "Implement feature" --base main --head feature-branch --agent-id a --session-id s
  [ "$status" -eq 0 ]
  run grep -F "Closes #42" "$GH_STUB_LOG"
  [ "$status" -eq 0 ]
  [ "$(jq -r '.action' "$AUDIT_LOG_FILE")" = "open_pr" ]
}

@test "a protected-branch failure exits 1 and logs the gh stderr as the reason" {
  enqueue_gh_response 1 "" "GH006: protected branch"
  run "$SCRIPT" --issue 42 --title "Implement feature" --base main --head feature-branch --agent-id a --session-id s
  [ "$status" -eq 1 ]
  [[ "$(jq -r '.reason' "$AUDIT_LOG_FILE")" == *"protected branch"* ]]
}
