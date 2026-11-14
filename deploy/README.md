# deploy

Deployment artifacts for grIdp.

- `compose/` — local development stack (currently RabbitMQ; Postgres,
  Valkey, and OpenBao to be added as those adapters are implemented). Not
  a production deployment target.
- `ocp/` — OpenShift Container Platform manifests (Kustomize or Helm, TBD)
  for actual deployment, including ConfigMap/Secret delivery of the
  GitOps entity files (realms, clients, RBAC, operator group mappings —
  see `docs/ARCHITECTURE.md`).
