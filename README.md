# grIdp

A CLI-first, API-first, GitOps-native Identity Provider (OAuth2 / OIDC / FAPI),
built as a learning project for event-driven architecture, Go, and Rust.

No GUI. A TUI may come later, but it will always be a thin client over the API —
never a requirement to operate the system.

## Goals

- Learn OAuth2, OIDC, and FAPI by implementing the protocols directly rather
  than hiding behind a framework that already does it.
- Learn event-driven architecture: durable, replayable event streams instead
  of database-backed polling.
- Learn Go and Rust, each used where it fits best (see
  [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)).

See [`docs/SPECS.md`](docs/SPECS.md) for the full list of OAuth2/OIDC/FAPI
RFCs and specs this project targets, with implementation status for each.

## Design principles

1. **GitOps-native.** Realms, clients, users, and RBAC are declared in plain
   files, reconciled into runtime state. Git history is the audit trail for
   *configuration*; the event stream is the audit trail for *behavior*.
2. **Infra-optional core.** The domain logic must run with zero external
   infrastructure: read from files, persist to files, emit events to stdout.
   Postgres, RabbitMQ, Valkey, and OpenBao are adapters, not requirements.
   This is a strict hexagonal (ports & adapters) design — see
   [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).
3. **API first.** The CLI (and, later, the TUI) are clients of the API.
   Nothing is CLI-only or TUI-only.
4. **Standards over invention.** Where a spec already solves the problem
   (e.g. RP-Initiated Logout, Back-Channel Logout, PKCE, DPoP), implement the
   spec rather than inventing a bespoke mechanism.

## Repository layout

```
.
├── README.md              This file.
├── AGENTS.md              Instructions for LLM coding agents working in this repo.
├── CONTRIBUTING.md        How to propose changes (ADRs, hexagonal architecture rules, etc.).
├── CODE_OF_CONDUCT.md
├── SECURITY.md            Vulnerability reporting.
├── LICENSE                MIT.
├── Makefile               Common dev tasks (build/test/lint/compose).
├── .github/               CI workflows, issue/PR templates, CODEOWNERS.
├── docs/
│   ├── ARCHITECTURE.md    Proposed architecture, components, and data flow.
│   ├── SPECS.md           OAuth2/OIDC/FAPI RFCs targeted, with status.
│   └── ADR/               Architecture Decision Records.
├── proto/                 Shared gRPC contracts (control-plane <-> CLI/TUI, see ADR 0007).
├── control-plane/         Go: internal management API, CLI, GitOps reconciler.
├── token-service/         Rust: OAuth2/OIDC/FAPI protocol logic, token issuance, crypto.
├── deploy/
│   ├── compose/           Local dev stack (no production use).
│   └── ocp/               OpenShift manifests.
├── examples/              Sample GitOps definitions (realms, clients, RBAC, operator mappings).
├── scripts/               Small dev utilities.
└── tests/
    ├── integration/       Cross-component tests, ideally infra-free.
    └── e2e/               Tests against a fully deployed stack.
```

## Status

Early design stage. Repository scaffolding is in place; no functional
code yet. See `docs/ADR/` for decisions made so far and
`docs/ARCHITECTURE.md` for the current architectural proposal.
