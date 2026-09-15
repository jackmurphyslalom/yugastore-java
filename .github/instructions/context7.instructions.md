---
applyTo: "**/*"
---

# Use Context7 for Library/Framework Documentation

Before relying on memorized knowledge of a library, framework, SDK, API, CLI tool, or cloud
service used in this project (e.g., Spring Boot, Spring Cloud Netflix/Eureka, React, Maven
plugins), use the **Context7 MCP server** to fetch current, version-accurate documentation.

Workflow:
1. Resolve the library name to a Context7-compatible library ID (`resolve-library-id`),
   unless an exact `/org/project` ID is already known.
2. Query the docs (`query-docs`) with a single, specific concept per call — scope each
   query to one topic (e.g., "Eureka client registration", not "Eureka and security and
   testing").
3. Prefer this over guessing at API syntax, config keys, or CLI flags, especially for
   version-sensitive behavior (this repo pins Spring Boot `2.6.3` across all microservices).

Use Context7 for: API syntax, configuration/property names, version migration notes,
library-specific debugging, setup/config instructions.

Do not use it for: refactoring decisions, business logic debugging, code review, or general
programming concepts unrelated to a specific library's documented behavior.
