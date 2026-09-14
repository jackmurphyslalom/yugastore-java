# Pull Request Readiness

Prepare a complete, read-only handoff before a provider pull request is created.

## 1. Establish the Comparison Base

Resolve one base ref in this order:

1. **Explicit `ready` input**: use it only after `git rev-parse --verify` succeeds.
2. **Configured upstream**: use the current branch's `@{upstream}` when it resolves.
3. **Provider/default remote HEAD**: use a provider-reported default branch or
   `refs/remotes/<remote>/HEAD` only when it resolves to a remote-tracking ref.
4. **Existing `main` or `master`**: use an existing local or remote ref, preferring the selected
   remote.
5. **Pause**: report verified candidates and ask the user to select one.

If an explicit ref does not verify, stop immediately. Do not fall through to another candidate.
Record the rejected ref, an empty fallback list, and `INVALID_COMPARISON_BASE`.

Do not assume that a non-default branch without an upstream tracks the remote default branch.
Record the selected ref, selection reason, remote when applicable, and rejected candidates. Run
`git merge-base <base-ref> HEAD`; stop when the ref is ambiguous or no merge-base exists.

## 2. Compute the Complete Change Scope

Collect each source separately:

| Source | Evidence |
| --- | --- |
| committed | `git log <merge-base>..HEAD` and `git diff --name-status <merge-base>..HEAD` |
| staged | `git diff --cached --name-status` |
| unstaged | `git diff --name-status` |
| untracked | `git ls-files --others --exclude-standard` |

Use `git diff <merge-base>` for the complete tracked working-tree review while retaining the source
labels above. Validate every untracked path against the repository root before reading it. Disclose
generated, ignored, binary, secret-like, or unusually large files without inferring their contents;
request direction only when their contents are required.

Report an empty scope only when committed, staged, unstaged, and untracked sources are all empty.

## 3. Ground the Handoff

Use `docs/context/routing-map.md` and `docs/context/index.yaml` for exact-file routing. Prefer an
explicit spec path, then the active feature recorded by `.specify/feature.json`, then a matching
feature under `specs/`. Read only changed files, routed standards, and the active feature's
`spec.md`, `plan.md`, and `tasks.md`.

Record:

- intended behavior and user-visible impact;
- changed interfaces, configuration, migrations, and operational concerns;
- tests already run and evidence still required;
- unresolved risks and decisions.

If the Spec source is missing or ambiguous, the Spec axis is incomplete. Do not report `ready`.

## 4. Produce the Readiness Report

After completing the Standards and Spec reviews in `local-review.md`, return:

1. selected base, merge-base, and resolution reason;
2. committed, staged, unstaged, and untracked inventories;
3. separate Standards and Spec reports with per-axis finding counts;
4. tests run, tests still required, and known gaps;
5. draft PR title, summary, and review focus;
6. one outcome:
   - `ready`: no confirmed documented-standard or Spec defects;
   - `changes-requested`: at least one confirmed documented-standard or Spec defect;
   - `incomplete`: required scope or Spec evidence could not be established;
7. a statement that no external write was made.

Advisory smell findings alone do not change `ready` to `changes-requested`. After changes are made,
rerun readiness against the same selected base.
