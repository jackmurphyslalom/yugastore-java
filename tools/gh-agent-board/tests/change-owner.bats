#!/usr/bin/env bats
# Tests for scripts/change-owner.sh (FR-004/005), shared by change-owner and reassign prompts.

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/change-owner.sh"
}

@test "a valid ticket + valid new owner succeeds and logs one succeeded change_owner entry" {
  enqueue_gh_response 0 '{"number":42,"assignees":[{"login":"octocat"}]}' ""
  enqueue_gh_response 0 "" ""

  run "$SCRIPT" --issue 42 --new-owner monalisa --agent-id a --session-id s
  [ "$status" -eq 0 ]
  [ "$(jq -r '.issue_number' <<<"$output")" = "42" ]
  [ "$(jq -r '.previous_assignees[0]' <<<"$output")" = "octocat" ]
  [ "$(jq -r '.new_owner' <<<"$output")" = "monalisa" ]
  [ "$(jq -r '.action' "$AUDIT_LOG_FILE")" = "change_owner" ]
  [ "$(jq -r '.result' "$AUDIT_LOG_FILE")" = "succeeded" ]
  [[ "$(cat "$GH_STUB_LOG")" == *"--remove-assignee octocat"* ]]
}

@test "a ticket with no previous assignees omits --remove-assignee" {
  enqueue_gh_response 0 '{"number":42,"assignees":[]}' ""
  enqueue_gh_response 0 "" ""

  run "$SCRIPT" --issue 42 --new-owner monalisa --agent-id a --session-id s
  [ "$status" -eq 0 ]
  [[ "$(cat "$GH_STUB_LOG")" != *"--remove-assignee"* ]]
}

@test "a not-found ticket exits 1 with a failed change_owner audit entry" {
  enqueue_gh_response 1 "" "no issues found"

  run "$SCRIPT" --issue 999 --new-owner monalisa --agent-id a --session-id s
  [ "$status" -eq 1 ]
  [ "$(jq -r '.action' "$AUDIT_LOG_FILE")" = "change_owner" ]
  [ "$(jq -r '.result' "$AUDIT_LOG_FILE")" = "failed" ]
  [ "$(jq -r '.reason' "$AUDIT_LOG_FILE")" = "ticket not found" ]
}

@test "a gh issue edit failure exits 1 with a failed audit entry and no partial change" {
  enqueue_gh_response 0 '{"number":42,"assignees":[{"login":"octocat"}]}' ""
  enqueue_gh_response 1 "" "could not add assignee: 'not-a-collaborator' not found"

  run "$SCRIPT" --issue 42 --new-owner not-a-collaborator --agent-id a --session-id s
  [ "$status" -eq 1 ]
  [ "$(jq -r '.result' "$AUDIT_LOG_FILE")" = "failed" ]
}

@test "an invalid --issue shape exits 2 with no gh call and no audit entry" {
  run "$SCRIPT" --issue not-a-number --new-owner monalisa --agent-id a --session-id s
  [ "$status" -eq 2 ]
  [ ! -s "$GH_STUB_LOG" ]
  [ ! -f "$AUDIT_LOG_FILE" ]
}

@test "an empty --new-owner exits 2 with no gh call and no audit entry" {
  run "$SCRIPT" --issue 42 --new-owner "" --agent-id a --session-id s
  [ "$status" -eq 2 ]
  [ ! -s "$GH_STUB_LOG" ]
  [ ! -f "$AUDIT_LOG_FILE" ]
}
