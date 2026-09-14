# Glossary

| Preferred term | Definition | Avoid | Evidence | Confidence | Last verified |
|---|---|---|---|---|---|
| Yugastore | The retail marketplace application in this repository. | YugaStore when referring to the codebase generally | `README.md`, `pom.xml` | medium | 2026-09-14 |
| Eureka | The service discovery component used by local microservices. | discovery server when naming the module | `eureka-server-local`, `README.md` | high | 2026-09-14 |
| YCQL | The YugabyteDB Cassandra-compatible API used by products and checkout data. | Cassandra, unless discussing the API lineage | `resources/schema.cql`, `README.md` | high | 2026-09-14 |
| YSQL | The YugabyteDB PostgreSQL-compatible API used by carts. | PostgreSQL, unless discussing compatibility | `resources/schema.sql`, `README.md` | high | 2026-09-14 |
| API gateway | The service receiving external API requests from the UI. | backend gateway without module context | `api-gateway-microservice`, `README.md` | high | 2026-09-14 |

Automated bootstrap draft. Human review is required before treating terminology or confidence as
authoritative.
