---
name: rabbit-session-close
description: Explicitly fold already-drafted session material into meta/rabbit-wiki/ontology.yaml and wiki entries. Use only when the user explicitly asks to close out or persist the current session's Rabbit Wiki drafts — never trigger this automatically from any other /rabbit-* skill or workflow.
license: MIT
---

# Rabbit Session Close

Explicit reconciliation step of the Rabbit Wiki lifecycle. Persists wiki/ontology material
already drafted conversationally during the current session. This skill MUST run only on
standalone, explicit user invocation, and MUST NOT be referenced or triggered from
`rabbit-ingest`, `rabbit-analyze`, `rabbit-query`, or `rabbit-lint`.

## When to Use

- "Close out this session's Rabbit Wiki updates."
- "Persist what we drafted into the wiki/ontology."
- Never invoke this skill automatically as a side effect of any other `/rabbit-*` command.

## Steps

1. Identify material already drafted conversationally during the current session (proposed
   wiki entries, ontology concepts/relations/categories, or corrections) that has not yet been
   persisted via `/rabbit-analyze` or a prior `/rabbit-session-close`.
2. If no such drafted material exists, report "nothing to close" and make no file changes
   (Acceptance Scenario 2, User Story 5) — stop here.
3. Perform no new research, web lookups, or fresh source ingestion. Operate only on material
   already drafted in this session (FR-010).
4. Update `meta/rabbit-wiki/ontology.yaml` with only the drafted concepts/categories/relations,
   following the same never-duplicate-by-`id`, append-`sources`-on-match rules as
   `/rabbit-analyze`.
5. Update the affected `meta/rabbit-wiki/wiki/{slug}.md` entries with only the drafted content,
   in place (no duplicates).
6. Report a summary of exactly what was persisted.

## Completion Report

Return: a summary of the ontology/wiki changes persisted (or an explicit "nothing to close"
statement when no drafted material existed).

## Invocation Constraint

This skill MUST NOT be referenced, invoked, or triggered automatically by
`rabbit-ingest/SKILL.md`, `rabbit-analyze/SKILL.md`, `rabbit-query/SKILL.md`, or
`rabbit-lint/SKILL.md`. It runs only when the user explicitly invokes it directly.
