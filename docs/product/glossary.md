# Glossary

This is the project's sole default source of canonical language. Keep only terms that improve precision across code, docs, specifications, and team communication.

Preserve an established project glossary's structure. For a new project, use concise entries like these:

| Preferred term | Definition | Avoid | Evidence | Confidence | Last verified |
|----------------|------------|-------|----------|------------|---------------|
| ASIN | Product identifier/primary key used across the catalog, cart, checkout, and inventory tables (`cronos.products.asin`, `shopping_cart.asin`). | "product ID," "SKU" | `resources/schema.cql`, `resources/schema.sql` | high | 2026-09-14 |
| Cronos | Legacy/internal codename for the product catalog + checkout + order YCQL keyspace and Java package (`cronoscheckoutapi`). Recognize it when reading code; do not introduce it as user-facing or spec terminology. | using "Cronos" in product-facing docs or new specs | `resources/schema.cql` (`CREATE KEYSPACE cronos`), `checkout-microservice/src/main/java/.../cronoscheckoutapi/*` | high | 2026-09-14 |
| api-gateway | The single external API surface (`api-gateway-microservice`, port 8081); the only service the UI talks to directly. | "BFF," "backend" | `README.md`, `api-gateway-microservice/src/main/java/.../controller/*` | high | 2026-09-14 |
| Eureka / service discovery | Spring Cloud Netflix Eureka registry (`eureka-server-local`, port 8761) that every microservice registers with; used to resolve hostnames/ports at runtime. | "service mesh" | `README.md`, `eureka-server-local/` | high | 2026-09-14 |
| YCQL | YugabyteDB's Cassandra-compatible API, used by products, checkout, orders, and inventory. | "Cassandra" (product name) when specifically meaning YugabyteDB's API | `resources/schema.cql`, `products-microservice/.../config/YugabyteYCQLConfig.java` | high | 2026-09-14 |
| YSQL | YugabyteDB's Postgres-compatible API, used by the shopping cart. | "Postgres" (product name) when specifically meaning YugabyteDB's API | `resources/schema.sql`, `README.md` | high | 2026-09-14 |
| Team Rabbit Mode | Team name for the current AI Immersion exercise using this repo as its working project (GitHub project: "Rabbit Mode Project"). | "the team," "session 518" | `docs/decisions/2026-09-14-1758-immersion-kickoff-decisions.md` | high | 2026-09-14 |

## Usage notes

- Prefer terms supported by code, tests, config, workflows, or explicit human confirmation.
- Record automated findings as draft until reviewed.
- Do not create a second glossary hierarchy unless a human explicitly chooses a split during guided bootstrap.
- Remove starter rows once the glossary contains project-specific language.
