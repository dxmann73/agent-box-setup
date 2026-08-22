# Machines

Per-machine setup: the Ubuntu host, the persistent agent VM on it, what both share, and the
leftovers of Windows.

| Directory | Scope | Disposable |
| --- | --- | --- |
| [common/](common/README.md) | Install guides used by both host and VM | no |
| [host/](host/README.md) | Ubuntu host: hardware, personal apps, system config, hypervisor | no |
| [vm/](vm/README.md) | Agent VM: bootstrap, agents, T3 Code, networking, credentials, snapshots | no |
| [migration/](migration/README.md) | One-time Windows → Kubuntu move | **yes** |
| [wsl/](wsl/README.md) | Deltas for the Windows + WSL host variant | **yes** |

Agent CLIs and their configuration are not here — they are the same on every machine and live in
[`../agents/`](../agents/README.md). Dotfiles live in [`../user-home/`](../user-home/). The GPU
model runtime is host-only: [`../local-llm/`](../local-llm/).

## Where to start

| Situation | Start at |
| --- | --- |
| Coming from Windows | [migration/](migration/README.md) |
| Staying on Windows + WSL for now | [wsl/](wsl/README.md) |
| Fresh Kubuntu host | [host/](host/README.md) |
| New agent VM | [host/05-hypervisor.md](host/05-hypervisor.md) then [vm/](vm/README.md) |
