# 0006 - Internal operator identity as its own port (LDAP / Azure Entra)

Status: Accepted

## Context

People who administer grIdp itself (create/modify realms, manage clients,
rotate signing keys, view audit logs) are a different population from the
end users grIdp issues tokens for (see ADR 0005), and from the OAuth2
clients (see ADR 0003). Enterprise environments adopting this project
typically already have a directory that is the authoritative source for
"who may administer internal platform tooling" — commonly LDAP or Azure
Entra ID. Forcing operators into the same local-file-based model as
end-user static identity would mean maintaining a shadow directory that
inevitably drifts from the real one.

## Decision

- `OperatorDirectory` is a dedicated port representing the source of
  truth for internal operators — the people authorized to administer
  grIdp via its CLI/TUI and internal management API.
- Adapters: `LocalFileAdapter` (suitable for the no-infra/dev mode and
  small deployments) and, for enterprise use, `LDAPAdapter` and
  `AzureEntraAdapter`.
- Operator authorization uses the platform RBAC model described in ADR
  0003 (realm-scoped `resource:action` permissions), which is distinct
  from end-user scopes/claims/consent (ADR 0005). An operator's directory
  group membership (from LDAP/Entra) maps to platform roles via the same
  RBAC binding files already planned — the directory adapter supplies
  *who the operator is*, the RBAC files supply *what they can do*, kept
  as two separate concerns.

## Consequences

- Authenticating an operator (proving identity) and authorizing an
  operator (checking RBAC) remain separable: swapping `LocalFileAdapter`
  for `LDAPAdapter` must not require touching RBAC evaluation logic.
- The control plane (Go) is the natural owner of this port's "real"
  adapters, since LDAP/Entra integration is an I/O-heavy, non-cryptographic
  concern (per the language boundary in ADR 0001).
- Mapping an external directory's groups/claims to grIdp's internal role
  names uses an explicit, file-declared mapping, kept separate from both
  the directory adapter and the RBAC role definitions — see
  [`ADR/0008-operator-group-role-mapping.md`](0008-operator-group-role-mapping.md).
