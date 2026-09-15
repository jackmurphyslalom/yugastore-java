---
name: rabbit-ingest
description: Ingest a source asset from pending_imports/ into a permanent, uniquely-slugged, non-destructive record under meta/rabbit-wiki/sources/. Use when the user wants to capture a new document, recording, or webpage into the Rabbit Wiki lifecycle before it is analyzed, queried, or linted.
license: MIT
---

# Rabbit Ingest

Capture step of the Rabbit Wiki lifecycle (Karpathy's "LLM Wiki" pattern). Converts a source
asset to Markdown and archives it permanently under `meta/rabbit-wiki/sources/{slug}/`, without
deciding yet what the content means — that is `/rabbit-analyze`'s job.

## When to Use

- "Ingest this file from `pending_imports/` into the Rabbit Wiki."
- "Capture this document/recording/webpage as a new Rabbit Wiki source asset."
- Near miss: the caller wants a one-off Markdown archive under `docs/context/sources/` with no
  Rabbit Wiki lifecycle involved — use `rabbit-archive-to-markdown` directly instead.

## Steps

1. Create `pending_imports/` at the repo root if it does not exist, and create
   `meta/rabbit-wiki/` if it does not exist. Do not create `meta/rabbit-wiki/wiki/` or
   `ontology.yaml` here — those belong to the Foundational scaffold or `/rabbit-analyze`.
2. Resolve the input reference (a path within `pending_imports/`, an absolute file path, or a
   URL), following the same input-resolution and repo-root-escape rejection rules as
   `.agents/skills/rabbit-archive-to-markdown/SKILL.md` step 1.
3. Convert the source to Markdown twice, reusing
   `.agents/skills/rabbit-archive-to-markdown/SKILL.md`'s conversion mechanics (step 2) without
   modifying that skill:
   - Produce `raw.md`: the direct, unedited conversion output.
   - Produce `transformed.md`: the same content, ready for `/rabbit-analyze` to read (may be
     identical to `raw.md` when no further transformation is needed).
4. Derive the slug `{YYYY-MM-DD}-{kebab-title}`:
   - Prefer a kebab-case title derived from the source's own title/heading content.
   - When no usable title can be extracted, fall back to a kebab-cased version of the original
     filename (Edge Cases in spec.md).
5. Check `meta/rabbit-wiki/sources/` for an existing folder with that exact slug. On collision,
   append a numeric suffix (`-2`, `-3`, ...) until the slug is unique. Never overwrite an
   existing `{slug}/` folder.
6. Create `meta/rabbit-wiki/sources/{slug}/` and write all three files:
   - `original.{ext}` — the source file content, extension preserved.
   - `transformed.md`
   - `raw.md`
   `pending_imports/` is a transient intake staging area, not a second permanent home for the
   asset — `meta/rabbit-wiki/sources/{slug}/original.{ext}` is the one permanent, immutable copy
   once ingestion completes (never overwritten by later steps):
   - If the input reference was a file inside `pending_imports/`, **move** it: write
     `original.{ext}` from its content, then delete the file from `pending_imports/`. Do not
     leave a duplicate copy behind in `pending_imports/`.
   - If the input reference was an absolute file path outside `pending_imports/` or a URL, the
     file is not staged intake we own — write `original.{ext}` as a copy and leave the source
     location untouched (never delete or mutate a file outside `pending_imports/`).
7. Report the assigned slug and the new folder path back to the user.

## Completion Report

Return: the assigned slug, the `meta/rabbit-wiki/sources/{slug}/` path, and confirmation of
whether the `pending_imports/` staging file was removed (moved in) or the input was left in
place (external path/URL).
