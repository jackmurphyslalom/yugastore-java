#!/usr/bin/env bats
# Tests for lib/board-item.sh: resolves a ticket number to its board item id + fields.

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  source "$BOARD_ROOT/lib/gh-common.sh"
  source "$BOARD_ROOT/lib/board-item.sh"
  export BOARD_CONFIG="$BATS_TEST_TMPDIR/board.json"
  cat > "$BOARD_CONFIG" <<'JSON'
{
  "project_id": "PROJECT_NODE_1",
  "project_number": 7,
  "owner": "@me",
  "fields": {
    "Status": {"field_id": "F_STATUS", "options": {"Todo": "O_TODO", "Done": "O_DONE"}},
    "Priority": {"field_id": "F_PRIORITY", "options": {"P0": "O_P0", "P1": "O_P1"}}
  }
}
JSON
}

@test "a valid ticket resolves all exported vars" {
  enqueue_gh_response 0 '{"number":42,"title":"Fix the thing","assignees":[{"login":"octocat"}]}' ""
  enqueue_gh_response 0 '{"items":[{"id":"ITEM_1","content":{"number":42},"status":"In Progress","priority":"P1"}]}' ""

  board_item_resolve --issue 42
  status=$?

  [ "$status" -eq 0 ]
  [ "$BOARD_ITEM_ID" = "ITEM_1" ]
  [ "$BOARD_ITEM_TITLE" = "Fix the thing" ]
  [ "$BOARD_ITEM_ASSIGNEES" = '["octocat"]' ]
  [ "$BOARD_ITEM_STATUS" = "In Progress" ]
  [ "$BOARD_ITEM_PRIORITY" = "P1" ]
}

@test "an invalid --issue shape exits 2 with no gh call" {
  set +e
  board_item_resolve --issue not-a-number
  status=$?
  set -e

  [ "$status" -eq 2 ]
  [ ! -s "$GH_STUB_LOG" ]
}

@test "a blank --issue exits 2 with no gh call" {
  set +e
  board_item_resolve --issue ""
  status=$?
  set -e

  [ "$status" -eq 2 ]
  [ ! -s "$GH_STUB_LOG" ]
}

@test "a negative --issue exits 2 with no gh call" {
  set +e
  board_item_resolve --issue -5
  status=$?
  set -e

  [ "$status" -eq 2 ]
  [ ! -s "$GH_STUB_LOG" ]
}

@test "issue not found sets BOARD_ITEM_NOT_FOUND=1 and returns 1" {
  enqueue_gh_response 1 "" "no issues found"

  set +e
  board_item_resolve --issue 999
  status=$?
  set -e

  [ "$status" -eq 1 ]
  [ "$BOARD_ITEM_NOT_FOUND" -eq 1 ]
}

@test "gh issue view succeeds but item-list failing is reported distinctly from not-found" {
  enqueue_gh_response 0 '{"number":42,"title":"Fix the thing","assignees":[]}' ""
  enqueue_gh_response 1 "" "gh: project item-list failed"

  set +e
  board_item_resolve --issue 42
  status=$?
  set -e

  [ "$status" -eq 1 ]
  [ "$BOARD_ITEM_NOT_FOUND" -eq 0 ]
}

@test "gh issue view succeeds but the issue has no matching board item is reported distinctly from not-found" {
  enqueue_gh_response 0 '{"number":42,"title":"Fix the thing","assignees":[]}' ""
  enqueue_gh_response 0 '{"items":[{"id":"ITEM_OTHER","content":{"number":7},"status":"Todo","priority":null}]}' ""

  set +e
  board_item_resolve --issue 42
  status=$?
  set -e

  [ "$status" -eq 1 ]
  [ "$BOARD_ITEM_NOT_FOUND" -eq 0 ]
}
