# Specs

This project's core principle is "implement the spec, don't invent a
mechanism" (see `AGENTS.md`). This document lists the specs relevant to
`grIdp`, grouped by area, with a status for each. It exists both as an
implementation checklist and as the authoritative list of what "spec
compliance" means for this project — if something isn't listed here and
isn't in a spec, it should be questioned before being built.

Status values:

- **Not started** — not yet implemented.
- **In progress** — partially implemented.
- **Done** — implemented and (ideally) covered by tests.
- **Deferred** — relevant, but intentionally out of scope for now.
- **Not planned** — considered and explicitly rejected for this project's scope.

## Core OAuth2

| Spec | Title | Status |
|---|---|---|
| [RFC 6749](https://www.rfc-editor.org/rfc/rfc6749) | The OAuth 2.0 Authorization Framework | Not started |
| [RFC 6750](https://www.rfc-editor.org/rfc/rfc6750) | Bearer Token Usage | Not started |
| [RFC 7009](https://www.rfc-editor.org/rfc/rfc7009) | Token Revocation | Not started |
| [RFC 7636](https://www.rfc-editor.org/rfc/rfc7636) | PKCE (Proof Key for Code Exchange) | Not started |
| [RFC 7662](https://www.rfc-editor.org/rfc/rfc7662) | Token Introspection | Not started |
| [RFC 8252](https://www.rfc-editor.org/rfc/rfc8252) | OAuth 2.0 for Native Apps | Deferred |
| [RFC 8414](https://www.rfc-editor.org/rfc/rfc8414) | Authorization Server Metadata (`.well-known/oauth-authorization-server`) | Not started |
| [RFC 8628](https://www.rfc-editor.org/rfc/rfc8628) | Device Authorization Grant | Deferred |
| [RFC 8693](https://www.rfc-editor.org/rfc/rfc8693) | Token Exchange | Deferred |
| [RFC 9068](https://www.rfc-editor.org/rfc/rfc9068) | JWT Profile for OAuth 2.0 Access Tokens | Not started |
| [RFC 9126](https://www.rfc-editor.org/rfc/rfc9126) | Pushed Authorization Requests (PAR) | Not started |
| [RFC 9207](https://www.rfc-editor.org/rfc/rfc9207) | Authorization Server Issuer Identification | Not started |
| [draft-ietf-oauth-v2-1](https://datatracker.ietf.org/doc/draft-ietf-oauth-v2-1/) | OAuth 2.1 (consolidates best practices: PKCE mandatory, implicit/password grants removed) | Not started — used as the baseline profile of RFC 6749 rather than the legacy spec |

## OpenID Connect (OIDC)

| Spec | Title | Status |
|---|---|---|
| [OIDC Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html) | OpenID Connect Core (ID Tokens, UserInfo, authentication flows) | Not started |
| [OIDC Discovery 1.0](https://openid.net/specs/openid-connect-discovery-1_0.html) | Discovery (`.well-known/openid-configuration`) | Not started |
| [OIDC Dynamic Client Registration 1.0](https://openid.net/specs/openid-connect-registration-1_0.html) | Dynamic Client Registration | Deferred — clients are GitOps-declared (see `docs/ADR/0003-gitops-files-and-runtime-state-split.md`); may revisit for a self-service registration flow later |
| [OIDC Session Management 1.0](https://openid.net/specs/openid-connect-session-1_0.html) | Session Management | Not started |
| [OIDC Front-Channel Logout 1.0](https://openid.net/specs/openid-connect-frontchannel-1_0.html) | Front-Channel Logout | Not started — see `docs/ADR/0004-event-sourced-audit-trail.md` |
| [OIDC Back-Channel Logout 1.0](https://openid.net/specs/openid-connect-backchannel-1_0.html) | Back-Channel Logout | Not started — see `docs/ADR/0004-event-sourced-audit-trail.md` |
| [OIDC RP-Initiated Logout 1.0](https://openid.net/specs/openid-connect-rpinitiated-1_0.html) | RP-Initiated Logout | Not started |
| [RFC 7515](https://www.rfc-editor.org/rfc/rfc7515) | JSON Web Signature (JWS) | Not started |
| [RFC 7516](https://www.rfc-editor.org/rfc/rfc7516) | JSON Web Encryption (JWE) | Deferred |
| [RFC 7517](https://www.rfc-editor.org/rfc/rfc7517) | JSON Web Key (JWK) | Not started |
| [RFC 7518](https://www.rfc-editor.org/rfc/rfc7518) | JSON Web Algorithms (JWA) | Not started |
| [RFC 7519](https://www.rfc-editor.org/rfc/rfc7519) | JSON Web Token (JWT) | Not started |

## Security extensions (OAuth2/OIDC)

| Spec | Title | Status |
|---|---|---|
| [RFC 9449](https://www.rfc-editor.org/rfc/rfc9449) | DPoP (Demonstrating Proof of Possession) | Not started |
| [RFC 8705](https://www.rfc-editor.org/rfc/rfc8705) | Mutual-TLS Client Authentication and Certificate-Bound Access Tokens | Not started |
| [RFC 9101](https://www.rfc-editor.org/rfc/rfc9101) | JWT-Secured Authorization Request (JAR) | Not started |
| [draft-ietf-oauth-jwsreq / JARM](https://openid.net/specs/openid-financial-api-jarm.html) | JWT Secured Authorization Response Mode (JARM) | Not started |
| [RFC 8176](https://www.rfc-editor.org/rfc/rfc8176) | Authentication Method Reference Values | Deferred |
| [RFC 9470](https://www.rfc-editor.org/rfc/rfc9470) | Step Up Authentication Challenge | Deferred |

## FAPI (Financial-grade API)

| Spec | Title | Status |
|---|---|---|
| [FAPI 1.0 Baseline](https://openid.net/specs/openid-financial-api-part-1-1_0.html) | FAPI 1.0 Part 1: Baseline Security Profile | Not started |
| [FAPI 1.0 Advanced](https://openid.net/specs/openid-financial-api-part-2-1_0.html) | FAPI 1.0 Part 2: Advanced Security Profile | Not started |
| [FAPI 2.0 Security Profile](https://openid.net/specs/fapi-2_0-security-profile.html) | FAPI 2.0 Security Profile (successor to 1.0 Advanced) | Not started — target profile once FAPI work begins, rather than 1.0 Advanced, since 2.0 is the current direction of the spec |
| [FAPI 2.0 Message Signing](https://openid.net/specs/fapi-2_0-message-signing.html) | FAPI 2.0 Message Signing | Deferred |
| [FAPI-CIBA](https://openid.net/specs/openid-financial-api-ciba-ID1.html) | FAPI CIBA (Client-Initiated Backchannel Authentication) Profile | Not planned — no current use case |

## Identity federation (upstream IdP, see `docs/ADR/0005-identity-provider-port.md`)

| Spec | Title | Status |
|---|---|---|
| OIDC Core 1.0 (relying-party role) | Using grIdp as an OIDC relying party against an upstream IdP | Not started |
| [SAML 2.0 Core](https://docs.oasis-open.org/security/saml/v2.0/saml-core-2.0-os.pdf) | SAML 2.0 | Deferred — only if a concrete federation use case requires it (see open question in `docs/ARCHITECTURE.md`) |

## Multi-factor / WebAuthn (future)

| Spec | Title | Status |
|---|---|---|
| [WebAuthn Level 2/3](https://www.w3.org/TR/webauthn-3/) | Web Authentication (passkeys / hardware security keys) | Deferred |
| [CTAP2](https://fidoalliance.org/specs/fido-v2.0-ps-20190130/fido-client-to-authenticator-protocol-v2.0-ps-20190130.html) | Client to Authenticator Protocol | Deferred |

## Not planned

Specs considered but explicitly out of scope, with rationale:

- **SAML as a first-class protocol grIdp itself speaks as an IdP** (as
  opposed to consuming SAML from an upstream IdP via federation) — out of
  scope; this project's focus is OAuth2/OIDC/FAPI.
- **OAuth 2.0 Implicit Grant** and **Resource Owner Password Credentials
  Grant** — removed in OAuth 2.1 and considered insecure; not implemented
  even for legacy compatibility.

## Maintaining this document

When starting work on a spec, update its status to "In progress"; when
implemented and tested, update to "Done" and link the relevant ADR or
code location. If a decision changes a spec's status to "Deferred" or
"Not planned" after being "Not started", explain why in this table or in
an ADR if the reasoning is substantial enough to warrant one.
