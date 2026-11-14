# 0009 - Valkey for distributed caching

Status: Accepted

## Context

Keycloak uses Infinispan for multi-pod caching because it embeds its
cache in-process (per JVM instance) and needs to replicate that in-memory
state across pods via JGroups. grIdp does not embed caching in-process —
caching needs (session/token introspection hot path, rate limiting,
OIDC nonce/`state` replay prevention, JWKS caching, compiled GitOps
config — see `docs/ARCHITECTURE.md`) were already identified as a
`RateLimiter`/cache port with an external "real" adapter.

Running on Kubernetes/OpenShift, it was initially unclear whether a
Raft-based coordination layer was needed for this. Raft is a consensus
protocol for strongly-consistent coordination (leader election, config
state) — it is not itself a caching technology, and is not what Infinispan
uses either (Infinispan uses its own embedded-cache replication via
JGroups, not Raft).

## Decision

- **Valkey** (the open-source Redis fork, Linux Foundation governed) is
  the "real" adapter for the caching/rate-limiting port(s) described in
  `docs/ARCHITECTURE.md`.
- Valkey is deployed as an **external, shared** service — pods are
  stateless with respect to caching and simply talk to the same Valkey
  instance/cluster over the network. This avoids the embedded-cache
  replication problem Infinispan solves for Keycloak, because there is no
  per-pod cache state to replicate in the first place.
- Valkey's own high availability (Sentinel for quorum-based failover, or
  Valkey Cluster for gossip-based sharding/replication) is an operational
  concern for whoever deploys it (Helm chart/operator), not something
  application code needs to reason about.
- No custom Raft (or other consensus protocol) implementation is needed
  for caching. Where strongly-consistent coordination *is* needed (e.g.
  leader election so only one reconciler replica applies GitOps changes
  at a time), the answer is Kubernetes' native `Lease` API (backed by
  etcd, which itself uses Raft) — not something to reimplement. This is
  recorded separately if/when leader election is actually designed.

## Consequences

- No dependency on an embedded-cache library or JVM-style cache
  replication machinery.
- Valkey becomes a required piece of infrastructure for the "real"
  deployment, consistent with the no-infra adapter still existing for
  dev/testing (see `docs/ADR/0002-hexagonal-architecture.md`).
- Any future need for strongly-consistent distributed coordination should
  default to Kubernetes-native primitives first, before considering a
  bespoke consensus implementation.
