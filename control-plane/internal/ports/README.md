# internal/ports

Port interfaces consumed by `internal/domain`: `EventPublisher`,
`SessionStore`, `RealmRepository`, `ClientRepository`, `RBACRepository`,
`IdentityProvider`, `OperatorDirectory`, `SigningKeyProvider`,
`RateLimiter` (see `docs/ARCHITECTURE.md`).

Every port here must have at least two adapters in `internal/adapters`:
a "real" infra adapter and a no-infrastructure adapter.
