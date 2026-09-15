#!/usr/bin/env bats
# Tests for lib/gh-common.sh: gh's exit code and stderr must be captured, not propagated raw.

setup() {
  BOARD_ROOT="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
  source "$BOARD_ROOT/tests/helpers.bash"
  setup_gh_stub
  source "$BOARD_ROOT/lib/gh-common.sh"
}

@test "captures stdout and a zero exit code on success" {
  enqueue_gh_response 0 '{"number":1}' ""
  gh_common_run issue create --title "x"
  [ "$GH_RUN_EXIT_CODE" -eq 0 ]
  [ "$GH_RUN_STDOUT" = '{"number":1}' ]
}

@test "captures a nonzero exit code and stderr on failure, without raising under set -e" {
  enqueue_gh_response 1 "" "boom"
  gh_common_run issue create --title "x"
  [ "$GH_RUN_EXIT_CODE" -eq 1 ]
  [ "$GH_RUN_STDERR" = "boom" ]
}

@test "records the exact arguments gh was invoked with" {
  enqueue_gh_response 0 "" ""
  gh_common_run issue create --title "hello world"
  run cat "$GH_STUB_LOG"
  [[ "$output" == *"issue create --title hello world"* ]]
}
