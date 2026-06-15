#!/bin/bash
# pull-models.sh — download the GGUFs into ~/lab/llm/models. Idempotent.
# The wrappers in bin/ are static files (committed) — this script does NOT
# generate them; it only fetches models.
set -euo pipefail

MODEL_DIR="${HOME}/lab/llm/models"
mkdir -p "${MODEL_DIR}"

# Coding workhorse: Qwen3.6-27B dense, Q6_K (~22 GB). Q4_K_M (~17 GB) if you
# want two models resident; Q8_0 (~28 GB) for max fidelity.
QWEN_REPO="bartowski/Qwen_Qwen3.6-27B-GGUF"
QWEN_FILE="Qwen_Qwen3.6-27B-Q6_K.gguf"

# Lightweight generic: Ministral-8B-Instruct-2410, Q5_K_M (~5.7 GB).
# K-quant, NOT the Q4_0_X_X "ARM" quants — those bypass Metal on Apple Silicon.
MINISTRAL_REPO="bartowski/Ministral-8B-Instruct-2410-GGUF"
MINISTRAL_FILE="Ministral-8B-Instruct-2410-Q5_K_M.gguf"

pull() {  # repo  file
  local repo="$1" file="$2"
  if [[ -f "${MODEL_DIR}/${file}" ]]; then
    echo "✓ ${file} already present — skipping"
  else
    echo "↓ pulling ${file} from ${repo}"
    hf download "${repo}" "${file}" --local-dir "${MODEL_DIR}"
  fi
}

pull "${QWEN_REPO}"      "${QWEN_FILE}"
pull "${MINISTRAL_REPO}" "${MINISTRAL_FILE}"

echo
echo "Models in ${MODEL_DIR}:"
ls -lh "${MODEL_DIR}"/*.gguf 2>/dev/null || echo "  (none yet)"
