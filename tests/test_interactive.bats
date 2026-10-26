#!/usr/bin/env bats

setup() {
  export PATH="${BATS_TEST_DIRNAME}/mocks:$PATH"
  export VENV_DIR="${BATS_TEST_DIRNAME}/mocks_venv"
  export MOCK_MODELS_DIR="${BATS_TEST_DIRNAME}/mocks_models"
  mkdir -p "$MOCK_MODELS_DIR"
  touch "${MOCK_MODELS_DIR}/mistralai_Ministral-3-8B-Instruct-2512-Q5_K_M.gguf"
  touch "${MOCK_MODELS_DIR}/Qwen3.8-27B-Q6_K.gguf"
  export MODEL_DIR="$MOCK_MODELS_DIR"
}

teardown() {
  rm -rf "${BATS_TEST_DIRNAME}/mocks_models"
}

@test "mini: executes llama-cli by default" {
  export LLM_BACKEND=llama
  run bin/mini --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_llama_cli called with"* ]]
  [[ "$output" == *"-m "* ]]
  [[ "$output" == *"-ngl 99"* ]]
}

@test "mini: fails with clean error when model file is missing" {
  export LLM_BACKEND=llama
  export MODEL_DIR="${BATS_TEST_DIRNAME}/nonexistent_models"
  run bin/mini --help
  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Model file not found"* ]]
  [[ "$output" == *"pull-models.sh"* ]]
}

@test "mini: executes chat-mlx and python under MLX backend" {
  export LLM_BACKEND=mlx
  run bin/mini --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_python called with"* ]]
  [[ "$output" == *"mlx_lm.chat"* ]]
}

@test "qwen: executes llama-cli by default" {
  export LLM_BACKEND=llama
  run bin/qwen --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_llama_cli called with"* ]]
  [[ "$output" == *"-m "* ]]
  [[ "$output" == *"-ngl 99"* ]]
}

@test "qwen: fails with clean error when model file is missing" {
  export LLM_BACKEND=llama
  export MODEL_DIR="${BATS_TEST_DIRNAME}/nonexistent_models"
  run bin/qwen --help
  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Model file not found"* ]]
  [[ "$output" == *"pull-models.sh"* ]]
}

@test "qwen: executes chat-mlx and python under MLX backend" {
  export LLM_BACKEND=mlx
  run bin/qwen --help
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_python called with"* ]]
  [[ "$output" == *"mlx_lm.chat"* ]]
}
