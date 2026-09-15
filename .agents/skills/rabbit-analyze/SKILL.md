---
name: rabbit-analyze
description: Turn an ingested Rabbit Wiki source asset into a structured wiki entry and grow the ontology. Use when the user wants to analyze an already-ingested asset (from /rabbit-ingest) into meta/rabbit-wiki/wiki/ and meta/rabbit-wiki/ontology.yaml.
license: MIT
---

# Rabbit Analyze

Analyze step of the Rabbit Wiki lifecycle. Reads an ingested source asset's converted Markdown,
drafts or updates one wiki entry summarizing its key terms and concepts, and extends the
ontology with any new concepts, categories, or typed relations the asset introduces.

## When to Use

- "Analyze this ingested asset into the Rabbit Wiki."
- "Turn `{slug}` into a wiki entry."
- Near miss: the asset has not been ingested yet — use `rabbit-ingest` first.

## Steps

1. Resolve the target slug (given directly, or resolvable from context/description) identifying
   a folder under `meta/rabbit-wiki/sources/`.
2. Require `meta/rabbit-wiki/sources/{slug}/transformed.md` to exist. If it does not, report the
   missing prerequisite back to the user and stop — never fabricate a wiki entry from partial or
   absent data (Edge Cases in spec.md).
3. Read `meta/rabbit-wiki/sources/{slug}/transformed.md` and the current
   `meta/rabbit-wiki/ontology.yaml` (create it with an empty `concepts: []`, `relations: []`,
   `categories: []` skeleton first if it does not yet exist).
4. Identify the asset's key terms/concepts and how they relate to existing ontology entries.
5. Write or update `meta/rabbit-wiki/wiki/{slug}.md` in place (never create a duplicate page for
   an already-analyzed slug — re-running this skill for the same slug MUST update the existing
   file). Every write or in-place update MUST begin with a YAML frontmatter block (data-model.md
   Wiki Entry Frontmatter, FR-007a) before the body sections:
   - Required fields, always set/refreshed on every write:
     - `type` — entry kind (e.g. `concept`, `decision`); preserve the existing value on an
       in-place update unless the asset clearly changes the entry's kind.
     - `authored_by` — always `rabbit-analyze`.
     - `confidence` — enum `high`|`medium`|`low`, this skill's confidence in the entry given its
       source material.
     - `last_verified` — today's date (`YYYY-MM-DD`); refresh this on every in-place update even
       when no other field changes.
   - Optional fields, include only when derivable from the source asset (omit otherwise; do not
     fabricate values):
     - `source_type` — e.g. `document`, `recording`, `url`, `conversation`.
     - `source_ref` — path/slug of `meta/rabbit-wiki/sources/{slug}/`.
     - `tags` — free-form topical tags.
     - `scope` — bounding context narrower than the whole wiki, if applicable.
     - `related` — slugs of related `wiki/*.md` entries.
   - After the frontmatter, the entry body MUST contain, at minimum:
     - **Term/Concept** — the identifier/title of the entry.
     - **Definition** — a concise explanation.
     - **Ontology links** — references to related `ontology.yaml` concept ids.
     - **Source anchor** — a link back to `meta/rabbit-wiki/sources/{slug}/`.
     - **Related entries** — links to other `wiki/*.md` pages.
   - This step never writes to `meta/rabbit-wiki/ontology.yaml` or `docs/context/index.yaml`;
     ontology updates happen only in step 6 below.
6. Update `meta/rabbit-wiki/ontology.yaml`:
   - Add a new `concepts`/`categories`/`relations` entry only when it does not already exist by
     `id`.
   - When a concept already exists, append this asset's slug to its `sources` list instead of
     creating a duplicate entry.
   - Never remove existing ontology entries.
7. Never write to `docs/product/glossary.md` or anything under `docs/context/` from this skill.
8. Report the wiki entry path and a summary of ontology additions back to the user.

## Completion Report

Return: the `meta/rabbit-wiki/wiki/{slug}.md` path, the frontmatter fields set/refreshed on this
write, a summary of new/updated ontology entries, and confirmation that the glossary was not
touched.
