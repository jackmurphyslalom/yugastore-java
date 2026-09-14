# Product Overview

## What This Project Does Today

Yugastore is a Spring Boot microservices retail marketplace with a React UI. It serves product
catalog browsing, shopping carts, checkout and inventory, user login, and service discovery. The
repository packages seven independently runnable services and provides local and Docker startup
instructions.

## Users, Actors, or Consumers

- Marketplace users browse products, manage carts, authenticate, and place orders through the UI.
- The React frontend calls the API gateway rather than calling each backend directly.
- Operators run YugabyteDB, initialize YCQL and YSQL schemas, start the services, and optionally run
	the Docker containers.
- Eureka provides service registration and discovery for the local deployment.

## Implementation-Relevant Rules

- The root Maven build targets Java 17 and Spring Boot 2.6.3.
- Products and product rankings use YCQL; carts use YSQL; checkout uses YCQL for orders and inventory.
- The documented local ports are 8761 for Eureka, 8080 for the UI, 8081 for the gateway, 8082 for
	products, 8083 for cart, 8085 for login, and 8086 for checkout.
- The repository includes schemas and a data-loading script; YugabyteDB must be initialized before
	the services are run.

## Observed Evidence

- `README.md`
- `pom.xml`
- `resources/schema.cql`, `resources/schema.sql`, `resources/dataload.sh`
- `api-gateway-microservice`, `products-microservice`, `cart-microservice`,
	`checkout-microservice`, `login-microservice`, `eureka-server-local`, and `react-ui`

## Assumptions and Open Questions

- Automated bootstrap draft: product behavior beyond the README and schema descriptions requires
	human review against service controllers and integration behavior.
- The README's login workflow is explicitly described as work in progress; its supported contract is
	not established by this bootstrap.
