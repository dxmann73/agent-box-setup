# Host setup

The Ubuntu/Kubuntu host: the personal laptop. It carries personal apps and data, the GPU and the
local model runtime, the hypervisor, and a development toolchain for host-scoped work (specification
§1, §10).

It does **not** carry agent-driven project work. That lives in the VM, see [`../vm/`](../vm/)
(specification §2, §8).

Hardware BOM, expected validation numbers, and the personal app list live in the dave.box overlay:
[agent-box/](https://github.com/dxmann73/dave.box-setup/blob/main/agent-box/README.md).

## Order

| File                                                   | Scope                                                                             |
| ------------------------------------------------------ | --------------------------------------------------------------------------------- |
| [01-hardware-validation.md](01-hardware-validation.md) | AMDGPU, Vulkan/Mesa, suspend, displays (power/thermal diagnostics in an appendix) |
| [02-applications.md](02-applications.md)               | Personal apps stay on the host; overlay has the install list                      |
| [03-system-config.md](03-system-config.md)             | Filesystem layout, backups, packaging, SSH, firewall                              |
| [04-dev-and-agents.md](04-dev-and-agents.md)           | Toolchain and agents via [`../common/`](../common/)                               |
| [05-hypervisor.md](05-hypervisor.md)                   | KVM/libvirt, agent VM creation                                                    |

Automatic patching applies to both machines and lives in
[`../common/08-auto-updates.md`](../common/08-auto-updates.md); do it as part of step 04.

Then:

- [local-llm](https://github.com/dxmann73/local-llm) — separate repo: llama.cpp, models, benchmarks,
  ROCm (host-only, needs the GPU)
- [`../vm/`](../vm/) — the agent VM

## Layout

```text
Kubuntu host
├── KDE Plasma, stock AMDGPU + Mesa/RADV
├── personal apps and data (browser profile, documents, optional sync)
├── local model runtime (llama.cpp, GPU-attached)
├── host toolchain + coding agents (host-scoped work)
└── KVM/libvirt (qemu-system-x86, virt-manager)
    └── agent VM  ── Kubuntu desktop, BB server, agents, projects, Playwright
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
