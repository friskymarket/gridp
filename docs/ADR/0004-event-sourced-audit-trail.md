# 0004 - Event-sourced audit trail on RabbitMQ Streams, distinct from client notifications

Status: Accepted

## Context

A common failure mode in systems that bolt an "event log" onto a
relational database is that the event log becomes a secondary table that
is polled, locked, and eventually becomes the real bottleneck instead of
the thing it was meant to offload. This project wants an audit trail that
is genuinely durable and replayable, queryable on demand by a separate
event logger service, without that trail degrading into a disguised
database table.

Separately, this project wants to notify relying-party clients when a
user logs in or out. This looks superficially similar to the audit trail
(it's "an event about something that happened") but has different
durability and consumption requirements: it needs to be delivered once,
soon, with retries, and has no value being replayed hours or days later.

RabbitMQ classic (and quorum) queues are destructively consumed — once a
consumer acks a message, it is gone. This is unsuitable as the backing
store for "query this history on demand," which is the stated requirement
for the audit trail's event logger service.

## Decision

- The **audit trail** is event-sourced: it is the system of record for
  "what happened" (login attempts, token issuance, reconciler-applied
  client/realm/user/RBAC changes, consent grants, etc.), complementing Git
  history as the system of record for *configuration* changes.
- The audit trail is implemented on **RabbitMQ Streams** (the stream queue
  type), explicitly not classic or quorum queues, because streams are
  append-only and non-destructively read, supporting replay from an
  arbitrary offset by multiple independent consumers — in particular, the
  event logger service that queries this history on demand.
- **Client login/logout notifications** are modeled on existing OIDC
  specs (Back-Channel Logout / Front-Channel Logout for logout; an
  equivalent pattern for login) rather than invented. They are published
  as domain events (`UserLoggedIn`, `UserLoggedOut`) through the same
  `EventPublisher` port, but consumed by a separate, dedicated consumer
  responsible for the actual HTTP delivery to the client's registered
  endpoint, with its own retry/backoff/dead-letter handling.
- The client-notification consumer does not require replay-for-history
  semantics and may use a different underlying primitive (e.g. a classic
  queue) even though it is fed by the same domain event type as the audit
  trail. The exact choice is an open question (see
  `docs/ARCHITECTURE.md`).

## Consequences

- Two logically separate event flows exist from day one, even where they
  share an underlying event bus: the durable, replayable audit stream, and
  the fire-with-retry client-notification flow. They must not be
  conflated into a single queue/stream with a single consumption model.
- The no-infra adapter for `EventPublisher` (see ADR 0002) uses stdout or
  an append-only local file; it is not expected to support replay-by-
  offset the way RabbitMQ Streams does, and this is an accepted
  limitation of that mode.
- Implementing Back-Channel/Front-Channel Logout means studying and
  following the OIDC Session Management spec directly, per the
  "standards over invention" principle in `AGENTS.md`.
