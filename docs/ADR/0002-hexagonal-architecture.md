# 0002 - Hexagonal architecture with mandatory no-infra adapters

Status: Accepted

## Context

Existing IDPs (Keycloak and similar) tie core logic tightly to specific
infrastructure (a particular DB, a particular cache), which makes them
heavy to run, slow to start, and hard to test without standing up the full
stack. One of this project's explicit goals is for the core business logic
to be runnable and testable with zero external infrastructure.

## Decision

Domain/core logic depends only on port interfaces it defines itself, never
directly on an infra library (no direct `lib/pq`, AMQP client, Valkey/Redis
client, or OpenBao client inside domain packages). Every port must have:

1. A "real" infra adapter (Postgres, RabbitMQ, Valkey, OpenBao, etc.), and
2. A file-based, in-memory, or stdout adapter with no external
   infrastructure dependency.

Both adapters must be added in the same change when a new port is
introduced — the no-infra adapter is not "nice to have, later."

The no-infra adapter set is explicitly a dev/demo/single-node mode: it is
not crash-safe for concurrent writers (e.g. appending sessions to a file
with no locking), and this should be documented wherever it is used.

## Consequences

- Every port addition costs at least two implementations instead of one.
- The full OAuth2/OIDC/FAPI flow (and its test suite) can run in CI with no
  external services, which is a direct enabler of fast iteration and of the
  learning goal (understanding the protocol logic in isolation from infra
  concerns).
- Swapping an adapter (e.g. moving a session store from the file adapter to
  Postgres) should never require a change to domain logic — if it does,
  the port boundary was drawn in the wrong place.
