# Agent VM setup

The persistent Ubuntu VM on the host. It is the security boundary: agents, their subprocesses, the
projects they work on and the browsers they drive all live here (specification §2, §3).

Prerequisite: the VM exists, created per [`../host/05-hypervisor.md`](../host/05-hypervisor.md).

Naming: the VM is called `xmg-evo-agent-vm`, as both libvirt domain and guest hostname. The pattern
is `<host>-agent-vm`, so VMs on different hosts stay apart; on another host, replace `xmg-evo`
throughout ([`../host/05-hypervisor.md`](../host/05-hypervisor.md) §5).

## Order

| File                                         | Scope                                                                 |
| -------------------------------------------- | --------------------------------------------------------------------- |
| [01-bootstrap.md](01-bootstrap.md)           | Console SSH/sudo bootstrap, then host-driven credential-free baseline |
| [02-dev-and-agents.md](02-dev-and-agents.md) | Baseline result, toolchain maintenance, and deliberate extras          |
| [03-networking.md](03-networking.md)         | NAT, host model endpoint, BB reachability, Tailscale                  |
| [04-bb.md](04-bb.md)                         | BB server, headless in the VM                                         |
| [05-credentials.md](05-credentials.md)       | VM-only SSH/GitHub/API credentials                                    |
| [06-shared-folders.md](06-shared-folders.md) | Narrow host directory shares, e.g. Dropbox tax folder                 |
| [07-snapshots.md](07-snapshots.md)           | Persistence, snapshots, backup, rebuild test                          |

The numbered files describe phases, not an instruction to authenticate early.
Complete 01 and its `--bootstrap` verification first, then take `clean-guest`.
Credentials, external exposure, and shares remain later opt-in phases.

## What lives here and what does not

|                                                 | VM  | Host               |
| ----------------------------------------------- | --- | ------------------ |
| coding agents, skills, hooks                    | ✅  | ✅                 |
| agent-worked projects                           | ✅  | ❌                 |
| BB server                                       | ✅  | ✅ own environment |
| Playwright + headless Chromium                  | ✅  | ❌                 |
| full dev toolchain                              | ✅  | ✅                 |
| personal apps, Dropbox, personal Chrome profile | ❌  | ✅                 |
| GPU and local model runtime                     | ❌  | ✅                 |

## Boundary rules

- the host `$HOME` is never mounted; individual directories are shared deliberately
  ([06-shared-folders.md](06-shared-folders.md))
- host `.ssh`, browser profiles and cloud config stay on the host
  ([05-credentials.md](05-credentials.md))
- treat every credential inside the VM as readable by an agent
- isolation is a property of the VM, not of which agent is running (specification §5)
