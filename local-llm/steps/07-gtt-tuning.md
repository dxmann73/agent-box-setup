# Step 07 — GTT kernel tuning (only if step 06 failed)

Goal: increase the AMD GTT addressable memory pool so a very large Vulkan model can offload.

**Do not do this step by default.** Only proceed if the large MoE model in
[step 06](06-bench-large-moe.md) failed to offload on the stock Kubuntu kernel configuration. If
the model already offloads successfully, leave the kernel parameters alone.

This step edits the bootloader configuration. A wrong kernel command line can leave the machine
unable to boot normally — know how to edit the GRUB entry from the boot menu before you change it.

---

## 1. Record the current state first

```bash
cat /proc/cmdline
free -h
./build-vulkan/bin/llama-cli --list-devices
```

Save this. Without a before-picture you cannot attribute any change to the tuning.

## 2. The reference parameters

A separate HX 370 / 96 GB experiment used:

```text
amdgpu.gttsize=40960 ttm.pages_limit=14680064
```

to enlarge the GTT pool for very large Vulkan models. That experiment ran Qwen3-Next 80B Q8_0 on
the 890M at roughly **10.9–11 tok/s** during a long session with more than 17K effective context.

Reference: <https://github.com/ggml-org/llama.cpp/issues/19396>

Kernel and driver memory behaviour evolves. Treat these values as an **experimental reference, not
a recommended default** — verify against current documentation before applying them.

## 3. Apply, then re-measure

Add the parameters to `GRUB_CMDLINE_LINUX_DEFAULT` in `/etc/default/grub`, run `sudo update-grub`,
reboot, and then re-run [step 06](06-bench-large-moe.md) unchanged. Compare against the recorded
before-picture.

If the result is not better, revert the kernel parameters rather than leaving an unexplained
non-default configuration in place.

---

Next: [step 08 — ROCm/HIP second backend](08-rocm.md)
