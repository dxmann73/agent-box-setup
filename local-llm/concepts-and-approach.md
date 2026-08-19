# Local LLMs: Concepts, Intent, Approach and Caveats

Companion to the [specification](../docs/specification/local-llm.md) and the[implementation guide](implementation.md) for local LLMs.

This file explains the intent, how the effort is framed and why, what the approach is, which caveats bit us, and what has been learned so far.

---

## 1. Intent

Run useful LLM inference locally on a single laptop, understand where the real limits are, and
decide when a local model is actually the better choice than a hosted one.

Concretely, the questions being answered:

- Which models, model sizes and quantizations fit this machine?
- How do Mixture-of-Experts vs. Dense models compare in practice, on real hardware?
- How fast is it really — load time, time to first token, tokens/s, behaviour at larger context?
- Can a local model drive a coding agent?
- What would change if this became a multi-user service e.g. on Kubernetes? (see [kubernetes.md](kubernetes.md))

---

## 2. Hardware context

- **Laptop:** XMG EVO 14 (E25)
- **CPU/APU:** AMD Ryzen AI 9 HX 370
- **GPU:** Radeon 890M (RDNA 3.5, `gfx1150`)
- **Memory:** 96 GB unified (2 × 48 GB Kingston DDR5-5600)
- **OS:** Kubuntu 26.04 LTS

The defining property is 96 GB of *unified* memory on a *dual-channel DDR5-5600* bus. Capacity is
generous; bandwidth is not. That asymmetry drives nearly every result in this project.

```text
5600 MT/s × 16 bytes = 89.6 GB/s theoretical
```

Real sustained bandwidth available to inference is lower.

---

## 3. Core concepts

### 3.1 Parameter count alone says very little

The numbers that actually matter, together:

```text
total parameters
+ active parameters
+ quantization
+ KV cache
=> memory footprint
+ memory bandwidth
+ context length
```



### 3.2 Quantization

Quantization is what makes large local models practical at all:

- 120B × 16 bit ≈ 240 GB
- 120B × ~4 bit ≈ 60 GB + overhead

The trade-off is memory footprint against potential quality loss.

### 3.3 Mixture-of-Experts: memory vs compute

MoE activates only a fraction of the weights per token. This forces a distinction between:

- **Memory:** which weights must be resident and available?
- **Compute:** which weights are actually used for *this* token?

Examples:


| Model           | Total params | Active params/token |
| --------------- | ------------ | ------------------- |
| Qwen3-Coder 30B | ~30.5B       | ~3.3B               |
| gpt-oss 120B    | ~117B        | ~5.1B               |


A MoE model can compute relatively little per token while still needing many weights resident. This
is why an 80B-class MoE can generate *faster* than a much smaller dense model on this machine.

### 3.4 Dense models are bandwidth-bound

For a dense model, nearly all weights participate in every generated token. As model size grows, memory bandwidth becomes the dominant limit. A ~19 GB dense model must move a large fraction of its weights per token — 30–32B dense models fit easily but will not necessarily be fast.

Expect the 7–14B range to feel considerably more responsive than dense 32B or 70B.

### 3.5 KV cache

The KV cache stores already-computed attention states so the model does not recompute the entire
prior context for every new token. It speeds up inference but consumes memory, and grows with
context length and with parallel sequences.

### 3.6 Context is a scarce resource

More context means more prefill work and more memory. Irrelevant context is the opposite of
helpful. This is the reason not to simply hand a whole repository to the model: a good agent
supplies the relevant files and loads only the context actually needed.

---

## 4. Approach

### 4.1 Benchmark on bare llama.cpp first, add convenience layers later

`llama.cpp` removes intermediate layers and gives direct visibility into what the hardware is
doing. Higher-level frontends (Ollama, OpenAI-compatible UIs) come *after* the backend and model
combinations are understood.

### 4.2 Establish a Vulkan baseline before touching anything else

Order matters: verify the AMD/Vulkan stack, build, measure, and only then consider ROCm or kernel
memory parameters. A working stock configuration plus repeatable benchmarks is far more useful than
a heavily tuned configuration whose improvement cannot be attributed to a specific change.

### 4.3 Change one thing at a time

Do not optimize everything simultaneously. Keep the Vulkan and ROCm builds side by side rather than
replacing one with the other — on an unusual UMA system the fastest backend depends on the model
and workload.

### 4.4 Measure what is actually felt

- Load time
- Time to first token (TTFT)
- Tokens per second (`tg` is what you feel while the model answers; `pp` is prompt ingestion)
- Memory consumption
- Behaviour at larger context
- Behaviour under multiple concurrent requests

### 4.5 Agent and model are two separate components

The agent handles context management, tool use, file access, shell and git. The runtime (Ollama,
llama-server) exposes inference over an HTTP API.

```text
Agent
   │  POST /api/chat
   ▼
Ollama
   ▼
Qwen3-Coder
   ▼
Tool call / answer
   ▼
Agent
   ├── read_file
   ├── search
   ├── git diff
   └── run_tests
```

The model may *propose* a tool call. The agent decides which tools exist, what rights they have,
executes them under control, and feeds results back into the model's context.

> A coding agent is not simply a better prompt. The LLM provides reasoning and decisions; the agent
> gives it controlled capabilities to interact with a real development environment.

See [Ollama tool calling](https://docs.ollama.com/capabilities/tool-calling).

### 4.6 Why use Ollama for the agent layer

Main focus is investigating models, not building an inference server. Ollama provides model management, runtime and an API, including an [OpenAI-compatible endpoint](https://docs.ollama.com/api/openai-compatibility). For a production system, the serving engine would be selected against actual requirements instead.

### 4.7 Agent frontend selection


| Frontend    | Verdict for a local Ollama backend                                                       |
| ----------- | ---------------------------------------------------------------------------------------- |
| Codex       | **Chosen.** Points at `http://localhost:11434/v1`; inference stays local.                |
| Cursor IDE  | Excellent editor integration, but local models need an OpenAI-compatible HTTPS endpoint. |
| Cursor CLI  | Not attempted — no documented local base-URL override.                                   |
| Claude Code | No — built primarily around Anthropic models.                                            |
| Pi          | Still outstanding.                                                                       |


---

## 5. Caveats

### 5.1 Do not force `--no-mmap` on this UMA machine

On HX 370 / 96 GB, `--no-mmap` has been reported to cause double allocation on UMA and lead to OOM
behaviour. Full Vulkan offload and ~17.6 tok/s on Qwen3-Coder-Next were obtained by **not** forcing
it. Start with mmap enabled (the default) and add `--no-mmap` only with a specific measured reason.

Reference: [https://github.com/ggml-org/llama.cpp/issues/19480](https://github.com/ggml-org/llama.cpp/issues/19480)

### 5.2 Treat GTT kernel parameters as experimental, not default

Parameters such as `amdgpu.gttsize=40960 ttm.pages_limit=14680064` have been used to enlarge the
GTT pool for very large Vulkan models. Kernel and driver memory behaviour evolves. If the model
already offloads successfully, leave the kernel parameters alone.

Reference: [https://github.com/ggml-org/llama.cpp/issues/19396](https://github.com/ggml-org/llama.cpp/issues/19396)

### 5.3 Do not copy old command lines from benchmark threads

Later findings in the same thread frequently contradict the original post. The `--no-mmap` case is
exactly this pattern.

### 5.4 Published numbers are orientation, not targets

Vulkan results will not match ROCm results exactly. The useful question is whether you are in the
same general performance class. Likewise, do not declare a backend "better" from a single 7B
result — Vulkan and ROCm differ by model architecture, quantization, prompt processing vs
generation, and memory pressure.

### 5.5 Laptop benchmarks are thermally noisy

Charger connected, same power profile, heavy applications closed, stable temperature, same
`llama.cpp` commit, same GGUF file, at least three runs per test. Otherwise the numbers are not
comparable to each other, let alone to anyone else's.

### 5.6 Record versions, or the history is worthless

Kernel, Mesa and `llama.cpp` version all materially change performance. Six months later a newer  
combination may be substantially faster — or introduce a regression. Without recorded versions you  
cannot tell which.

---

## 6. Findings so far

From the Ollama + coding agent experiments:

- **Context:** very tight.
- **Tool use:** mixed, but better than expected.
- **Latency:** partly terrible, especially as tasks grow.
- **Cost of local inference:** mostly heat.
- Working with Qwen was better than with gpt-oss.

Model classes examined:

- **Qwen3-Coder 30B** — coding model; interesting as MoE (~30.5B total, ~3B active per token).
- **Gemma 3 27B** — comparatively compact, capable, and useful for multimodal experiments.
- **gpt-oss 120B** — to see how far the 96 GB unified memory can be pushed.

### Preferred agent

**Codex** — the most open of those examined, native support via API, and pleasant to work with.

---

## 7. Use cases to look at

### Coding

- Understand a repository
- Explain code
- Refactorings
- Generate tests
- Analyse failures
- Agentic coding workflows



### Reasoning / agents

- Tool calling
- Structured outputs
- Multi-step tasks
- Local automation
- Processing confidential information



### Multimodal

- Analyse screenshots
- Interpret diagrams
- Evaluate visual documents
- Process text and image together

---

## 9. The one-line takeaway

Local LLM inference is a **resource-management problem**.

```text
model
  ↓
quantization
  ↓
memory
  ↓
context / KV cache
  ↓
concurrency
  ↓
latency / throughput
```

On the laptop this chain is already visible. On an AI platform the same problems reappear,
distributed across many models, users and GPUs.

---

## References

- llama.cpp project: [https://github.com/ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp)
- llama.cpp build documentation:
[https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md](https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md)
- llama.cpp feature matrix: [https://github.com/ggml-org/llama.cpp/wiki/Feature-matrix](https://github.com/ggml-org/llama.cpp/wiki/Feature-matrix)
- AMD ROCm documentation: [https://rocm.docs.amd.com/](https://rocm.docs.amd.com/)
- AMD ROCm Linux installation: [https://rocm.docs.amd.com/projects/install-on-linux/en/latest/](https://rocm.docs.amd.com/projects/install-on-linux/en/latest/)
- llama.cpp ROCm performance discussion (HX 370 / 890M / 96 GB DDR5-5600):
[https://github.com/ggml-org/llama.cpp/discussions/15021](https://github.com/ggml-org/llama.cpp/discussions/15021)
- Qwen3-Coder-Next HX 370 / 96 GB benchmark and Vulkan follow-up:
[https://github.com/ggml-org/llama.cpp/issues/19480](https://github.com/ggml-org/llama.cpp/issues/19480)
- Qwen3-Next 80B Q8 / HX 370 / 96 GB Vulkan experiment:
[https://github.com/ggml-org/llama.cpp/issues/19396](https://github.com/ggml-org/llama.cpp/issues/19396)
- HX 370 ROCm/GTT OOM investigation: [https://github.com/ggml-org/llama.cpp/issues/19818](https://github.com/ggml-org/llama.cpp/issues/19818)
- GGUF models on Hugging Face: [https://huggingface.co/models?library=gguf](https://huggingface.co/models?library=gguf)
- Ollama tool calling: [https://docs.ollama.com/capabilities/tool-calling](https://docs.ollama.com/capabilities/tool-calling)
- Ollama OpenAI compatibility: [https://docs.ollama.com/api/openai-compatibility](https://docs.ollama.com/api/openai-compatibility)

