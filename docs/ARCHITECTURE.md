# Architecture

Status: Proposed, early design stage. This document reflects the current
thinking and will evolve. Significant decisions are recorded as ADRs in
[`ADR/`](ADR/); this document is the living summary, ADRs are the historical
record of *why*.

## Goals driving the design

This project exists primarily to learn:

1. OAuth2 / OIDC / FAPI by implementing the specs directly.
2. Event-driven architecture, specifically avoiding the common trap of
   treating a relational database as an event bus.
3. Go and Rust, each used deliberately rather than interchangeably.

It is explicitly **not** trying to match the feature surface of Keycloak,
Auth0, or similar — the scope is intentionally smaller and better-defined.

## High-level shape

```
                 ┌─────────────┐
                 │  CLI / TUI  │  (Go) — thin clients over the internal API
                 └──────┬──────┘
                        │ gRPC (internal management API)
                 ┌──────▼──────┐
                 │   Control   │  (Go) — gRPC management API, GitOps
                 │    Plane    │        reconciler, event plumbing
                 └──────┬──────┘
                        │
        ┌───────────────┼──────────────────┬───────────────┐
        │               │                  │               │
┌───────▼──────┐ ┌──────▼──────┐   ┌───────▼──────┐ ┌──────▼──────┐
│ Token Service│ │   Files     │   │ Identity &   │ │  Event Bus  │
│    (Rust)    │ │ (realms,    │   │ Operator     │ │ (RabbitMQ   │
│  OAuth2/OIDC/│ │  clients,   │   │ Directories  │ │  Streams)   │
│  FAPI, crypto│ │  users,RBAC)│   │ (see below)  │ │             │
│  REST/JSON   │ └─────────────┘   └──────────────┘ └──────┬──────┘
│  per spec    │                                             │
└───────┬──────┘                                     ┌───────▼──────┐
        │                                             │ Event Logger │
┌───────▼──────┐                                     │   Service    │
│  Postgres    │                                     │ (audit query)│
│ (sessions,   │                                     └──────────────┘
│  consent,    │
│  refresh     │
│  tokens)     │
└──────────────┘
```

Every arrow above is a port in the hexagonal sense — see
[Hexagonal architecture / ports & adapters](#hexagonal-architecture--ports--adapters).

Note the two different public-facing protocols: the **internal management
API** (CLI/TUI ↔ control plane; realm/client/user/RBAC CRUD) uses gRPC,
chosen for a typed contract shared across the Go/Rust boundary and native
streaming support (e.g. a future "tail the audit log" TUI view). The
**OAuth2/OIDC/FAPI endpoints** (authorization endpoint, token endpoint,
JWKS, etc., served by the token service) are REST/JSON because the specs
require it — this is not a protocol choice, it's spec compliance. See
[`ADR/0007-grpc-internal-api.md`](ADR/0007-grpc-internal-api.md).

## Language boundaries

| Component | Language | Why |
|---|---|---|
| Token service (OAuth2/OIDC/FAPI protocol logic, crypto, signing) | Rust | Correctness and performance matter most here; no GC pauses in the security-critical path; learning goal. |
| Control plane (API, CLI, GitOps reconciler, event plumbing) | Go | Concurrency model is a better teaching ground for event-driven I/O; fast startup, small footprint; learning goal. |

Do not blur this boundary without an ADR (see
[`ADR/0001-language-boundaries.md`](ADR/0001-language-boundaries.md) if it
exists, or propose one).

## Hexagonal architecture / ports & adapters

The domain/core logic depends only on interfaces ("ports") it defines itself.
Every port has at least two adapters: a "real" infra adapter and a
no-infrastructure adapter (file-based, in-memory, or stdout). This is a hard
constraint — see `AGENTS.md`.

| Port | "Real" adapter | No-infra adapter |
|---|---|---|
| `EventPublisher` | RabbitMQ Streams | stdout / append-only local file |
| `SessionStore` | Postgres | Local file (single-instance, not crash-safe for concurrent writers) |
| `RealmRepository` / `ClientRepository` / `RBACRepository` | File adapter (same in both cases — see below) | — |
| `IdentityProvider` (end users — subjects of issued tokens) | `LocalFileAdapter`, `FederatedIdentityAdapter` (delegate to an upstream OIDC/SAML IdP) | `LocalFileAdapter` |
| `OperatorDirectory` (internal operators administering grIdp) | `LDAPAdapter`, `AzureEntraAdapter` | `LocalFileAdapter` |
| `SigningKeyProvider` | OpenBao Transit engine | Local key file |
| `RateLimiter` / cache | Valkey | In-memory map |
| `PluginRuntime` | WASM (`wasmtime`/`wasmer`/`wazero`) | Lua (`gopher-lua`/`mlua`) — both adapters are "real" here, no-infra mode N/A |

Note that `RealmRepository` / `ClientRepository` / `RBACRepository` are
file-based in *both* modes — GitOps files are the declarative source of
truth regardless of which other infra is present. See
[GitOps entities](#gitops-entities-realms-clients-users-rbac).

`IdentityProvider` and `OperatorDirectory` are deliberately separate ports,
not a single "User" abstraction — see
[Three distinct identity concerns](#three-distinct-identity-concerns) below.

The no-infra adapter set is a legitimate dev/demo/single-node mode for
running and testing the core business logic, but is not a production
posture — concurrent writers to the same file will corrupt state. This
should be documented clearly wherever the file adapter is used, not just
here.

## Three distinct identity concerns

It is tempting to model "users" as a single concept, but this system
actually has three distinct identity concerns that must not share a port
or a RBAC model, even where their data happens to look similar:

| Concern | Who | Port | Typical adapters | Authorization model |
|---|---|---|---|---|
| End users | Subjects of the tokens grIdp issues to relying-party apps | `IdentityProvider` | Local file; federated (delegate to an upstream OIDC/SAML IdP) | Scopes / claims / consent, evaluated per OAuth2/OIDC flow |
| Internal operators | People administering grIdp itself (realms, clients, signing keys, audit access) | `OperatorDirectory` | Local file; LDAP; Azure Entra | Platform RBAC (`realm:*`, `client:create`, etc.) |
| OAuth2 clients | Relying-party applications | `ClientRepository` | File (GitOps) | Client credentials / registered grant types, not a user concern at all |

The `IdentityProvider` port matters most when federation is involved:
when an adapter delegates end-user authentication to an upstream IdP,
grIdp is acting as **both an IdP (to the relying party) and an RP (to the
upstream IdP)** for that flow — i.e. it must implement the *client* side
of OIDC in addition to the *server* side. This is a deliberate design
point, not an edge case to special-case later.

The `OperatorDirectory` port exists because enterprise deployments
typically already have a directory (LDAP, Azure Entra) that is the source
of truth for "who is allowed to administer this system," and grIdp should
integrate with it rather than maintain a shadow copy of operator
identities. Directory group membership is mapped to platform RBAC roles
via a dedicated GitOps file (`operator-group-mappings.yaml`, see
[`examples/operator-group-mappings.yaml`](../examples/operator-group-mappings.yaml)),
scoped per realm, deny-by-default for any unmapped group — see
[`ADR/0008-operator-group-role-mapping.md`](ADR/0008-operator-group-role-mapping.md).
This keeps *authentication* (the directory adapter answers "who is this
operator") strictly separate from *authorization* (this mapping file plus
the RBAC role definitions answer "what can they do").

See [`ADR/0005-identity-provider-port.md`](ADR/0005-identity-provider-port.md)
and [`ADR/0006-operator-directory-port.md`](ADR/0006-operator-directory-port.md).

## GitOps entities: realms, clients, users, RBAC

Desired state for these entities lives in plain files (YAML/JSON), the same
pattern used for the RabbitMQ `definitions.json` proof of concept that
preceded this project. A reconciler process reads these files and writes
runtime state; it never writes back to files. This mirrors how the RabbitMQ
management plugin's `load_definitions` works, generalized to the IDP's own
entities.

On OpenShift (OCP), these files are expected to be delivered as ConfigMaps
(non-secret data: realms, clients, roles, RBAC bindings) and Secrets
(client secrets, if not yet migrated to OpenBao — see
[Secrets: OpenBao](#secrets-openbao)).

### Static identity vs. dynamic security state

Users have two distinct kinds of data that must not be conflated:

- **Static identity** (username, realm membership, declared roles): changes
  by Git commit, lives in files, reconciled one-way into runtime state.
- **Dynamic security state** (failed login counters, lockout status, MFA
  enrollment, last password change): changes by user/system action at
  runtime, cannot live in a file without the reconciler and runtime fighting
  over ownership. This lives in Postgres (durable) or Valkey (ephemeral,
  TTL-based) depending on access pattern — see
  [Caching: Valkey](#caching-valkey).

### RBAC

RBAC follows the same GitOps pattern: roles and role bindings are declared
in files, scoped per-realm (an admin of realm A must not implicitly be an
admin of realm B). Permission strings use a `resource:action` format
(e.g. `client:create`, `user:read:self`), with wildcard support
(`realm:*`) to be decided and recorded in an ADR once the shape is final.

RBAC evaluation itself is pure domain logic with no infra dependency, and
should be covered by table-driven/property-based tests once implemented.

## Event model

Two distinct event categories exist, with different durability and
consumption needs. They are **not** the same stream, even though both flow
through the same underlying event bus.

### Audit trail (event-sourced)

The audit trail is the system of record for "what happened." It is:

- Durable and replayable: implemented on **RabbitMQ Streams** (the stream
  queue type), not classic or quorum queues, because classic queues are
  destructively consumed — an acked message is gone, which is incompatible
  with "query this history on demand" from an event logger service.
- Queried on demand by a separate **event logger service**, which reads
  from the stream (potentially replaying from an arbitrary offset) rather
  than duplicating events into a secondary store by default.
- The source of truth for *behavior history* (login attempts, token
  issuance, client/realm/user changes applied by the reconciler, consent
  grants, etc.), complementing Git history as the source of truth for
  *configuration* changes.

### Client notifications (fire-with-retry, not replay-for-history)

Separate from the audit trail: notifying a relying party (OAuth2/OIDC
client) that a user has logged in or out. This is modeled on existing OIDC
specs rather than invented:

- **Back-Channel Logout** / **Front-Channel Logout** (OIDC Session
  Management) for logout notification to clients.
- Login notification follows the equivalent pattern: the IDP core publishes
  a domain event (`UserLoggedIn`, `UserLoggedOut`) to the `EventPublisher`
  port; a dedicated consumer (distinct from the audit logger) performs the
  actual HTTP call to the client's registered endpoint, with its own
  retry/backoff/dead-letter handling.
- This consumer does not need replay-for-history semantics — a login
  notification is only meaningful in the moment it happens — so it may use
  a different underlying primitive (e.g. a classic queue) even though it
  is fed by the same domain event.

## State storage: what goes where

| Data | Storage | Why |
|---|---|---|
| Realms, clients, user static identity, RBAC | Files (ConfigMap/Secret on OCP) | GitOps source of truth, human-authored, changes by commit. |
| Sessions, consent, refresh/offline access tokens | Postgres | Needs strong consistency and point-in-time correctness; GDPR-style deletes are painful under pure event sourcing. |
| Dynamic user security state (lockouts, MFA, failed attempts) | Postgres, or Valkey if purely ephemeral | See static vs. dynamic identity above. |
| Audit trail | RabbitMQ Streams | Durable, replayable, queryable on demand. |
| Client login/logout notifications | Event bus (queue type TBD) | Fire-with-retry, not history. |

## Caching: Valkey

Not required for the core to function (see hexagonal architecture above —
there is always a no-infra adapter), but expected to be introduced
deliberately at these points, not merely "for performance":

1. **Session/token introspection hot path** — read-through cache in front
   of Postgres sessions once request volume makes a DB round-trip per
   request a bottleneck.
2. **Rate limiting / brute-force protection** — atomic increment-with-TTL
   counters for login attempts and token endpoint throttling; doing this in
   Postgres means row-lock contention under load.
3. **OIDC nonce / `state` replay prevention** — nonces and `state`
   parameters must be single-use and short-lived; a TTL cache is the
   natural fit and avoids a Postgres table that needs active
   garbage-collection. This is directly tied to the FAPI/OIDC security
   learning goal, not just a performance optimization, so it is introduced
   early rather than deferred.
4. **JWKS caching** for downstream services validating tokens frequently.
5. **Compiled GitOps config** — once the reconciler parses realms/clients/
   users/RBAC from files, the compiled result can be pushed into Valkey so
   request-time lookups don't repeatedly hit the filesystem or ConfigMap
   API.

Valkey is deployed as an **external, shared** service — pods are
stateless with respect to caching, unlike Keycloak/Infinispan's embedded
per-pod cache replication model. No Raft (or other custom consensus
protocol) is needed for caching; where strongly-consistent coordination
is needed elsewhere (e.g. reconciler leader election), the expected answer
is Kubernetes' native `Lease` API rather than a bespoke implementation.
See [`ADR/0009-valkey-caching.md`](ADR/0009-valkey-caching.md).

## Plugin extensibility: WASM (primary) and Lua (optional)

Custom claim mappers, login/logout event hooks, and future extension
points are modeled as a `PluginRuntime` port — hexagonal, same as every
other infra-facing concern. Two adapters are planned:

- **WASM** (primary): `wasmtime`/`wasmer` for the Rust token service,
  `wazero` for the Go control plane. Chosen specifically because grIdp
  intends to support a **third-party plugin ecosystem**, not only
  in-house trusted plugins — WASM's structural sandboxing (no host
  memory/syscall/network access without an explicitly granted host
  function) and enforceable resource limits (fuel/instruction metering,
  memory caps) matter once plugin authors aren't fully trusted, especially
  given plugins may run inside the authentication/token-issuance path.
- **Lua** (secondary): available for simpler, trusted, in-house scripts
  where the WASM toolchain overhead isn't justified.

The host interface (what data a plugin receives, what it may call) is
deliberately not designed yet — it will be designed once the first
concrete extension points (claim mappers, event hooks) exist, to avoid
guessing at an ABI for use cases that don't exist yet. Once designed, this
interface is a contract subject to the same breaking-change discipline as
the GitOps file schemas and proto contracts, since third parties will
eventually build against it.

See [`ADR/0010-plugin-runtime.md`](ADR/0010-plugin-runtime.md).

## Secrets: OpenBao

Plain files/Secrets are adequate for non-sensitive declarative config, but
secret custody is core to the security model being learned here, not
incidental:

- **Signing keys**: the OIDC token signing key should ideally never leave
  the vault. OpenBao's **Transit engine** can hold the private key and
  expose only a "sign this payload" operation — the key material never
  touches the Rust token service's process memory. This is directly
  relevant to FAPI's stricter key-custody expectations and is planned as a
  deliberate milestone once the basic token flow works, not a "nice to
  have."
- **Client secrets** for confidential clients: generated/rotated via
  OpenBao rather than committed to a ConfigMap-adjacent file.
- **Dynamic Postgres credentials**: OpenBao can mint short-lived DB
  credentials per service instance instead of a static password sitting in
  a Secret indefinitely.

On OCP, the expected integration is a Vault Agent sidecar/init-container
injecting secrets as files or environment variables at pod startup, keeping
the IDP services themselves unaware of *how* secrets are fetched (another
port/adapter boundary).

## Observability (future)

OpenTelemetry (tracing, metrics) is planned once the core flows exist.
Deferred intentionally — observability instrumentation should wrap stable
ports/adapters rather than be threaded through code that is still changing
shape.

## Open questions / not yet decided

- Exact permission-string wildcard semantics for RBAC.
- Whether the client-notification event uses a classic queue, a second
  stream, or something else — needs the actual retry/dead-letter
  requirements worked out first.
- CLI distribution/packaging approach (Go binary via `go install`, OCP-native
  packaging, etc.).
- TUI framework choice (phase 2, deliberately deferred).
- Federation protocol support beyond OIDC (SAML?) for the `IdentityProvider`
  port — deferred until the local-file adapter and OIDC federation adapter
  both exist.
- `PluginRuntime` host interface (ABI) design — deferred until the first
  extension points (claim mappers, event hooks) are implemented concretely.
- Plugin distribution/trust model for a third-party ecosystem (signing,
  review process, registry) — not yet designed.

These should move into ADRs as they get resolved, rather than being edited
silently in place here.
