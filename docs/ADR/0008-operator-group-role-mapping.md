# 0008 - Operator group-to-role mapping as a GitOps file, deny by default

Status: Accepted

## Context

ADR 0006 introduced the `OperatorDirectory` port (LDAP, Azure Entra) for
authenticating internal operators, but deferred how directory group
membership maps to grIdp's platform RBAC roles (ADR 0003). Leaving this
mapping implicit or hardcoded would violate the GitOps-native principle
(`AGENTS.md`) and would conflate *authentication* (who is this operator,
answered by the directory adapter) with *authorization* (what can they
do, answered by RBAC) in a way that's hard to audit.

## Decision

- Operator group → role mappings are declared in a file
  (`operator-group-mappings.yaml`, see
  `examples/operator-group-mappings.yaml` for the shape),
  reconciled the same one-way, file-is-source-of-truth way as realms,
  clients, and RBAC role definitions (ADR 0003).
- Each mapping entry is a tuple of `(directory, group, realm, role)`:
  - `directory` identifies which configured `OperatorDirectory` adapter
    instance the mapping applies to (a deployment may have more than one,
    e.g. during an LDAP → Entra migration).
  - `group` is the directory's native group identifier (LDAP DN, Entra
    group object ID) — not a grIdp-invented name.
  - `realm` scopes the grant to a specific realm, or the explicit literal
    `"*"` for all realms. Wildcard scope must be written explicitly; it is
    never implied by omitting the field.
  - `role` references a role already declared in the RBAC files (ADR
    0003); this file does not define roles itself, only bindings.
- **Deny by default**: an operator who authenticates successfully via the
  directory adapter but has no matching mapping entry for any of their
  groups has zero platform permissions. There is no default/minimal role
  granted implicitly. This mirrors how the directory adapter answers
  "who are you" while this file alone answers "what can you do."

## Consequences

- Authentication and authorization remain cleanly separable: changing
  directory adapters (LDAP → Entra) only requires updating this mapping
  file's `directory`/`group` values, never touching RBAC role
  definitions themselves.
- An operator with a misconfigured or missing mapping is locked out
  rather than silently granted some default access — this is a
  deliberate fail-closed posture appropriate for an identity provider's
  own administration surface.
- This file is subject to the same change discipline as other GitOps
  entities (ADR 0003): its shape is a contract, and changes to that shape
  require an ADR, not a quiet edit.
- The `realm: "*"` wildcard is intentionally explicit rather than
  inferred from an absent field, to make overly broad grants visible in
  review (a missing field being silently treated as "all realms" would be
  a dangerous default).
