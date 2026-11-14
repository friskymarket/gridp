# proto

Shared protobuf definitions for the internal gRPC management API (see
`docs/ADR/0007-grpc-internal-api.md`). Both `control-plane` (Go) and
`token-service` (Rust, where applicable) generate code from here — this
directory is the single source of truth for the contract between them and
for the CLI/TUI-facing management API.

Versioned by directory (`v1/`, `v2/`, ...) rather than in-message, to keep
breaking changes explicit.

Changes to a `.proto` file here are a breaking-change-risk, same
discipline as the GitOps file schemas (see
`docs/ADR/0003-gitops-files-and-runtime-state-split.md`) — do not edit
quietly.
