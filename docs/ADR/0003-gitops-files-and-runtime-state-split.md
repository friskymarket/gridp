# 0003 - GitOps files for realms, clients, users, and RBAC; Postgres for runtime security state

Status: Accepted

## Context

Existing IDPs typically store all identity data (realm/client/user
definitions as well as runtime security state) in a single relational
database, with GitOps bolted on afterward via API calls replaying desired
state. This project wants Git to be the native source of truth for
declarative configuration, following the same pattern already proven with
RabbitMQ's `definitions.json` / `load_definitions` mechanism used
elsewhere in this project's tooling.

At the same time, not all user-related data is declarative: some of it
changes through runtime user/system action and cannot be reconciled
one-way from a file without the reconciler and the runtime fighting over
ownership of the same field.

## Decision

- Realms, clients, user **static identity** (username, realm membership,
  declared roles), and RBAC role/binding definitions are declared in plain
  files (YAML/JSON), delivered as ConfigMaps (and Secrets, pending
  ADR/decision on OpenBao migration — see 0005) once running on OpenShift.
- A GitOps reconciler reads these files and writes runtime state. It never
  writes back to files. This is a strict one-way sync.
- User **dynamic security state** (failed login counters, lockout status,
  MFA enrollment, last password change), **sessions**, **consent**, and
  **refresh/offline access tokens** live in Postgres, not in files. This
  data needs strong consistency and point-in-time correctness, and
  GDPR-style deletes are impractical to reason about if this state were
  event-sourced or file-reconciled.
- RBAC is scoped per-realm: an admin of realm A must not implicitly be an
  admin of realm B. Exact permission-string wildcard semantics are an open
  question, to be resolved in a future ADR once the shape is implemented.

## Consequences

- Two distinct mutation paths exist for "user" data: the reconciler
  (file → runtime, static identity) and the token service / control plane
  (runtime mutation, dynamic security state). These must never target the
  same field — if a field needs to be both declaratively set and runtime
  mutated, that is a design smell to revisit.
- Postgres is required for a "real" deployment, but not for the no-infra
  adapter mode (see ADR 0002) — the file adapter for sessions/consent in
  that mode is single-instance only.
- Changes to the shape of the realms/clients/users/RBAC file schema are
  breaking changes requiring an ADR, per `AGENTS.md`, not a quiet edit.
