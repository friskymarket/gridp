# internal/grpcapi

gRPC service implementations for the internal management API (see
`docs/ADR/0007-grpc-internal-api.md`). Generated code from `proto/v1`
lands here (or in a dedicated `genpb` subpackage); hand-written service
implementations translate gRPC requests into calls against
`internal/domain`.
