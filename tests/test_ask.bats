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

@test "ask: routes to warm server completions by default" {
  export MOCK_WARM_SERVER=1
  run bin/ask "What is Kubernetes?" < /dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_warm_server_response"* ]]
}

@test "ask: fallback cold-loading (llama backend) formats correctly" {
  export MOCK_WARM_SERVER=0
  export LLM_BACKEND=llama
  run bin/ask "What is Kubernetes?" < /dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_llama_completion called with"* ]]
  [[ "$output" == *"[INST]"* ]]
}

@test "ask: fails with clean error during cold fallback when model file is missing (llama backend)" {
  export MOCK_WARM_SERVER=0
  export LLM_BACKEND=llama
  export MODEL_DIR="${BATS_TEST_DIRNAME}/nonexistent_models"
  run bin/ask "What is Kubernetes?" < /dev/null
  [ "$status" -eq 1 ]
  [[ "$output" == *"Error: Model file not found"* ]]
  [[ "$output" == *"pull-models.sh"* ]]
}

@test "ask: fallback cold-loading (mlx backend) formats correctly" {
  export MOCK_WARM_SERVER=0
  export LLM_BACKEND=mlx
  run bin/ask "What is Kubernetes?" < /dev/null
  [ "$status" -eq 0 ]
  [[ "$output" == *"mock_python called with"* ]]
  [[ "$output" == *"mock_python_generation_result"* ]]
}

@test "ask: handles stdin correctly" {
  export MOCK_WARM_SERVER=0
  export LLM_BACKEND=mlx
  run bash -c 'echo "hello stdin" | bin/ask'
  [ "$status" -eq 0 ]
  [[ "$output" == *"hello stdin"* ]]
}
