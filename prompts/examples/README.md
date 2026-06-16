# Example prompts

This directory holds **sanitized, shareable** prompts. Everything else under
`prompts/` is gitignored (it may carry customer context). Only files under
`prompts/examples/` are committed.

## commit-message

```bash
git diff --staged | ask "Write a Conventional Commits message for this diff. \
One subject line under 72 chars, then a short body if warranted."
```

## explain-k8s-event

```bash
kubectl get events --sort-by=.lastTimestamp | ask -m qwen \
  "Summarize what's going wrong in this cluster and the most likely cause."
```

## fr-to-en first pass

```bash
ask -m qwen "Translate to natural English, keep technical terms" < draft.fr.md
```

## Running with MLX

All of these examples work seamlessly under the Apple Silicon-native MLX backend. Simply prefix any `ask` execution with the `LLM_BACKEND=mlx` environment variable:

```bash
git diff --staged | LLM_BACKEND=mlx ask "Write a Conventional Commits message..."
```
