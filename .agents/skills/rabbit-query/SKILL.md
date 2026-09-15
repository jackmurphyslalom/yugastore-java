---
name: rabbit-query
description: Answer a question from the Rabbit Wiki with citations to specific wiki entries, or state plainly when no entry answers it. Use when the user asks a question intended to be answered from meta/rabbit-wiki/wiki/ and ontology.yaml.
license: MIT
---

# Rabbit Query

Query step of the Rabbit Wiki lifecycle. Searches the wiki and ontology for entries relevant to
a question, reads them, and answers with citations — filing a genuinely new answer back into the
wiki when it is not already captured.

## When to Use

- "What does the Rabbit Wiki say about X?"
- "Answer this question using the wiki."
- Near miss: the user wants a general web/codebase answer unrelated to `meta/rabbit-wiki/` — this
  skill only searches the Rabbit Wiki's own store.

## Steps

1. Search `meta/rabbit-wiki/wiki/` and `meta/rabbit-wiki/ontology.yaml` for entries relevant to
   the question.
2. Read the matching entries (and, where relevant, their linked source assets under
   `meta/rabbit-wiki/sources/`) in full before answering.
3. If one or more entries answer the question, synthesize an answer that cites the specific
   `wiki/*.md` entries used (and underlying source assets, where relevant).
4. If no entry answers the question, state that explicitly rather than fabricating a citation
   (FR-013).
5. If multiple entries conflict with each other, surface the conflict to the user instead of
   silently picking one side (Edge Cases in spec.md).
6. When the synthesized answer is genuinely new and not already captured in any existing entry,
   file it as a new `meta/rabbit-wiki/wiki/{slug}.md` page, using the same
   `{YYYY-MM-DD}-{kebab-title}` slug format as `/rabbit-ingest` (FR-012). Do not file a new page
   for an answer that is already covered by an existing entry.
7. Never modify an existing wiki page or `meta/rabbit-wiki/ontology.yaml` as a side effect of
   answering — the only permitted write is the new page in step 6.

## Completion Report

Return: the answer, the specific wiki entries (and source assets) cited, and — if applicable —
the path of any new wiki page filed.
