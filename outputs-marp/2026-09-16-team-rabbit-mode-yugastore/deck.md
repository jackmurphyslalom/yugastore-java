---
marp: true
theme: slalom
paginate: true
title: Team Rabbit Mode — 3-day recap
---

<!-- _class: lead -->

# Team Rabbit Mode

**3-day recap · 2026-09-14 → 2026-09-16**

A brownfield YugaStore recap — what the team built, which agentic tools carried the load, and what the last three days actually looked like in the repo.

---

## Meet team Rabbit Mode

*Three humans in the loop*

| Commits | Member | Focus |
| ---: | :--- | :--- |
| **22** | **Young Chul Kim** | Spec Kit driver — constitution v1.0.0, boundary docs, testing-framework alignment, perf test suite, project board wire-up. |
| **15** | **Jack Murphy** | Rabbit Wiki + agent tooling — gh-agent-board CRUD, rabbit-wiki lifecycle, architecture-assessment skills, client-feedback iterations. |
| **14** | **Michael Apfelbeck** | Skill authoring + framing — AI-SDLC bootstrap, 16-factor analysis skill, MCP config, dynamic pricing plan, Slalom deck skill. |

Commits per member, 2026-09-14 → 2026-09-16 (no-merges).

---

## Brownfield YugaStore — seven tiers we inherited

*The project*

Spring Boot microservices commerce reference app, Eureka-based service discovery, a React storefront on top. We did not rewrite it — we wired agentic scaffolding around it and started shipping specs against the existing shape.

| Layer | Tiers |
| :--- | :--- |
| **Edge** | `react-ui` · `api-gateway-microservice` |
| **Domain** | `products-microservice` · `cart-microservice` · `checkout-microservice` · `login-microservice` |
| **Platform** | `eureka-server-local` (service discovery) |

Brownfield: existing system + our recent additions. The additions live in `.agents/`, `.github/`, `docs/`, `meta/`, `specs/`, and `tools/` — not inside the microservices themselves.

---

## 42 skills, five families

*Agentic surface*

- **speckit-\*** — **25** — Spec Kit workflow: specify, plan, tasks, implement, analyze, converge, iterate, bugfix, issue.import/link/sync, checklist, taskstoissues.
- **rabbit-\*** — **10** — Repo-specific knowledge ops: wiki ingest/analyze/query/lint, architecture assessment (tier + rollup), future-state recommendations, deck gen.
- **aisdlc-\*** — **5** — Bootstrap language: grilling interviews, domain modeling, knowledge ingestion, PR flow, skill authoring.
- **Analysis & decks** — **2** — 16-factor-analysis (12-factor + 4 AI-era factors) and slalom-html-slide-decks (this deck).

Enumerated from `.agents/skills/*/SKILL.md`. Each skill has a canonical body plus agent-specific wrappers under `.claude/`, `.cursor/`, `.grok/`, `.zcode/`, `.rovodev/`, `.factory/`, and `.kiro/`.

---

## 43 Copilot prompts, 2 MCP servers

*How the team invokes it*

### `.github/prompts/` — 43 Copilot chat commands

- **15 rabbit-\*** — wiki lifecycle, arch assessment, deck gen, gh-board CRUD, archive-to-markdown.
- **25 speckit.\*** — full Spec Kit loop, each delegating to a subagent.
- **1 slalom-html-slide-decks** — free-text deck brief.
- **1 rabbit-deck-gen** — the prompt that drove this deck.

### `.vscode/mcp.json` — 2 MCP servers wired to the workspace

- **context7** — HTTP MCP at `mcp.context7.com/mcp`. Pulls current library/framework docs so we don't guess at Spring Boot 2.6.3 config keys or Eureka client behavior.
- **github-mcp** — GitHub Copilot's HTTP MCP. Backs the `gh-agent-board` tooling and the `rabbit-gh-board-*` prompts against real Issues and Projects.

---

## 51 commits, one team, three days

*3-day recap · window: "3 days ago" → HEAD*

### Commits per day (no-merges)

| Day | Commits |
| :--- | ---: |
| Sep 14 | 10 |
| **Sep 15** | **38** |
| Sep 16 | 3 |

**51** no-merge commits · **84** including merges.

Sep 15 was the sprint's spike day: 10 new specs, testing-framework alignment, perf test suite, and the first Slalom-themed slide generation all landed together.

---

## Five lanes carried the work

*Themes across the 51 commits*

- **Features** — Dynamic pricing plan · perf & fault-injection suite · gh-agent-board.
  Externalized dynamic pricing spec+plan, k6 load + toxiproxy fault-injection suite for issue #55, and gh-agent-board CRUD/reassign/change-owner prompts merged as PR #14.
- **Spec Kit** — 10 new features authored end-to-end.
  Each with `spec.md`, `plan.md`, `tasks.md`, `research.md`, `data-model.md`, `quickstart.md`. See the next-but-one slide for the full list. Boundary doc (#21) implemented and closed.
- **Rabbit Wiki** — Lifecycle + arch assessment + wiki ingest.
  Rabbit Wiki lifecycle skill added; architecture-assessment tier+rollup skills replaced SCQA with Context/Findings/Recommendation + scored 16-factor; LLM Wiki, Knowledge Graph, and recap recordings ingested.
- **Skills & tooling** — 16-factor analysis, Slalom decks, Marp.
  16-factor-analysis skill authored and run against every tier. Marp-based slide generation added, then Slalom-themed. Slalom HTML deck skill installed on Sep 16 (this deck).
- **Docs, style, ops** — Constitution v1.0.0 · writing style · localhost target.
  Project constitution ratified. Writing style guide + phrasal-verb clarification. Recorded localhost-only deployment scope. Real GitHub Projects board wired up with audit entries.

---

## The work landed in the agentic scaffolding

*File-touch buckets, 3-day window*

| Area | File-touches | Signal |
| :--- | ---: | :--- |
| `.agents/skills/` | **76** | Skill authoring |
| `.shared/slalom-html-slide-decks/` | **69** | Slalom deck install |
| `meta/rabbit-wiki/` | **43** | Wiki ingest |
| `.github/prompts/` | **43** | Copilot prompts |
| `.specify/extensions/` | **40** | Spec Kit extensions |
| `tools/gh-agent-board/` | **37** | Project-board CLI |
| Agent mirrors (`.claude`, `.cursor`, `.grok`, `.zcode`, `.rovodev`, `.factory`) | **180** | Skill fan-out |

No production Java `src/main` was touched. Every microservice got new `src/test` scaffolding under testing-framework-alignment, and `react-ui/frontend` components saw targeted edits.

---

## Every one has spec, plan, tasks, research, data-model, and quickstart

*10 features authored end-to-end*

- **001-\*** — `externalized-dynamic-pricing` · `gh-board-crud-prompts` · `user-story-spec-boundary`
- **002-\*** — `rabbit-wiki-lifecycle` · `testing-framework-alignment`
- **003-\*** — `architecture-assessment` · `ci-test-pipeline`
- **004-\*** — `future-state-recommendations` · `marp-slide-generation`
- **Named** — `copilot-agent-issue-board`

**60** new Spec Kit files across 10 features (spec + plan + tasks + research + data-model + quickstart, each).

Boundary: *001-user-story-spec-boundary* was specified, planned, tasked, and implemented — issue #21 closed inside the 3-day window.

---

## Three days built the runway. The next sprint lands the planes.

*From scaffolding to shipping*

### Open at HEAD

- **feature/slide-deck-gen** — this deck's branch; installed Slalom HTML deck skill on Sep 16.
- **feature/dynamic-pricing-plan** — merged to master via PR #66 on Sep 16.
- **feature/16-factor-analysis-skill**, **feature/ci-cd-bootstrap**, **feature/writing-style**, **feature/mcp-config** — landed and archived.

### Now do the work

- Implement the **001-externalized-dynamic-pricing** plan against `products-microservice` and `checkout-microservice`.
- Turn the **003-architecture-assessment** tier findings into the graceful-degradation and pricing-agility future-state recommendations.
- Wire the **003-ci-test-pipeline** spec through GitHub Actions so the perf suite and JUnit 5 suite run on push.

> **Rabbit Mode: three humans, forty-two skills, one brownfield repo. Onward.**
