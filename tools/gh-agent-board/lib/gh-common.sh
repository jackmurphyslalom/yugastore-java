#!/usr/bin/env bash
# Shared gh CLI invocation wrapper: runs `gh` and captures its exit code/stdout/stderr for callers.

# Runs `gh "$@"` and stores the result in GH_RUN_EXIT_CODE/GH_RUN_STDOUT/GH_RUN_STDERR.
# Never lets gh's exit code propagate directly, so callers under `set -e` can inspect it first.
gh_common_run() {
  local gh_bin="${GH_BIN:-gh}"
  local stdout_file stderr_file
  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"

  GH_RUN_EXIT_CODE=0
  "$gh_bin" "$@" >"$stdout_file" 2>"$stderr_file" || GH_RUN_EXIT_CODE=$?

  GH_RUN_STDOUT="$(cat "$stdout_file")"
  GH_RUN_STDERR="$(cat "$stderr_file")"
  rm -f "$stdout_file" "$stderr_file"

  export GH_RUN_EXIT_CODE GH_RUN_STDOUT GH_RUN_STDERR
  return 0
}
