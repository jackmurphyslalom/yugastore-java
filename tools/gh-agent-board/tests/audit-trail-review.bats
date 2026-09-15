#!/usr/bin/env bats
# Confirms a multi-action sequence is reconstructable from the audit log by session_id (SC-002/SC-003).

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  export AUDIT_LOG_FILE="$BATS_TEST_TMPDIR/agent-actions.jsonl"
}

@test "create-issue, set-field, and open-pr for one session are reconstructable in order via jq" {
  enqueue_gh_response 0 'https://github.com/o/r/issues/42' ""
  enqueue_gh_response 0 '{"id":"ITEM_1"}' ""
  run "$BOARD_ROOT/scripts/create-issue.sh" --title "Feature" --agent-id a --session-id local-1
  [ "$status" -eq 0 ]

  enqueue_gh_response 0 "" ""
  run "$BOARD_ROOT/scripts/set-field.sh" --item-id ITEM_1 --field Status --value "In Progress" --agent-id a --session-id local-1
  [ "$status" -eq 0 ]

  enqueue_gh_response 0 'https://github.com/o/r/pull/7' ""
  run "$BOARD_ROOT/scripts/open-pr.sh" --issue 42 --title "PR" --base main --head feature --agent-id a --session-id local-1
  [ "$status" -eq 0 ]

  actions="$(jq -r 'select(.session_id == "local-1") | .action' "$AUDIT_LOG_FILE" | tr '\n' ',')"
  [ "$actions" = "create_issue,set_field,open_pr," ]
}
