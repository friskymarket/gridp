# Security Policy

grIdp is an Identity Provider implementation. Security issues are taken
seriously, including in this early/learning-stage phase of the project.

## Reporting a vulnerability

Please **do not** open a public GitHub issue for security vulnerabilities.

Instead, use [GitHub's private vulnerability reporting](../../security/advisories/new)
for this repository, or contact the maintainers directly if that is not
available.

Please include:

- A description of the vulnerability and its potential impact.
- Steps to reproduce (a minimal example is ideal).
- The affected component (`control-plane`, `token-service`, deployment
  manifests, etc.) and version/commit if known.

## Scope notes

This project is in early development and is **not production-ready**. In
particular:

- The no-infrastructure adapters (see
  [`docs/ADR/0002-hexagonal-architecture.md`](docs/ADR/0002-hexagonal-architecture.md))
  are explicitly dev/demo-only and not crash-safe for concurrent access —
  this is a known limitation, not a vulnerability to report.
- Cryptographic and protocol implementations are being built as a learning
  exercise following the relevant OAuth2/OIDC/FAPI specs directly. Reports
  pointing out spec non-compliance or incorrect cryptographic usage are
  very welcome and are exactly the kind of issue this policy is for.

## Response

As a small, early-stage project there is no formal SLA, but reports will be
acknowledged and triaged as soon as possible.
