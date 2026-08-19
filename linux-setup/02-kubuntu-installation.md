# 02 – Kubuntu installation and hardware validation

First installation of Kubuntu 26.04 LTS and verification that the base system works: desktop,
graphics, and laptop power features. No application installation yet — that is
[03-software-installation.md](03-software-installation.md).

## 1. Test the live environment

Boot the USB and choose to try Kubuntu before installing.

Check hardware:

```bash
lspci
lspci -k | grep -EA4 'VGA|Display'
ip link
wpctl status
lsusb
free -h
lscpu
```

Confirm that approximately 96 GB RAM is visible.

Test Wi-Fi, Bluetooth, keyboard, touchpad, brightness, speakers, microphone, webcam, USB ports and,
if practical, an external monitor.

## 2. Install Kubuntu

If the installer reliably offers:

```text
Install Kubuntu alongside Windows Boot Manager
```

that is the simplest dual-boot choice.

For manual partitioning, a simple layout is adequate:

```text
Existing EFI System Partition
    → reuse
    → DO NOT FORMAT

Linux root partition
    → ext4
    → mount point /
    → most/all Linux space
```

A separate `/home` is optional. A dedicated swap partition is generally unnecessary for a normal
modern installation.

**Never format the existing EFI System Partition during a dual-boot installation.** Formatting it
destroys the Windows boot entry.

## 3. Encryption

Disk/filesystem encryption is useful on a laptop. If the Kubuntu installer offers a supported
encrypted setup compatible with your desired dual-boot layout, consider enabling it.

Keep the recovery/passphrase information somewhere safe. Avoid experimental storage configurations
during the first installation.

## 4. First boot

Immediately update the installed system:

```bash
sudo apt update
sudo apt full-upgrade -y
sudo reboot
```

Then record the baseline:

```bash
mkdir -p ~/system-info

{
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
  echo "=== GPU ==="
  lspci -k | grep -EA4 'VGA|Display'
} | tee ~/system-info/initial-system.txt
```

## 5. Verify AMDGPU

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

## 6. Verify Vulkan and Mesa

```bash
sudo apt install -y vulkan-tools mesa-vulkan-drivers mesa-utils
vulkaninfo --summary
glxinfo -B
```

Save the baseline:

```bash
vulkaninfo --summary | tee ~/system-info/vulkan.txt
glxinfo -B | tee ~/system-info/mesa.txt
```

The Radeon 890M should appear in Vulkan. This matters for both Steam/Proton and `llama.cpp`.

Do not add experimental Mesa PPAs initially.

## 7. Test suspend/resume

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

## 8. Power profiles

Check:

```bash
powerprofilesctl
powerprofilesctl get
powerprofilesctl list
```

Start with Kubuntu's stock power management.

Do not immediately install TLP and several other overlapping power-management tools.

## 9. Battery measurements

Install:

```bash
sudo apt install -y powertop
sudo powertop
```

Measure idle consumption under repeatable conditions before optimizing.

Do not automatically apply every `powertop --auto-tune` recommendation; some power-saving settings
can affect peripherals.

## 10. Thermals

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

## 11. External displays and docking

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

## 12. Secure Boot

If everything works with Secure Boot enabled, leave it enabled.

Do not disable it merely because some Linux instructions mention doing so. Revisit the setting only
if a specific required kernel module creates a real issue.

## 13. Base-system checklist

- [ ] Kubuntu boots reliably
- [ ] Windows still boots
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

Next: [03-software-installation.md](03-software-installation.md)
