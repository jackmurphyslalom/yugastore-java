#!/usr/bin/env bats
# Tests for scripts/retire-ticket.sh (FR-009). Never calls gh issue close.

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/retire-ticket.sh"
}

@test "a valid ticket + --outcome done succeeds, maps to Status Done, and prints the close reminder" {
  enqueue_gh_response 0 '{"number":42,"title":"Fix the thing","assignees":[]}' ""
  enqueue_gh_response 0 '{"items":[{"id":"ITEM_1","content":{"number":42},"status":"In Progress","priority":null}]}' ""
  enqueue_gh_response 0 "" ""

  run "$SCRIPT" --issue 42 --outcome done --agent-id a --session-id s
  [ "$status" -eq 0 ]
  json_line="$(tail -n1 <<<"$output")"
  [ "$(jq -r '.issue_number' <<<"$json_line")" = "42" ]
  [ "$(jq -r '.status' <<<"$json_line")" = "Done" ]
  [[ "$output" == *"remains open"* ]]
  [ "$(wc -l < "$AUDIT_LOG_FILE" | tr -d ' ')" -eq 1 ]
  [ "$(jq -r '.action' "$AUDIT_LOG_FILE")" = "set_field" ]
}

@test "--outcome wont-fix propagates set-field.sh's field-not-configured failure unchanged" {
  enqueue_gh_response 0 '{"number":42,"title":"Fix the thing","assignees":[]}' ""
  enqueue_gh_response 0 '{"items":[{"id":"ITEM_1","content":{"number":42},"status":"In Progress","priority":null}]}' ""

  run "$SCRIPT" --issue 42 --outcome wont-fix --agent-id a --session-id s
  [ "$status" -eq 2 ]
  [ "$(jq -r '.reason' "$AUDIT_LOG_FILE")" = "field not configured" ]
}

@test "a not-found ticket exits 1 with no mutation" {
  enqueue_gh_response 1 "" "no issues found"

  run "$SCRIPT" --issue 999 --outcome done --agent-id a --session-id s
  [ "$status" -eq 1 ]
  [ ! -f "$AUDIT_LOG_FILE" ]
}

@test "an invalid --issue shape exits 2 with no gh call" {
  run "$SCRIPT" --issue not-a-number --outcome done --agent-id a --session-id s
  [ "$status" -eq 2 ]
  [ ! -s "$GH_STUB_LOG" ]
}

@test "an unsupported --outcome value exits 2 with no gh call" {
  run "$SCRIPT" --issue 42 --outcome cancelled --agent-id a --session-id s
  [ "$status" -eq 2 ]
  [ ! -s "$GH_STUB_LOG" ]
}

@test "never invokes gh issue close" {
  run bash -c "grep -l 'issue close' '$BOARD_ROOT/scripts/retire-ticket.sh'"
  [ "$status" -ne 0 ]
}
