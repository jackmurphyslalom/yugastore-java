# Product Overview

Grounded in repo evidence gathered during the 2026-09-14 guided bootstrap pass. Assumptions are
labeled explicitly rather than presented as settled fact.

## What This Project Does Today

Yugastore is a sample microservices-based retail marketplace/e-commerce app, originally built as a
YugabyteDB reference application: a Spring Boot backend (Java 17, Spring Boot 2.6.3, Spring Cloud
2021.0.0) plus a React storefront, backed by YugabyteDB's distributed SQL (YSQL) and Cassandra-compatible
(YCQL) APIs. It is a demo/reference app, not a production system.

This repository is currently *also* the working project for a 3-day "AI Immersion" exercise by
"Team Rabbit Mode": the team is bootstrapping the AI-SDLC framework here, ingesting their kickoff
meeting transcript into the knowledge base, and intends to work real client-style problem statements
against this codebase. See [`docs/decisions/2026-09-14-1758-immersion-kickoff-decisions.md`](../decisions/2026-09-14-1758-immersion-kickoff-decisions.md)
and [`specs/intake/2026-09-14-ai-immersion-open-questions.md`](../../specs/intake/2026-09-14-ai-immersion-open-questions.md).

## Users, Actors, or Consumers

- **Shopper** (react-ui end user): browses the product catalog, adds items to a shopping cart, and
  checks out. Served by `react-ui` -> `api-gateway-microservice` -> downstream services.
- **Registered user / account holder**: modeled by `login-microservice` (`User`, `Role`), but this
  service is explicitly unfinished (README: "still a work in progress") and `api-gateway-microservice`
  has no REST client for it — not yet part of the working end-to-end flow.
- **Immersion team engineers** (Team Rabbit Mode): use this repo to practice AI-SDLC workflows
  against a real multi-service Java codebase and to feed meeting transcripts into project context.

## Implementation-Relevant Rules

- Each product's price is stored directly on the product record (`cronos.products.price`, a
  `double`) and duplicated on `cronos.product_rankings` — there is no separate pricing-rules layer.
  This is flagged as a likely mismatch with an (unverified) client requirement that "pricing rules
  change weekly without a redeploy" — see [`docs/context/gaps.md`](../context/gaps.md).
- Checkout enforces stock via `NotEnoughProductsInStockException`, reading `cronos.product_inventory`
  (YCQL transactions enabled).
- Orders are written to `cronos.orders` (YCQL transactions enabled) — treat order/inventory writes as
  consistency-sensitive.
- Service discovery is mandatory: every microservice registers with Eureka
  (`eureka-server-local`, port 8761). The UI only talks to `api-gateway-microservice` (port 8081),
  never directly to a backend service.
- `login-microservice` is explicitly unfinished and not wired into the gateway — treat it as
  out of the supported flow until confirmed otherwise.

## Observed Evidence

- [`README.md`](../../README.md) (service table, ports, build/run steps, "work in progress" note on login)
- [`pom.xml`](../../pom.xml) (Maven multi-module reactor listing all seven modules)
- [`resources/schema.cql`](../../resources/schema.cql) (`cronos` keyspace: products, product_rankings, orders, product_inventory)
- [`resources/schema.sql`](../../resources/schema.sql) (`shopping_cart` YSQL table)
- `products-microservice/src/main/java/.../domain`, `checkout-microservice/src/main/java/.../cronoscheckoutapi`
- `api-gateway-microservice/src/main/java/.../rest/clients` (Checkout, ShoppingCart, ProductCatalog clients — no Login client)
- [`docs/decisions/2026-09-14-1758-immersion-kickoff-decisions.md`](../decisions/2026-09-14-1758-immersion-kickoff-decisions.md)
- [`specs/intake/2026-09-14-ai-immersion-open-questions.md`](../../specs/intake/2026-09-14-ai-immersion-open-questions.md)

## Assumptions and Open Questions

- Whether the pricing/redeploy, graceful-degradation, and A/B-testing items in
  `specs/intake/2026-09-14-ai-immersion-open-questions.md` are real client requirements or exercise
  prompts is unconfirmed by this pass. See [`docs/context/gaps.md`](../context/gaps.md).
- Whether `login-microservice` is planned to be finished during this engagement, or intentionally
  left out of scope, is unconfirmed.
