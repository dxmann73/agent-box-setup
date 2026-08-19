# 01 – Preparation of the Windows system

Everything in this file happens **before** the Kubuntu installer is started, while Windows is still
the only installed OS. See [README.md](README.md) for the overall plan.

## 1. Keep Windows initially

Do not erase Windows during the first installation. Keep dual boot until you have verified:

- suspend/resume and battery life;
- Wi-Fi, Bluetooth, webcam, microphone and audio;
- USB-C, docking and external displays;
- Steam games and controllers;
- Microsoft Office workflow;
- CapCut replacement/workflow;
- development tools;
- local LLMs.

Office desktop, CapCut, and some anti-cheat games are the strongest reasons you may still need
Windows.

## 2. Back up Windows

Before repartitioning:

1. Back up all important files.
2. Preferably create Windows recovery media or a system image.
3. Record the BitLocker/device-encryption recovery key if encryption is enabled.
4. Confirm that the backup can actually be accessed.

BitLocker information: <https://support.microsoft.com/windows/bitlocker-drive-encryption>

## 3. Update firmware

Check XMG's current BIOS/firmware instructions before installing Linux:
<https://www.xmg.gg/en/support/>

Recommended baseline:

```text
Boot mode:       UEFI
Legacy/CSM:      Disabled
Secure Boot:     Leave enabled initially
Fast Boot:       Prefer disabled during setup
```

Do not start changing AMD UMA/memory or power settings yet. Establish a stock baseline first.

## 4. Disable Windows Fast Startup

Windows Fast Startup can leave NTFS volumes partially hibernated, which is undesirable in dual boot.

In Windows:

```text
Control Panel
→ Hardware and Sound
→ Power Options
→ Choose what the power buttons do
→ Change settings that are currently unavailable
→ Disable "Turn on fast startup"
```

Then perform a full shutdown.

Do not hibernate Windows and subsequently mount its system volume read/write from Linux.

## 5. Plan disk space

Local models and Steam games consume substantial storage.

| Use | Suggested Linux space |
| --- | --- |
| Evaluation | 150–200 GB |
| Normal primary OS | 300–500 GB |
| Gaming + local LLMs | 500 GB+ |
| Large game/model collection | 1 TB+ if available |

A 32B GGUF may consume roughly 20 GB, while large MoE models can consume 40–80+ GB each.

If you have two NVMe drives, installing Linux on a separate physical drive can simplify recovery and
partition management.

## 6. Shrink Windows from Windows

If sharing one SSD, use Windows Disk Management:

```text
Win + X
→ Disk Management
→ select Windows partition
→ Shrink Volume
```

Leave the resulting area **unallocated**. Do not create Linux filesystems from Windows.

## 7. Download Kubuntu

Get Kubuntu 26.04 LTS from <https://kubuntu.org/getkubuntu/>

Verify the ISO's SHA-256 checksum against the official value.

Windows PowerShell:

```powershell
Get-FileHash .\kubuntu-*.iso -Algorithm SHA256
```

Linux:

```bash
sha256sum kubuntu-*.iso
```

## 8. Create the installer USB

Suitable tools:

- Rufus: <https://rufus.ie/>
- balenaEtcher: <https://etcher.balena.io/>
- Ventoy: <https://www.ventoy.net/>

Use GPT/UEFI rather than legacy BIOS/CSM.

## Checklist

- [ ] important files backed up and backup verified
- [ ] Windows recovery media or system image created
- [ ] BitLocker recovery key recorded
- [ ] BIOS/firmware updated, UEFI without CSM
- [ ] Fast Startup disabled and full shutdown performed
- [ ] unallocated space created via Disk Management
- [ ] Kubuntu ISO downloaded and checksum verified
- [ ] bootable UEFI installer USB created

Next: [02-kubuntu-installation.md](02-kubuntu-installation.md)
