# internal/reconciler

The GitOps reconciler: reads realm/client/user/RBAC/operator-mapping
files and applies them to runtime state via the domain layer. One-way
only — never writes back to files (see
`docs/ADR/0003-gitops-files-and-runtime-state-split.md`).
