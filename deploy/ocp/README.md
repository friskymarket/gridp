# deploy/ocp

OpenShift Container Platform manifests. Not yet populated — see
`docs/ARCHITECTURE.md` for the intended shape (ConfigMaps for
non-secret GitOps entities, Secrets or OpenBao injection for sensitive
data, per `docs/ADR/` entries on secrets management).

Per the `devops` tooling conventions for this project: Podman/Buildah for
image builds, `oc` for cluster interaction — see container build files
once added (named `Containerfile`, not `Dockerfile`).
