# 0001 - Language boundaries: Rust for the token service, Go for the control plane

Status: Accepted

## Context

This project is partly a vehicle for learning two new languages, Go and
Rust, in addition to building an Identity Provider. A single-language
implementation would be simpler, but would not serve the learning goal, and
there are also genuine technical reasons to split responsibilities rather
than pick one language arbitrarily.

## Decision

- **Rust** implements the token service: OAuth2/OIDC/FAPI protocol logic,
  token issuance and validation, cryptography, and signing-key handling.
  This is the most security- and performance-critical path, where the
  absence of GC pauses and Rust's type system (making invalid states
  unrepresentable) have the most leverage.
- **Go** implements the control plane: the HTTP/gRPC API, the CLI, the
  GitOps reconciler, and event publishing/consumption. Go's concurrency
  model (goroutines, channels) is a better teaching ground for
  event-driven I/O than Rust's async model, and this is the
  I/O-and-concurrency-heavy half of the system.

This mirrors a real microservice boundary: a Rust "token service" behind a
Go "control plane," communicating over an internal API.

## Consequences

- Two toolchains, two sets of dependencies, two build pipelines to
  maintain.
- Any logic that doesn't obviously belong to one side must be raised as a
  question (see `AGENTS.md`) rather than guessed at — this ADR does not
  attempt to enumerate every case.
- Changing this boundary later requires a superseding ADR, not a quiet
  refactor.
