# Architecture Overview

## System Shape

The repository is a Maven multi-module Spring Boot application. Eureka, the API gateway, product
catalog, cart, checkout, login, and React UI are separate modules and runtime processes. The normal
local flow is YugabyteDB initialization, Eureka startup, backend startup, then UI startup. The
Docker alternative is `docker-run.sh` after the modules have been packaged.

## Key Modules and Responsibilities

- `eureka-server-local/src/main/java/com/yugabyte/yugastore/eureka/YugastoreEurekaServer.java`:
	local service discovery.
- `api-gateway-microservice/src/main/java/com/yugabyte/app/yugastore/YugastoreApiGateway.java`:
	external API entrypoint.
- `products-microservice`: product catalog and rankings backed by YCQL.
- `cart-microservice`: shopping cart backed by YSQL.
- `checkout-microservice`: orders and inventory backed by YCQL.
- `login-microservice`: login service, documented as incomplete.
- `react-ui`: Spring-hosted React frontend.
- `resources/schema.cql`, `resources/schema.sql`, and `resources/dataload.sh`: database setup and
	sample data loading.

## Important Flows

The UI sends marketplace requests to the gateway; service discovery supplies backend locations.
Services register with Eureka and connect to YugabyteDB according to their module configuration.
The root Maven project builds all seven modules and the Docker script starts images on the documented
ports. Exact request choreography and failure handling require deeper implementation review.

## Integrations and Platform Surfaces

- YugabyteDB YCQL and YSQL schemas and Java drivers.
- Eureka service discovery.
- Spring Boot configuration in each module's `src/main/resources`.
- Docker images and local container networking in each module's `Dockerfile` and `docker-run.sh`.
- No CI workflow was found under `.github/workflows`.

## Build, Test, and Delivery

- Build/package: `./mvnw -DskipTests package` or `mvn -DskipTests package` from the root.
- Test convention: Maven test sources live under each module's `src/test/java`; observed names end
	in `Tests.java` or `Test.java`.
- Narrow test: `./mvnw -pl <module> test`.
- Full test: `./mvnw test`, which covers the Maven reactor modules and their unit/integration tests.
- Container delivery: package first, then run `./docker-run.sh`; the script expects locally built
	images and Docker.
- No CI or release automation was found, so the command hierarchy above is inferred from the root
	Maven structure and README instructions.

## Observed Evidence

- `pom.xml` and each module `pom.xml`
- `README.md`
- `docker-run.sh` and module `Dockerfile` files
- `resources/schema.cql`, `resources/schema.sql`, `resources/dataload.sh`
- The seven `@SpringBootApplication` entrypoint classes
- Six module test files under `src/test/java`

## Assumptions and Open Questions

- The exact Maven wrapper behavior and integration-test prerequisites were not executed during
	bootstrap.
- Docker image names and database network settings should be verified against each module's current
	Dockerfile and application configuration before production use.
