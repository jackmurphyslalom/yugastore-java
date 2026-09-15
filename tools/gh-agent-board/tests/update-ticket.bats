#!/usr/bin/env bats
# Tests for scripts/update-ticket.sh (FR-003). Delegates the write + audit entry to set-field.sh.

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
  SCRIPT="$BOARD_ROOT/scripts/update-ticket.sh"
}

@test "a valid ticket + supported Status value succeeds and delegates one audit entry to set-field.sh" {
  enqueue_gh_response 0 '{"number":42,"title":"Fix the thing","assignees":[]}' ""
  enqueue_gh_response 0 '{"items":[{"id":"ITEM_1","content":{"number":42},"status":"Todo","priority":null}]}' ""
  enqueue_gh_response 0 "" ""

  run "$SCRIPT" --issue 42 --field Status --value "In Progress" --agent-id a --session-id s
  [ "$status" -eq 0 ]
  [ "$(jq -r '.issue_number' <<<"$output")" = "42" ]
  [ "$(jq -r '.field' <<<"$output")" = "Status" ]
  [ "$(jq -r '.previous_value' <<<"$output")" = "Todo" ]
  [ "$(jq -r '.new_value' <<<"$output")" = "In Progress" ]
  [ "$(wc -l < "$AUDIT_LOG_FILE" | tr -d ' ')" -eq 1 ]
  [ "$(jq -r '.action' "$AUDIT_LOG_FILE")" = "set_field" ]
}

@test "an unsupported field/value propagates set-field.sh's exit 2 with no additional audit entry" {
  enqueue_gh_response 0 '{"number":42,"title":"Fix the thing","assignees":[]}' ""
  enqueue_gh_response 0 '{"items":[{"id":"ITEM_1","content":{"number":42},"status":"Todo","priority":null}]}' ""

  run "$SCRIPT" --issue 42 --field Status --value "Not A Real Status" --agent-id a --session-id s
  [ "$status" -eq 2 ]
  [ "$(wc -l < "$AUDIT_LOG_FILE" | tr -d ' ')" -eq 1 ]
  [ "$(jq -r '.reason' "$AUDIT_LOG_FILE")" = "field not configured" ]
}

@test "a not-found ticket exits 1 with no gh mutation attempted and no audit entry" {
  enqueue_gh_response 1 "" "no issues found"

  run "$SCRIPT" --issue 999 --field Status --value Done --agent-id a --session-id s
  [ "$status" -eq 1 ]
  [ ! -f "$AUDIT_LOG_FILE" ]
}

@test "an invalid --issue shape exits 2 with no gh call" {
  run "$SCRIPT" --issue not-a-number --field Status --value Done --agent-id a --session-id s
  [ "$status" -eq 2 ]
  [ ! -s "$GH_STUB_LOG" ]
  [ ! -f "$AUDIT_LOG_FILE" ]
}
