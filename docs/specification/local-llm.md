# Local LLM — Specification

What the local-LLM effort has to deliver on the laptop.

- Rationale, concepts, caveats and findings: [concepts-and-approach.md](../../local-llm/concepts-and-approach.md)
- Execution guide and step index: [implementation.md](../../local-llm/implementation.md)

---

## 1. Goal

Get from a freshly updated Kubuntu install to a machine that runs useful LLM inference locally,
with measured evidence of what it can and cannot do, and a local coding agent on top.

---

## 2. Target system

| Component | Value                                |
| --------- | ------------------------------------ |
| Laptop    | XMG EVO 14 (E25)                     |
| CPU/APU   | AMD Ryzen AI 9 HX 370                |
| GPU       | Radeon 890M (RDNA 3.5, `gfx1150`)    |
| Memory    | 96 GB (2 × 48 GB Kingston DDR5-5600) |
| OS        | Kubuntu 26.04 LTS, already installed |

---

## 3. Requirements

1. **Verified GPU stack**

   - The AMD/Vulkan stack must be verified before anything is built on top of it.
   - `vulkaninfo --summary` reports the Radeon 890M on Mesa/RADV.
   - `llama-cli --list-devices` sees the GPU.

2. **Locally built `llama.cpp`**

   - Built from upstream source, not a distro package.
   - Vulkan backend is mandatory.
   - A ROCm/HIP build is optional; if built, it is kept **alongside** the Vulkan build, not
     replacing it.
   - The exact source revision is recorded.

3. **Model set**

   - Three GGUF model classes on disk, one per test class:
     - a fast 7–14B dense model,
     - a high-quality ~30–32B dense model,
     - an 80B-class MoE model.
   - Filename and quantization recorded per model.

4. **Benchmarks**

   - CPU and Vulkan numbers recorded for all three model classes.
   - If a ROCm build exists, the identical benchmarks are repeated against it.
   - Every measurement repeated at least three times under identical conditions.
   - Kernel, Mesa and `llama.cpp` versions recorded with every result.

5. **Benchmark history**

   - `~/llm-bench/README.md` holds one filled-in log entry per test.
   - The history must still be interpretable and comparable in six months.

6. **Backend selection**

   - A backend/model combination is chosen per use case, justified by the recorded numbers.

7. **Local coding agent**

   - Ollama serves a local model over its OpenAI-compatible API.
   - Codex talks to it at `http://localhost:11434/v1`; inference stays local.

8. **Stock configuration first**

   - Kernel memory parameters (GTT) are changed only if a large model fails to offload on the
     stock configuration.

---

## 4. Target end state

```text
Kubuntu 26.04 LTS
│
├── Mesa/RADV + Vulkan
│   └── llama.cpp Vulkan build
│
├── ROCm/HIP (optional)
│   └── llama.cpp ROCm build
│
├── ~/models/
│   ├── fast 7–14B model
│   ├── high-quality ~30B model
│   └── large MoE model
│
├── ~/llm-bench/
│   └── reproducible benchmark history
│
└── Ollama
    └── Codex against http://localhost:11434/v1
```

---

## 5. Definition of done

- [ ] `vulkaninfo --summary` reports the Radeon 890M on Mesa/RADV
- [ ] `llama-cli --list-devices` sees the GPU
- [ ] CPU and Vulkan numbers recorded for 7B, 32B and MoE
- [ ] Each measurement repeated at least three times under identical conditions
- [ ] `~/llm-bench/README.md` contains a filled-in log entry per test
- [ ] A backend/model combination chosen per use case
- [ ] Codex talking to a local model over Ollama's OpenAI-compatible API

---

## 6. Out of scope

- Building an inference server. Ollama is used as-is as the convenience layer.
- Multi-user or production serving. The Kubernetes outlook is a separate thought experiment:
  [kubernetes.md](../../local-llm/kubernetes.md).
