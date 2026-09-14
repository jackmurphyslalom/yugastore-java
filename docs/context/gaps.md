# Context Gaps

Use this file to record important things the repo does not yet prove clearly enough.

Keep unresolved or weak-signal context here so later feature work does not quietly guess through it.

## What Belongs Here

- product or architecture questions that still need a human answer
- stale docs or conflicting evidence discovered during bootstrap or promotion
- important source areas that have not been reviewed yet
- repo conventions that seem real but are not verified strongly enough to treat as durable guidance

## What Does Not Belong Here

- feature task lists
- implementation TODOs that belong in `specs/`
- temporary scratch notes better kept in `specs/<feature>/context/scratch/`

## Current Gaps

- **Area**: Service contracts and request flows
  - **Why it matters**: The README and entrypoint inventory identify modules but do not establish all
    API contracts, error handling, or inter-service request choreography.
  - **Evidence checked**: `README.md`, module entrypoints, module test tree
  - **Next best reviewer or source**: Service controllers, clients, and contract/integration tests
- **Area**: Test and delivery verification
  - **Why it matters**: No CI workflow was found, and Maven tests were not executed during bootstrap;
    database-backed tests may need local YugabyteDB.
  - **Evidence checked**: root and module `pom.xml` files, `src/test/java`, `.github/workflows`
  - **Next best reviewer or source**: Maintainer documentation and a successful local `./mvnw test`
- **Area**: Runtime configuration and deployment
  - **Why it matters**: Docker and manifest behavior depends on image names, environment variables,
    and network settings not fully verified in this pass.
  - **Evidence checked**: `docker-run.sh`, module `Dockerfile` and `manifest.yml` files
  - **Next best reviewer or source**: Current deployment target and module application configuration

Remove this starter entry once real repo-specific gaps are recorded.
