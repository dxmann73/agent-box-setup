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
├── personal apps and data (browser placement from overlay, sync, documents)
├── local model runtime on the GPU            ← local-llm repo (separate)
├── development toolchain + coding agents     ← machines/common/ + agents/
├── BB desktop AppImage + shared server       ← machines/host/04-dev-and-agents.md
└── KVM/libvirt                               ← machines/host/05-hypervisor.md
    └── agent VM (Kubuntu desktop)            ← machines/vm/
        ├── enrolled BB execution machine + many agents
        ├── development toolchain + agents    ← machines/common/ + agents/
        ├── projects agents work on
        └── Playwright / headless Chromium
```

The host and the VM share the same development toolchain and the same agent configuration; they
differ in what is _only_ on one side — GPU and personal data on the host, agent-worked projects in
the VM. The host AppImage server is the shared BB control plane and lists both the host and the
enrolled VM as execution machines. A persistent headless VM server may remain temporarily as an
independent fallback; clients use the host server when both machines must be selectable.

## Directories

| Directory                                  | Scope                                                               | Disposable |
| ------------------------------------------ | ------------------------------------------------------------------- | ---------- |
| [docs/specification/](docs/specification/) | What the setup has to achieve                                       | no         |
| [agents/](agents/)                         | Agent CLIs: instructions, config, global skill index                | no         |
| [machines/common/](machines/common/)       | Install guides used by both host and VM                             | no         |
| [machines/host/](machines/host/)           | Ubuntu host: hardware, personal apps, system config, hypervisor     | no         |
| [machines/vm/](machines/vm/)               | Agent VM: bootstrap, agents, BB, networking, credentials, snapshots | no         |
| [modules/](modules/)                       | Modular target catalog, ticks, profile values and module scaffolds  | no         |
| [user-home/](user-home/)                   | Dotfiles and scripts symlinked into `~`                             | no         |

Hardware BOM, locale, personal apps, VM sizes, and this-host migration live in
[dave.box-setup/agent-box/](https://github.com/dxmann73/dave.box-setup/blob/main/agent-box/README.md).

Grep guard (must stay empty except a pointer to that overlay):

```bash
grep -rilE 'xmg-evo|890M|HX 370|tailb67542|dxmann73@gmail|clackworks\.agents|/Dropbox/Docs/Geld|de_DE|plasma-localerc|VibeTyper|vibe-typer' \
  machines/host machines/vm machines/common agents user-home START-HERE.md \
  docs verify-setup.sh \
  --exclude-dir=skills
```

Windows/migration leftover grep (must stay empty; no exemptions):

```bash
grep -rilE 'bitlocker|fast startup|dual.?boot|windows partition|shrink windows|ntfs|WSL|/mnt/c|winget install|DrvFs' \
  machines/host machines/vm machines/common agents user-home START-HERE.md docs verify-setup.sh \
  --exclude-dir=skills
```

## Host-first bootstrap

On a fresh Kubuntu host, start with [START-HERE.md](START-HERE.md). Bootstrap one local agent and
obtain the setup repository plus any deployment overlay. Reuse working installations and logins.

Prepare the host baseline and virtualization first. If the overlay selects a separate personal
browser guest, establish it before the remaining account logins, host tooling and project inventory.
One initial setup-agent login and repository access are the bootstrap exceptions. Keep personal
browser profiles outside the agent VM.

Full host completion remains a checkpoint before creating the **agent VM**, not before preparing
virtualization or an overlay's personal browser guest.

## Where to start

| Situation          | Start at                                                                                           |
| ------------------ | -------------------------------------------------------------------------------------------------- |
| Fresh Kubuntu host | [START-HERE.md](START-HERE.md)                                                                     |
| New agent VM       | [machines/host/05-hypervisor.md](machines/host/05-hypervisor.md) then [machines/vm/](machines/vm/) |
| Local model work   | [local-llm](https://github.com/dxmann73/local-llm) (separate repo)                                 |

## Setup order

Numeric filenames identify guides; follow this phased order. Apply matching overlays at the step
that consumes them, and explicit overlay-only insertions from the deployment's sequence.

### Host

1. [host/01-hardware-validation.md](machines/host/01-hardware-validation.md): hardware and
   desktop/session review; honor explicit deployment preferences.
2. [host/02-applications.md](machines/host/02-applications.md): decide personal browser placement
   and the later personal-app list. Installation of all personal apps is not a prerequisite.
3. [host/03-system-config.md](machines/host/03-system-config.md): host baseline, required paths,
   update policy and firewall review. Apply the locale overlay here.
4. [host/05-hypervisor.md](machines/host/05-hypervisor.md): infrastructure and installation media
   only, then `machines/host/verify-virtualization.sh`. Follow the overlay's personal browser guest
   insertion, if selected; verify its isolation and browser handoff before remaining account logins.
5. [host/04-dev-and-agents.md](machines/host/04-dev-and-agents.md): shared tooling, remaining
   authentication, editor, BB and deployment inventory. Finish selected personal apps. Link overlay
   git identity with common 00 before its identity checks. Run host operational verification.
6. [host/05-hypervisor.md](machines/host/05-hypervisor.md#4-create-the-agent-vm): agent-VM creation
   and the VM sequence below. Existing working VMs do not need to be rebuilt.

The separate [local-llm](https://github.com/dxmann73/local-llm) runtime is optional host-only work;
it does not gate a personal browser guest.

### VM

1. [vm/01-bootstrap.md](machines/vm/01-bootstrap.md) - Console SSH/sudo bootstrap and host-driven
   credential-free guest baseline
2. [vm/02-dev-and-agents.md](machines/vm/02-dev-and-agents.md) - Baseline toolchain and deliberate
   optional guest tooling
3. [vm/03-networking.md](machines/vm/03-networking.md) - NAT, host model endpoint, BB reachability
4. [vm/04-bb.md](machines/vm/04-bb.md) - BB fallback server and shared-host enrollment
5. [vm/05-credentials.md](machines/vm/05-credentials.md) - VM-only credentials
6. [vm/06-shared-folders.md](machines/vm/06-shared-folders.md) - Narrow host directory shares
7. [vm/07-snapshots.md](machines/vm/07-snapshots.md) - Persistence, snapshots, live backup

### Shared install detail

1. [common/00-home-environment.md](machines/common/00-home-environment.md) - Shell configuration and
   dotfiles
2. [common/02-core-tools.md](machines/common/02-core-tools.md) - GitHub CLI, jq/yq, Docker
3. [common/03-dev-environment.md](machines/common/03-dev-environment.md) - Node.js 24 and
   development tools
4. [agents/](agents/README.md) - Claude Code, Codex, Cursor CLI, Pi, global rules, skills, Caveman
5. [common/04-ide+tooling.md](machines/common/04-ide+tooling.md) - VS Code
6. [common/05-bb.md](machines/common/05-bb.md) - BB desktop AppImage and VM server runtime
7. [common/07-imaging-tools.md](machines/common/07-imaging-tools.md) - Deployment imaging overlay
8. [common/06-optional.md](machines/common/06-optional.md) - Helm, cloud CLIs, extras
9. [common/08-auto-updates.md](machines/common/08-auto-updates.md) - Unattended apt upgrades,
   needrestart, weekly tooling update timer

## Host workspace inventory

Project inventory is a deployment concern. This repository does not track a project list. The
dave.box overlay requires a private inventory checkout as part of host completion. The VM receives
separate project clones later for agent execution.

## Config files

`user-home/` holds dotfiles that are **symlinked** (not copied) into `~`:

| File              | Purpose                                                                   |
| ----------------- | ------------------------------------------------------------------------- |
| `.bashrc`         | Bash shell configuration                                                  |
| `.bash_aliases`   | Custom command aliases                                                    |
| `.bash_secrets`   | API tokens/secrets, created from the `.bash_secrets.CHANGE-ME` template   |
| `.profile`        | User profile settings                                                     |
| `.gitconfig`      | Git configuration (`[include]` of `~/.gitconfig.local` for identity)      |
| `ua.sh`           | Update-all script: fetch/pull all git repos under a root dir              |
| `update-tools.sh` | Weekly tooling update: npm globals, agent CLIs, overlay SDKMAN if present |

The repo root `.markdownlint.json` is symlinked to `~/projects/.markdownlint.json`. Full symlink
commands: [machines/common/00-home-environment.md](machines/common/00-home-environment.md).

## Scope: box-level vs. project-level

The repo name is historical. Not everything in here is machine setup — two different scopes live
side by side:

- **Box-level** — installed once per machine: shell/dotfiles, agent binaries, Docker, Node, IDE.
  These are the `machines/` guides plus `agents/` and `user-home/`.
- **Project-level** — belongs to whatever you are working on, and is only wired globally because
  there is no better home yet: skills indexed by `agents/skills/` and project-specific toolchains.
  Dave-specific SDKMAN, Java, Quarkus, Maven, Docker Compose, and imaging tools live in the Dave
  overlay.

Project-level items are installed globally through the agent skill index as an interim measure so
every project gets them. Some index entries may symlink to skills owned by follow-up repositories.
The intended end state is packaging them per project type — see the "project setup" entry in
[ROADMAP.md](./ROADMAP.md).

## Usage

This repo is designed to work with coding agents. On a fresh physical host, begin at
[START-HERE.md](START-HERE.md). For an existing machine, begin with the numbered guide sequence for
its known target.

## Verification

```bash
cd ~/projects/agent-box-setup
# Before creating a personal browser guest; no agent credentials required:
./machines/host/verify-virtualization.sh
# Later, after completing host tooling and authentication:
./verify-setup.sh --host --operational
# A new guest, before any provider or GitHub login:
./verify-setup.sh --vm --bootstrap
# Explicitly enabled credentials and optional capabilities:
./verify-setup.sh --vm --full
```

The separate virtualization check covers infrastructure only; guest-specific resources, ISO
integrity and network policy need their own checks. It does not replace browser acceptance.

Toolchain verification profiles are intentionally cumulative:

- `bootstrap` checks credential-free deterministic readiness and is the acceptance gate for a new
  guest before taking `clean-guest`.
- `operational` adds the required host-completion gate: host GitHub access, Firecrawl auth, VS Code
  settings and keybindings, and BB AppImage. It never requires guest provider credentials.
- `full` checks only credentials and integrations that were explicitly enabled on that target.

The checks cover:

- Claude Code, Codex, Cursor CLI, Pi, and VS Code
- Home directory symlinks (`.bashrc`, `.bash_aliases`, `.profile`, `.gitconfig`, `.bash_secrets`,
  `ua.sh`, `update-tools.sh`, `.markdownlint.json`)
- Git `user.name` / `user.email` are set (values come from `~/.gitconfig.local`)
- Agent configuration and symlinks
- Skills setup, including a `SKILL.md` frontmatter audit (`./audit-skills.sh`)
- Core tools (GitHub CLI, Docker, jq, yq)
- Development environment (Node.js 24, pnpm, TypeScript, Markdownlint, Firecrawl CLI)
- Target-specific items (Playwright in the VM, GPU stack on the host)
- Optional tools (if installed)

Fixes for anything it flags live in the guide the line names — `agents/README.md`,
`machines/common/*.md` or `machines/<target>/*.md`.

`./audit-skills.sh` also runs standalone and prints one line per finding. It is directory-driven:
every reachable `agents/skills/*/SKILL.md`, including symlinked skill directories, is checked
against the [frontmatter reference](https://code.claude.com/docs/en/skills#frontmatter-reference) —
unknown keys, missing `description`, duplicate `name`, `name` differing from the directory name,
`metadata` shadowing a reserved field, and the `description` listing cap. Errors exit non-zero;
`--strict` also fails on warnings.

## Staying current

Both machines patch themselves: `unattended-upgrades` for everything apt reaches (including Chrome,
Docker, Node and the other third-party repos), a weekly user timer for the npm-installed agent CLIs.
Set up per machine in [machines/common/08-auto-updates.md](machines/common/08-auto-updates.md).

Two things stay deliberate on purpose: **BB updates**, so running agent sessions are not
interrupted, and **Ubuntu release upgrades**, because they move the GPU stack and libvirt. The host
AppImage uses its built-in updater; the VM runtime lives in a dedicated npm prefix outside the
weekly global package update.

## Synchronizing settings

TBD, we need a way to sync settings from / to machines.

## Setup checklist

- [ ] the target guide sequence is complete
- [ ] Claude Code, Codex, Cursor CLI, and Pi are installed on both targets
- [ ] personal browser is ready before remaining host logins; agent-VM credentials follow
      `clean-guest`
- [ ] the appropriate profiled verification command completes
