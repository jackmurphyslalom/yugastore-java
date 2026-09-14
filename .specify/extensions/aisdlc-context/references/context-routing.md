# AI-SDLC Context Routing Contract

Use this contract whenever an AI-SDLC command or managed skill selects project context.

## Route selection

1. Read `docs/context/routing-map.md` when it exists.
2. Select exactly one command or skill route ID. For preflight, use the explicit upcoming command or
   map the invoking `before_specify`, `before_plan`, or `before_implement` hook to its command. If the
   command is still unknown, ask for it rather than guessing.
3. Read the authority baseline, the selected row's exact artifact inputs, and its exact baseline
   documents.
4. Omit and report missing files. Never substitute a directory, glob, similarly named file, or
   adjacent route.
5. Record the selected route ID and the reason each file was included.

## Two-pass rule

The first pass is limited to the selected exact-file route. The second pass may expand only when a
concrete unresolved question matches a trigger in the routing map. Record the trigger before reading
the expanded file. A route may authorize a directory search, dependency traversal, ownership lookup,
or implementation-code search, but those operations are never part of the first pass.

## Compatibility fallback

Older projects may not contain `docs/context/routing-map.md`, and newer commands or skills may not
have a row in an older map. Use the compatibility fallback declared in the command or skill, report
`route ID: compatibility-fallback`, and retain the same exact-file and recorded-reason rules. Do not
silently broaden discovery.

## Maintenance

When bootstrap, promotion, ingestion, or PR-gap handling creates a durable document that should be
baseline context, propose a stable route-row change in the same operation. Include the route ID,
exact path, selection reason, and affected command or skill. Do not apply the route change without
the confirmation required by that workflow.
