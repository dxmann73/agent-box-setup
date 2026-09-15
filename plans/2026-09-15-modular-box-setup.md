# Modular box setup — intent

What we are changing, why, and how to proceed. The **target state** (modules, ticks, per-host
values) lives in one file and is edited there:

[2026-09-14-modular-machine-catalog-design.md](./2026-09-14-modular-machine-catalog-design.md)

Do not treat this intent note as a second tick matrix. If the catalog and this file disagree on a
tick or a value, the catalog wins.

## Problem

Machine setup is split across two repos and shaped as **targets** (`host` / `vm` / `common` plus a
Dave overlay), not as **capabilities**.

That leaks in three ways:

1. **Hidden bundles.** `common/` assumes the Kubuntu host and the agent VM share one toolchain
   (Node, four agent CLIs, Firecrawl, VS Code, …). A box cannot say “Claude and Pi only” or “Java
   only on the agent VM” without fighting the guides. The catalog now does say Java/SDKMAN on the
   agent VM only; VS Code stays on the daily host.
2. **A third box with no first-class home.** The personal Chrome guest is Kubuntu, but it is not an
   agent VM. It has Python (from the desktop) and Chrome; it must not get Node, agents, BB, or
   Tailscale. Today that walk lives in the overlay as a special case.
3. **A second daily host is coming.** blade-14 will dual-boot Kubuntu (daily work) and Windows
   (gaming). The Kubuntu side should look like a daily host with its own Chrome VM, BB, and VS Code
   looking at **xmg’s** agent VM — not like a copy of xmg’s 96 GB AgentBox host. Windows and the
   existing VMware Chrome guest stay in `dave.box-setup/windows-box/`.

The old shape cannot express “same Chrome VM _role_, different RAM and resolution” or “this host
ticks KVM + Chrome VM + BB client and skips agent VM + BB server.”

## Goal

One **menu of atomic modules** (tools, roles, configs, credentials) in dependency order. Each box is a
**profile**: a tick-set plus values (hostname, vCPU, RAM, resolution, webcam, URL list, …).

Follow the catalog when setting up or reconciling a machine: tick what that box needs, fill values,
run only those modules. Unattended work stays bunched. Human login is clustered into a few windows, not
sandwiched after every install.

When recipes match the catalog, **correct live drift** on the machines. Docs first; boxes last.

## Decisions already made

These are constraints on later implementation. The catalog is allowed to refine ticks; it should not
quietly reverse these.

**Boxes**

| ID      | Box              | Role                                                                                                                                                                  |
| ------- | ---------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `xhost` | xmg Kubuntu host | Personal laptop, GPU, hypervisor, BB **server**, owns Chrome VM and agent VM                                                                                          |
| `xagt`  | xmg agent VM     | Only YOLO / project / Playwright box                                                                                                                                  |
| `xchr`  | xmg Chrome VM    | Personal browser sandbox (guest-side ticks; blade's guest reuses these until `bchr`)                                                                                  |
| `bhost` | blade-14 Kubuntu | Same daily-host modules as `xhost`, except recorded `N`. Own KVM Chrome VM, BB **client** of xmg, VS Code Remote SSH to xmg agent VM. No local agent VM. No BB server |
| —       | blade-14 Windows | Gaming / dual-boot. VMware Chrome guest. Out of the KVM catalog                                                                                                       |

xmg must stay reachable for agent work on blade-14 Kubuntu.

**Catalog shape**

- Modules are atomic (`claude-code`, `pi`, `node-24`, `java-21`, …), not “host toolchain.”
- Role modules are separate: `kvm`, `chrome-vm`, `agent-vm`, `bb-server`, `bb-client`. Guests require
  `kvm`.
- `chrome-vm` is one module configured **per host**. Size and resolution are values, not extra modules.
  xmg’s 12 GiB / 2048×1152 guest is not portable; blade-14 has ~16 GiB total and targets ~4 GiB RAM
  for Chrome. Measure the Blade panel; do not copy xmg geometry.
- Windows VMware Chrome is a **different recipe** (`windows-box`), same browsing _role_.
- Install modules and credential modules are different types. `personal-browser-logins` is one module; the
  URL list is a per-host value.
- Box IDs are 3–8 chars (`xhost` `xagt` `xchr` `bhost`). Sit codes: `boot` `iso` `login` `gcred`.
  `scp` `g+d` is `both`.
- No `bb-vm-runtime`. Host AppImage is the only BB server. The agent VM is enrolled only.

**Human time**

- Several babysit windows are fine. Auth on every other step is not.
- Typical clusters: bootstrap (including `host-sudo-session`), guest ISO, login marathon, later
  agent-VM credentials.
- On `xhost` and `bhost`, a setup agent does provisioning. Claude may be signed in with Google on
  the fly in the **stock** browser so that agent can run. That is the documented exception, not a
  template for Codex/Tailscale/BB/site logins.
- Host sudo stays password-protected. Do not add host `NOPASSWD`. The setup agent asks the user for
  a lingering authenticated sudo terminal and uses it for root steps so the password is not typed
  every other command. Guest `NOPASSWD` stays guest-only (`guest-ssh-sudo-bootstrap`).
- After Chrome VM and the needed binaries exist, remaining browser/device-code logins happen in a
  login cluster.

**Recipe folders (when guides rewrite)**

One **directory** per catalog module: `modules/<section>/<module-id>/`. Short `README.md`
(what it is, what it does). Truth lives in scripts, config, and unit files beside it.

`agents/` and `user-home/` stay payload trees.

**What lives where**

This repo stays standalone. Tick-sets, host/VM configs (RAM, vCPU, resolution, hostnames), and module recipes live here.

- `agent-box-setup` — modules, catalog ticks, host/VM values
- `dave.box-setup` — Windows, keys/secrets, Dave-only values (identity, locale, URL lists)
- `windows-box` — dual-boot, Windows host, VMware guest
- `local-llm` — GPU runtime, still a separate repo
- `infra` — Tailscale URLs, MagicDNS, SSH `from=`

Do not put keys or secret values in this tree. Do not move tick-sets or host/VM configs out.

**Out of catalog**

local-llm, Tailscale inventory, blade-14 Windows/VMware, overlay extras that are notes only,
`bb-vm-runtime`.

## What the catalog file is

[2026-09-14-modular-machine-catalog-design.md](./2026-09-14-modular-machine-catalog-design.md) is the
working target:

- legend and profile values (Chrome / agent VM / host RAM)
- the tick grids (`bhost` filled like `xhost` except recorded `N` and `bb-client`)
- operator schedule, recipe folder map, and live-vs-docs drift

Edit ticks and values **there**. Keep the fenced grids aligned (every cell is `Y`, `-`, `N`, or `.`).
`bhost` cell review is later; abbreviations and `bb-vm-runtime` are closed.

## Work still ahead

Four phases, in order. Finish one before the next. If a catalog tick or value changes, stop and
edit the catalog first.

Not a phase: Windows / keys stay in `dave.box-setup`. Tick-sets and host/VM configs stay in this repo. Recipes never embed secrets; they may read host/VM values from the catalog (or
a later `profiles/<box-id>` file **in this repo**).

### 1. Scaffold

Create `modules/00-os` … `modules/07-apps`. One directory per catalog module:
`modules/<section>/<module-id>/README.md`.

README is short: what the module is, what it does, plus typ / sit / scp / requires / ticks (or
“see catalog”). No install steps.

Leave `machines/` in place. No extra modules.

**Done:** every catalog row has a README; READMEs have no how-to.

### 2. Recipes

Put the how-to in scripts / config / unit files in that directory. Keep the README as short as
possible; do not grow it into a guide.

Each module also gets its own verify (this tick only). Daily-host bootstrap (`START-HERE` on
`xhost` / `bhost`) runs `host-sudo-session` before rootful module work. `agents/` and `user-home/`
stay payload trees.

Do not delete `machines/` yet. Dual tree is expected. Do not change live boxes.

**Done:** every catalog module has a short README, apply artifacts, and a per-tick verify.

### 3. Cutover

Step by step, one module at a time (virt guests may move as a section if kvm / nets / ISO are
coupled). For each slice: run that module’s verify on a box that ticks it, then delete the
overlapping `machines/` text. Update README / START-HERE / AGENTS.md as slices land.

Replace `verify-setup.sh` with a thin runner: given a box id, run each **ticked** module’s verify.
No host-vs-VM monolith. `--host` / `--vm` / `--bootstrap|--operational|--full` are not the source
of truth. Sit still decides which ticks to run (unattended vs login).

Delete spec §4 standalone VM BB fallback when the BB slice cuts over.

**Done:** `machines/` bundles gone; no giant verify script; verifying `xagt` runs `java-stack` and
does not run host-only ticks; spec does not mention the VM npm BB server.

### 4. Reconcile live boxes

Last. After phase 3. Apply the catalog’s live-vs-catalog table (yq, java-stack host→`xagt`,
k8s-stack on `xagt`, remove `bb-vm-runtime`). Do not use this phase to change ticks.

**Done:** that table is empty; each drifted tick’s verify matches the catalog on the live boxes.

## Success

A new or rebuilt box is specified by a profile (ticks + values) against the catalog. Two Kubuntu
hosts can share the Chrome VM _module_ and differ in RAM and resolution. An agent VM can tick Java
without forcing it on every host. blade-14 Kubuntu can be a BB/VS Code client of xmg without a
32 GiB guest it cannot host. Existing boxes eventually match that same catalog.

Until that is implemented, the catalog file is the contract. This note is the why.
