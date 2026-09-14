# Bootstrap Report

Use this file to record what happened during the latest AI-SDLC bootstrap pass.

This file is a review artifact. Keep durable product, architecture, glossary, and constitution guidance in their canonical docs instead of duplicating it here.

## Repo Classification

- `existing-project`

## Bootstrap Mode and Status

- Mode: `automated`
- Resulting status: `draft`
- Final guided confirmation received: `not applicable`

## Evidence Sources Used

- `README.md`
- `pom.xml` and module `pom.xml` files
- seven `@SpringBootApplication` entrypoints
- module `src/test/java` trees
- `resources/schema.cql`, `resources/schema.sql`, `resources/dataload.sh`
- `docker-run.sh`, module `Dockerfile` and `manifest.yml` files
- `.agents/config.yaml`
- no `.github/workflows` directory was found

## Durable Docs Reviewed

- `README.md`
- scaffolded `docs/product`, `docs/architecture`, and `docs/context` files
- `.specify/memory/constitution.md`

## Created or Updated

- `docs/product/overview.md`
- `docs/product/glossary.md`
- `docs/architecture/overview.md`
- `docs/context/repo-map.md`
- `docs/context/routing-map.md` (reviewed; framework route matrix retained)
- `docs/context/index.yaml`
- `docs/context/gaps.md`
- `docs/context/bootstrap-report.md`
- `.specify/memory/constitution.md`

## Support Files Refreshed

- Both files were updated with draft statuses, source paths, and repo-specific unresolved gaps.

## Assumptions and Risks

- API request choreography and error contracts need review against controllers and clients.
- Maven/database-backed test prerequisites were not executed.
- Docker image names and deployment environment settings need verification.

## Missing, Stale, or Conflicting Context

- See `docs/context/gaps.md` for service-contract, test-verification, and deployment gaps.

## Follow-up Questions

- Which service API contracts are supported and expected to remain compatible?
- Which tests require a running YugabyteDB instance, and what is the supported CI command?
- Which deployment target and environment variables are authoritative for Docker/Cloud Foundry?

## Boundaries

- Human review required: `yes` for automated mode
- ADRs created: `none`
- Application code changed: `no`

## Routing Result

- Selected route ID: `command:speckit.aisdlc.bootstrap`, because this run creates repository context.
- Authority files read: `.specify/memory/constitution.md`, `.github/copilot-instructions.md`,
	`docs/context/index.yaml`.
- Exact baseline files read: `README.md`, `pom.xml`, `docker-run.sh`, `resources/schema.cql`,
	`resources/schema.sql`, `.agents/config.yaml`.
- Triggered files read: module `pom.xml` files and `src/test/java` paths because the bootstrap
	requires module and test conventions.
- Deferred route proposals: service controllers and clients were not added as baselines because no
	feature or subsystem was selected.
- Manifest validation: passed `aisdlc status`; no `Context Manifest: invalid` message.
