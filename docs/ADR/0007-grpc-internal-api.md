# 0007 - gRPC for the internal management API

Status: Accepted

## Context

The CLI (and, later, the TUI) need to talk to the control plane for
realm/client/user/RBAC management and other operational concerns. This is
a separate surface from the public-facing OAuth2/OIDC/FAPI endpoints
(authorization endpoint, token endpoint, JWKS, etc.), which must remain
REST/JSON because the relevant specs require it — that part is not a
choice. The internal management API, however, is a free design choice,
and needs to work cleanly across the Go/Rust language boundary (ADR 0001),
since the control plane (Go) and the token service (Rust) also need to
communicate internally.

## Decision

The internal management API (CLI/TUI ↔ control plane, and control plane
↔ token service where applicable) uses gRPC, with protobuf as the shared
contract definition across Go and Rust.

Rationale:

- A single protobuf schema is the contract for both the Go control plane
  and the Rust token service, avoiding hand-written client/server code
  staying in sync manually across two languages.
- Native streaming support is useful for future TUI features (e.g. a live
  "tail the audit log" view) without bolting on SSE/websockets separately.
- The public OAuth2/OIDC/FAPI endpoints are unaffected — they remain
  REST/JSON per spec, served by the token service directly.

## Consequences

- A `grpcurl`-style tool (or a documented wrapper) is needed for anyone
  who wants to poke the internal API without the CLI, since gRPC is not
  directly curl-able. This should be documented once the first service
  definitions exist.
- Protobuf schemas for the management API become a contract subject to
  the same discipline as the GitOps file schemas (ADR 0003): breaking
  changes to a `.proto` file are a breaking change requiring care, not a
  quiet edit.
- If a REST/JSON view of the management API is wanted later (e.g. for
  scripting with `curl`/`jq`), the addition of a REST gateway in front of
  the same gRPC service definitions is the expected path — not a parallel,
  independently maintained REST API.
