# Modular box setup — implementation plan

Status: open

The target state lives in the catalog:

[modular machine catalog](../modules/README.md)

This file tracks only the remaining implementation phases. Do not duplicate catalog ticks, values,
module definitions, operator schedule, or live-drift details here. If a catalog tick or value
changes, stop and edit the catalog first.

## Guardrails

- Finish one phase before starting the next.
- Keep `machines/` in place until the cutover phase.
- Keep `agents/` and `user-home/` as payload trees.
- Do not change live boxes before the reconcile phase.
- Recipes must not embed secrets.

## 1. Recipes

Put the how-to in scripts / config / unit files in that directory. Keep the README as short as
possible; do not grow it into a guide.

Each module also gets its own verify (this tick only). Daily-host bootstrap (`START-HERE` on `xhost`
/ `bhost`) runs `host-sudo-session` before rootful module work.

Keep the existing big `verify-setup.sh` as the repo safety net while module recipes and per-module
verifies are being built. Do not replace or delete it during recipe work.

Do not delete `machines/` yet. Dual tree is expected. Do not change live boxes.

Tick each module after its recipe folder has the module README, needed scripts/config/unit files, and
its own verify. This is only a work queue of catalog module IDs; keep host ticks and values in the
catalog.

### 1.1 OS and host baseline

- [x] `kubuntu-desktop`
- [x] `kubuntu-baseline`
- [x] `host-sudo-session`
- [ ] `hardware-review`
- [ ] `git-identity`
- [ ] `ssh-client`
- [ ] `ssh-server`
- [ ] `ufw-firewall`

### 1.2 Repos and home

- [ ] `claude-code-bootstrap`
- [ ] `clone-agent-box-setup`
- [ ] `clone-dave-box-setup`
- [ ] `home-dotfiles`
- [ ] `update-tools-timer`
- [ ] `markdownlint`

### 1.3 Hypervisor and guests

- [ ] `kvm`
- [ ] `kubuntu-iso`
- [ ] `isolated-agent-net`
- [ ] `isolated-browser-net`
- [ ] `chrome-vm`
- [ ] `agent-vm`
- [ ] `guest-ssh-sudo-bootstrap`
- [ ] `guest-integration`
- [ ] `chrome-vm-packages`
- [ ] `host-url-launcher`
- [ ] `virtiofs-desktop-share`
- [ ] `virtiofs-user-data-shares`
- [ ] `vm-snapshots`
- [ ] `vm-disk-backup`

### 1.4 Core tools

- [ ] `build-essential`
- [ ] `jq`
- [ ] `yq`
- [ ] `ripgrep`
- [ ] `fd-find`
- [ ] `github-cli`
- [ ] `wezterm`
- [ ] `docker`

### 1.5 Languages and JS CLIs

- [ ] `node-24`
- [ ] `pnpm`
- [ ] `typescript`
- [ ] `firecrawl-cli`
- [ ] `java-stack`
- [ ] `imaging`
- [ ] `k8s-stack`

### 1.6 Editor, agents, BB, browser automation

- [ ] `vscode`
- [ ] `vscode-java-extensions`
- [ ] `vscode-remote-ssh`
- [ ] `cursor-agent-launcher`
- [ ] `claude-code`
- [ ] `codex-cli`
- [ ] `cursor-cli`
- [ ] `pi`
- [ ] `agent-config`
- [ ] `playwright-chromium`
- [ ] `bb-server`
- [ ] `bb-enroll-execution-machine`
- [ ] `tailscale`
- [ ] `bb-client`

### 1.7 Credentials

- [ ] `setup-agent-login`
- [ ] `github-auth`
- [ ] `claude-login`
- [ ] `codex-login`
- [ ] `cursor-login`
- [ ] `pi-login`
- [ ] `firecrawl-login`
- [ ] `vscode-settings-sync`
- [ ] `tailscale-login`
- [ ] `personal-browser-logins`
- [ ] `bitwarden-chrome`

### 1.8 Personal host apps

- [ ] `firefox-stock`
- [ ] `bitwarden-snap`
- [ ] `dropbox-client`
- [ ] `libreoffice`
- [ ] `kdenlive`
- [ ] `vibe-typer`

## 2. Cutover

Step by step, one module at a time. Virt guest modules may move as a section if KVM, nets, and ISO
are too coupled to move safely one-by-one.

For each slice:

1. Run that module’s verify on a box that ticks it.
2. Delete the overlapping `machines/` text.
3. Update `README.md`, `START-HERE.md`, and `AGENTS.md` as needed.

Replace `verify-setup.sh` only at the end of cutover, after module verifies cover the ticked
catalog modules. The replacement is a thin runner: given a box id, run each ticked module’s verify.
`--host`, `--vm`, and `--bootstrap|--operational|--full` are compatibility aliases at most, not the
source of truth.

**Done when:** `machines/` bundles gone; no giant verify script; per-box verification follows catalog
ticks; spec does not mention the VM npm BB server.

## 3. Reconcile live boxes

Last. After phase 3, apply the catalog’s current live-vs-catalog table. Do not use this phase to
change ticks.

**Done when:** the live-vs-catalog table is empty; each drifted tick’s verify matches the catalog on the
live boxes.
