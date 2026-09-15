---
marp: true
theme: slalom
paginate: true
---

<!-- _class: lead -->

# yugastore-java: Bootstrapping AI-SDLC enabled

Rabbit Mode: 
Michael Apfelbeck
Jack Murphy
Young Kim

---

# AI-SDLC bootstrap & foundations

- Adopted the AI-SDLC framework (Spec Kit + core preset) as the project's durable scaffolding
- Archived requirements and meeting transcripts as source material for context bootstrap
- Bootstrapped evidence-backed context docs: product, architecture, glossary, repo-map, gaps
- Ratified the project constitution — five core principles for how the repo is built

---

# Tooling & process

- `gh-agent-board`: `gh`-CLI-only Bash tooling for Copilot agent issue tracking, fully tested
- Added a writing style guide (ASD-STE100) to keep docs and PRs short and clear
- Committed shared MCP server config so the whole team uses the same setup
- Added Context7 instructions so agents pull current library docs instead of guessing
- Added a `Brewfile` — one command provisions the full local dev toolchain
- Documented the boundary between GitHub Issues and Spec Kit feature specs

---

# CI & testing

- Designed a GitHub Actions CI/CD pipeline (parallel Java + React jobs, coverage artifacts)
- Stabilized CI by isolating context-load smoke tests from external services
- Standardized the Java testing framework (JUnit 5 + Mockito + AssertJ + JaCoCo) across every
  module, fixing pre-existing build failures along the way

---

# Recap

One continuous thread: bootstrap the AI-SDLC framework and its supporting docs/tooling, then
raise the CI and testing floor on top of it — all hand-curated here from this repo's own
decisions, docs, and merged PRs.
