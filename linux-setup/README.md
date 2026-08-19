# Kubuntu Installation and Windows-to-Linux Migration Guide

Installing Kubuntu 26.04 LTS on an XMG EVO 14 (E25), initially as dual boot next to Windows.

## Target system

- **Laptop:** XMG EVO 14 (E25)
- **Processor:** AMD Ryzen AI 9 HX 370
- **GPU:** Radeon 890M
- **Memory:** 96 GB (2 × 48 GB Kingston DDR5-5600)
- **Linux:** Kubuntu 26.04 LTS
- **Initial strategy:** dual boot with Windows

## Guide index

| File | Scope |
| --- | --- |
| [01-windows-preparation.md](01-windows-preparation.md) | Backup, firmware, Fast Startup, disk planning, installer USB |
| [02-kubuntu-installation.md](02-kubuntu-installation.md) | Live test, install, first boot, GPU/desktop/power validation |
| [03-software-installation.md](03-software-installation.md) | Daily applications, Steam, backups, SSH/firewall |
| [04-development-setup.md](04-development-setup.md) | Developer tooling, runtimes, editors, coding agents |

Follow them in order. The separate local-LLM guide comes only after the basic Kubuntu
installation is stable.

## Intended final configuration

```text
XMG EVO 14 (E25)
│
├── UEFI
├── Windows (retained initially)
│
└── Kubuntu 26.04 LTS
    ├── KDE Plasma
    ├── stock AMDGPU
    ├── stock Mesa/RADV
    ├── Chrome
    ├── VS Code
    ├── Bitwarden
    ├── VLC
    ├── Steam + Proton
    ├── Microsoft 365 Web / LibreOffice
    ├── Kdenlive or CapCut Web
    │
    └── local AI
        ├── llama.cpp Vulkan
        └── ROCm/HIP after baseline testing
```

The key principle is to change one layer at a time: establish stable stock Kubuntu first, migrate
applications second, validate gaming and laptop behavior third, and only then add the specialized
AMD/LLM compute stack.

## Why Kubuntu

Kubuntu uses the Ubuntu base with KDE Plasma as its desktop environment. It shares Ubuntu's kernel,
repositories, system services, AMDGPU/Mesa stack, `apt` ecosystem, and compatibility with
Ubuntu-oriented third-party software.

KDE Plasma is a full desktop environment, not merely a window manager. It provides a familiar
taskbar/application-menu workflow for Windows users.

Useful links:

- Kubuntu: <https://kubuntu.org/>
- Ubuntu flavors: <https://ubuntu.com/desktop/flavors>
- KDE Plasma: <https://kde.org/plasma-desktop/>

## Recommended migration sequence

```text
Windows
   │
   ├── backup
   ├── record BitLocker key
   ├── update BIOS
   ├── disable Fast Startup
   └── shrink Windows partition
           │
           ▼
Create Kubuntu USB
           │
           ▼
Test live environment
           │
           ▼
Install Kubuntu dual boot
           │
           ▼
Update stock Kubuntu
           │
           ▼
Validate AMDGPU / Mesa / Vulkan
           │
           ▼
Validate laptop hardware
           │
           ▼
Install daily applications
           │
           ▼
Install development setup
           │
           ▼
Move development workflow
           │
           ▼
Test Steam games
           │
           ▼
Test Office + video workflow
           │
           ▼
Configure backups
           │
           ▼
Follow local-LLM setup guide
           │
           ▼
Use Kubuntu as primary OS
           │
           ▼
After several weeks:
decide whether Windows is still needed
```

## References

### Kubuntu and Ubuntu

- Kubuntu: <https://kubuntu.org/>
- Kubuntu download: <https://kubuntu.org/getkubuntu/>
- Ubuntu flavors: <https://ubuntu.com/desktop/flavors>
- Ubuntu releases: <https://releases.ubuntu.com/>
- KDE Plasma: <https://kde.org/plasma-desktop/>

### Hardware

- XMG support: <https://www.xmg.gg/en/support/>

### Development

- VS Code on Linux: <https://code.visualstudio.com/docs/setup/linux>
- Git: <https://git-scm.com/>
- Docker on Ubuntu: <https://docs.docker.com/engine/install/ubuntu/>
- Podman: <https://podman.io/>

### Applications

- Chrome: <https://www.google.com/chrome/>
- Bitwarden: <https://bitwarden.com/download/>
- WhatsApp Web: <https://web.whatsapp.com/>
- VLC: <https://www.videolan.org/vlc/>
- Microsoft 365: <https://www.microsoft365.com/>
- LibreOffice: <https://www.libreoffice.org/>
- ONLYOFFICE: <https://www.onlyoffice.com/>
- CapCut: <https://www.capcut.com/>
- Kdenlive: <https://kdenlive.org/>
- DaVinci Resolve: <https://www.blackmagicdesign.com/products/davinciresolve>

### Gaming

- Steam Support: <https://help.steampowered.com/>
- ProtonDB: <https://www.protondb.com/>

### Local AI

- AMD ROCm: <https://rocm.docs.amd.com/>
- llama.cpp: <https://github.com/ggml-org/llama.cpp>
