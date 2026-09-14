# Architecture Overview

Grounded in repo evidence gathered during the 2026-09-14 guided bootstrap pass.

## System Shape

Yugastore is a Spring Boot microservices system (Java 17, Spring Boot 2.6.3, Spring Cloud 2021.0.0)
with a React frontend, built as a single Maven multi-module reactor
([`pom.xml`](../../pom.xml): `eureka-server-local`, `products-microservice`, `checkout-microservice`,
`cart-microservice`, `api-gateway-microservice`, `react-ui`, `login-microservice`). YugabyteDB is the
datastore, accessed through two APIs: YCQL (Cassandra-compatible, for products/checkout/orders/inventory)
and YSQL (Postgres-compatible, for the shopping cart).

## Key Modules and Responsibilities

| Module | Port | Responsibility |
|---|---|---|
| `eureka-server-local` | 8761 | Spring Cloud Netflix Eureka service registry; every other service registers here |
| `react-ui` (`frontend/`) | 8080 | React storefront UI; only talks to the api-gateway |
| `api-gateway-microservice` | 8081 | Single external API surface; `*Controller` -> `*ServiceRest` -> `rest/clients/*RestClient` fan out to Checkout/ShoppingCart/ProductCatalog |
| `products-microservice` | 8082 | Product catalog + rankings, YCQL (`ProductMetadataRepo`, `ProductRankingRepository`, `ProductInventoryRepository`) |
| `cart-microservice` | 8083 | Shopping cart, YSQL (`ShoppingCartRepository`, `shopping_cart` table) |
| `checkout-microservice` | 8086 | Checkout + inventory + order placement, package `cronoscheckoutapi` (`CheckoutServiceImpl`, `NotEnoughProductsInStockException`) |
| `login-microservice` | 8085 | User/Role auth (`UserRepository`, `RoleRepository`, `UserServiceImpl`) — **WIP**, no `api-gateway` REST client wired yet |

## Important Flows

- **Request flow**: `react-ui` -> `api-gateway-microservice` (`*Controller`) -> per-domain
  `*ServiceRest` -> `*RestClient` -> downstream microservice, resolved via Eureka.
- **Checkout flow**: `CheckoutController` -> `CheckoutServiceImpl` -> `ProductInventoryRepo` /
  `ShoppingCartRestClient` / `ProductCatalogRestClient`, raising `NotEnoughProductsInStockException`
  when stock is insufficient.
- **Startup flow**: `eureka-server-local` must start first; each `Yugastore*` Spring Boot app
  (`YugastoreProducts`, `YugastoreCart`, `YugastoreCheckout`, `YugastoreApiGateway`,
  `YugastoreLoginService`) registers with it before the UI is usable end to end (see README run order).
- No fallback/circuit-breaker code was found in the gateway's REST clients — a downstream outage is
  not currently handled gracefully by observed code (see open question below).

## Integrations and Platform Surfaces

- YugabyteDB YCQL and YSQL, with separate local vs. cloud connection config in checkout
  (`YugabyteLocalConfig`, `YugabyteCloudConfig`, `YugabyteYCQLConfig`).
- Docker: each service has its own `Dockerfile`; [`docker-run.sh`](../../docker-run.sh) runs the full
  stack in containers.
- Cloud Foundry: each service has a `manifest.yml` (legacy Pivotal/CF target referenced by the
  README's hosted demo link).
- Data loading: [`resources/dataload.sh`](../../resources/dataload.sh),
  [`resources/cassandra-loader`](../../resources/cassandra-loader),
  [`resources/parse_metadata_json.py`](../../resources/parse_metadata_json.py),
  `resources/products.json` / `metadata_strict_small.json` (~6K sample products).

## Build, Test, and Delivery

- **Build**: `mvn -DskipTests package` from the repo root (multi-module Maven reactor).
- **Test**: per-module `src/test/java`; currently mostly Spring Boot context-load smoke tests
  (e.g. `CronosCheckoutApiApplicationTests`, `YugastoreCartTests`) — low behavioral signal today.
- **Local run**: manual, ordered `mvn spring-boot:run` per service (README steps), or
  `docker-run.sh` for containers.
- No CI workflow files were found for the application build itself under `.github/workflows/`
  (only the AI-SDLC framework's own prompts/skills live under `.github/`).

## Observed Evidence

- [`pom.xml`](../../pom.xml), each microservice's `pom.xml` / `Dockerfile` / `manifest.yml`
- each microservice's `application.yml` (ports, `spring.application.name`)
- [`resources/schema.cql`](../../resources/schema.cql), [`resources/schema.sql`](../../resources/schema.sql)
- source packages under each microservice's `src/main/java`
- [`README.md`](../../README.md) build/run instructions and `docker-run.sh`

## Assumptions and Open Questions

- Whether Cloud Foundry (`manifest.yml`) or Docker is the intended deployment target for this
  engagement, versus AWS (tentatively chosen per the kickoff decisions), is unresolved.
- The intake's idea to "build graceful degradation on Eureka" is unverified against actual
  gateway code — no such logic was observed.
