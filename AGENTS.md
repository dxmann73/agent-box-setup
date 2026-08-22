# Agent rules for agent-box-setup

This repository contains instructions for setting up machines that run agents in YOLO mode: an
Ubuntu host and one or more persistent agent VMs on it.

[docs/specification/agent-box.md](docs/specification/agent-box.md) is the source of truth for the
architecture. Check changes against it. [README.md](./README.md) holds the setup order, directory
map and config-file list; read it when you need those details.

Note: Setup is geared **specifically** towards an xmg evo right now; proceed with care.

## Project Rules

- Every guide belongs to exactly one target: `machines/host/`, `machines/vm/`, or `machines/common/`
  when it applies to both. Agent-CLI instructions live in `agents/<agent>/README.md`. Classify
  before adding.
- `machines/migration/` and `machines/wsl/` are disposable. No dual-boot, migration or WSL
  instruction may live outside them; nothing outside them may depend on them. The guides elsewhere
  describe the native Linux case only and may point into these directories, never the reverse. Both
  greps must stay empty, except for the exemptions `machines/wsl/README.md` itself records:

  ```bash
  grep -rilE 'bitlocker|fast startup|dual.?boot|windows partition|shrink windows|ntfs' \
    machines/host/ machines/vm/ machines/common/
  grep -rnE 'WSL|/mnt/c|winget install|DrvFs' \
    machines/host/ machines/vm/ machines/common/ agents/ user-home/ \
    --exclude-dir=skills | grep -v 'wsl/README.md'
  ```

- Two scopes live in this repo: **box-level** (machine setup under `machines/`, plus `agents/` and
  `user-home/`) and **project-level** (skills, per-language toolchains). Project-level items are
  installed globally as an interim measure; classify new additions before adding them. See
  "Scope" in `README.md`.
- Treat `agents/skills/` as the single source of truth for installed skills.
- Keep setup docs/scripts in sync with that directory (`agents/README.md`, `verify-setup.sh`).
- Verification must be directory-driven (derive expected skills from `agents/skills/`), not
  hardcoded skill-name lists.
- Everything in `user-home/` is **symlinked** into `~`, never copied. Same for the repo root
  `.markdownlint.json` → `~/projects/.markdownlint.json`.

## When Running Setup

- **Determine the target first** - host or VM. They share `machines/common/` but differ in what
  each one additionally installs.
- **Follow the numbered files in order** within each directory; each includes its own verification
  commands.
- **Don't run everything blindly** - ask the user before installing optional tools.
- **Check existing installations** - many tools may already be installed; verify first.
- **Respect user preferences** - these are defaults; the user may want variations.
- **Handle errors gracefully** - if a step fails, diagnose before continuing.
- **Verify at the end** - `./verify-setup.sh --host` or `--vm`.
