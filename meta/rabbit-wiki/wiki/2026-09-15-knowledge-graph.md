---
type: concept
authored_by: rabbit-analyze
confidence: high
last_verified: 2026-09-15
source_type: document
source_ref: meta/rabbit-wiki/sources/2026-09-15-knowledge-graph
tags: [knowledge-graph, semantic-web, ontology, graph-database, entity-alignment]
related: [2026-09-15-llm-wiki]
---

# Knowledge Graph

## Term/Concept

**Knowledge graph** — a knowledge base that uses a graph-structured data model or topology to
represent and operate on data (per the archived Wikipedia article).

## Definition

Knowledge graphs store interlinked descriptions of entities — objects, events, situations, or
abstract concepts — while encoding the free-form semantics or relationships underlying them.
There is no single accepted definition, but most share these features:
- Flexible relations among knowledge in topical domains: abstract classes and relations are
  defined in a schema, real-world entities and their interrelations are described, arbitrary
  entities can be interrelated, and various topical domains are covered.
- General structure: a network of entities, their semantic types, properties, and
  relationships (using categorical or numerical values for properties).
- Supporting reasoning over inferred ontologies: a knowledge graph acquires and integrates
  information into an ontology and applies a reasoner to derive new (implicit) knowledge, not
  just retrieve explicit facts.

A simpler definition used for less formal representations: a digital structure representing
knowledge as concepts and the relationships between them (facts), optionally with an ontology
that lets humans and machines understand and reason about its contents.

Historically associated with the Semantic Web and linked open data, and popularized by search
engines/knowledge engines (Google Knowledge Graph, Bing, WolframAlpha, Siri, Alexa) and social
networks (LinkedIn, Facebook). Early examples include WordNet (1985) and Geonames (2005);
DBpedia and Freebase (2007) were general-purpose graph-based knowledge repositories; Google
introduced its Knowledge Graph in 2012, building on these sources.

Knowledge graphs support machine learning via **knowledge graph embeddings** (latent feature
representations of entities/relations), often produced with graph neural networks (GNNs), which
enable tasks like node/edge prediction, reasoning, and alignment. **Entity alignment** is the
task of identifying nodes across disparate knowledge graphs that represent the same real-world
entity — an active research area, with LLMs recently applied to improve alignment via
syntactically meaningful embeddings (2023).

The rise of large language models has broadened the term to include dynamically constructed,
adaptive graph structures supporting retrieval, reasoning, and summarization in generative
systems — e.g., Microsoft Research's GraphRAG (2024), which integrates LLM-generated graphs into
retrieval-augmented generation.

## Ontology links

- [knowledge-graph](../ontology.yaml) (concept)
- [llm-wiki-pattern](../ontology.yaml) (concept, related — GraphRAG and the LLM Wiki pattern
  both use LLMs to build persistent, structured knowledge representations rather than
  re-deriving synthesis at query time)

## Source anchor

[meta/rabbit-wiki/sources/2026-09-15-knowledge-graph/](../sources/2026-09-15-knowledge-graph/)

## Related entries

- [2026-09-15-llm-wiki](2026-09-15-llm-wiki.md) — an informal, markdown-native, LLM-maintained
  analogue of a knowledge graph, using cross-linked pages instead of a formal graph schema.
