//! Entry point for the token service: OAuth2/OIDC/FAPI protocol logic,
//! token issuance/validation, signing-key handling.
//!
//! See `docs/ARCHITECTURE.md` and
//! `docs/ADR/0001-language-boundaries.md` for why this is Rust, and
//! `docs/ADR/0002-hexagonal-architecture.md` for why `domain` must only
//! depend on `ports`, never directly on an adapter's infra library.

mod adapters;
mod api;
mod domain;
mod ports;

fn main() {
    todo!("not implemented yet");
}
