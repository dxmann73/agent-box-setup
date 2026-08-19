# Step 02 — Build llama.cpp with Vulkan

Goal: a working upstream `llama.cpp` Vulkan build, with the exact source revision recorded.

Use upstream rather than a distro package, so you get a known, current version and access to
`llama-bench`.

---

## 1. Clone and build

```bash
cd ~
git clone https://github.com/ggml-org/llama.cpp
cd llama.cpp

cmake -B build-vulkan \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_VULKAN=ON

cmake --build build-vulkan -j "$(nproc)"
```

## 2. Confirm the executables

```bash
./build-vulkan/bin/llama-cli --version
./build-vulkan/bin/llama-bench --help | head
./build-vulkan/bin/llama-cli --list-devices
```

`--list-devices` must show the Vulkan device. If it does not, go back to
[step 01](01-system-prep.md) rather than benchmarking a CPU-only build by accident.

## 3. Record the source revision

```bash
git rev-parse HEAD | tee ~/llm-bench/results/llama-cpp-commit.txt
```

Every benchmark result is only meaningful together with this commit.

---

## Reference

- Build documentation: <https://github.com/ggml-org/llama.cpp/blob/master/docs/build.md>
- Project: <https://github.com/ggml-org/llama.cpp>

---

Next: [step 03 — obtain models](03-models.md)
