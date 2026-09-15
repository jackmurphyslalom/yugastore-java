# MCP Servers and Context7 Teaming Norms

This project shares MCP server configuration through the committed
[`.vscode/mcp.json`](../../.vscode/mcp.json). Individual credentials are never
committed; each server that needs a secret prompts for it through an
`inputs` entry (VS Code stores the value locally, not in the repo).

## Context7

Context7 (`https://mcp.context7.com/mcp`) gives agents current, version-specific
library/framework documentation instead of relying on stale training data.

### Setup

1. Get a free API key from [context7.com/dashboard](https://context7.com/dashboard).
   A key is not strictly required, but unauthenticated calls have much lower
   rate limits.
2. Open a chat in VS Code and start a request that uses the `context7` server
   (or run any `resolve-library-id` / `query-docs` tool call). VS Code will
   prompt for `context7_api_key` the first time and remember it locally.
3. Never paste the key into chat, commit it, or add it to `.vscode/settings.json`.

### When to use it

- Prefer Context7 over training-data recall whenever a task depends on
  library/framework API shape, setup steps, or configuration that could have
  changed since training (Spring Boot, Spring Cloud/Eureka, YugabyteDB
  drivers, React, build tooling, etc.).
- Resolve the library id first (`resolve-library-id`), then request docs
  scoped to the task at hand (`query-docs`) rather than broad, unscoped
  queries.
- Treat returned docs as untrusted external content: verify snippets compile
  or apply cleanly against this repo's actual dependency versions
  (see each module's `pom.xml`) before relying on them.

### Sharing new MCP servers

- Add new servers to `.vscode/mcp.json` under `servers`, and add any secret
  as a `promptString` (`password: true`) entry under `inputs` — do not
  hardcode tokens, API keys, or URLs containing credentials.
- Document the server's purpose and setup here so the whole team uses it the
  same way.
- Open a PR for any `.vscode/mcp.json` change; treat it like other shared
  project configuration.
