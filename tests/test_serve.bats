#!/usr/bin/env bats

setup() {
  export PATH="${BATS_TEST_DIRNAME}/mocks:$PATH"
  export VENV_DIR="${BATS_TEST_DIRNAME}/mocks_venv"
}

@test "llm-serve: executes llama-server by default" {
  export LLM_BACKEND=llama
  run bin/llm-serve mini
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_llama_server called with"* ]]
}

@test "llm-serve: executes serve-mlx and python under MLX backend" {
  export LLM_BACKEND=mlx
  run bin/llm-serve mini
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_python called with"* ]]
  [[ "$output" == *"mlx_lm.server"* ]]
}
