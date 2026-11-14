# 0010 - Plugin extensibility via a PluginRuntime port, WASM primary, Lua optional

Status: Accepted

## Context

grIdp should be extensible (custom claim mappers, event hooks on
login/logout, and likely further extension points not yet designed), with
a potential **third-party plugin ecosystem** rather than only in-house,
fully-trusted plugin authors. This changes the risk profile considerably:
plugin code may run inside the authentication/token-issuance path, with
access to claims and decision points like "did auth succeed" — a
different severity class than, say, a request-rewrite plugin in a reverse
proxy.

Lua is a well-proven embeddable scripting choice (nginx/OpenResty, Kong,
HAProxy) with mature embedding libraries in both project languages
(`gopher-lua` for Go, `mlua`/`rlua` for Rust) and a small footprint
consistent with this project's scope. However, Lua's sandboxing relies on
careful standard-library stripping (`os`, `io`, `debug`, etc.) — a
"don't shoot yourself in the foot" model rather than a hard security
boundary. WebAssembly (WASM) sandboxing is structural: a wasm module
cannot touch host memory, syscalls, or the network unless explicitly
granted an imported host function, and supports precise resource limits
(fuel/instruction metering, memory caps) — properties that matter more
once plugin authors are not fully trusted.

## Decision

- Plugin execution is modeled as a **port**, `PluginRuntime`, following the
  same hexagonal pattern as every other infra-facing concern (see
  `docs/ADR/0002-hexagonal-architecture.md`). Domain code (e.g. the
  claim-mapping step, the login/logout event-hook dispatch) depends only
  on this port, never on a specific runtime's embedding library.
- **WASM is the primary adapter** (`wasmtime`/`wasmer` for the Rust token
  service, `wazero` for the Go control plane — both avoid cgo,
  consistent with this project's footprint goals), chosen specifically
  because of the third-party trust model: structural sandboxing and
  enforceable resource limits are treated as a requirement, not a nice-to-
  have, for any plugin point that executes inside the auth/token flow.
- **Lua remains available as a second adapter** of the same
  `PluginRuntime` port, for cases where the stronger WASM toolchain
  overhead isn't justified (e.g. simple, trusted, in-house scripts) or
  for plugin authors who prefer Lua's ergonomics. Lua-authored plugins are
  not automatically granted the same trust level as WASM ones purely by
  existing — see open question below.
- The concrete extension points implemented first are **custom claim
  mappers** and **event hooks** (login/logout), per the current stated
  use cases. Further extension points are deliberately not designed yet.

## Consequences

- A stable **host interface** (what data a plugin receives, what host
  functions it may call) must be designed once the first extension
  points (claim mappers, event hooks) are implemented concretely — not
  speculatively before then, since designing an ABI for extension points
  that don't exist yet tends to guess wrong. This host interface becomes
  a contract subject to the same versioning/breaking-change discipline as
  the GitOps file schemas (ADR 0003) and proto contracts (`proto/`), since
  third parties will eventually build against it.
- Supporting two runtimes behind one port means the host interface must
  be runtime-agnostic from the start — avoid leaking WASM-specific or
  Lua-specific concepts into the port contract itself.
- Resource limiting, timeout enforcement, and trust-tiering (e.g.
  "reviewed/signed plugins run with fewer restrictions than unreviewed
  ones") are open design questions, expected to be resolved once a
  concrete third-party distribution story (a plugin registry? signed
  manifests?) is designed — out of scope for this ADR.

## Open questions

- Whether Lua-authored plugins get the same execution guarantees as WASM
  ones, or are restricted to a narrower set of (lower-risk) extension
  points.
- Plugin distribution/trust model for third parties (signing, review
  process, registry) — not yet designed.
