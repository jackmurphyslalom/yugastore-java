---
name: 16-factor-analysis
description: Analyze every service or web app in a repository against the 12-Factor App methodology plus the 4 AI-era factors (Prompts as Code, State as a Service, Observability for Non-determinism, Trust & Safety by Design), and generate a report grading compliance and suggested improvements. Use when the user asks to evaluate a codebase's cloud readiness, run a 12/16-factor audit, score services against the twelve-factor methodology, or produce a factor-based improvement plan.
license: Complete terms in NOTICE
---

# 16-Factor Analysis

> Notice: Factor definitions paraphrase material listed in `NOTICE`.

Discover the services and web apps in a repository, rate each against the 16 factors, and write a single report with per-service tables and graded improvement suggestions.

## When to Use

- "Run a 12-factor / 16-factor audit on this repo."
- "Grade our microservices for cloud readiness."
- "Which services are furthest from the twelve-factor methodology and what should we fix first?"
- Near miss: "Review this codebase's architecture" with no reference to the factor framework — do not trigger; use a general architecture review instead.

## Inputs

- Repository root (default: current workspace root).
- Optional: an explicit list of subdirectories to treat as services (skip discovery).

## Output

Overwrite `docs/architecture/16-factor-analysis.md` with the assembled report. Create `docs/architecture/` if it does not exist.

## Steps

1. **Discover services and apps.** From the repo root, list top-level and nested directories that contain their own build or runtime manifest (`pom.xml`, `package.json`, `build.gradle`, `build.gradle.kts`, `requirements.txt`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`) or a `Dockerfile`. Exclude a root aggregator manifest (for example a Maven parent POM whose only role is to list `<modules>`) unless it is the only unit found. Record each unit's directory path and a short identifier.
2. **Classify AI usage per service.** For each service, apply the AI-detection heuristic in [references/sixteen-factors.md](references/sixteen-factors.md#ai-detection-heuristic). If none of the signals are present, mark factors XIII–XVI as **not applicable** and omit those rows from that service's factor table. If any signal is present, evaluate all 16 factors.
3. **Evaluate each in-scope factor.** For every service and every applicable factor, gather concrete evidence from the repo (config files, Dockerfiles, dependency manifests, source layout, CI/CD files, logging setup). Assign one rating using the scale in [references/sixteen-factors.md](references/sixteen-factors.md#rating-scale): `Compliant`, `Partial`, `Non-Compliant`, or `Not Applicable`. Record a one-line evidence citation (file path or configuration key) and a short note explaining the rating.
4. **Draft suggested updates.** For each `Partial` or `Non-Compliant` factor, propose a concrete, actionable update tied to that factor. Grade each suggestion on three axes using `High / Medium / Low`:
   - **Importance** — how much it improves compliance, reliability, or safety.
   - **Size of Change** — implementation effort (files touched, coordination needed).
   - **Risk** — likelihood of regressions or operational disruption.
   Add a one-line rationale. Do not compute a combined score.
5. **Assemble the report.** Use the skeleton in [assets/report-template.md](assets/report-template.md). Produce one section per discovered service or app, in discovery order. Each section contains the factor rating table followed by the suggested updates table. If a service has zero suggestions, state "No changes recommended" instead of an empty table.
6. **Write the report.** Save to `docs/architecture/16-factor-analysis.md`, overwriting any existing file. Do not update `docs/context/index.yaml` or other durable-context indexes from this skill.
7. **Report back.** Return: the output path, the number of services analyzed, the count of services with any AI factors evaluated, and the total suggestion count broken down by Importance tier (High / Medium / Low).

## Completion Criteria

- Every discovered service has its own section in the report.
- Every factor row cites at least one piece of evidence (file path, config key, or "no evidence found in repo").
- Every suggestion has all three grades filled in plus a rationale.
- Factors XIII–XVI appear only in sections for services flagged as AI-using.
