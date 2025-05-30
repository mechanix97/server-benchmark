.PHONY: run-rust run-elixir run-go run-ab

run-rust:
	@echo "Running Rust server..."
	@cd rust && cargo run --release

run-elixir:
	@echo "Running Elixir server..."
	@cd elixir/lib && elixir server.ex

run-go:
	@echo "Running Go server..."
	@cd go && go run server.go
