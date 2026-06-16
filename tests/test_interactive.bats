#!/usr/bin/env bats

setup() {
  export PATH="${BATS_TEST_DIRNAME}/mocks:$PATH"
  export VENV_DIR="${BATS_TEST_DIRNAME}/mocks_venv"
}

@test "mini: executes llama-cli with conversation mode by default" {
  export LLM_BACKEND=llama
  run bin/mini --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_llama_cli called with"* ]]
  [[ "$output" == *"-cnv"* ]]
}

@test "mini: executes chat-mlx and python under MLX backend" {
  export LLM_BACKEND=mlx
  run bin/mini --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_python called with"* ]]
  [[ "$output" == *"mlx_lm.chat"* ]]
}

@test "qwen: executes llama-cli with conversation mode by default" {
  export LLM_BACKEND=llama
  run bin/qwen --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_llama_cli called with"* ]]
  [[ "$output" == *"-cnv"* ]]
}

@test "qwen: executes chat-mlx and python under MLX backend" {
  export LLM_BACKEND=mlx
  run bin/qwen --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_python called with"* ]]
  [[ "$output" == *"mlx_lm.chat"* ]]
}
