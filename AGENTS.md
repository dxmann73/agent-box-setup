# Instructions for setting up an Agent Box

This repository contains instructions for setting up the machines that run agents in YOLO mode: an
Ubuntu host and a persistent agent VM on it.

[docs/specification/agent-box.md](docs/specification/agent-box.md) is the source of truth for the
architecture. Check changes against it.

## How to Use This Repo

1. **Determine the target first** - host or VM. They share `common/` but differ in what each one
   additionally installs
2. **Follow the numbered files in order** - within each directory
3. **Verify each step** - each setup file includes verification commands after installation steps
4. **Run complete verification** - `./verify-setup.sh --host` or `--vm`
5. **Copy configs** - use files from `configs/` directory as templates

## Setup Order

### Host

1. [host/01-hardware-validation.md](host/01-hardware-validation.md) - AMDGPU, Vulkan, power,
   displays
2. [host/02-applications.md](host/02-applications.md) - Chrome, Bitwarden, Dropbox, Office, Steam
3. [host/03-system-config.md](host/03-system-config.md) - Filesystem, backups, SSH, firewall
4. [host/04-dev-and-agents.md](host/04-dev-and-agents.md) - Toolchain and agents via `common/`
5. [host/05-hypervisor.md](host/05-hypervisor.md) - KVM/libvirt, agent VM

Then [local-llm/](local-llm/) for the GPU model runtime (host-only).

### VM

1. [vm/01-bootstrap.md](vm/01-bootstrap.md) - Kubuntu guest settings, desktop access, first agent
2. [vm/02-dev-and-agents.md](vm/02-dev-and-agents.md) - Toolchain and agents via `common/`,
   Playwright
3. [vm/04-t3code.md](vm/04-t3code.md) - T3 Code server, headless in the VM
4. [vm/03-networking.md](vm/03-networking.md) - NAT, host model endpoint, Tailscale
5. [vm/05-credentials.md](vm/05-credentials.md) - VM-only credentials
6. [vm/06-shared-folders.md](vm/06-shared-folders.md) - Narrow host directory shares
7. [vm/07-snapshots.md](vm/07-snapshots.md) - Persistence, snapshots, rebuild test

### Shared install detail

1. [common/00-home-environment.md](common/00-home-environment.md) - Shell configuration and dotfiles
2. [common/01-agent-setup.md](common/01-agent-setup.md) - Claude Code, Cursor CLI, Codex, skills,
   hooks
3. [common/02-core-tools.md](common/02-core-tools.md) - GitHub CLI, jq, Docker
4. [common/03-dev-environment.md](common/03-dev-environment.md) - Node.js and development tools
5. [common/04-ide+tooling.md](common/04-ide+tooling.md) - Cursor IDE
6. [common/06-optional.md](common/06-optional.md) - Helm, cloud CLIs, extras
7. [common/07-imaging-tools.md](common/07-imaging-tools.md) - ImageMagick, sharp, resvg, optional
   image tools
8. [common/08-auto-updates.md](common/08-auto-updates.md) - Unattended apt upgrades, needrestart,
   weekly tooling update timer

Voice tooling is retired: see [host/voice-setup.old/](host/voice-setup.old/).

## Quick Verification

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh --host     # or --vm
```

This will verify:

- Agent binaries (Claude Code, Cursor CLI Agent, Cursor IDE)
- Home directory symlinks (`.bashrc`, `.bash_aliases`, `.profile`, `.gitconfig`, `.bash_secrets`, `ua.sh`,
  `update-tools.sh`, `.markdownlint.json`)
- Agent configuration and symlinks
- Caveman hooks (Codex, Cursor)
- Skills setup
- Core tools (GitHub CLI, Docker, jq)
- Development environment (Node.js, Java, etc.)
- Imaging tools (ImageMagick, sharp, resvg)
- Target-specific items (Playwright in the VM, GPU stack on the host)
- Optional tools (if installed)

## Important Notes

- **Don't run everything blindly** - Ask the user before installing optional tools
- **Check existing installations** - Many tools may already be installed; verify first
- **Assume parallel agent work** - If unexpected changes appear, treat them as edits from another
  agent and work around them without reverting
- **Respect user preferences** - These are defaults; the user may want variations
- **Handle errors gracefully** - If a step fails, diagnose before continuing

## Project Rules

- Every guide belongs to exactly one target: `host/`, `vm/`, or `common/` when it applies to both.
  Classify before adding.
- `migration/` is disposable. No dual-boot/migration instruction may live outside it; nothing
  outside it may depend on it. WSL notes are exempt — WSL is a supported host variant, not
  migration content. This must stay empty:

  ```bash
  grep -rilE 'bitlocker|fast startup|dual.?boot|windows partition|shrink windows|ntfs' \
    host/ vm/ common/
  ```

- Two scopes live in this repo: **box-level** (machine setup: `common/`, `host/`, `vm/`) and
  **project-level** (skills, per-language toolchains). Project-level items are installed globally as
  an interim measure; classify new additions before adding them. See "Scope" in `README.md`.
- Treat `configs/agents/skills/` as the single source of truth for installed skills.
- Keep setup docs/scripts in sync with that directory (`common/01-agent-setup.md`,
  `verify-setup.sh`, `SETUP.md`).
- Verification must be directory-driven (derive expected skills from `configs/agents/skills/`), not
  hardcoded skill-name lists.
- Plan artifacts are excluded from markdownlint workflows (`plans/**/*.md`, `**/*-plan.md`).
- Markdown linting should work even without a preinstalled binary: prefer `markdownlint` when
  present, otherwise use `npx --yes markdownlint-cli`.

## Config Files

The `configs/user-home-directory/` contains dotfiles that must be **symlinked** (not copied) to `~`:

- `.bashrc` - Bash shell configuration
- `.bash_aliases` - Custom command aliases
- `.bash_secrets` - API tokens/secrets (created from `.bash_secrets.CHANGE-ME` template)
- `.profile` - User profile settings
- `.gitconfig` - Git configuration
- `ua.sh` - Update-all script: fetch/pull all git repos under a root dir
- `update-tools.sh` - Weekly tooling update: npm globals, agent CLIs, SDKMAN

The repo root `.markdownlint.json` is symlinked to `~/projects/.markdownlint.json`.

See `common/00-home-environment.md` for the full symlink commands.

## Structure

- `docs/specification/` - What the setup has to achieve; source of truth
- `common/` - Install guides used by both host and VM
- `host/` - Ubuntu host: hardware, personal apps, system config, hypervisor
- `vm/` - Agent VM: bootstrap, agents, T3 Code, networking, credentials, snapshots
- `local-llm/` - llama.cpp, models, benchmarks, ROCm (host-only)
- `migration/` - One-time Windows → Kubuntu move; deletable
- `configs/` - Configuration files to copy/symlink
- `verify-setup.sh` - Automated verification script (`--host` / `--vm`)
- `SETUP.md` - Detailed verification checklist with troubleshooting
