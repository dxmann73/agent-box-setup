# Step 08 — ROCm/HIP second backend (optional)

Goal: a second `llama.cpp` build against ROCm/HIP, kept alongside the Vulkan build, and an
apples-to-apples comparison between the two.

Only start this once Vulkan is working and benchmarked.

---

## 1. Install ROCm

Use AMD's **current** installation documentation rather than package commands copied from an older
guide:

- <https://rocm.docs.amd.com/projects/install-on-linux/en/latest/>
- <https://rocm.docs.amd.com/>

Check AMD's compatibility documentation before installing — the supported Ubuntu release, kernel
and ROCm combinations change over time.

After installation, verify the stack with the tools the current AMD guide specifies (commonly
including `rocminfo`).

## 2. Build a separate HIP binary

Do not replace the Vulkan build.

```bash
cd ~/llama.cpp

cmake -B build-rocm \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_HIP=ON

cmake --build build-rocm -j "$(nproc)"
```

Check devices:

```bash
./build-rocm/bin/llama-cli --list-devices
```

The 890M should identify as **`gfx1150`**.

## 3. Apples-to-apples comparison

Use exactly the same model, prompt length, generation length and Flash Attention setting.

```bash
MODEL=~/models/YOUR-7B-Q4.gguf
```

Vulkan:

```bash
./build-vulkan/bin/llama-bench \
  -m "$MODEL" \
  -ngl 99 \
  -fa 1 \
  -p 512,2048 \
  -n 128,256 \
  2>&1 | tee ~/llm-bench/results/7b-vulkan-final.txt
```

ROCm:

```bash
./build-rocm/bin/llama-bench \
  -m "$MODEL" \
  -ngl 99 \
  -fa 1 \
  -p 512,2048 \
  -n 128,256 \
  2>&1 | tee ~/llm-bench/results/7b-rocm-final.txt
```

Repeat for the 32B model and the MoE model.

---

## Interpretation warning

Do not decide that one backend is "better" from the 7B result alone. Vulkan and ROCm behave
differently depending on model architecture, quantization, prompt processing versus generation, and
memory pressure. The llama.cpp feature matrix notes that ROCm is generally faster in many cases,
while Vulkan can sometimes have faster text generation:

<https://github.com/ggml-org/llama.cpp/wiki/Feature-matrix>

There have also been ROCm memory-management/OOM issues on 96 GB HX 370 UMA systems — one more
reason to establish the Vulkan baseline first:

<https://github.com/ggml-org/llama.cpp/issues/19818>

---

Next: [step 09 — benchmark method, matrix and log](09-benchmark-method.md)
