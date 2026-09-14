---
name: rm-archive-to-markdown
description: Quickly convert a local file, URL, or document into a Markdown copy stored under docs/context/sources/ for future reference. Use when the user wants to archive a document, recording, image, or webpage as searchable Markdown without doing full knowledge extraction or distillation.
license: MIT
---

# Archive to Markdown

Convert a source into a durable Markdown copy so its content is greppable and reusable later, without deciding yet what it means. This is lighter-weight than `aisdlc-knowledge-ingestion`: it preserves the full source content and adds no distilled facts, decisions, or index entries.

## When to Use

- "Convert this doc/PDF/recording/webpage to Markdown and keep it for later."
- "Archive this file so we can search it/reference it going forward."
- Near miss: the caller wants facts or decisions extracted into project docs (`docs/decisions/`, `docs/context/gaps.md`, product/architecture docs) — use `aisdlc-knowledge-ingestion` instead. That skill can consume the archive this skill produces as its source.

## Steps

1. Resolve the input reference (absolute file path, `file://` URI, or `http(s)://` URL). Reject a destination that would escape the repository root through `..`, an absolute path override, or a symlink.
2. Convert the source to Markdown:
   - Local file (docx, pdf, pptx, xlsx, image, or similar): use the Markdown-conversion tool available in this environment.
   - URL: fetch it and convert its main content to Markdown.
3. Derive a stable output filename: `docs/context/sources/{YYYY-MM-DD}-{slug}.md`, where `{slug}` is a short kebab-case name from the source title or filename. Create `docs/context/sources/` if it does not exist.
4. Prepend frontmatter to the output file:
   ```yaml
   ---
   source: <original path or URL>
   source_type: <docx|pdf|pptx|url|image|other>
   retrieved: <YYYY-MM-DD>
   original_filename: <name, if a local file>
   ---
   ```
5. Write the full converted Markdown body beneath the frontmatter. Keep the conversion complete — do not summarize or cut content short. If the source is too large for one write, split it across sequential reads/writes but preserve every section; note any chunk boundaries in the file rather than dropping content.
6. Do not update `docs/context/index.yaml` or any canonical doc from this skill alone — the output is a raw archive, not evidence-graded durable context. If the user also wants it distilled into decisions, gaps, or product/architecture docs, hand off to `aisdlc-knowledge-ingestion` with this archived file as the source.
7. Report the archived file's path back to the user.

## Completion Report

Return: source identity, output path, and a one-line reminder that this is a raw archive, not distilled context.
