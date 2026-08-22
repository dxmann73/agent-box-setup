# 03 – Staging rules for the migration

Sequencing advice that only applies while moving off Windows. Once the host is stable this file is
obsolete.

## 1. Change one layer at a time

Establish stable stock Kubuntu first, migrate applications second, validate gaming and laptop
behavior third, and only then add the specialized AMD/LLM compute stack and the agent VM.

## 2. Do not install ROCm immediately

For the initial Linux setup, stop once these work:

```text
AMDGPU
Mesa
Vulkan
Steam
suspend/resume
daily applications
```

Only then follow the separate local-LLM guide and add ROCm: <https://rocm.docs.amd.com/>

This gives you a clean baseline: if something breaks after adding the compute stack, you know the
underlying desktop installation worked beforehand.

## 3. Keep Windows until the workflow is proven

Retain the Windows partition until Office files, games and any hardware-specific tooling have been
tested under Linux for several weeks. Decide about removing it after that, not before.

## 4. Do not develop on NTFS

Keep active repositories on ext4 rather than developing directly on a mounted Windows NTFS
filesystem. The same applies to a Steam library shared with Windows.
