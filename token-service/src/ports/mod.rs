//! Port traits consumed by `crate::domain`: `SigningKeyProvider`,
//! `SessionStore`, `EventPublisher`, etc. (see `docs/ARCHITECTURE.md`).
//!
//! Every trait here must have at least a no-infrastructure implementation
//! in `crate::adapters` in addition to any "real" infra implementation.
