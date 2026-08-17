# AGENT.md

## Repository Overview & Architecture

`local-llm` is a lightweight, Unix-shaped local LLM toolkit optimized for Apple Silicon (Metal acceleration). It deliberately avoids monolithic daemons or opaque managers like Ollama in favor of explicit, inspectable shell wrappers, standard GGUF files, and OpenAI-compatible `/v1` endpoints.

### Dual-Backend Architecture
Inference backends are switchable on the fly via the `LLM_BACKEND` environment variable (default: `llama`):
1. **`llama.cpp` (Default)**: Direct Metal acceleration for GGUF model files using `llama-cli`, `llama-server`, and `llama-completion`.
2. **Apple `MLX` (`LLM_BACKEND=mlx`)**: Native Apple MLX execution using `mlx-lm` inside the Python virtual environment (`.venv/`).

### Standard Model Aliases
- **`qwen`**: High-capability coding and complex reasoning model (e.g. Qwen 27B / dense).
- **`mini`**: Fast, lightweight model for everyday Q&A, Git commit generation, and CLI pipe operations (e.g. Ministral 8B).

---

## Model Upgrade Runbook

Follow these exact steps whenever upgrading an existing model alias (such as `qwen` or `mini`) or swapping upstream versions.

### Step 1: Upstream Model Discovery & Selection

1. **`llama.cpp` GGUF Backend**:
   - Prefer standard GGUF repositories maintained by [bartowski](https://huggingface.co/bartowski) or official model providers.
   - Use standard K-quants:
     - Heavy / Coding (`qwen`): `Q6_K` (or `Q4_K_M` if running low on RAM).
     - Lightweight (`mini`): `Q5_K_M` (or `Q4_K_M`).
   - ⚠️ **Important**: Avoid `Q4_0_X_X` "ARM" quants — they bypass Apple Silicon Metal GPU acceleration and run on CPU only.

2. **Apple `MLX` Backend**:
   - Target models from [mlx-community](https://huggingface.co/mlx-community) or official MLX quantized repositories (typically `4bit`).

---

### Step 2: Codebase Reference Checklist

When bumping a model, update all of the following files:

| File | What to Update | Example / Context |
|---|---|---|
| `pull-models.sh` | `<ALIAS>_REPO` and `<ALIAS>_FILE` constants, plus header comments. | GGUF Hugging Face repo & filename. |
| `bin/ask-llama` | `<ALIAS>_FILE` constant. | GGUF filename located in `~/lab/llm/models`. |
| `bin/ask-mlx` | `<ALIAS>_MLX_MODEL` default fallback in `export <ALIAS>_MLX_MODEL="${...:-...}"`. | Hugging Face MLX model ID. |
| `bin/llm-serve` | Both `case` blocks: MLX model ID (for `BACKEND=mlx`) and GGUF path + context length `CTX` (for `llama`). | Server entry point. |
| `bin/<alias>` | Default MLX model ID and GGUF filename path. | Interactive chat wrapper (e.g. `bin/qwen`, `bin/mini`). |
| `Taskfile.yml` | Benchmark task (`llama-bench` GGUF path and `mlx_lm.benchmark` model ID). | Performance benchmarking. |
| `README.md` | Models summary table and usage comments. | Documentation and architecture tables. |

---

### Step 3: Disk Cleanup & Downloading

GGUF models are large (5 GB to 25+ GB). Always clean up superseded models to avoid running out of disk space:

```bash
# 1. Remove old GGUF files and download metadata
rm -f models/<Old_Model_File>.gguf models/.cache/huggingface/download/<Old_Model_File>.gguf.metadata

# 2. Clear any stale lock or incomplete files
rm -f models/.cache/huggingface/download/*.incomplete models/.cache/huggingface/download/*.lock

# 3. Pull new models (idempotent)
./pull-models.sh
```

*Note: MLX models are downloaded and cached dynamically by `transformers` / `mlx-lm` into `~/.cache/huggingface/hub` upon first invocation.*

---

### Step 4: Verification & Test Suite

Always run the BATS test suite after making changes:

```bash
# Run all unit and integration tests
bats tests/

# Or via go-task
task test
```

Ensure all tests pass and verify that mock binaries in `tests/mocks/` continue to simulate tool invocations properly without regressions.
