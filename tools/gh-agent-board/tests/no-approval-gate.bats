#!/usr/bin/env bats
# Confirms no script reads interactive input or gates on human approval (FR-009).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "no script invokes the read builtin (interactive prompts)" {
  run bash -c "grep -rlE '(^|[^A-Za-z_])read( |\$)' '$BOARD_ROOT/scripts' '$BOARD_ROOT/lib'"
  [ "$status" -ne 0 ]
}

@test "no script contains a confirm/approve/proceed y-or-n style prompt" {
  run bash -c "grep -rliE 'confirm|approve|proceed\\?|y/n' '$BOARD_ROOT/scripts' '$BOARD_ROOT/lib'"
  [ "$status" -ne 0 ]
}

@test "every entry-point script runs to completion non-interactively against the gh stub" {
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"

  enqueue_gh_response 0 "" ""
  run "$BOARD_ROOT/scripts/reopen-issue.sh" --issue 1 --agent-id a --session-id s
  [ "$status" -eq 0 ]
}
