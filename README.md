# Agent Box Setup

Markdown-based setup documentation for the machines that run coding agents: an Ubuntu host and a
persistent agent VM on top of it.

The [specification](docs/specification/agent-box.md) is the source of truth for the architecture.
Everything in this repo should be traceable back to it.

## Why

1. To unlock the power of coding agents, they need to run in YOLO mode.
2. To reduce the blast radius, agents run in a VM that is the security boundary.
3. To automate the setup itself, and also sync changes to existing machines, we need a repo that
   holds both the configuration and the instructions to synchronize it.

## Two targets, one toolchain

```text
Kubuntu host                                  ← machines/host/
├── personal apps and data (Chrome, Dropbox, Steam, documents)
├── local model runtime on the GPU            ← local-llm/
├── development toolchain + coding agents     ← machines/common/ + agents/
├── T3 Code desktop app + local server        ← machines/host/04-dev-and-agents.md
└── KVM/libvirt                               ← machines/host/05-hypervisor.md
    └── agent VM (Kubuntu desktop)            ← machines/vm/
        ├── T3 Code server + many agents
        ├── development toolchain + agents    ← machines/common/ + agents/
        ├── projects agents work on
        └── Playwright / headless Chromium
```

The host and the VM share the same development toolchain and the same agent configuration; they
differ in what is *only* on one side — GPU and personal data on the host, agent-worked projects in
the VM. T3 Code runs on both: a headless server in the VM, a server plus the desktop app on the
host, with the app holding both environments at once.

## Directories

| Directory | Scope | Disposable |
| --- | --- | --- |
| [docs/specification/](docs/specification/) | What the setup has to achieve | no |
| [agents/](agents/) | Agent CLIs: instructions, config, shared skills | no |
| [machines/common/](machines/common/) | Install guides used by both host and VM | no |
| [machines/host/](machines/host/) | Ubuntu host: hardware, personal apps, system config, hypervisor | no |
| [machines/vm/](machines/vm/) | Agent VM: bootstrap, agents, T3 Code, networking, credentials, snapshots | no |
| [local-llm/](local-llm/) | llama.cpp, models, benchmarks, ROCm — host-only | no |
| [user-home/](user-home/) | Dotfiles and scripts symlinked into `~` | no |
| [machines/migration/](machines/migration/) | One-time Windows → Kubuntu move | **yes** |
| [machines/wsl/](machines/wsl/) | Deltas for the Windows + WSL host variant | **yes** |

Both are deliberately self-contained so they can be deleted once Windows is gone. Keep them that
way — no Windows, dual-boot or WSL instruction may appear outside them, beyond the touchpoints
`machines/wsl/README.md` lists:

```bash
# must stay empty
grep -rilE 'bitlocker|fast startup|dual.?boot|windows partition|shrink windows|ntfs' \
  machines/host/ machines/vm/ machines/common/
```

## Where to start

| Situation | Start at |
| --- | --- |
| Coming from Windows | [machines/migration/](machines/migration/) |
| Staying on Windows + WSL for now | [machines/wsl/](machines/wsl/) |
| Fresh Kubuntu host | [machines/host/](machines/host/) |
| New agent VM | [machines/host/05-hypervisor.md](machines/host/05-hypervisor.md) then [machines/vm/](machines/vm/) |
| Local model work | [local-llm/](local-llm/) |

## Scope: box-level vs. project-level

The repo name is historical. Not everything in here is machine setup — two different scopes live
side by side:

- **Box-level** — installed once per machine: shell/dotfiles, agent binaries, Docker, Node, Java,
  IDE. These are the `machines/` guides plus `agents/` and `user-home/`.
- **Project-level** — belongs to whatever you are working on, and is only wired globally because
  there is no better home yet: skills in `agents/skills/` and language toolchains that only
  some projects need (SDKMAN, Quarkus, pnpm).

Project-level items are installed globally (symlinked into `~/.claude/skills`, `~/.cursor/skills`)
as an interim measure so every project gets them. The intended end state is packaging them per
project type — see the "project setup" entry in [ROADMAP.md](./ROADMAP.md). When adding something,
decide which scope it belongs to first.

## Usage

This repo is designed to work with coding agents. Just tell them to "Set up this machine using the
agent-box-setup repo", and say whether it is the host or the VM.

## Verification

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh --host     # or --vm
```

Detailed checklist with troubleshooting: [SETUP.md](./SETUP.md).

## Staying current

Both machines patch themselves: `unattended-upgrades` for everything apt reaches (including Chrome,
Docker, Node and the other third-party repos), a weekly user timer for the npm-installed agent CLIs.
Set up per machine in [machines/common/08-auto-updates.md](machines/common/08-auto-updates.md).

Two things stay manual on purpose: **T3 Code**, because the desktop app and the VM server have to
move together, and **Ubuntu release upgrades**, because they move the GPU stack under the local
model and the libvirt version under the VM.

## Synchronizing settings

TBD, we need a way to sync settings from / to machines.
