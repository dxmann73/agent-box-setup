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
Kubuntu host                                  ← host/
├── personal apps and data (Chrome, Dropbox, Steam, documents)
├── local model runtime on the GPU            ← local-llm/
├── development toolchain + coding agents     ← common/
└── VMware Workstation Pro
    └── agent VM                              ← vm/
        ├── herdr server + many agents
        ├── development toolchain + agents    ← common/
        ├── projects agents work on
        └── Playwright / headless Chromium
```

The host and the VM share the same development toolchain and the same agent configuration; they
differ in what is *only* on one side — GPU and personal data on the host, herdr and agent-worked
projects in the VM.

## Directories

| Directory | Scope | Disposable |
| --- | --- | --- |
| [docs/specification/](docs/specification/) | What the setup has to achieve | no |
| [common/](common/) | Install guides used by both host and VM | no |
| [host/](host/) | Ubuntu host: hardware, personal apps, system config, hypervisor | no |
| [vm/](vm/) | Agent VM: bootstrap, agents, herdr, networking, credentials, snapshots | no |
| [local-llm/](local-llm/) | llama.cpp, models, benchmarks, ROCm — host-only | no |
| [configs/](configs/) | Dotfiles, agent configuration, skills | no |
| [migration/](migration/) | One-time Windows → Kubuntu move | **yes** |

`migration/` is deliberately self-contained so it can be deleted once Windows is gone. Keep it that
way — no Windows or dual-boot instruction may appear outside it:

```bash
grep -rilE 'bitlocker|fast startup|dual.?boot|windows partition|shrink windows|ntfs' host/ vm/ common/   # must stay empty
```

## Where to start

| Situation | Start at |
| --- | --- |
| Coming from Windows | [migration/](migration/) |
| Fresh Kubuntu host | [host/](host/) |
| New agent VM | [host/05-hypervisor.md](host/05-hypervisor.md) then [vm/](vm/) |
| Local model work | [local-llm/](local-llm/) |

## Scope: box-level vs. project-level

The repo name is historical. Not everything in here is machine setup — two different scopes live
side by side:

- **Box-level** — installed once per machine: shell/dotfiles, agent binaries, Docker, Node, Java,
  IDE. These are the `common/`, `host/` and `vm/` guides.
- **Project-level** — belongs to whatever you are working on, and is only wired globally because
  there is no better home yet: skills in `configs/agents/skills/` and language toolchains that only
  some projects need (SDKMAN, Quarkus, pnpm).

Project-level items are installed globally (symlinked into `~/.claude/skills`, `~/.cursor/skills`)
as an interim measure so every project gets them. The intended end state is packaging them per
project type — see the "project setup" entry in [TODOs.md](./TODOs.md). When adding something,
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

## Synchronizing settings

TBD, we need a way to sync settings from / to machines.
