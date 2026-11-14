.PHONY: help go-build go-test go-vet rust-build rust-test rust-lint \
        compose-up compose-down test-integration

help:
	@echo "Targets:"
	@echo "  go-build          Build the Go control plane"
	@echo "  go-test           Test the Go control plane"
	@echo "  go-vet            Vet the Go control plane"
	@echo "  rust-build        Build the Rust token service"
	@echo "  rust-test         Test the Rust token service"
	@echo "  rust-lint         Lint the Rust token service (fmt + clippy)"
	@echo "  compose-up        Start the local dev stack (deploy/compose)"
	@echo "  compose-down      Stop the local dev stack"
	@echo "  test-integration  Run cross-component integration tests"

go-build:
	cd control-plane && go build ./...

go-test:
	cd control-plane && go test ./... -race -cover

go-vet:
	cd control-plane && go vet ./...

rust-build:
	cd token-service && cargo build --all-targets

rust-test:
	cd token-service && cargo test

rust-lint:
	cd token-service && cargo fmt --check && cargo clippy --all-targets -- -D warnings

compose-up:
	podman-compose -f deploy/compose/compose.yml up -d

compose-down:
	podman-compose -f deploy/compose/compose.yml down

test-integration:
	@echo "TODO: wire up tests/integration once control-plane and token-service exist"
