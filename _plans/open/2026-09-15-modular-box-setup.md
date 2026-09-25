# Modular box setup — implementation plan

Status: open

The target state lives in the catalog:

[modular machine catalog](../../modules/README.md)

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
- [x] `hardware-review`
- [x] `ssh-client`
- [x] `ssh-server`
- [x] `ufw-firewall`

### 1.2 Repos and home

- [x] `claude-code-bootstrap`
- [x] `home-dotfiles`
- [x] `update-tools-timer`
- [x] `markdownlint`

### 1.3 Hypervisor and guests

- [x] `kvm`
- [x] `kubuntu-iso`
- [x] `isolated-agent-net`
- [x] `isolated-browser-net`
- [x] `chrome-vm`
- [x] `agent-vm`
- [x] `guest-ssh-sudo-bootstrap`
- [x] `guest-integration`
- [x] `chrome-vm-packages`
- [x] `chrome-vm-launcher`
- [x] `virtiofs-desktop-share`
- [x] `virtiofs-user-data-shares`
- [x] `vm-snapshots`
- [x] `vm-disk-backup`

### 1.4 Core tools

- [x] `build-essential`
- [x] `jq`
- [x] `yq`
- [x] `ripgrep`
- [x] `fd-find`
- [x] `github-cli`
- [x] `wezterm`
- [x] `docker`

### 1.5 Languages and JS CLIs

- [x] `node-24`
- [x] `pnpm`
- [x] `typescript`
- [x] `firecrawl-cli`
- [x] `java-stack`
- [x] `imaging`
- [x] `k8s-stack`

### 1.6 Editor, agents, BB, browser automation

- [x] `vscode`
- [x] `vscode-java-extensions`
- [x] `vscode-remote-ssh`
- [x] `cursor-agent-launcher`
- [x] `claude-code`
- [x] `codex-cli`
- [x] `cursor-cli`
- [x] `pi`
- [x] `agent-config`
- [x] `playwright-chromium`
- [x] `bb-appimage`
- [x] `bb-enroll-execution-machine`
- [x] `tailscale`
- [x] `bb-client`

### 1.7 Credentials

- [x] `setup-agent-login`
- [x] `github-auth`
- [x] `claude-login`
- [x] `codex-login`
- [x] `cursor-login`
- [x] `pi-login`
- [x] `firecrawl-login`
- [x] `vscode-settings-sync`
- [x] `tailscale-login`
- [x] `personal-browser-logins`
- [x] `bitwarden-chrome`

### 1.8 Personal host apps

- [x] `firefox-stock`
- [x] `bitwarden-snap`
- [x] `dropbox-client`
- [x] `libreoffice`
- [x] `kdenlive`
- [x] `vibe-typer`
- [x] `losslesscut`

## 2. Cutover [x]

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

**Done:** `machines/` bundles gone; the root verifier is a thin catalog-runner entry point; per-box
verification follows catalog ticks.

## 3. Reconcile live boxes [x]

Last. After phase 3, apply the catalog’s current live-vs-catalog table. Do not use this phase to
change ticks.

**Done 2026-09-24:** the live-vs-catalog table is empty; each drifted tick’s verify matches the
catalog on the live boxes.

## Things that still need to be fixed

`verify-box xhost --full` on 2026-09-24 found remaining live/configuration work. Keep catalog
values in the deployment overlay; this list records only failed verification and required repair.

- [x] Fix the remaining `ssh-server` verifier false negatives, then verify the key-only effective
  configuration from the sudo work terminal.
- [x] Add missing non-secret Chrome VM and virtiofs-share verification context to the deployment
  overlay; rerun `chrome-vm`, `virtiofs-desktop-share`, and `virtiofs-user-data-shares` verifies.
- [x] Create a new verified Chrome VM backup set. The selected old set lacks its `backup-info`
  manifest. Done 2026-09-25: offline set `2026-09-25T145936Z-clean` passes `vm-disk-backup` with
  the `clean` snapshot.
- [x] Reconcile WezTerm apt source/unattended-upgrades configuration.
- [x] Reinstall or reconcile global `pnpm` ownership/state.
- [x] Install/reconcile `pngquant`, `optipng`, and `libimage-exiftool-perl` for `imaging`.
- [x] Reconcile the VS Code apt source and rerun VS Code/extension verification.
- [x] Configure Git to use the GitHub CLI credential helper.
- [x] Complete Firecrawl login with a real API key. Home-stored Firecrawl CLI credentials authenticate
  successfully; do not store the key in this repository.
- [x] Rerun catalog-derived full verification for `xhost`, `xagt`, and `xchr` with deployment
  context after every repair passes. Defer the Chrome run until the `clean` restore/login sequence.
  2026-09-25: `xhost --full` passed from the sudo work terminal with overlay `box.env` (now incl.
  `BROWSER_NET_*`), Vibe Typer overlay, and `chrome-vm` `clean` snapshot/backup context.
  `xchr --full` passed in the guest from a temporary host-streamed `git archive` (removed after).
  `personal-browser-logins` and `bitwarden-chrome` no longer have verifiers; `verify-box` skips
  them as manual operator steps.
- [x] Replace the agent VM backup set that lacked `backup-info`. Fixed `vm-disk-backup/apply.sh`
  (relative `SHA256SUMS` paths; no false exit 1 without `--prune-weekly`). Live set
  `2026-09-25T170522Z-current-credentialed` passes verify; the 2026-09-13 set is deleted.
- [x] `xagt --full` passed 2026-09-25 in the guest checkout (fast-forwarded to `9163b47`) with
  overlay `AGENT_VM_DOMAIN`/`USER_DATA_SHARES` exported, after rerunning `agent-config` apply
  (removed `~/CLAUDE.md` shim; no `CLAUDE.md` left under guest `~/projects`) and `kubuntu-baseline`
  guest apply from `be91e56`. Host-side `vm-snapshots` (`credentialed`, live) also passes.
- [x] Drop the fixed 22:00 automatic reboot from `kubuntu-baseline` on every box (a reboot can kill
  running agent work); keep the reboot-required dialog. Applied and verified on `xhost`, `xagt`,
  and `xchr` 2026-09-25. Coordinated reboots are drafted in `dave.agent-coordinator`
  (`_plans/drafts/coordinated-agent-vm-reboot.md`).
