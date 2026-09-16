---
name: rabbit-lint
description: Report Rabbit Wiki health issues (contradictions, staleness, orphans, missing pages, missing cross-references, frontmatter gaps, data gaps) without modifying anything or performing web searches. Use when the user asks for a Rabbit Wiki health check.
license: MIT
---

# Rabbit Lint

Lint step of the Rabbit Wiki lifecycle. A read-only maintenance safeguard: scans
`meta/rabbit-wiki/wiki/` and reports findings for a human to act on. Never fixes anything and
never performs the web searches it flags as gaps.

## When to Use

- "Check the Rabbit Wiki's health."
- "Lint the wiki for issues."
- Near miss: the user wants a finding fixed automatically — report it instead; do not fix it or
  invoke any other skill from here.

## Steps

1. Scan `meta/rabbit-wiki/wiki/` (read-only) and `meta/rabbit-wiki/ontology.yaml` for the
   following finding categories, per data-model.md's Lint Finding shape:
   - **Contradiction** — two or more pages making conflicting claims about the same concept.
   - **Stale claim** — a claim sourced from an asset that appears superseded by a newer,
     contradicting source.
   - **Orphan page** — a page with no inbound links from any other page or ontology entry.
   - **Missing page candidate** — a concept mentioned across pages with no dedicated entry.
   - **Missing cross-reference** — related pages that do not link to each other.
   - **Data gap** — something a web search could fill in, reported only.
   - **Frontmatter gap** — a `wiki/*.md` entry missing any of the 4 required frontmatter fields
     (`type`, `authored_by`, `confidence`, `last_verified`) (data-model.md Wiki Entry Frontmatter,
     FR-007a). Read-only: report each such page by name; never add or fix the missing field.
2. For each finding, name the specific page(s) it concerns.
3. Do not auto-fix any finding, and do not perform the web searches a data-gap finding
   identifies — report them for human follow-up instead (FR-015).
4. Do not edit any wiki page, source file, or `meta/rabbit-wiki/ontology.yaml` — this skill is
   strictly read-only.
5. Present the findings grouped by category.

## Completion Report

Return: the findings report, grouped by category, each naming the specific page(s) involved, and
confirmation that no files were modified.
