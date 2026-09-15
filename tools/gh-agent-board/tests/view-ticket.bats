#!/usr/bin/env bats
# Tests for scripts/view-ticket.sh (FR-002/006). Read-only — writes no audit entry.

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/view-ticket.sh"
}

@test "an existing ticket prints the documented JSON shape and exits 0" {
  enqueue_gh_response 0 '{"number":42,"title":"Fix the thing","assignees":[{"login":"octocat"}]}' ""
  enqueue_gh_response 0 '{"items":[{"id":"ITEM_1","content":{"number":42},"status":"In Progress","priority":"P1"}]}' ""

  run "$SCRIPT" --issue 42
  [ "$status" -eq 0 ]
  [ "$(jq -r '.issue_number' <<<"$output")" = "42" ]
  [ "$(jq -r '.title' <<<"$output")" = "Fix the thing" ]
  [ "$(jq -r '.status' <<<"$output")" = "In Progress" ]
  [ "$(jq -r '.priority' <<<"$output")" = "P1" ]
  [ "$(jq -r '.assignees[0]' <<<"$output")" = "octocat" ]
  [ ! -f "$AUDIT_LOG_FILE" ]
}

@test "a ticket with unset Status/Priority prints null for those fields" {
  enqueue_gh_response 0 '{"number":42,"title":"Fix the thing","assignees":[]}' ""
  enqueue_gh_response 0 '{"items":[{"id":"ITEM_1","content":{"number":42},"status":null,"priority":null}]}' ""

  run "$SCRIPT" --issue 42
  [ "$status" -eq 0 ]
  [ "$(jq -r '.status' <<<"$output")" = "null" ]
  [ "$(jq -r '.priority' <<<"$output")" = "null" ]
  [ "$(jq -c '.assignees' <<<"$output")" = "[]" ]
  [ ! -f "$AUDIT_LOG_FILE" ]
}

@test "a not-found ticket exits 1 with a clear stderr message and no output JSON" {
  enqueue_gh_response 1 "" "no issues found"

  run "$SCRIPT" --issue 999
  [ "$status" -eq 1 ]
  [[ "$output" == *"not found"* ]]
  [ ! -f "$AUDIT_LOG_FILE" ]
}

@test "an invalid --issue shape exits 2 with no gh call" {
  run "$SCRIPT" --issue not-a-number
  [ "$status" -eq 2 ]
  [ ! -s "$GH_STUB_LOG" ]
  [ ! -f "$AUDIT_LOG_FILE" ]
}
