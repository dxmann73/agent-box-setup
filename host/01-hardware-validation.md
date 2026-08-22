# 01 – Hardware validation

Verify that graphics, laptop power features and displays work on the host. This is permanent host
knowledge, re-run it after kernel or Mesa changes — it is not migration-only.

The GPU results here are the precondition for the local model runtime
([`../local-llm/`](../local-llm/), specification §10).

## 1. Verify AMDGPU

Run:

```bash
lspci -k | grep -EA4 'VGA|Display'
```

The Radeon 890M should report:

```text
Kernel driver in use: amdgpu
```

Inspect messages if necessary:

```bash
sudo dmesg | grep -i amdgpu
```

For ordinary graphics, use the kernel/Mesa AMD stack rather than installing a random proprietary
graphics-driver package.

## 2. Verify Vulkan and Mesa

```bash
sudo apt install -y vulkan-tools mesa-vulkan-drivers mesa-utils
vulkaninfo --summary
glxinfo -B
```

Save the baseline:

```bash
mkdir -p ~/system-info
vulkaninfo --summary | tee ~/system-info/vulkan.txt
glxinfo -B | tee ~/system-info/mesa.txt
```

The Radeon 890M should appear in Vulkan. This matters for both Steam/Proton and `llama.cpp`.

Do not add experimental Mesa PPAs initially.

## 3. Test suspend/resume

Repeat this several times:

```text
normal use
→ close lid
→ wait
→ reopen
```

Test short and long suspends, battery and AC power, Wi-Fi reconnect, Bluetooth and external
displays.

After a problematic resume:

```bash
journalctl -b -1
journalctl -k -b -1
```

Suspend reliability is more important for a laptop than many benchmark differences.

A running agent VM changes suspend behavior. Re-test suspend/resume once the VM from
[`../vm/`](../vm/) is running continuously (specification §14).

## 4. External displays and docking

Test the configurations you actually use:

- laptop display;
- HDMI;
- USB-C display;
- USB-C dock;
- multiple displays;
- different refresh rates;
- suspend/resume while docked.

KDE configuration is under:

```text
System Settings
→ Display & Monitor
```

## 5. Hardware checklist

- [ ] 96 GB RAM detected
- [ ] Radeon 890M uses AMDGPU
- [ ] Vulkan detects Radeon 890M
- [ ] Wi-Fi stable
- [ ] Bluetooth stable
- [ ] speakers work
- [ ] microphone works
- [ ] webcam works
- [ ] touchpad works
- [ ] brightness control works
- [ ] suspend/resume works repeatedly
- [ ] battery life acceptable
- [ ] USB-C works
- [ ] external display works
- [ ] dock works if applicable

## 6. Appendix: power and thermal diagnostics (optional)

None of this is setup — it is measurement, and it is only worth doing when something is actually
wrong (short battery life, fan noise, thermal throttling). Kubuntu's stock power management is the
starting point and usually the ending point. Skip this section on a first pass.

### Power profiles

Check:

```bash
powerprofilesctl
powerprofilesctl get
powerprofilesctl list
```

Start with Kubuntu's stock power management.

Do not immediately install TLP and several other overlapping power-management tools.

### Battery measurements

Install:

```bash
sudo apt install -y powertop
sudo powertop
```

Measure idle consumption under repeatable conditions before optimizing.

Do not automatically apply every `powertop --auto-tune` recommendation; some power-saving settings
can affect peripherals.

### Thermals

```bash
sudo apt install -y lm-sensors
sudo sensors-detect
sensors
```

For monitoring:

```bash
watch -n 2 sensors
```

Test temperatures during compilation, gaming and later local-LLM inference.

Do not stack TLP, `powertop --auto-tune` and the stock power management on top of each other; the
overlapping settings are what makes power problems hard to diagnose.

Next: [02-applications.md](02-applications.md)
