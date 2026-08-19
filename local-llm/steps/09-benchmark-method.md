# Step 09 — Benchmark method, matrix and log

Goal: numbers that are comparable to each other and still meaningful in six months.

These rules apply from [step 04](04-bench-7b.md) onward — read them before the first measurement,
not after the last.

---

## 1. Measurement conditions

Laptop benchmarks are sensitive to temperature and power management. For meaningful results:

1. connect the charger;
2. select the same XMG/Kubuntu performance profile each time;
3. close browsers and other heavy applications;
4. let the laptop reach a stable temperature;
5. use the same `llama.cpp` commit;
6. use the exact same GGUF file;
7. run each test at least three times.

Record the power mode:

```bash
powerprofilesctl get
```

Install sensors so CPU temperature/frequency can be recorded while testing:

```bash
sudo apt install -y lm-sensors
sudo sensors-detect
sensors
```

## 2. Benchmark matrix

Use this as the first serious comparison:

| Model            | Backend | GPU layers | FA  | pp  | tg  |
| ---------------- | ------- | ---------- | --- | --- | --- |
| 7B Q4            | CPU     | 0          | on  | 512 | 128 |
| 7B Q4            | Vulkan  | 99         | on  | 512 | 128 |
| 7B Q4            | ROCm    | 99         | on  | 512 | 128 |
| 32B Q4_K_M       | CPU     | 0          | on  | 512 | 128 |
| 32B Q4_K_M       | Vulkan  | 99         | on  | 512 | 128 |
| 32B Q4_K_M       | ROCm    | 99         | on  | 512 | 128 |
| 80B-class MoE Q4 | CPU     | 0          | on  | 512 | 128 |
| 80B-class MoE Q4 | Vulkan  | 99         | on  | 512 | 128 |
| 80B-class MoE Q4 | ROCm    | 99         | on  | 512 | 128 |

For the winning configurations, repeat with:

```text
pp: 512, 2048, 8192
tg: 128, 512
```

This separates prompt-ingestion performance from sustained generation.

## 3. Keep a benchmark log

```bash
nano ~/llm-bench/README.md
```

Record for every test:

```text
Date:
Kubuntu version:
Kernel:
Mesa version:
llama.cpp commit:
Backend:
Model:
GGUF quantization:
GGUF size:
Context:
Flash Attention:
GPU layers:
Power profile:
Prompt-processing tok/s:
Generation tok/s:
Peak RAM:
Notes:
```

This matters because six months later a newer Mesa/kernel/llama.cpp combination may be
substantially faster — or may introduce a regression. Without the recorded versions you cannot tell
which.

## 4. Interpreting the results

### Dense models

Nearly all weights participate in generating every token, so DDR5-5600 bandwidth dominates as model
size grows. Expect 7–14B to feel considerably more responsive than dense 32B or 70B.

### MoE models

Very large total parameter count, small active subset per token. Unusually well matched to this
laptop:

- 96 GB RAM keeps a very large model resident;
- only a subset of weights is active per token;
- the 890M can use the unified/shared memory architecture;
- Vulkan can expose large amounts of that memory to llama.cpp.

This is why an 80B MoE can generate faster than a much smaller dense model.

### Context size

Large context consumes extra memory through the KV cache and raises prompt-processing cost. Do the
initial benchmarks at modest context sizes; once a backend/model combination is stable, test 8K,
16K and larger contexts separately.

---

Next: [step 10 — Ollama and the coding agent](10-ollama-and-agent.md)
