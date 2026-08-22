# 02 – Kubuntu installation

Getting Kubuntu 26.04 LTS onto the machine next to Windows. Installation only — hardware
validation and everything permanent about the host lives in
[`../host/01-hardware-validation.md`](../host/01-hardware-validation.md).

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

## 5. Secure Boot

If everything works with Secure Boot enabled, leave it enabled.

Do not disable it merely because some Linux instructions mention doing so. Revisit the setting only
if a specific required kernel module creates a real issue.

## 6. Installation checklist

- [ ] Kubuntu boots reliably
- [ ] Windows still boots
- [ ] EFI System Partition intact
- [ ] system fully updated
- [ ] baseline recorded in `~/system-info/`
- [ ] Secure Boot state decided

Next: [`../host/01-hardware-validation.md`](../host/01-hardware-validation.md)
