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

@test "llm-serve: executes llama-server by default" {
  export LLM_BACKEND=llama
  run bin/llm-serve mini
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_llama_server called with"* ]]
}

@test "llm-serve: fails with clean error when model file is missing (llama backend)" {
  export LLM_BACKEND=llama
  export MODEL_DIR="${BATS_TEST_DIRNAME}/nonexistent_models"
  run bin/llm-serve mini
  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Model file not found"* ]]
  [[ "$output" == *"pull-models.sh"* ]]
}

@test "llm-serve: executes serve-mlx and python under MLX backend" {
  export LLM_BACKEND=mlx
  run bin/llm-serve mini
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_python called with"* ]]
  [[ "$output" == *"mlx_lm.server"* ]]
}

@test "llm-serve: gives each slot its own context with a quantized KV cache" {
  export LLM_BACKEND=llama
  run bin/llm-serve qwen
  [ "$status" -eq 0 ]
  [[ "$output" == *"-np 2 --kv-unified-per-slot 65536"* ]]
  [[ "$output" == *"-ctk q8_0 -ctv q8_0"* ]]
  [[ "$output" != *" -c "* ]]
}

@test "llm-serve: honours LLM_CTX, LLM_PARALLEL and LLM_KV_TYPE overrides" {
  export LLM_BACKEND=llama LLM_CTX=8192 LLM_PARALLEL=1 LLM_KV_TYPE=f16
  run bin/llm-serve mini
  [ "$status" -eq 0 ]
  [[ "$output" == *"-np 1 --kv-unified-per-slot 8192"* ]]
  [[ "$output" == *"-ctk f16 -ctv f16"* ]]
}
