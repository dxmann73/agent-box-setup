# Host setup

The Ubuntu/Kubuntu host: the personal laptop. It carries personal apps and data, the GPU and the
local model runtime, the hypervisor, and a development toolchain for host-scoped work
(specification §1, §10).

It does **not** carry agent-driven project work. That lives in the VM, see [`../vm/`](../vm/)
(specification §2, §8).

Target system:

| Part | Value |
| --- | --- |
| Laptop | XMG EVO 14 (E25) |
| Processor | AMD Ryzen AI 9 HX 370 |
| GPU | Radeon 890M |
| Memory | 96 GB (2 × 48 GB Kingston DDR5-5600) |
| OS | Kubuntu 26.04 LTS |

## Order

| File | Scope |
| --- | --- |
| [01-hardware-validation.md](01-hardware-validation.md) | AMDGPU, Vulkan/Mesa, suspend, power, thermals, displays |
| [02-applications.md](02-applications.md) | Chrome, Bitwarden, Dropbox, VLC, Office, Steam, dictation |
| [03-system-config.md](03-system-config.md) | Filesystem layout, backups, packaging, SSH, firewall |
| [04-dev-and-agents.md](04-dev-and-agents.md) | Toolchain and agents via [`../common/`](../common/) |
| [05-hypervisor.md](05-hypervisor.md) | VMware Workstation Pro, agent VM creation |

Then:

- [`../local-llm/`](../local-llm/) — llama.cpp, models, benchmarks, ROCm (host-only, needs the GPU)
- [`../vm/`](../vm/) — the agent VM

Retired: [voice-setup.old/](voice-setup.old/).

## Layout

```text
Kubuntu host
├── KDE Plasma, stock AMDGPU + Mesa/RADV
├── personal apps and data (Chrome profile, Dropbox, documents, Steam)
├── local model runtime (llama.cpp, GPU-attached)
├── host toolchain + coding agents (host-scoped work)
└── VMware Workstation Pro
    └── agent VM  ── T3 Code server, agents, projects, Playwright
```

## Why Kubuntu

Kubuntu uses the Ubuntu base with KDE Plasma as its desktop environment. It shares Ubuntu's kernel,
repositories, system services, AMDGPU/Mesa stack, `apt` ecosystem, and compatibility with
Ubuntu-oriented third-party software.

KDE Plasma is a full desktop environment, not merely a window manager. It provides a conventional
taskbar/application-menu workflow.

## References

### Kubuntu and Ubuntu

- Kubuntu: <https://kubuntu.org/>
- Kubuntu download: <https://kubuntu.org/getkubuntu/>
- Ubuntu flavors: <https://ubuntu.com/desktop/flavors>
- Ubuntu releases: <https://releases.ubuntu.com/>
- KDE Plasma: <https://kde.org/plasma-desktop/>

### Hardware

- XMG support: <https://www.xmg.gg/en/support/>

### Applications

- Chrome: <https://www.google.com/chrome/>
- Dropbox: <https://www.dropbox.com/install-linux>
- Bitwarden: <https://bitwarden.com/download/>
- WhatsApp Web: <https://web.whatsapp.com/>
- VLC: <https://www.videolan.org/vlc/>
- Microsoft 365: <https://www.microsoft365.com/>
- LibreOffice: <https://www.libreoffice.org/>
- ONLYOFFICE: <https://www.onlyoffice.com/>
- Kdenlive: <https://kdenlive.org/>
- DaVinci Resolve: <https://www.blackmagicdesign.com/products/davinciresolve>

### Gaming

- Steam Support: <https://help.steampowered.com/>
- ProtonDB: <https://www.protondb.com/>

### Local AI

- AMD ROCm: <https://rocm.docs.amd.com/>
- llama.cpp: <https://github.com/ggml-org/llama.cpp>
