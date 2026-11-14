# internal/adapters

Concrete implementations of the port interfaces in `internal/ports`.
Organize one subpackage per adapter, e.g.:

```
adapters/
├── file/        # RealmRepository, ClientRepository, RBACRepository,
│                # IdentityProvider, OperatorDirectory (no-infra adapters)
├── postgres/    # SessionStore
├── rabbitmq/    # EventPublisher (RabbitMQ Streams)
├── valkey/      # RateLimiter, caching
├── openbao/     # SigningKeyProvider
├── ldap/        # OperatorDirectory
└── entra/       # OperatorDirectory
```

No code outside this directory (and `cmd/`, for wiring) should import a
specific infra client library directly (see
`docs/ADR/0002-hexagonal-architecture.md`).
