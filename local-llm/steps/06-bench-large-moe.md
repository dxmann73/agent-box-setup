# Step 06 — Large MoE benchmark

Goal: run an 80B-class MoE model and find out whether it fully offloads on the stock kernel
configuration. This is where the 96 GB configuration becomes interesting.

A relevant target is the **Qwen3-Coder-Next / Qwen3-Next 80B MoE family**.

---

## Read this before running: leave `--no-mmap` alone

An HX 370 / 96 GB report found that `--no-mmap` could cause problematic double allocation on UMA
and lead to OOM behaviour. Full Vulkan offload and ~17.6 tok/s on Qwen3-Coder-Next were obtained by
**not** forcing `--no-mmap`.

**Start with mmap enabled (the default). Do not add `--no-mmap` unless you have a specific measured
reason to do so.**

This is also why old command lines from benchmark threads should not be copied without checking
the later findings in the same thread.

Reference: <https://github.com/ggml-org/llama.cpp/issues/19480>

---

## 1. Set the model

```bash
MODELMOE=~/models/YOUR-QWEN3-CODER-NEXT-GGUF.gguf
```

## 2. Start conservatively

```bash
./build-vulkan/bin/llama-bench \
  -m "$MODELMOE" \
  -ngl 99 \
  -fa 1 \
  -p 512 \
  -n 128 \
  2>&1 | tee ~/llm-bench/results/moe-vulkan.txt
```

## 3. Monitor while it runs

RAM, in a second terminal:

```bash
watch -n 1 free -h
```

Kernel log, if you hit a crash:

```bash
sudo dmesg -w
```

---

## What to expect

A public benchmark on Ryzen AI 9 HX 370 / Radeon 890M / 96 GB DDR5-5600 reported:

- CPU-only Qwen3-Coder-Next Q4_K_M: **~7.74 tok/s**
- Vulkan after full iGPU offload: **~17.6 generation tok/s**
- Vulkan prompt processing: **~53.8 tok/s**

Reference: <https://github.com/ggml-org/llama.cpp/issues/19480>

Note that this can beat the dense 32B result — a MoE keeps many weights resident but activates only
a small subset per token.

---

## Outcome

- **Fully offloads, no memory problems** → leave the kernel parameters alone. Skip step 07 and go
  to [step 08](08-rocm.md) (or straight to [step 09](09-benchmark-method.md) if you skip ROCm).
- **Offload or memory problem** → [step 07 — GTT tuning](07-gtt-tuning.md).
