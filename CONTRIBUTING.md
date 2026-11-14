# Contributing to grIdp

Thanks for your interest in contributing. This is primarily a learning
project (see [`README.md`](README.md)), so expect a somewhat opinionated,
slower-moving review process focused on understanding *why* a change is
correct, not just that it works.

## Before you start

Read these first — they are not optional background reading, they are the
actual constraints this project operates under:

- [`AGENTS.md`](AGENTS.md) — hard architectural constraints (hexagonal
  architecture, language boundaries, GitOps-native entities, standards over
  invention).
- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — the current
  architectural proposal.
- [`docs/ADR/`](docs/ADR/) — Architecture Decision Records. Do not
  propose a change that contradicts an accepted ADR without addressing it
  explicitly.

## Making changes

1. **Significant decisions need an ADR first.** New component, new storage
   choice, protocol implementation approach, language boundary change —
   write the ADR before (or alongside) the code. Use the next sequential
   number in `docs/ADR/`.
2. **Hexagonal architecture is enforced, not a suggestion.** Domain/core
   logic must depend only on port interfaces it defines itself. If you add
   a new port, add both a "real" adapter and a no-infrastructure adapter in
   the same change.
3. **Prefer implementing the spec.** For anything with an existing
   OAuth2/OIDC/FAPI spec, implement the spec. If you think a bespoke
   mechanism is warranted, open an issue to discuss before writing code.
4. **Language boundaries**: Rust is for the token service (OAuth2/OIDC/FAPI
   protocol logic, crypto, signing). Go is for the control plane (API, CLI,
   GitOps reconciler, event plumbing). See
   [`ADR/0001-language-boundaries.md`](docs/ADR/0001-language-boundaries.md).

## Development setup

See [`deploy/compose/`](deploy/compose/) for the local dependency stack
(currently RabbitMQ) and [`README.md`](README.md) for project layout.

Go module: `control-plane/` — standard `go build`, `go test ./...`.
Rust crate: `token-service/` — standard `cargo build`, `cargo test`.

## Pull requests

- Keep PRs scoped to one logical change.
- Include or update tests for behavior changes.
- Update `docs/ARCHITECTURE.md` and/or add an ADR if the change affects
  architecture, not just implementation detail.
- CI must pass (see `.github/workflows/`).

## Code of conduct

This project follows the [Code of Conduct](CODE_OF_CONDUCT.md).
