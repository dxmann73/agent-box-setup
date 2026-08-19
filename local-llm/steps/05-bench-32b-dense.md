# Step 05 — ~30–32B dense benchmark

Goal: measure a dense model large enough to expose the memory-bandwidth ceiling of this machine.

---

## 1. Set the model

```bash
MODEL32=~/models/YOUR-32B-Q4_K_M.gguf
```

## 2. Vulkan

```bash
./build-vulkan/bin/llama-bench \
  -m "$MODEL32" \
  -ngl 99 \
  -fa 1 \
  -p 512 \
  -n 128 \
  2>&1 | tee ~/llm-bench/results/32b-vulkan.txt
```

## 3. CPU

```bash
./build-vulkan/bin/llama-bench \
  -m "$MODEL32" \
  -ngl 0 \
  -p 512 \
  -n 128 \
  2>&1 | tee ~/llm-bench/results/32b-cpu.txt
```

---

## What to expect

A published test on an HX 370 with **96 GB dual-channel DDR5-5600** measured Qwen2.5-Coder 32B
Q4_K_M at about **3.54 generation tok/s** in CPU inference. That machine is very close to this one
in the characteristics that matter here.

Reference: <https://github.com/ggml-org/llama.cpp/issues/19480>

This illustrates the central limitation for dense large models: **memory bandwidth, not memory
capacity**.

```text
5600 MT/s × 16 bytes = 89.6 GB/s theoretical
```

Real sustained bandwidth available to an LLM is lower. A ~19 GB dense model must move a large
fraction of its weights per generated token, so 30–32B dense models fit easily but will not
necessarily be fast.

---

Next: [step 06 — large MoE benchmark](06-bench-large-moe.md)
