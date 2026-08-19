# Step 04 — 7B baseline: CPU, Vulkan, interactive

Goal: a CPU baseline and a Vulkan result for the 7B model, plus a first interactive sanity check.

Before taking any number, skim the measurement rules in
[step 09](09-benchmark-method.md) — charger connected, same power profile, three runs.

---

## 1. Set the model

```bash
MODEL=~/models/YOUR-7B-Q4.gguf
```

## 2. CPU baseline

Benchmark on CPU only *before* testing the GPU.

```bash
cd ~/llama.cpp

./build-vulkan/bin/llama-bench \
  -m "$MODEL" \
  -ngl 0 \
  -p 512 \
  -n 128
```

Then save it:

```bash
./build-vulkan/bin/llama-bench \
  -m "$MODEL" \
  -ngl 0 \
  -p 512 \
  -n 128 \
  2>&1 | tee ~/llm-bench/results/7b-cpu.txt
```

Reading the output:

- `pp512` — prompt processing of 512 tokens.
- `tg128` — generation of 128 tokens.

For interactive use, **`tg` is the number that corresponds to the tokens/second you feel while the
model is answering.**

## 3. Vulkan

First confirm llama.cpp sees the 890M:

```bash
./build-vulkan/bin/llama-cli --list-devices
```

Then:

```bash
./build-vulkan/bin/llama-bench \
  -m "$MODEL" \
  -ngl 99 \
  -fa 1 \
  -p 512,2048 \
  -n 128,256
```

Save it:

```bash
./build-vulkan/bin/llama-bench \
  -m "$MODEL" \
  -ngl 99 \
  -fa 1 \
  -p 512,2048 \
  -n 128,256 \
  2>&1 | tee ~/llm-bench/results/7b-vulkan.txt
```

- `-ngl 99` asks llama.cpp to offload essentially all model layers to the GPU.
- `-fa 1` enables Flash Attention.

## 4. Published comparison point

A public `llama.cpp` ROCm benchmark uses essentially the same hardware: Ryzen AI 9 HX 370, Radeon
890M, **96 GB DDR5-5600**, `gfx1150`, 7B Q4_0, 99 GPU layers. It reports roughly **16.1 tok/s for
`tg128`** and about **417 tok/s for `pp512`**, with Flash Attention disabled in that particular run.

Reference: <https://github.com/ggml-org/llama.cpp/discussions/15021>

Do not expect a Vulkan number to match a ROCm result exactly. The useful question is whether you
are in the same general performance class.

## 5. Try it interactively

```bash
./build-vulkan/bin/llama-cli \
  -m "$MODEL" \
  -ngl 99 \
  -fa on \
  -c 8192 \
  -cnv
```

Watch the startup output — it should report the Vulkan device and GPU offloading.

For a local HTTP server:

```bash
./build-vulkan/bin/llama-server \
  -m "$MODEL" \
  -ngl 99 \
  -fa on \
  -c 8192 \
  --host 127.0.0.1 \
  --port 8080
```

Then open <http://127.0.0.1:8080>.

**Security:** do not bind the server to `0.0.0.0` unless you actually want other machines on your
network to reach it. It has no authentication.

---

Next: [step 05 — ~30–32B dense benchmark](05-bench-32b-dense.md)
