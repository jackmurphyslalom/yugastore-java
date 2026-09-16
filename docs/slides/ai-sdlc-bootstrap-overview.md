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
- Wired lifecycle hooks (`before_specify`/`before_plan`/`before_implement`) to auto-run repo-context preflight checks

---

# Tooling & process

- `gh-agent-board`: `gh`-CLI-only Bash tooling for Copilot agent issue tracking, fully tested
- Added a writing style guide (ASD-STE100) to keep docs and PRs short and clear
- Committed shared MCP server config so the whole team uses the same setup
- Added Context7 instructions so agents pull current library docs instead of guessing
- Added a `Brewfile` — one command provisions the full local dev toolchain
- Documented the boundary between GitHub Issues and Spec Kit feature specs
- Set up a GitHub Projects board ("Rabbit Mode Project") as the team's Kanban, replacing early Miro-based note tracking
- Captured a client requirements interview and open questions as Spec Kit intake for future feature specs

---

# CI & testing

- Designed a GitHub Actions CI/CD pipeline (parallel Java + React jobs, coverage artifacts)
- Stabilized CI by isolating context-load smoke tests from external services
- Standardized the Java testing framework (JUnit 5 + Mockito + AssertJ + JaCoCo) across every module, fixing pre-existing build failures along the way

---

# Architecture assessment & future-state recommendations

- Added a 16-factor app analysis skill (12-factor + 4 AI-era factors) as the scoring model
- Built the Rabbit Wiki knowledge lifecycle (ingest → analyze → query → lint → session-close) so project knowledge is captured once and queried with citations
- Assessed every tier (Eureka, products, checkout, cart, API gateway, login, React UI) against Context/Findings/Recommendation + the 16-factor score, rolled up into a whole-system view
- Turned findings into future-state recommendations (Before/After/Bridge, ranked solutions, SWOT/Buy-vs-Build-vs-Partner/TCO) for experimentation, graceful degradation, and pricing agility

---

# Pricing agility: spec authored

- Turned the "pricing agility" recommendation into a full Spec-Kit feature spec: `specs/001-externalized-dynamic-pricing/`
- Future state: prices externalized from the catalog into a new pricing microservice (behind `api-gateway-microservice`, per the constitution) — merchandisers change prices/promotions with no redeploy
- Five prioritized user stories: merchandiser self-service pricing, one consistent effective price across storefront/cart/checkout, immutable order-line price snapshots, graceful degradation when pricing is down, auditable change history
- Preserves the existing stock-check and order-write path — pricing is a read-side concern, not a transactional change
- Coordinates with, but doesn't duplicate, `specs/002-graceful-degradation-resilience/`
- Three open clarifications flagged for `/speckit.clarify`: merchandiser auth (login-microservice is out of scope), whether A/B pricing experimentation ships with it, and the pricing datastore (YCQL vs. YSQL vs. config)

---

# Performance & resiliency testing

- Built a k6 + Toxiproxy load/fault-injection suite to find the app's failure/bottleneck point under simulated traffic (issue #55)
- Found real bugs: 500-vs-404 on unknown ASIN, cart-microservice hardcoded YSQL datasource, Eureka `bootstrap.yml` hostname precedence, DB reconnect lag after simulated connection reset
- Checked in a baseline findings report for comparison once fixes land

---

# Deployment scope ratified

- Resolved the open AWS-vs-Cloud-Foundry ambiguity: deployment target is **localhost only** (ADR-0001), Cloud Foundry manifests remain dormant/unused

---

# Lessons learned

- `gh`'s default auth token lacks the `project` scope — Projects v2 automation needs an explicit `gh auth refresh -s project -s read:project`
- AWS was picked only by available credentials (a reversible, tentative choice); later ratified as localhost-only via ADR-0001, so no cloud target is in scope for this engagement
- Explored Andrej Karpathy's 12/16-factor-inspired "wiki" concept as a longer-term aspiration; not adopted as this engagement's primary knowledge base
- Running the AI-SDLC README's bootstrap command from the plain CLI failed to generate some repo-context files; rerunning the same step as a VS Code Copilot slash command completed correctly

---

# Recap

One continuous thread: bootstrap the AI-SDLC framework and its supporting docs/tooling, raise the CI and testing floor on top of it, then turn an assessment recommendation into a real spec (dynamic pricing) — all hand-curated here from this repo's own decisions, docs, and merged PRs.
