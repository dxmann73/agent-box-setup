# Step 10 — Ollama and the coding agent

Goal: a local coding agent (Codex) doing real work against a model served by Ollama on this
machine.

Do this **after** benchmarking. Benchmarking directly with `llama.cpp` first removes extra layers
and gives much better visibility into what the hardware is actually doing. Ollama is added here as
the convenience layer: model management, runtime and an API.

---

## 1. Install Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

Verify the service is up:

```bash
ollama --version
systemctl status ollama --no-pager
curl -s http://localhost:11434/api/version
```

**Security:** Ollama's API has no authentication. Keep it bound to localhost. Do not set
`OLLAMA_HOST=0.0.0.0` unless you deliberately want other machines on the network to use it.

## 2. Pull the models

Use the classes established in the benchmarks:

```bash
ollama pull qwen3-coder:30b
ollama pull gemma3:27b
```

Check what is installed and what is currently resident:

```bash
ollama list
ollama ps
```

Verify inference and tool-calling support:

```bash
curl -s http://localhost:11434/api/chat -d '{
  "model": "qwen3-coder:30b",
  "messages": [{"role": "user", "content": "Say hello in one word."}],
  "stream": false
}'
```

Tool calling reference: <https://docs.ollama.com/capabilities/tool-calling>

## 3. Point Codex at the local endpoint

Ollama exposes an OpenAI-compatible API at `http://localhost:11434/v1`:
<https://docs.ollama.com/api/openai-compatibility>

Add a local provider to the Codex configuration. In this repo that file is
`configs/agents/codex/config.toml`, symlinked to `~/.codex/config.toml` — edit the repo copy, not
the symlink target.

```toml
[model_providers.ollama]
name = "Ollama (local)"
base_url = "http://localhost:11434/v1"
wire_api = "chat"
```

Then run Codex against it, for example:

```bash
codex --oss -m qwen3-coder:30b
```

Or switch the profile permanently by setting `model_provider = "ollama"` and
`model = "qwen3-coder:30b"` in the config. Keep the hosted-model configuration intact so you can
switch back — check the current Codex documentation for the exact key names, they change.

## 4. Verify the inference is actually local

While Codex is working:

```bash
ollama ps
```

The model should show as loaded. Also watch memory and heat:

```bash
watch -n 1 free -h
sensors
```

---

## What to expect

From the experiments so far:

- **Context:** very tight.
- **Tool use:** mixed, but better than expected.
- **Latency:** partly terrible, especially as tasks grow.
- **Cost of local inference:** mostly heat.
- Qwen worked better than gpt-oss.

## Agent frontend notes

| Frontend    | Verdict for a local Ollama backend                                                       |
| ----------- | ---------------------------------------------------------------------------------------- |
| Codex       | **Chosen.** Native support via API, most open of those examined.                         |
| Cursor IDE  | Great editor integration, but local models need an OpenAI-compatible HTTPS endpoint.     |
| Cursor CLI  | Not attempted — no documented local base-URL override.                                   |
| Claude Code | No — built primarily around Anthropic models.                                            |
| Pi          | Still outstanding.                                                                       |

## Security when an agent is involved

- Limit tool access: filesystem, shell, network, git.
- Keep secrets out of prompts and logs.
- Plan for prompt injection from repository files, issues and web pages.
- Isolate users, projects and models.
- Provide audit logs for tool calls and model access.

---

Background: [concepts-and-approach.md](../concepts-and-approach.md) — Kubernetes outlook:
[kubernetes.md](../kubernetes.md)
