# Machines

Per-machine setup: the Ubuntu host, the persistent agent VM on it, and what both share.

| Directory                   | Scope                                                               | Disposable |
| --------------------------- | ------------------------------------------------------------------- | ---------- |
| [common/](common/README.md) | Install guides used by both host and VM                             | no         |
| [host/](host/README.md)     | Ubuntu host: hardware, personal apps, system config, hypervisor     | no         |
| [vm/](vm/README.md)         | Agent VM: bootstrap, agents, BB, networking, credentials, snapshots | no         |

Hardware BOM, locale, personal apps, and VM sizes live in the dave.box overlay:
[agent-box/](https://github.com/dxmann73/dave.box-setup/blob/main/agent-box/README.md).

Agent CLIs and their configuration are not here — they are the same on every machine and live in
[`../agents/`](../agents/README.md). Dotfiles live in [`../user-home/`](../user-home/). The GPU
model runtime is host-only and lives in its own repo:
[local-llm](https://github.com/dxmann73/local-llm).

## Where to start

| Situation          | Start at                                                                |
| ------------------ | ----------------------------------------------------------------------- |
| Fresh Kubuntu host | [host/](host/README.md)                                                 |
| New agent VM       | [host/05-hypervisor.md](host/05-hypervisor.md) then [vm/](vm/README.md) |
