# From Laptop to Kubernetes

What changes if the local single-user setup from [concepts-and-approach.md](concepts-and-approach.md)
becomes a productive multi-user service on Kubernetes.

---

## 1. Model serving

- Ollama is one possible inference runtime, not the whole platform.
- For production requirements, evaluate specialised serving engines such as vLLM.
- Keep model weights and container image separate where possible.
- Account for a model cache.
- Large models cause significant cold-start times.

## 2. GPU and scheduling

- Treat GPU as a scarce and expensive resource.
- GPU memory is often more decisive than raw GPU utilization.
- Classic path: Kubernetes device plugins and `nvidia.com/gpu`.
- DRA (Dynamic Resource Allocation) as the more modern Kubernetes model for specialised hardware.
- With many models: model placement, warm models and GPU sharing.

## 3. Scaling

LLMs do not scale on the usual signal:

```text
CPU up → more pods
```

Relevant signals instead:

```text
queue length
GPU utilization
GPU memory
TTFT
tokens/s
concurrent sequences
KV cache
```

- Batching raises GPU utilization.
- Continuous batching improves throughput with unevenly sized requests.
- New replicas become available slowly because of model loading — hence model caching and warm
  pools.
- Adding capacity is expensive; scaling out is not instant.

## 4. Health probes

Keep the three Kubernetes probes distinct:

- **Startup:** is runtime + model up?
- **Readiness:** can the server actually accept inference requests?
- **Liveness:** is the process still functioning?

Model loading makes startup and readiness far more important than for a simple REST service.

## 5. Observability

What to measure:

- Time to first token (TTFT)
- Tokens/s
- Request latency
- Queue length
- GPU utilization
- GPU memory
- KV cache usage
- Model load time
- Error rate
- Pod restarts
- OOM kills and rejected requests

## 6. Security and isolation

Security is critical as soon as coding agents are involved — see also
[concepts-and-approach.md](concepts-and-approach.md) for the single-user version of this list.

- Limit tool access: filesystem, shell, network, git.
- Keep secrets out of prompts and logs.
- Plan for prompt injection from repository files, issues and web pages.
- Isolate users, projects and models.
- Provide audit logs for tool calls and model access.

## 7. 20 models on four GPUs

A scheduling and capacity problem:

- Which models stay warm?
- Which are loaded on demand?
- How expensive is model swapping?
- Can workloads share GPUs?
- Which requests get queued?
- Which models get priority?
- How is GPU memory accounted for?

---

## Open questions

### Why not just Ollama on a VM?

For a single user that can be entirely sufficient — though whether it beats a subscription on cost
is questionable. With multiple users, models and GPUs, scheduling, isolation, scaling, recovery and
observability problems appear.

### How do you scale LLM inference?

Not on CPU. Queue length, TTFT, tokens/s, GPU utilization, GPU memory, active sequences and KV
cache are the interesting signals. Also account for model loading making extra capacity expensive
to start.

### What happens on GPU OOM?

Look at the memory consumers: **weights + KV cache + runtime + parallel requests.** Then reduce
quantization, context limit or concurrency, use a smaller model, or move to hardware with more
memory.

---

The project-level conclusion — local LLM inference is a resource-management problem — lives in
[concepts-and-approach.md](concepts-and-approach.md).
