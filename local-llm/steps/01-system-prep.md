# Step 01 — System prep and Vulkan verification

Goal: fully updated Kubuntu, a recorded snapshot of the system state, build tooling installed, and
proof that the Radeon 890M is visible to Vulkan.

Do not proceed to step 02 until Vulkan sees the GPU.

---

## 1. Update Kubuntu

```bash
sudo apt update
sudo apt full-upgrade -y
sudo reboot
```

## 2. Record the system state

After the reboot:

```bash
mkdir -p ~/llm-bench/results
cd ~/llm-bench

{
  echo "=== DATE ==="
  date
  echo
  echo "=== OS ==="
  cat /etc/os-release
  echo
  echo "=== KERNEL ==="
  uname -a
  echo
  echo "=== CPU ==="
  lscpu
  echo
  echo "=== MEMORY ==="
  free -h
  echo
  echo "=== PCI GPU ==="
  lspci -k | grep -EA4 'VGA|Display'
} | tee results/system.txt
```

Keep this file with the benchmark results. Kernel, Mesa and `llama.cpp` versions can materially
change performance.

## 3. Install build and Vulkan tooling

```bash
sudo apt install -y \
  build-essential \
  cmake \
  ninja-build \
  git \
  curl \
  wget \
  pkg-config \
  libvulkan-dev \
  glslc \
  vulkan-tools \
  mesa-vulkan-drivers
```

## 4. Verify Vulkan

```bash
vulkaninfo --summary
```

Expect the **AMD Radeon 890M** on the Mesa/RADV Vulkan driver.

```bash
ls -l /dev/dri/
```

There should normally be at least one `renderD*` device.

Save the output:

```bash
vulkaninfo --summary | tee ~/llm-bench/results/vulkan-info.txt
```

---

## Troubleshooting: Vulkan does not detect the 890M

Stop here rather than continuing with `llama.cpp`.

```bash
dmesg | grep -i amdgpu
lspci -k | grep -EA4 'VGA|Display'
```

The kernel driver should be `amdgpu`.

---

Next: [step 02 — build llama.cpp with Vulkan](02-build-llama-cpp.md)
