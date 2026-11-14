# 0005 - End-user identity as its own port, separate from clients and operators

Status: Accepted

## Context

Initial design treated "users" as a single concept backed by files. In
practice, the people who authenticate *through* grIdp to use a
relying-party application (end users) are a different concern from the
people who *administer* grIdp (operators, see ADR 0006) and from the
relying-party applications themselves (OAuth2 clients, see ADR 0003).
Conflating end users with either of the other two leads to a single
"User" model trying to serve two different authorization questions at
once: "what can this app do with this user's token" vs. "can this person
manage realms." It would also make it awkward to later support
federated end-user authentication (delegating to an upstream IdP),
since that has nothing to do with how OAuth2 clients or operators are
modeled.

## Decision

- `IdentityProvider` is a dedicated port representing the source of truth
  for end users — the subjects of the tokens grIdp issues to relying-party
  applications.
- Adapters: `LocalFileAdapter` (static identity declared in files, per ADR
  0003) and, later, a `FederatedIdentityAdapter` that delegates end-user
  authentication to an upstream OIDC (and potentially SAML) identity
  provider.
- When the federated adapter is in use, grIdp acts as both an IdP (to the
  relying party making the request) and an RP/client (to the upstream
  IdP) for that authentication flow. This means implementing the client
  side of OIDC (authorization code flow as a relying party, consuming an
  upstream ID token) in addition to the server side grIdp already
  implements. This is treated as a first-class part of the design, not an
  edge case.
- End-user authorization (what a token can do) is modeled as scopes,
  claims, and consent — not as the operator RBAC model described in ADR
  0006. These are evaluated at different points in the flow and must not
  share a permission model.

## Consequences

- `IdentityProvider` depends only on the port interface from domain code;
  no OIDC-client-library specifics leak into domain logic — the federated
  adapter owns that complexity (consistent with ADR 0002).
- Supporting a new upstream federation protocol (e.g. SAML) later is an
  additive adapter, not a change to the port contract, provided the
  contract is designed generically enough from the start (a concrete risk
  to watch for when implementing the first adapter).
- Static end-user identity (declared via files) and federated end-user
  identity (delegated to an upstream IdP) can coexist per realm, since the
  port, not the realm model, is what's swappable.
