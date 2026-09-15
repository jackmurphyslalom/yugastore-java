#!/usr/bin/env bash
# Resolves a ticket (Issue) number to its Projects v2 item id + current Status/Priority/assignees
# (FR-002/003/006/009). Sourced by view-ticket.sh, update-ticket.sh, and retire-ticket.sh.

_board_item_lib_dir() {
  cd "$(dirname "${BASH_SOURCE[0]}")" && pwd
}

BOARD_ITEM_LIB_DIR="$(_board_item_lib_dir)"
BOARD_ITEM_ROOT="$(cd "$BOARD_ITEM_LIB_DIR/.." && pwd)"

# board_item_resolve --issue <number>
#
# On success (return 0), exports BOARD_ITEM_ID, BOARD_ITEM_TITLE, BOARD_ITEM_ASSIGNEES (JSON array
# string), BOARD_ITEM_STATUS, and BOARD_ITEM_PRIORITY (empty string if unset).
# On invalid --issue shape, returns 2 before any gh call.
# On not-found, sets BOARD_ITEM_NOT_FOUND=1 and returns 1, with no further gh calls.
# On any other resolution failure (e.g. gh project item-list failing, or no matching board item),
# returns 1 without setting BOARD_ITEM_NOT_FOUND, so callers can distinguish the two cases.
board_item_resolve() {
  local issue=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --issue) issue="$2"; shift 2 ;;
      *) echo "board_item_resolve: unknown argument: $1" >&2; return 2 ;;
    esac
  done

  BOARD_ITEM_NOT_FOUND=0
  export BOARD_ITEM_NOT_FOUND

  if ! [[ "$issue" =~ ^[0-9]+$ ]] || [[ "$issue" -eq 0 ]]; then
    echo "board_item_resolve: --issue must be a positive integer" >&2
    return 2
  fi

  gh_common_run issue view "$issue" --json number,title,assignees
  if [[ "$GH_RUN_EXIT_CODE" -ne 0 ]]; then
    BOARD_ITEM_NOT_FOUND=1
    export BOARD_ITEM_NOT_FOUND
    return 1
  fi

  local issue_title issue_assignees
  issue_title="$(jq -r '.title' <<<"$GH_RUN_STDOUT")"
  issue_assignees="$(jq -c '[.assignees[].login]' <<<"$GH_RUN_STDOUT")"

  local board_config project_number owner
  board_config="${BOARD_CONFIG:-$BOARD_ITEM_ROOT/config/board.json}"
  project_number="$(jq -r '.project_number' "$board_config")"
  owner="$(jq -r '.owner' "$board_config")"

  gh_common_run project item-list "$project_number" --owner "$owner" --format json
  if [[ "$GH_RUN_EXIT_CODE" -ne 0 ]]; then
    echo "board_item_resolve: gh project item-list failed: $GH_RUN_STDERR" >&2
    return 1
  fi

  local item
  item="$(jq -c --argjson n "$issue" '[.items[] | select(.content.number == $n)] | .[0] // empty' <<<"$GH_RUN_STDOUT")"
  if [[ -z "$item" ]]; then
    echo "board_item_resolve: issue #$issue has no matching board item" >&2
    return 1
  fi

  BOARD_ITEM_ID="$(jq -r '.id' <<<"$item")"
  BOARD_ITEM_TITLE="$issue_title"
  BOARD_ITEM_ASSIGNEES="$issue_assignees"
  BOARD_ITEM_STATUS="$(jq -r '.status // empty' <<<"$item")"
  BOARD_ITEM_PRIORITY="$(jq -r '.priority // empty' <<<"$item")"

  export BOARD_ITEM_ID BOARD_ITEM_TITLE BOARD_ITEM_ASSIGNEES BOARD_ITEM_STATUS BOARD_ITEM_PRIORITY
  return 0
}
