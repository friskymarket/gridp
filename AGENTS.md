# AGENTS.md

Instructions for LLM coding agents (and anyone acting as one) working in this
repository.

## What this project is

`grIdp` is a CLI-first, API-first, GitOps-native Identity Provider
(OAuth2 / OIDC / FAPI), built primarily as a learning project. Read
[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) and
[`docs/ADR/`](docs/ADR/) before proposing or making structural changes.
ADRs are the authoritative record of *why* something is the way it is — do not
contradict an accepted ADR without raising it explicitly and, if agreed,
writing a superseding ADR.

## Hard constraints

1. **Hexagonal architecture is not optional.** Domain/core logic must only
   depend on port interfaces it defines itself, never directly on an infra
   library (no `lib/pq`, no `amqp091-go`, no Valkey/Redis client, no OpenBao
   client inside domain packages). Infra always lives behind an adapter that
   implements a port.
2. **The core must run with zero external infrastructure.** Every port must
   have a file-based or in-memory/stdout adapter in addition to any
   "real" infra adapter (Postgres, RabbitMQ, Valkey, OpenBao). If you add a
   new port, add its no-infra adapter in the same change, not "later."
3. **GitOps entities are declared in files, reconciled one-way.**
   Realms, clients, users (static identity), and RBAC are desired state in
   files. The reconciler reads files and writes runtime state. It never
   writes back to files. Runtime-mutated security state (session data,
   lockouts, consent, refresh tokens) lives in a runtime store (Postgres in
   the "real" adapter), not in the GitOps files.
4. **Audit events are append-only and replayable.** The audit trail uses a
   durable, replayable stream (RabbitMQ Streams, not classic/quorum queues).
   Do not model the audit trail as a destructively-consumed queue.
5. **Prefer implementing the spec over inventing a mechanism.** For anything
   with an existing OAuth2/OIDC/FAPI spec (PKCE, DPoP, RP-Initiated Logout,
   Back-Channel Logout, JARM, etc.), implement the spec. Ask before proposing
   a bespoke alternative. See `docs/SPECS.md` for the full list of RFCs/specs
   this project targets and their implementation status — update that status
   when starting or finishing work on a given spec.
6. **Standards-compliant code, written to be understood, not hidden behind a
   library.** A goal of this project is learning the protocols. Avoid pulling
   in a dependency that implements an entire spec end-to-end if it defeats
   that purpose — small, focused crates/modules (e.g. JWT encode/decode,
   crypto primitives) are fine; "one import and OAuth2 is handled" is not.

## Language boundaries

- **Rust**: the token service — OAuth2/OIDC/FAPI protocol logic, token
  issuance/validation, crypto, signing-key handling.
- **Go**: the control plane — API, CLI, GitOps reconciler, event
  publishing/consumption, anything I/O- and concurrency-heavy.

Do not blur this boundary without an ADR. If a piece of logic doesn't
obviously belong to one side, raise it as a question rather than guessing.

## Working process

- Before adding a new infra dependency (a new "real" adapter, a new external
  service), check whether it changes anything described in
  `docs/ARCHITECTURE.md`. If so, update that doc and write an ADR.
- Significant decisions (new component, new storage choice, protocol
  implementation approach, language boundary change) get an ADR in
  `docs/ADR/`, numbered sequentially (`0001-...md`, `0002-...md`, ...).
  Use a short status (`Proposed` / `Accepted` / `Superseded by NNNN`).
- Keep file-based declarative schemas (realms, clients, users, RBAC) as the
  reference contract — treat changes to their shape as a breaking change
  requiring an ADR, not a quiet edit.
- When in doubt about scope, prefer the smaller, more explicit implementation
  over pulling in a framework — this project intentionally avoids "a
  Keycloak-sized footprint for a well-defined scope."
