---
marp: true
theme: default
paginate: true
---

# AI-SDLC Bootstrap: yugastore-java Repo History

A hand-curated summary of PRs #1–#52, merged 2026-09-14 through 2026-09-15.

Content below is authored/curated by hand from [`docs/decisions/`](../decisions/),
[`docs/architecture/adr/`](../architecture/adr/), [`docs/product/`](../product/),
[`AGENTS.md`](../../AGENTS.md), `.github/instructions/context7.instructions.md`, and
[`Brewfile`](../../Brewfile) — it is **not** auto-generated from git history or diffs.

---

# Agenda

1. AI-SDLC bootstrap
2. Requirements & meeting transcripts
3. AI-SDLC context bootstrap docs
4. Project constitution ratification
5. gh-agent-board tooling
6. Writing style guide
7. MCP config
8. Context7 usage instructions
9. Brewfile local dev setup
10. GitHub Issues / Spec Kit boundary docs
11. CI/CD bootstrap
12. CI stabilization
13. Java testing framework alignment

---

# 1. AI-SDLC bootstrap

**PR #1** — *Add ai sdlc bootstrap* (2026-09-14)

- First adoption of the AI-SDLC framework (Spec Kit + AI-SDLC core preset) into this
  Java/Maven repo.
- Established the durable project scaffolding this deck itself now depends on: `AGENTS.md`,
  `.agents/`, and `.specify/`.

---

# 2. Requirements & meeting transcripts

**PRs #2–#8** (2026-09-14)

- Archived the AI Immersion kickoff meeting transcript and a requirements interview
  transcript as Markdown sources for ingestion (`docs: archive meeting transcript as markdown
  source`, `requirements interview transcript`).
- Added supporting 12-factor app reference context and a "processed requirements" pass.
- This raw material fed directly into the context bootstrap in PR #9.

---

# 3. AI-SDLC context bootstrap docs

**PR #9** — *docs: bootstrap AI-SDLC context (product, architecture, glossary, repo-map, gaps)*
(2026-09-14)

- Replaced placeholder product/architecture overviews and the glossary with evidence-backed
  content.
- Added `docs/context/repo-map.md` with real entrypoints.
- Added `docs/context/gaps.md`, recording 6 unresolved items (e.g. a verified
  pricing/redeploy mismatch).
- No application code changed, no ADRs created — docs-only.

---

# 4. Project constitution ratification

**PR #10** — *docs: ratify project constitution v1.0.0* (2026-09-15)

Ratified `.specify/memory/constitution.md` with five core principles:

1. Gateway-Only Service Boundary
2. Consistency-Sensitive Data Paths
3. Canonical Terminology
4. Context-Grounded Change
5. Incremental Test Hardening

---

# 5. gh-agent-board tooling

**PR #14** — *Add gh-agent-board tooling for Copilot agent issue tracking* (2026-09-15)

- Added `tools/gh-agent-board/`: `gh`-CLI-only Bash scripts (create-issue, set-field,
  reopen-issue, open-pr, link-artifacts, set-milestone) with mandatory audit logging.
- Shipped with 36 passing `bats` tests.

**PR #39** — *gh-agent-board: CRUD, change-owner, and reassign prompts* (2026-09-15)

- Added a shared `board-item.sh` helper to resolve a ticket number to its board item.
- Introduced a new `change_owner` audit-log action.

---

# 6. Writing style guide

**PR #29** — *Add writing style guide* (2026-09-15)

- Added `.github/writing-style-guide.md`, an ASD-STE100 Simplified Technical English style
  skill for docs, READMEs, PR descriptions, and error messages.
- Goal: short sentences, active voice, one name per concept — reduce "AI slop" in written
  output.

---

# 7. MCP config

**PR #30** — *MCP config* (2026-09-15)

- Committed shared MCP server configuration in `.vscode/mcp.json`.
- Added `docs/process/mcp-servers.md` documenting setup and teaming norms — no secrets
  committed; each server that needs a credential prompts locally via an `inputs` entry.

---

# 8. Context7 usage instructions

**PR #32** — *Add Context7 usage instructions and doc gap* (2026-09-15)

- Added `.github/instructions/context7.instructions.md`.
- Directs agents to consult Context7 for current, version-accurate library/framework docs
  (Spring Boot, Spring Cloud/Eureka, etc.) instead of relying on memorized training data.

---

# 9. Brewfile local dev setup

**PR #38** — *Add Brewfile for local dev environment setup* (2026-09-15)

- Added a root `Brewfile`: `gh`, `jq`, `bats-core`, `openjdk@17`, `maven`, `node`,
  `python@3.11`, `wget`, and the Docker cask.
- One command, `brew bundle`, now provisions the full local toolchain.

---

# 10. GitHub Issues / Spec Kit boundary docs

**PR #40** — *Document the boundary between GitHub Issues and Spec Kit feature specs*
(2026-09-15)

- Added `docs/process/user-stories-vs-specs.md`.
- Defines when to promote a GitHub Issue into a `specs/<feature>/` Spec Kit feature versus
  resolving it directly with a PR, and which artifact is authoritative at each delivery stage.

---

# 11. CI/CD bootstrap

**PR #42** — *speckit derived CI/CD bootstrap features* (2026-09-15)

- Landed `specs/003-ci-test-pipeline` (spec, plan, tasks, contracts) planning a GitHub
  Actions CI workflow.
- Design: parallel `java-reactor` + `react-ui` jobs, JaCoCo + React coverage published as
  workflow artifacts, report-only (no merge gate), DB-backed integration tests excluded.

---

# 12. CI stabilization

**PR #50** — *Stabilize `java-reactor` CI by isolating context-load tests from external
services* (2026-09-15)

- Hardened `contextLoads()` smoke tests in `api-gateway-microservice`, `cart-microservice`,
  `checkout-microservice`, and `products-microservice`.
- Each test now disables Eureka client discovery and mocks/excludes Cassandra and JPA
  autoconfiguration, so the reactor's tests no longer need live external services to pass.

---

# 13. Java testing framework alignment

**PRs #51 / #52** — *Align on standardized (Java) testing framework (JUnit 5 + Mockito +
AssertJ + JaCoCo)* (2026-09-15)

- Standardized the test toolchain across all 7 modules, including `login-microservice`,
  which previously had zero test infrastructure.
- Fixed 4 pre-existing `BUILD FAILURE`s caused by a test-class package mismatch with each
  module's `@SpringBootApplication` package.
- Added `docs/patterns/testing-conventions.md`; every module now produces a JaCoCo coverage
  report via `./mvnw test`.

---

# Recap

Thirteen themes, one continuous thread: bootstrap the AI-SDLC framework and its supporting
docs/tooling, then raise the CI and testing floor on top of it — all hand-curated here from
this repo's own decisions, docs, and merged PRs.
