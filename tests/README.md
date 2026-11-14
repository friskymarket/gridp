# tests

Cross-component tests that don't belong to a single module:

- `integration/` — tests exercising control-plane + token-service
  together (e.g. full OAuth2 authorization code flow), ideally runnable
  against the no-infrastructure adapter set (see
  `docs/ADR/0002-hexagonal-architecture.md`) so they can run in CI with
  zero external infra.
- `e2e/` — tests against a fully deployed stack (compose or OCP),
  exercising real adapters (Postgres, RabbitMQ, etc.).

Unit tests for a single component live alongside that component's code
(`control-plane/**/*_test.go`, `token-service/src/**` with `#[cfg(test)]`),
not here.
