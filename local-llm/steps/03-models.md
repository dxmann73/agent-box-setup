# Step 03 — Obtain models

Goal: three GGUF models on disk, one per test class, with filename and quantization recorded.

---

## 1. Create the model directory

```bash
mkdir -p ~/models
```

`llama.cpp` can use local GGUF files and can also fetch compatible models from Hugging Face with
its `-hf` option. For repeatable benchmarking, keep the actual GGUF files locally and record the
exact filename and quantization in every benchmark.

## 2. Pick the models

Model sizes and repositories change. Search Hugging Face for current GGUF conversions rather than
copying an old download URL:

<https://huggingface.co/models?library=gguf>

| Test | Model class                                      | Suggested quantization | Purpose                                              |
| ---- | ------------------------------------------------ | ---------------------- | ---------------------------------------------------- |
| A    | 7–8B dense                                       | Q4_K_M or Q4_0         | sanity check / compare with published 890M results   |
| B    | ~30–32B dense                                    | Q4_K_M                 | expose the DDR5 bandwidth limitation                 |
| C    | large MoE, e.g. Qwen3-Coder-Next / Qwen3-Next 80B | Q4_K_M initially       | exploit the 96 GB capacity                           |

For the closest comparison with the published ROCm benchmark, use **Llama 2 7B Q4_0** for test A.
For actual daily use, pick a newer 7–14B model.

## 3. Record what you downloaded

For each file, note filename, quantization and on-disk size — these go into every benchmark log
entry (see [step 09](09-benchmark-method.md)).

```bash
ls -lh ~/models | tee ~/llm-bench/results/models.txt
```

---

Next: [step 04 — 7B baseline](04-bench-7b.md)
