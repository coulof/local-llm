#!/usr/bin/env bats

setup() {
  export PATH="${BATS_TEST_DIRNAME}/mocks:$PATH"
  export VENV_DIR="${BATS_TEST_DIRNAME}/mocks_venv"
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
