//! Pure OAuth2/OIDC/FAPI domain logic: token issuance rules, grant
//! validation, PKCE/DPoP verification, consent rules.
//!
//! Must depend only on traits defined in `crate::ports`, never on a
//! specific crypto/HTTP/storage crate directly (see
//! `docs/ADR/0002-hexagonal-architecture.md`).
