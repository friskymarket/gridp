# internal/domain

Pure business logic: RBAC evaluation, realm/client/user domain models,
reconciliation rules. Must depend only on interfaces defined in
`internal/ports`, never on a specific infrastructure library (see
`docs/ADR/0002-hexagonal-architecture.md`).

No package here should import anything from `internal/adapters`.
