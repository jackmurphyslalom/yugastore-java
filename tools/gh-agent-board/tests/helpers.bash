#!/usr/bin/env bash
# Shared bats test setup: puts a stubbed `gh` on PATH and provides a response-queue helper.

setup_gh_stub() {
  export GH_STUB_DIR="$BATS_TEST_TMPDIR/gh-stub-bin"
  mkdir -p "$GH_STUB_DIR"
  cp "$BOARD_ROOT/tests/fixtures/gh-stub" "$GH_STUB_DIR/gh"
  chmod +x "$GH_STUB_DIR/gh"
  export PATH="$GH_STUB_DIR:$PATH"

  export GH_STUB_LOG="$BATS_TEST_TMPDIR/gh-stub.log"
  export GH_STUB_QUEUE="$BATS_TEST_TMPDIR/gh-stub.queue"
  : > "$GH_STUB_LOG"
  : > "$GH_STUB_QUEUE"
}

# enqueue_gh_response <exit_code> <stdout> [<stderr>]
enqueue_gh_response() {
  local exit_code="$1" stdout="$2" stderr="${3:-}"
  jq -nc --argjson exit_code "$exit_code" --arg stdout "$stdout" --arg stderr "$stderr" \
    '{exit_code: $exit_code, stdout: $stdout, stderr: $stderr}' >> "$GH_STUB_QUEUE"
}
