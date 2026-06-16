# local-llm

A tiny, opinionated wrapper around [`llama.cpp`](https://github.com/ggml-org/llama.cpp)
for running local models on Apple Silicon — no Ollama, no daemon you didn't ask
for, just bash and GGUFs.

Lives at `~/lab/llm`. Built for a 48 GB M5 Mac; degrades gracefully on less RAM
(pick a smaller quant).

## Layout

```
local-llm/                  # → clone/keep as ~/lab/llm
├── Brewfile.llm            # llama.cpp + huggingface-cli + python/uv
├── pull-models.sh          # fetch GGUFs (does NOT generate wrappers)
├── local.llm.serve.plist   # launchd agent: keep a model warm
├── bin/                    # the wrappers — put THIS on PATH
│   ├── qwen                #   interactive coding chat (supports LLM_BACKEND)
│   ├── mini                #   quick generic chat (supports LLM_BACKEND)
│   ├── llm-serve           #   OpenAI-compatible server on :8080
│   ├── ask                 #   multi-backend router for the pipe-friendly helper
│   ├── ask-llama           #   llama.cpp-specific one-shot logic
│   ├── ask-mlx             #   mlx-lm-specific one-shot logic
│   ├── chat-mlx            #   generic MLX interactive chat helper
│   └── serve-mlx           #   generic MLX OpenAI-compatible server helper
├── prompts/                # local prompts (gitignored except examples/)
│   └── examples/
└── models/                 # GGUFs (gitignored — 20+ GB)
```

The wrappers in `bin/` are **static, hand-edited files** — read them, version
them, change the flags. Nothing generates them.

## Models

| Alias | Model | Quant | ~Size | Use |
|-------|-------|-------|-------|-----|
| `qwen` | Qwen3.6-27B (dense) | Q6_K | ~22 GB | Coding, agentic work, long context |
| `mini` | Ministral-8B-Instruct-2410 | Q5_K_M | ~5.7 GB | Fast everyday Q&A, summaries, drafts |

Both are Apache 2.0 / open-weight, fetched from
[bartowski](https://huggingface.co/bartowski) GGUF repos.

> **Apple Silicon note:** these use K-quants, not the `Q4_0_X_X` "ARM" quants.
> The ARM quants bypass Metal and run on CPU only — slower on an M-series Mac.

## Setup

Prerequisites: Homebrew, GNU bash at `/opt/homebrew/bin/bash`.

```bash
# 0. Place the repo (or clone it) at ~/lab/llm
mv local-llm ~/lab/llm && cd ~/lab/llm

# 1. Install engine + fetcher
brew bundle --file=./Brewfile.llm

# 2. Make the wrappers executable
chmod +x bin/*

# 3. Create python venv & install mlx-lm (for MLX backend support)
uv venv .venv
./.venv/bin/pip install mlx-lm

# 4. Pull models for llama.cpp (~28 GB download)
./pull-models.sh

# 5. Put the wrappers on PATH
export PATH="$HOME/lab/llm/bin:$PATH"
```

Make the PATH change permanent in your shell config:

- **bash** (this setup — login shell is `/opt/homebrew/bin/bash`):
  drop it in a `~/.bashrc.d/llm.sh` block, or append to `~/.bashrc`.
- **zsh** (stock macOS default, if you're on it): append to `~/.zshrc`.

## Engine Selection (MLX vs. llama.cpp)

By default, the wrappers run using **`llama.cpp`** and local GGUFs.
You can switch to the **Apple-native MLX** backend by setting `LLM_BACKEND=mlx`:

```bash
LLM_BACKEND=mlx qwen        # Runs Qwen-32B via MLX
LLM_BACKEND=mlx mini        # Runs Ministral-8B via MLX
LLM_BACKEND=mlx ask "hello" # Runs ask helper via MLX
```

Unlike `llama.cpp` which requires pulling files manually via `./pull-models.sh`, the MLX engine downloads and caches Hugging Face models dynamically in `~/.cache/huggingface/hub` during first-use.

## Usage

```bash
qwen                      # interactive coding chat
mini                      # quick generic chat
llm-serve qwen            # OpenAI-compatible API on :8080

# Talk to the server from anything that speaks /v1
curl -s http://127.0.0.1:8080/v1/chat/completions \
  -H 'Content-Type: application/json' \
  -d '{"messages":[{"role":"user","content":"Explain Longhorn replicas in one line"}]}' \
  | jq -r '.choices[0].message.content'
```

### `ask` — the pipe helper

`ask` reads an instruction, stdin, or both, and prints a plain-text answer to
stdout. If `llm-serve` is running it reuses that warm server; otherwise it
cold-loads a one-shot model.

```bash
ask "what's a PVC in k8s"                  # plain question
git diff | ask "write a commit message"    # stdin = context, arg = instruction
ask "explain this" < script.sh             # same, from a file
kubectl get events | ask                   # stdin only
ask -m qwen "tricky architecture question" # escalate to the 27B model
```

Defaults to `mini`. Set `export ASK_MODEL=qwen` to flip the default.
Start a warm server once (`llm-serve mini &`) and every `ask` after is instant.

## Keep a model warm (launchd)

`local.llm.serve.plist` runs `llm-serve mini` as a per-user login agent — no
sudo, so it's fine on a Fleet-managed Mac.

```bash
mkdir -p ~/lab/llm/logs
cp local.llm.serve.plist ~/Library/LaunchAgents/local.llm.serve.plist
sed -i '' "s|/Users/YOURUSER|$HOME|g" ~/Library/LaunchAgents/local.llm.serve.plist
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/local.llm.serve.plist
launchctl enable gui/$(id -u)/local.llm.serve

# stop / remove
launchctl bootout gui/$(id -u)/local.llm.serve
```

Logs land in `~/lab/llm/logs/serve.{out,err}.log`. Swap `mini` → `qwen` in the
plist's `ProgramArguments` to keep the big model warm instead.

## Tuning

- **More context:** raise `-c` in a wrapper (32K → 64K) at the cost of RAM.
- **More fidelity:** swap `Q6_K` → `Q8_0` in `pull-models.sh` (~28 GB, slower).
- **Two models resident:** drop `qwen` to `Q4_K_M` (~17 GB) so both fit at once.
- **Speed check:** `llama-bench -m models/<file>.gguf` for tok/s on your machine.

## Why no Ollama

Ollama wraps `llama.cpp` and adds a model registry, a background daemon, and its
own storage layout. This repo skips all of that: plain GGUF files you control,
explicit flags you can read, wrappers you can edit. Plain-text, inspectable,
Unix-shaped.

## License

Wrappers: do whatever you like. Models carry their own upstream licenses.
