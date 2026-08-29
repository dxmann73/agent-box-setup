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
├── local model runtime on the GPU            ← local-llm repo (separate)
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

## Agent-led bootstrap

The only manual bootstrap is Git, plus one (installed and authenticated) coding agent. Then clone this
repository and let the agent complete the target setup:

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/dxmann73/agent-box-setup
cd agent-box-setup
```

Start the installed agent in this directory and give it this instruction:

> Set up this machine using agent-box-setup. Determine whether this is the host or VM, follow the
> numbered guides for that target in order, ask before optional tools, diagnose errors before
> continuing, and finish with the required verification command.

After verification, hand over to the project-manager agent to pull the remaining projects — see
[Next: clone the projects](#next-clone-the-projects).

## Where to start

| Situation | Start at |
| --- | --- |
| Coming from Windows | [machines/migration/](machines/migration/) |
| Staying on Windows + WSL for now | [machines/wsl/](machines/wsl/) |
| Fresh Kubuntu host | [machines/host/](machines/host/) |
| New agent VM | [machines/host/05-hypervisor.md](machines/host/05-hypervisor.md) then [machines/vm/](machines/vm/) |
| Local model work | [local-llm](https://github.com/dxmann73/local-llm) (separate repo) |

## Setup order

Each directory's files are numbered; follow them in order. Every file carries its own verification
commands.

### Host

1. [host/01-hardware-validation.md](machines/host/01-hardware-validation.md) - AMDGPU, Vulkan, power,
   displays
2. [host/02-applications.md](machines/host/02-applications.md) - Chrome, Bitwarden, Dropbox,
   Office, Steam
3. [host/03-system-config.md](machines/host/03-system-config.md) - Filesystem, backups, SSH, firewall
4. [host/04-dev-and-agents.md](machines/host/04-dev-and-agents.md) - Toolchain and agents via `machines/common/`
5. [host/05-hypervisor.md](machines/host/05-hypervisor.md) - KVM/libvirt, agent VM

Then the separate [local-llm](https://github.com/dxmann73/local-llm) repo for the GPU model
runtime (host-only).

### VM

1. [vm/01-bootstrap.md](machines/vm/01-bootstrap.md) - Kubuntu guest settings, desktop access,
   first agent
2. [vm/02-dev-and-agents.md](machines/vm/02-dev-and-agents.md) - Toolchain and agents via `machines/common/`,
   Playwright
3. [vm/04-t3code.md](machines/vm/04-t3code.md) - T3 Code server, headless in the VM
4. [vm/03-networking.md](machines/vm/03-networking.md) - NAT, host model endpoint, Tailscale
5. [vm/05-credentials.md](machines/vm/05-credentials.md) - VM-only credentials
6. [vm/06-shared-folders.md](machines/vm/06-shared-folders.md) - Narrow host directory shares
7. [vm/07-snapshots.md](machines/vm/07-snapshots.md) - Persistence, snapshots, rebuild test

### Shared install detail

1. [common/00-home-environment.md](machines/common/00-home-environment.md) - Shell configuration
   and dotfiles
2. [agents/](agents/README.md) - Claude Code, Cursor CLI, Codex, global rule file, skills, hooks
3. [common/02-core-tools.md](machines/common/02-core-tools.md) - GitHub CLI, jq, Docker
4. [common/03-dev-environment.md](machines/common/03-dev-environment.md) - Node.js and development tools
5. [common/04-ide+tooling.md](machines/common/04-ide+tooling.md) - VS Code
6. [common/06-optional.md](machines/common/06-optional.md) - Helm, cloud CLIs, extras
7. [common/07-imaging-tools.md](machines/common/07-imaging-tools.md) - ImageMagick, sharp, resvg, optional
   image tools
8. [common/08-auto-updates.md](machines/common/08-auto-updates.md) - Unattended apt upgrades, needrestart,
   weekly tooling update timer

## Next: clone the projects

Machine setup ends here. Filling the box with projects belongs to the **project-manager** agent in
[clackworks.agents](https://github.com/dxmann73/clackworks.agents) (private), which owns the project
inventory, the VS Code workspace file, and the periodic project review.

After Agent Box Setup verification passes, authenticate GitHub CLI with access to private
repositories, clone that repo, and hand over:

```bash
cd ~/projects
git clone https://github.com/dxmann73/clackworks.agents
```

> Act as the project-manager agent described in `clackworks.agents/project-manager/README.md`.
> Clone or update every project in its inventory and add them to `projects.code-workspace`.

Nothing in this repository tracks the project list; keep it in the inventory over there.

## Config files

`user-home/` holds dotfiles that are **symlinked** (not copied) into `~`:

| File | Purpose |
| --- | --- |
| `.bashrc` | Bash shell configuration |
| `.bash_aliases` | Custom command aliases |
| `.bash_secrets` | API tokens/secrets, created from the `.bash_secrets.CHANGE-ME` template |
| `.profile` | User profile settings |
| `.gitconfig` | Git configuration |
| `ua.sh` | Update-all script: fetch/pull all git repos under a root dir |
| `update-tools.sh` | Weekly tooling update: npm globals, agent CLIs, SDKMAN |

The repo root `.markdownlint.json` is symlinked to `~/projects/.markdownlint.json`.
Full symlink commands: [machines/common/00-home-environment.md](machines/common/00-home-environment.md).

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

This checks:

- Agent binaries (Claude Code, Cursor CLI Agent, Codex) and VS Code
- Home directory symlinks (`.bashrc`, `.bash_aliases`, `.profile`, `.gitconfig`, `.bash_secrets`,
  `ua.sh`, `update-tools.sh`, `.markdownlint.json`)
- Agent configuration and symlinks
- Caveman hooks (Codex, Cursor)
- Skills setup, including a `SKILL.md` frontmatter audit (`./audit-skills.sh`)
- Core tools (GitHub CLI, Docker, jq)
- Development environment (Node.js, Java, etc.)
- Imaging tools (ImageMagick, sharp, resvg)
- Target-specific items (Playwright in the VM, GPU stack on the host)
- Optional tools (if installed)

Fixes for anything it flags live in the guide the line names — `agents/README.md`,
`machines/common/*.md` or `machines/<target>/*.md`.

`./audit-skills.sh` also runs standalone and prints one line per finding. It is directory-driven:
every `agents/skills/*/SKILL.md` is checked against the
[frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference) — unknown
keys, missing `description`, duplicate `name`, `name` differing from the directory name, `metadata`
shadowing a reserved field, and the `description` listing cap. Errors exit non-zero; `--strict`
also fails on warnings.

## Staying current

Both machines patch themselves: `unattended-upgrades` for everything apt reaches (including Chrome,
Docker, Node and the other third-party repos), a weekly user timer for the npm-installed agent CLIs.
Set up per machine in [machines/common/08-auto-updates.md](machines/common/08-auto-updates.md).

Two things stay manual on purpose: **T3 Code**, because the desktop app and the VM server have to
move together, and **Ubuntu release upgrades**, because they move the GPU stack under the local
model and the libvirt version under the VM.

## Synchronizing settings

TBD, we need a way to sync settings from / to machines.
