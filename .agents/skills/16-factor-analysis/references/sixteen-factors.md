# Sixteen-Factor Rubric

Paraphrased factor definitions plus concrete evidence signals to look for in a repository. Sources listed in `../NOTICE`.

## Rating Scale

Use exactly one of:

- **Compliant** — the service clearly satisfies the factor; direct evidence in the repo.
- **Partial** — the factor is partially satisfied; important gaps remain (for example, some config is externalized but secrets are hardcoded).
- **Non-Compliant** — the factor is not satisfied or is actively violated.
- **Not Applicable** — the factor does not apply (used for XIII–XVI on non-AI services, or for factors that genuinely do not apply to the service type).

Every row must cite at least one piece of concrete evidence: a file path, a configuration key, or the explicit note "no evidence found in repo".

## Original 12 Factors

### I. Codebase — One codebase tracked in revision control, many deploys

- Compliant signals: service lives under a single source tree in this repo; no vendored copies of the same service; no divergent forks in-tree.
- Non-compliant signals: multiple copies of the same service under different paths; source pulled from an untracked location at build time.

### II. Dependencies — Explicitly declare and isolate dependencies

- Compliant signals: a manifest (`pom.xml`, `package.json` with lockfile, `requirements.txt` / `pyproject.toml`, `go.mod`, `Cargo.toml`) pins direct and transitive dependencies; build uses an isolated environment (Maven wrapper, virtualenv, container build).
- Partial signals: manifest exists but lockfile missing; wide version ranges; reliance on globally installed tools.
- Non-compliant signals: dependencies pulled ad hoc during runtime; no manifest; unpinned system packages.

### III. Config — Store config in the environment

- Compliant signals: hostnames, ports, credentials, and feature flags read from environment variables or an environment-scoped config service (Spring Cloud Config, Vault); different values per deploy come from the environment, not the code.
- Partial signals: some config externalized, other values hardcoded in `application.yml` / source; env vars mixed with committed defaults that must be overridden.
- Non-compliant signals: credentials, endpoints, or environment-specific values committed in source (including per-environment files like `application-prod.yml` with real secrets).

### IV. Backing Services — Treat backing services as attached resources

- Compliant signals: databases, queues, caches, third-party APIs are addressed by a URL/URI supplied via config; swapping a local database for a managed one requires only a config change.
- Partial signals: connection details in config but code assumes a specific vendor/driver in non-abstract ways.
- Non-compliant signals: hostnames, ports, or credentials hardcoded; backing service selection buried in source.

### V. Build, Release, Run — Strictly separate build and run stages

- Compliant signals: a build produces an immutable artifact (jar, container image); release combines artifact + config; runtime does not modify code.
- Partial signals: builds produce artifacts but releases mutate them (patching config into the artifact after build).
- Non-compliant signals: runtime pulls source and compiles on start; no build artifact; release process not defined.

### VI. Processes — Execute the app as one or more stateless processes

- Compliant signals: no local session state; caches marked as ephemeral; scale-out documented.
- Partial signals: sticky sessions or in-memory caches used but with an external fallback.
- Non-compliant signals: state held in local files or memory that must persist across requests; sticky-session-only design.

### VII. Port Binding — Export services via port binding

- Compliant signals: service starts its own HTTP/gRPC listener on a configurable port; no external web-server injection required.
- Partial signals: port fixed rather than configurable.
- Non-compliant signals: service designed to run only inside a specific application server or reverse proxy without self-contained port binding.

### VIII. Concurrency — Scale out via the process model

- Compliant signals: horizontal scaling supported (Kubernetes replicas, Cloud Foundry instances, multiple container instances); process types documented.
- Partial signals: single-instance assumptions in some code paths (leader election implicit).
- Non-compliant signals: singletons that block horizontal scaling; explicit "run one instance only" constraints.

### IX. Disposability — Maximize robustness with fast startup and graceful shutdown

- Compliant signals: SIGTERM handled; readiness/liveness probes present; startup time reasonable; work drained before shutdown.
- Partial signals: probes present but shutdown behavior undefined; long startup times.
- Non-compliant signals: no shutdown handling; no probes; lengthy warm-up with no readiness gate.

### X. Dev/Prod Parity — Keep development, staging, and production as similar as possible

- Compliant signals: same backing service families across envs (e.g. Postgres everywhere, not SQLite in dev / Postgres in prod); local Docker Compose or dev container matches deployed topology.
- Partial signals: backing services differ but abstractions minimize impact.
- Non-compliant signals: divergent backing services (in-memory H2 in dev vs Postgres in prod), divergent runtimes, or manual-only deploy steps.

### XI. Logs — Treat logs as event streams

- Compliant signals: application writes to stdout/stderr; log routing handled by the platform; structured logs preferred.
- Partial signals: mix of file logging and stdout; log rotation configured inside the app.
- Non-compliant signals: logs written to files under the app root with no stdout output; log storage/rotation handled by the app.

### XII. Admin Processes — Run admin/management tasks as one-off processes

- Compliant signals: migrations, data loads, and admin tasks run as separate processes using the same codebase and config (Flyway/Liquibase migrations, dedicated CLI subcommands, one-off jobs).
- Partial signals: admin scripts exist but drift from application config/dependencies.
- Non-compliant signals: admin work performed via ad-hoc scripts outside version control, or via manual database edits.

## AI-Era Factors (XIII–XVI)

Evaluate these only when the AI-detection heuristic below flags the service. Otherwise omit these rows from the service's factor table.

### XIII. Prompts as Code — Version prompts, prompt-shaping logic, and behavioral specs alongside application code

- Compliant signals: prompt templates committed as files; a behavioral spec (golden dataset, eval tests) committed and run in CI; context-engineering logic (retrieval, history selection, tool selection) versioned with tests.
- Partial signals: prompts committed but no eval/spec; prompts embedded as inline strings without templating.
- Non-compliant signals: prompts stored only in an external tool; no versioning; no behavioral tests.

### XIV. State as a Service — Externalize conversational and long-term memory to a backing service

- Compliant signals: conversation state stored in an external session service; per-request session identifier; long-term memory in a persistent, searchable store; service process itself remains stateless.
- Partial signals: session state externalized but long-term memory kept in-process; single-node cache used as session store.
- Non-compliant signals: conversation history kept in process memory; no session identifier; horizontal scaling breaks continuity.

### XV. Observability for Non-determinism — Log prompts, responses, tool calls, token counts, and quality signals

- Compliant signals: structured logs capture full request lifecycle (agent request, model request, tool calls, responses); token/cost metrics emitted; user feedback signal captured; traces integrated (OpenTelemetry).
- Partial signals: system-health metrics present but no AI-specific logs; tool calls untraced.
- Non-compliant signals: only HTTP status/latency observed; no prompt/response or tool-call visibility; no quality signal.

### XVI. Trust & Safety by Design — Defense-in-depth for prompts, outputs, and tools

- Compliant signals: input sanitization for prompt injection; guardrails on model output; least-privilege service accounts / API scopes for AI-callable tools; user-persona-aware capability gating; safety filters or content moderation in the pipeline.
- Partial signals: some layers present (e.g. safety filters) without least-privilege on tools; guardrails only at one layer.
- Non-compliant signals: raw user input passed to model with broad tool access; tool service accounts hold broad platform permissions; no output filtering.

## AI Detection Heuristic

A service is treated as AI-using when at least one of these signals is present in its directory or its manifest. Cite the signal that triggered the classification in the report.

- Dependency manifest declares an LLM/agent SDK: for example `openai`, `anthropic`, `@anthropic-ai/*`, `langchain`, `llama-index`, `google-cloud-aiplatform`, `vertexai`, `@google/generative-ai`, `spring-ai`, `semantic-kernel`, `ollama`, `transformers`, `sentence-transformers`, `pgvector`, `chromadb`, `pinecone-client`, `weaviate-client`, `qdrant-client`.
- Agent-framework markers: Agent Development Kit (ADK), Model Context Protocol (MCP) server/client packages, `crewai`, `autogen`.
- Prompt or agent assets committed under the service: files or directories named `prompts/`, `*.prompt`, `*.prompt.md`, `agent.md`, `AGENTS.md` co-located with the service (not a repo-wide agent file), `system-prompt.*`, `eval/` datasets for LLM output.
- Model endpoint configuration: config keys referencing `openai`, `bedrock`, `vertex`, `gemini`, `azure-openai`, `ollama`, model IDs (e.g. `gpt-*`, `claude-*`, `gemini-*`), or embedding model names.
- Source references to LLM completion / chat / embedding APIs (`chat.completions`, `generateContent`, `Embeddings`, etc.).

If none of these are found in the service's directory or its manifests, mark factors XIII–XVI as **Not Applicable** and omit those rows from that service's factor table.
