# yugastore-java Constitution

Automated bootstrap draft. These principles are evidence-backed working guidance and require human
review before ratification.

## Core Principles

### I. Preserve Service Boundaries

Keep changes within the owning Maven module unless an inter-service contract, shared schema, or
root build change is explicitly required.

### II. Verify Database Contracts

Treat `resources/schema.cql`, `resources/schema.sql`, and module configuration as compatibility
boundaries. Changes to data shape or API choice require focused verification.

### III. Test the Changed Module

Add or update tests under the owning module's `src/test/java` using the existing `*Test.java` and
`*Tests.java` convention, then run the narrow module test before the full Maven reactor when practical.

### IV. Keep Runtime Configuration Explicit

Preserve the documented service ports, Eureka registration, YugabyteDB connectivity, and Docker
startup assumptions unless the change deliberately updates the corresponding documentation and
deployment configuration.

## Development Workflow

Use the root Maven wrapper for build and test commands. Do not modify application code as part of
context bootstrap. Record unresolved architectural or product choices in `docs/context/gaps.md`.

## Governance

This draft is subordinate to human project decisions and existing source contracts. Amendments should
be documented and reviewed with the affected module and tests.

**Version**: 0.1.0-draft | **Ratified**: not ratified | **Last Amended**: 2026-09-14

<!-- AI-SDLC:CONTEXT-ROUTING START -->
## AI-SDLC Context Routing

- Use `docs/context/routing-map.md` to select the smallest relevant context set.
- Start with exact-file baselines. Expand to directories, globs, dependencies, ownership, or implementation code only after a documented trigger.
- Record why each additional file was selected.
- Keep `.specify/memory/constitution.md` project-owned. Framework refreshes must preserve it.
<!-- AI-SDLC:CONTEXT-ROUTING END -->
