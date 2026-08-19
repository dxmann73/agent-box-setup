# Implementation

How to satisfy [the specification](../docs/specification/local-llm.md) on this machine. Each step
below is a self-contained file in [steps/](steps/) with commands and verification.

Read [concepts-and-approach.md](concepts-and-approach.md) first if you want to know *why* the order
is what it is.

---

## Steps

| #  | Step                                                              | Covers spec §  | Required?        |
| -- | ----------------------------------------------------------------- | -------------- | ---------------- |
| 01 | [System prep and Vulkan verification](steps/01-system-prep.md)     | 3.1            | yes              |
| 02 | [Build llama.cpp with Vulkan](steps/02-build-llama-cpp.md)         | 3.2            | yes              |
| 03 | [Obtain models](steps/03-models.md)                                | 3.3            | yes              |
| 04 | [7B baseline: CPU, Vulkan, interactive](steps/04-bench-7b.md)      | 3.4            | yes              |
| 05 | [~30–32B dense benchmark](steps/05-bench-32b-dense.md)             | 3.4            | yes              |
| 06 | [Large MoE benchmark](steps/06-bench-large-moe.md)                 | 3.4            | yes              |
| 07 | [GTT kernel tuning](steps/07-gtt-tuning.md)                        | 3.8            | only if 06 fails |
| 08 | [ROCm/HIP second backend](steps/08-rocm.md)                        | 3.2, 3.4       | optional         |
| 09 | [Benchmark method, matrix and log](steps/09-benchmark-method.md)   | 3.4, 3.5, 3.6  | yes              |
| 10 | [Ollama and the coding agent](steps/10-ollama-and-agent.md)        | 3.7            | yes              |

Step 09 is listed last but its rules — charger connected, three runs, log every version — apply
from step 04 onward. Skim it before you take the first measurement.

---

## Execution order

```text
Kubuntu fully updated
        │
        ▼
Verify AMDGPU + Vulkan/RADV                     (step 01)
        │
        ▼
Build llama.cpp Vulkan                          (step 02)
        │
        ▼
Obtain 7B / 32B / MoE GGUFs                     (step 03)
        │
        ▼
7B CPU baseline → 7B Vulkan                     (step 04)
        │
        ▼
32B CPU + Vulkan                                (step 05)
        │
        ▼
Large MoE Vulkan                                (step 06)
        │
        ├── works and fully offloads ──► leave GTT settings alone
        │
        └── memory/offload problem ───► investigate GTT carefully   (step 07)
        │
        ▼
Install supported ROCm stack                    (step 08)
        │
        ▼
Build separate llama.cpp HIP binary
        │
        ▼
Repeat identical benchmarks                     (step 09)
        │
        ▼
Choose backend per model
        │
        ▼
Add Ollama + Codex on top                       (step 10)
```

---

## Rules while executing

- **Baseline before tuning.** Do the Vulkan tests before changing kernel memory parameters or
  installing ROCm. A clean baseline makes troubleshooting far easier and lets any later improvement
  be attributed to a specific change.
- **One change at a time.** Do not tune several things in the same measurement round.
- **Do not proceed past a failed verification.** Every step ends with a check; a later step built on
  an unverified one produces numbers that mean nothing.
- **Record versions with every number** (kernel, Mesa, `llama.cpp` commit, GGUF file).
- **Keep both builds.** ROCm does not replace Vulkan.

---

## Done

Work through the [definition of done](../docs/specification/local-llm.md#5-definition-of-done) once
step 10 is finished. Record findings in [concepts-and-approach.md](concepts-and-approach.md#6-findings-so-far).

---

*Commands and compatibility details should be rechecked against current llama.cpp and AMD ROCm
documentation when executing this guide — both projects evolve quickly.*
