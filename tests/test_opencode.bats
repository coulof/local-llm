#!/usr/bin/env bats

setup() {
  export PATH="${BATS_TEST_DIRNAME}/mocks:$PATH"
  export LLM_LOG_DIR="${BATS_TEST_DIRNAME}/mocks_logs"
  export MODEL_DIR="${BATS_TEST_DIRNAME}/mocks_models"
  mkdir -p "$MODEL_DIR"
  touch "${MODEL_DIR}/Qwen3.8-27B-Q6_K.gguf"
}

teardown() {
  rm -rf "${BATS_TEST_DIRNAME}/mocks_logs" "${BATS_TEST_DIRNAME}/mocks_models"
}

@test "opencode-local: reuses running server and launches opencode TUI" {
  export MOCK_WARM_SERVER=1
  run bin/opencode-local
  [ "$status" -eq 0 ]
  [[ "$output" == *"already running on :8080"* ]]
  [[ "$output" == *"mock_opencode called with: "* ]]
  [[ "$output" != *"Starting llm-serve"* ]]
}

@test "opencode-local: injects --model for 'run' subcommand" {
  export MOCK_WARM_SERVER=1
  run bin/opencode-local qwen run "hello"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_opencode called with: run --model llama.cpp/qwen hello"* ]]
}

@test "opencode-local: keeps user-provided --model" {
  export MOCK_WARM_SERVER=1
  run bin/opencode-local run -m other/model "hi"
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_opencode called with: run -m other/model hi"* ]]
}

@test "opencode-local: refuses when a different model is served" {
  export MOCK_WARM_SERVER=1 MOCK_SERVED_MODEL=mini
  run bin/opencode-local qwen
  [ "$status" -eq 1 ]
  [[ "$output" == *"already serving 'mini'"* ]]
  [[ "$output" != *"mock_opencode"* ]]
}

@test "opencode-local: warns when running server context is too small" {
  export MOCK_WARM_SERVER=1 MOCK_N_CTX=16384
  run bin/opencode-local qwen
  [ "$status" -eq 0 ]
  [[ "$output" == *"n_ctx=16384"* ]]
}

@test "opencode-local: reports startup failure with log tail" {
  export MOCK_WARM_SERVER=0 LLM_WAIT_SECS=3
  run bin/opencode-local qwen
  [ "$status" -eq 1 ]
  [[ "$output" == *"Starting llm-serve qwen (ctx 65536)"* ]]
  [[ "$output" == *"exited during startup"* ]]
  [[ "$output" == *"mock_llama_server called with"* ]]
  [[ "$output" == *"--alias qwen"* ]]
}
