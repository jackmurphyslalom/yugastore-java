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

# Lessons learned

- `gh`'s default auth token lacks the `project` scope — Projects v2 automation needs an explicit `gh auth refresh -s project -s read:project`
- AWS was picked only by available credentials (a reversible, tentative choice) even though every microservice already ships a Cloud Foundry `manifest.yml` — deployment target still needs revisiting
- Explored Andrej Karpathy's 12/16-factor-inspired "wiki" concept as a longer-term aspiration; not adopted as this engagement's primary knowledge base
- Running the AI-SDLC README's bootstrap command from the plain CLI failed to generate some repo-context files; rerunning the same step as a VS Code Copilot slash command completed correctly

---

# Recap

One continuous thread: bootstrap the AI-SDLC framework and its supporting docs/tooling, then raise the CI and testing floor on top of it — all hand-curated here from this repo's own decisions, docs, and merged PRs.
