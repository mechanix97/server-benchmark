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

run-ab:
	@echo "Running Apache Benchmark..."
	@ulimit -n 20000 && ab -n 100000 -c 500 -T application/json -p correct_request.json http://localhost:8080/

run-wrk:
	@echo "Running wrk..."
	@ulimit -n 20000 && wrk -t12 -c500 -d20s -s post.lua http://localhost:8080/
