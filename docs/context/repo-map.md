# Repo Map

High-signal entrypoints, gathered during the 2026-09-14 guided bootstrap pass.

## Read Order

1. [`README.md`](../../README.md) — service table, ports, build/run order
2. [`pom.xml`](../../pom.xml) — Maven multi-module reactor (all 7 services)
3. [`resources/schema.cql`](../../resources/schema.cql), [`resources/schema.sql`](../../resources/schema.sql) — data model
4. `docs/product/overview.md`, `docs/architecture/overview.md` — durable context

## Key Entry Points

| Path | Why it matters |
|---|---|
| `README.md` | Service table (ports), build/run steps, notes `login-microservice` as WIP |
| `pom.xml` | Root Maven reactor listing all modules |
| `api-gateway-microservice/src/main/java/.../controller/*Controller.java` | Only entrypoint the UI calls; fans out to downstream services |
| `api-gateway-microservice/src/main/java/.../rest/clients/*RestClient.java` | Confirms which services the gateway actually integrates (no Login client) |
| `checkout-microservice/src/main/java/.../cronoscheckoutapi/service/CheckoutServiceImpl.java` | Core checkout/inventory business logic |
| `products-microservice/src/main/java/.../domain/ProductMetadata.java` | Product/pricing shape (price stored directly on the record) |
| `resources/schema.cql` | YCQL keyspace `cronos`: products, product_rankings, orders, product_inventory |
| `resources/schema.sql` | YSQL `shopping_cart` table |
| `docker-run.sh` | Full-stack container run script |
| each microservice's `application.yml` | Port + `spring.application.name` per service |
| each microservice's `manifest.yml` | Legacy Cloud Foundry deployment target |

## Supporting Paths

- `resources/dataload.sh`, `resources/cassandra-loader`, `resources/parse_metadata_json.py`, `resources/products.json` — sample data loading (~6K products)
- `src/test/java/**` per module — mostly Spring Boot context-load smoke tests, low behavioral signal today
- `docs/decisions/2026-09-14-1758-immersion-kickoff-decisions.md`, `specs/intake/2026-09-14-ai-immersion-open-questions.md` — active engagement context

## Notes

- No application CI workflow files exist under `.github/workflows/`; only AI-SDLC framework prompts/skills live under `.github/`.
- `login-microservice` exists but is not wired into `api-gateway-microservice` — treat as WIP.
