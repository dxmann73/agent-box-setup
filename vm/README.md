# Agent VM setup

The persistent Ubuntu VM on the host. It is the security boundary: agents, their subprocesses, the
projects they work on and the browsers they drive all live here (specification §2, §3).

Prerequisite: the VM exists, created per
[`../host/05-hypervisor.md`](../host/05-hypervisor.md).

## Order

| File | Scope |
| --- | --- |
| [01-bootstrap.md](01-bootstrap.md) | Kubuntu guest settings, SPICE console, passwordless sudo, first agent |
| [02-dev-and-agents.md](02-dev-and-agents.md) | Toolchain and agents via [`../common/`](../common/), Playwright |
| [03-networking.md](03-networking.md) | NAT, host model endpoint, T3 Code reachability, Tailscale |
| [04-t3code.md](04-t3code.md) | T3 Code server, headless in the VM |
| [05-credentials.md](05-credentials.md) | VM-only SSH/GitHub/API credentials |
| [06-shared-folders.md](06-shared-folders.md) | Narrow host directory shares, e.g. Dropbox tax folder |
| [07-snapshots.md](07-snapshots.md) | Persistence, snapshots, backup, rebuild test |

## What lives here and what does not

| | VM | Host |
| --- | --- | --- |
| coding agents, skills, hooks | ✅ | ✅ |
| agent-worked projects | ✅ | ❌ |
| T3 Code server | ✅ | ✅ own environment |
| Playwright + headless Chromium | ✅ | ❌ |
| full dev toolchain | ✅ | ✅ |
| personal apps, Dropbox, personal Chrome profile | ❌ | ✅ |
| GPU and local model runtime | ❌ | ✅ |

## Boundary rules

- the host `$HOME` is never mounted; individual directories are shared deliberately
  ([06-shared-folders.md](06-shared-folders.md))
- host `.ssh`, browser profiles and cloud config stay on the host
  ([05-credentials.md](05-credentials.md))
- treat every credential inside the VM as readable by an agent
- isolation is a property of the VM, not of which agent is running (specification §5)
