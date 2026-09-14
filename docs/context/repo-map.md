# Repo Map

## Read Order

1. `README.md` for user-visible scope, ports, and local/Docker startup.
2. `pom.xml` and the selected module `pom.xml` for build and dependency boundaries.
3. The selected module's `src/main/java` entrypoint and `src/test/java` tests.
4. `src/main/resources/application.yml` or `application.yaml` for runtime configuration.
5. `resources/schema.cql`, `resources/schema.sql`, and `resources/dataload.sh` for data setup.

## Key Entry Points

| Path | Why it matters |
|---|---|
| `pom.xml` | Root Maven reactor, Java 17 target, and seven modules. |
| `README.md` | Product scope, service ports, build, startup, and Docker instructions. |
| `eureka-server-local/src/main/java/com/yugabyte/yugastore/eureka/YugastoreEurekaServer.java` | Eureka runtime entrypoint. |
| `api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/YugastoreApiGateway.java` | External API runtime entrypoint. |
| `products-microservice`, `cart-microservice`, `checkout-microservice`, `login-microservice`, `react-ui` | Service/UI module boundaries and runtime entrypoints. |
| `resources/schema.cql` and `resources/schema.sql` | YCQL and YSQL schema definitions. |
| `docker-run.sh` | Local Docker startup orchestration. |

## Tests and Verification

Observed tests are under module-specific `src/test/java` paths and use `*Tests.java` or
`*Test.java`, including the Eureka, products, cart, checkout, React UI, and API gateway modules.
Use `./mvnw -pl <module> test` for a narrow check and `./mvnw test` for the reactor suite. No CI
workflow was found.

## Supporting Paths

- Module `src/main/resources/application.yml` or `application.yaml`: service configuration.
- Module `Dockerfile` and `manifest.yml`: container and deployment surfaces.
- `docs/context/*`: AI-SDLC project context, currently automated draft content.
