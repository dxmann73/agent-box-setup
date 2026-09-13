**Amendment 2026-09-13:** live Tailscale node names, MagicDNS, IPv4 addresses, Serve URLs, and SSH
`from=` addresses live in `infra/tailscale/`, not in the dave.box overlay. dave.box cites those
values; agent-box-setup cites the generic procedure. See
[`2026-09-13-tailscale-docs-home-plan.md`](./2026-09-13-tailscale-docs-home-plan.md).

# Untangle Dave-box from agent-box-setup

**Status:** done 2026-09-13. Overlay in dave.box-setup `agent-box/`; abs parameterized in
`9949cd6`. Live `apply-locale.sh` is a host apply, not a docs leftover.

**Date:** 2026-09-13.

agent-box-setup is the reusable architecture for an Ubuntu host plus one or more persistent
agent VMs. dave.box-setup is now the private two-machine inventory: blade-14 under
`windows-box/` (already stubbed) and xmg-evo under `agent-box/` (still a stub). This split
fills `agent-box/` only. It does not touch `windows-box/`, does not run from a windows-box
change, and does not wait on dave.box incoming plans 02–04.

The destination is the existing private repo
[dave.box-setup](https://github.com/dxmann73/dave.box-setup)
(`~/projects/dave.box-setup`), not a new hyphenated repo.

## Locked decisions

1. **`agents/AGENTS.md` GitHub org line** stays in agent-box-setup. It is shared working
   context for this repo, not a dave.box overlay.
2. **`machines/wsl/`** is deleted from agent-box-setup. WSL is unused. Do not copy it to
   dave.box-setup. blade-14 already forbids WSL-as-dev-host in `windows-box/`.
3. **Locale profile** (`en_US` UI + `de_DE` formats, `plasma-localerc`,
   `machines/common/01-localization.md`) moves to `dave.box-setup/agent-box/`.
4. **Vibe Typer** files in `user-home/` move to `dave.box-setup/agent-box/` with the
   personal app list.
5. **Overlay root is `dave.box-setup/agent-box/`**, not dave.box repo-root `machines/`.
   Pairing with agent-box-setup stays a path-suffix mirror
   (`machines/host/05-hypervisor.md` ↔ `agent-box/machines/host/05-hypervisor.md`).
6. **Guest disk is 80 GiB** (live value). Do not write 200 GiB back into the overlay.
7. **Host AppImage is the shared BB control plane.** Live Serve origins, node IPs, and SSH `from=`
   addresses live in `infra/tailscale/`. Generic guides keep the enrollment *procedure*. dave.box
   cites infra; it does not re-own those URLs.
8. Live VM backup/restore in `machines/vm/07-snapshots.md` has already landed. It is not a
   gate. Do not interleave this split with a live SSH key/firewall apply from
   [`2026-09-13-ssh-tailnet-hardening-plan.md`](./2026-09-13-ssh-tailnet-hardening-plan.md) (doc generalization already
   landed).

## Contract

Same pattern as the Geld share split and as [local-llm](https://github.com/dxmann73/local-llm):

| Repo | Owns | Does not own |
| ---- | ---- | ------------ |
| `agent-box-setup` | Architecture spec, numbered procedures, toolchain, skills, verification profiles, parameterized scripts, shared `agents/AGENTS.md` | Physical BOM, live domain names, Tailscale nodes, git identity, locale profile, personal apps, Dropbox paths, this-host migration, Windows inventory |
| `dave.box-setup` / `windows-box/` | blade-14 Windows host, VMware Chrome guest, product keys, VS Code Remote SSH client | AgentBox / KVM procedures, WSL, coding agents |
| `dave.box-setup` / `agent-box/` | xmg-evo inventory and overlays: hardware, VM names and sizes, shares, personal apps, Vibe Typer, locale, git identity, one-time XMG Windows → Kubuntu move | Re-explaining KVM, virtiofs, BB, guest baseline, or agent CLI install; live Tailscale URLs (those are infra) |
| `local-llm` | Host GPU model runtime | Unchanged |
| `infra` | This tailnet: nodes, MagicDNS, IPv4, Serve URLs, SSH `from=`, ACL grants | Generic join/Serve/SSH procedure (agent-box-setup) |

**Grep guard for agent-box-setup** after the split (must stay empty except a single pointer
file that names the overlay repo):

```bash
grep -rilE 'xmg-evo|890M|HX 370|tailb67542|dxmann73@gmail|clackworks\.agents|/Dropbox/Docs/Geld|de_DE|plasma-localerc|VibeTyper|vibe-typer' \
  machines/host machines/vm machines/common agents user-home START-HERE.md \
  docs verify-setup.sh \
  --exclude-dir=skills
```

WSL/migration guard, no exemptions once `machines/wsl/` is gone:

```bash
grep -rilE 'bitlocker|fast startup|dual.?boot|windows partition|shrink windows|ntfs|WSL|/mnt/c|winget install|DrvFs' \
  machines/host machines/vm machines/common agents user-home START-HERE.md docs verify-setup.sh \
  --exclude-dir=skills
```

Allowed leftovers: this repo's own GitHub URL (`dxmann73/agent-box-setup`), the GitHub org
line in `agents/AGENTS.md`, links to `dxmann73/local-llm`, `dxmann73/dave.box-setup`, and
published tools such as `dxmann73/scm-tidy`. Pointers into
`dave.box-setup/agent-box/…` (not repo-root `setup/11`).

**Grep guard for dave.box-setup** (whole repo except licenses; must stay empty except
citations/URLs):

```bash
grep -rilE 'virt-install|virtiofs|guest-baseline|memfd|SeaBIOS' \
  . --exclude-dir=licenses --exclude-dir=.git
```

No copy of virt-install flag rationale, virtiofs attach procedure, guest-baseline steps, or
BB install. Cite agent-box-setup by URL. Expand the current windows-box-only grep to cover
`agent-box/` when the overlay lands.

## How an agent follows setup after the split

1. Clone `agent-box-setup` and `dave.box-setup` next to each other under `~/projects`.
2. Classify the physical machine:
   - blade-14 → `dave.box-setup/windows-box/` only.
   - xmg-evo → walk numbered agent-box-setup guides, then apply the matching
     `dave.box-setup/agent-box/` overlay.
3. Source `dave.box-setup/agent-box/box.env` before invoking parameterized scripts.
4. After each numbered host, VM, or common guide, apply the matching overlay if it exists
   (locale is the common overlay).
5. Run `./verify-setup.sh` from agent-box-setup (generic). Then run
   `agent-box/verify-dave-box.sh` (hostname, BOM, locale, shares, personal apps).

Overlay paths mirror agent-box-setup under the `agent-box/` prefix:

```text
agent-box-setup/machines/host/05-hypervisor.md
dave.box-setup/agent-box/machines/host/05-hypervisor.md   # name, vCPU, RAM, disk, ISO dest

agent-box-setup/machines/vm/06-shared-folders.md
dave.box-setup/agent-box/machines/vm/06-shared-folders.md  # Geld tags and paths (today's setup/11)

dave.box-setup/agent-box/machines/common/01-localization.md  # no generic counterpart after the move
```

Replace dave.box's leftover `setup/` dump with that mirrored layout inside `agent-box/`.
Move `setup/09-amd ai setup.md`, `wezterm-gallery/`, and `scripts/gl.sh` to
`agent-box/extras/`. Do not copy `scripts/ua.sh`; agent-box-setup already tracks it.
Keep the existing dave.box README two-machine contract; fill the `agent-box/` stub instead
of rewriting the repo as a single-host overlay.

When dave.box `_incoming/2026-09-13-03-agent-box-chrome-vm-plan.md` later runs, write its
files under `agent-box/` (e.g. `agent-box/machines/host/06-chrome-vm.md`). Its current
repo-root `machines/` paths are stale.

## Parameterization in agent-box-setup

Hardcoded `xmg-evo-agent-vm` becomes a required value, not a default that happens to be
this laptop. `backup-agent-vm.sh` still defaults the domain; drop that default.

| Variable | Meaning | Dave value |
| -------- | ------- | ---------- |
| `AGENT_BOX_VM_HOSTNAME` | libvirt domain and guest hostname | `xmg-evo-agent-vm` |
| `AGENT_BOX_VM_VCPUS` | guest vCPUs | `20` |
| `AGENT_BOX_VM_MEMORY_MIB` | guest RAM | `32768` |
| `AGENT_BOX_VM_DISK_GIB` | sparse qcow2 size | `80` |
| `AGENT_BOX_BACKUP_ROOT` | same-host backup directory | `~/backup/vm` |

Scripts (`guest-baseline.sh`, `backup-agent-vm.sh`, `verify-setup.sh`) refuse to guess.
They read the variables from the environment. dave.box documents exporting them from
`agent-box/box.env` that the host agent sources before invoking those scripts.
`guest-baseline.sh` already reads `AGENT_BOX_VM_HOSTNAME` but still defaults to
`xmg-evo-agent-vm`; remove the default.

Guides use placeholders (`VM_NAME`, example `virt-install` numbers) and point at the
overlay for the live line. Keep the *reasons* for flags (`memfd`, SeaBIOS, 2D virtio,
`discard=unmap`) in agent-box; keep the *counts* in dave.box.

Naming rule stays in agent-box as advice: `<host>-agent-vm`. The string `xmg-evo` does
not.

BB: generic guides describe publishing the host AppImage via `infra` Serve, enrolling the
guest as an execution machine named `VM_NAME`, and an optional standalone guest origin.
Live URLs live in `infra/tailscale/`. SSH *procedure* stays in agent-box-setup; live node
names and `from=` client addresses live in `infra/tailscale/ssh.md`. Windows client steps
stay in `windows-box/host/05-vscode-remote-ssh.md`.

Locale is not parameterized in agent-box. Generic host/guest scripts stop generating
`de_DE`, writing `/etc/default/locale`, and linking `plasma-localerc`. Dave's overlay
script applies the profile on both machines after the generic baseline.

## What moves, what stays, what splits

### Move wholesale to `dave.box-setup/agent-box/`

| Source in agent-box-setup | Why it is Dave-only |
| ------------------------- | ------------------- |
| `machines/host/README.md` target-system table (XMG EVO 14, HX 370, 890M, 96 GB) | Physical BOM |
| Expected results in `machines/host/01-hardware-validation.md` (890M, 96 GB RAM) | Same |
| Personal install list in `machines/host/02-applications.md` (Dropbox, Steam, Kdenlive snap pin, Vibe Typer, WhatsApp, Office, Claude/ChatGPT desktop) | This host's apps |
| `user-home/vibe-typer-launch.sh`, `vibe-typer-update-reminder.sh`, `applications/vibe-typer.desktop`, and the two systemd reminder units | Goes with that app |
| `machines/common/01-localization.md`, `user-home/plasma-localerc` | Locale profile |
| Concrete Tailscale Serve URLs in `machines/common/05-bb.md` and `machines/vm/04-bb.md` | This tailnet — they belong in `infra/tailscale/`, not the dave.box overlay |
| `machines/migration/` | One-time XMG Windows → Kubuntu move (not blade-14) |
| `_incoming/vm-load-test.md` | This CPU/RAM topology |
| Host-completion requirement on `clackworks.agents` | Dave's project inventory |
| `user-home/.gitconfig` `[user]` name/email | Identity |

Already in dave.box; relocate into the overlay during this split:

| Current dave.box path | Destination |
| --------------------- | ----------- |
| `setup/11-agent-vm-shared-folders.md` | `agent-box/machines/vm/06-shared-folders.md` |
| `setup/09-amd ai setup.md` | `agent-box/extras/` |
| `wezterm-gallery/` | `agent-box/extras/wezterm-gallery/` |
| `scripts/gl.sh` | `agent-box/extras/` |
| `scripts/ua.sh` | delete leftover; do not copy |
| `_incoming/2026-09-13-03-agent-box-chrome-vm-plan.md` | stays in dave.box `_incoming/`; implement later under `agent-box/` |

`machines/vm/06-shared-folders.md` already points at
`dave.box-setup/setup/11-agent-vm-shared-folders.md`. Retarget that link to
`dave.box-setup/agent-box/machines/vm/06-shared-folders.md`.

### Delete from agent-box-setup (do not move)

| Source | Why |
| ------ | --- |
| `machines/wsl/` | Unused. Native Kubuntu is the only host. |
| README / `machines/README.md` "Staying on Windows + WSL" start path | Same |
| `AGENTS.md` WSL exemption (`grep -v 'wsl/README.md'`) | File will not exist |
| Any `verify-setup.sh` `/mnt/c` VS Code fallback, if still present | Same |

After deletion the WSL/Windows grep must stay empty with no exemptions. Update
`AGENTS.md`: `machines/migration/` remains disposable **after it has moved** to
`dave.box-setup/agent-box/`; agent-box-setup then has no migration or WSL tree.

### Stay in agent-box-setup (generic)

- `docs/specification/agent-box.md` — architecture. Keep Chrome/Dropbox as examples of
  *personal host apps*, not as required packages. Keep host AppImage as shared BB control
  plane; do not name `xmg-evo`.
- Numbered procedures: hardware *checks* (GPU driver in use, suspend, displays), KVM
  install, guest SSH/sudo bootstrap, `guest-baseline.sh` behavior, toolchain, agents,
  BB (host control plane + guest enrollment + optional fallback), credentials *policy*,
  virtiofs *procedure*, snapshot *procedure*.
- `machines/common/` toolchain, auto-updates, imaging tools. Not localization.
- `agents/` CLI install, skills, hooks, and `agents/AGENTS.md` including the GitHub org
  line. Spec §9 stays here.
- `user-home/` shell, aliases, WezTerm, update-tools, Klipper clipboard sync, VS Code
  settings that are toolchain not identity. Not Vibe Typer, not `plasma-localerc`, not
  git `[user]`.
- Verification profiles `bootstrap` / `operational` / `full`, with hostname, locale
  profile, and project-inventory checks removed from the generic script.
- Kubuntu as the documented desktop flavor (Plasma, AppImage, virt-manager). That is a
  distro choice, not this laptop.

### Split in place (generic remainder + dave overlay)

| File | Generic remainder | Overlay (`agent-box/…`) |
| ---- | ----------------- | ----------------------- |
| `machines/host/01-hardware-validation.md` | Commands to record GPU/Vulkan/suspend/display | Expected 890M / 96 GB / XMG support URL |
| `machines/host/02-applications.md` | Personal apps stay on the host; agents never use the personal browser profile | The install list, including Vibe Typer |
| `machines/host/03-system-config.md` | `~/projects`, `~/vms`, `~/backup/vm`, libvirt pool, SSH, firewall; Dropbox as optional | `~/Dropbox`, `~/models` layout, deferred host-backup decision |
| `machines/host/04-dev-and-agents.md` | Host toolchain and four CLIs; host completion gate; host AppImage as control plane | Clone `clackworks.agents` and reconcile the inventory; locale overlay; cite infra Serve |
| `machines/host/05-hypervisor.md` | `kvm-ok`, nsswitch, pool, virt-install flags with reasons | `virt-install --name … --vcpus 20 --memory 32768 --disk size=80` |
| `machines/vm/01-bootstrap.md`, `07-snapshots.md`, host SSH examples | Commands with `VM_NAME` | `xmg-evo-agent-vm` and `~/backup/vm/xmg-evo-agent-vm/` |
| `machines/common/05-bb.md`, `machines/vm/04-bb.md` | Host AppImage control plane; enroll guest; optional standalone origin; Serve via `infra` | Pointer only; URLs stay in `infra/tailscale/` |
| `machines/common/00-home-environment.md` | Shell/WezTerm/gitconfig include symlink list | `plasma-localerc` and Vibe Typer links |
| `START-HERE.md` | Supervised host agent clones agent-box-setup and walks generic host guides | Dave START-HERE in `agent-box/README.md`: clone both repos, source `box.env`, apply locale, require clackworks inventory |
| `verify-setup.sh` | Symlinks, tools, BB, Playwright; no `de_DE` / hostname / clackworks | `agent-box/verify-dave-box.sh`: hostname, BOM, locale, Geld mounts, personal apps, `clackworks.agents` |
| `README.md` / project `AGENTS.md` | Two-target map, setup order, "classify before adding"; pointer to dave.box overlay | Drop "geared specifically towards an xmg evo"; drop WSL/migration from the directory map |

`prepare-host-system.sh` and `guest-baseline.sh` drop `ensure_locale_sources`,
`locale-gen de_DE`, `/etc/default/locale`, and the `plasma-localerc` symlink. Dave.box
ships `agent-box/machines/common/apply-locale.sh` (or the localization overlay itself)
and the host/guest sequences run it after the generic baseline.

## dave.box-setup layout after the move

`windows-box/` is unchanged by this split. `agent-box/` becomes:

```text
dave.box-setup/
├── README.md                          # two machines (already exists)
├── AGENTS.md                          # classify windows-box vs agent-box (already exists)
├── windows-box/                       # blade-14 — do not touch
├── _incoming/                         # windows-box 02–04 + chrome-vm plan stay here
└── agent-box/
    ├── README.md                      # xmg-evo contract, clone both, source box.env
    ├── box.env                        # hostname, vCPU, RAM, disk, backup root
    ├── verify-dave-box.sh             # overlay checks only
    ├── machines/common/
    │   └── 01-localization.md         # en_US UI, de_DE formats, plasma-localerc
    ├── machines/host/
    │   ├── 01-hardware.md             # XMG EVO BOM + expected validation results
    │   ├── 02-applications.md         # personal app list + Vibe Typer
    │   ├── 03-system-config.md        # Dropbox/models paths, backup deferral
    │   ├── 04-dev-and-agents.md       # clackworks.agents inventory; cite infra Serve
    │   └── 05-hypervisor.md           # concrete virt-install (80 GiB disk)
    ├── machines/vm/
    │   ├── identity.md                # libvirt name/size; Tailscale cites infra
    │   ├── 06-shared-folders.md       # Geld (from setup/11)
    │   └── 07-snapshots.md            # live backup labels/paths if they stay Dave-only
    ├── machines/migration/            # moved tree; drop the "WSL is a supported variant" line
    ├── identity/                      # git user, plasma-localerc, Vibe Typer units
    └── extras/                        # AMD AI notes, wezterm-gallery, gl.sh
```

No `machines/wsl/` here. No overlay files at dave.box repo root.

## Identity and locale

**Git identity:** agent-box `user-home/.gitconfig` drops `[user]` and uses

```text
[include]
    path = ~/.gitconfig.local
```

dave.box tracks `agent-box/identity/gitconfig.local` (name + email) and the overlay guide
links it to `~/.gitconfig.local`. Generic verify checks that Git has `user.name` /
`user.email`; it does not check the values.

**Locale:** dave.box owns the profile. Track `agent-box/identity/plasma-localerc` and
`agent-box/machines/common/01-localization.md`. Apply on host after
`prepare-host-system.sh`, on guest after `guest-baseline.sh`.
`verify-dave-box.sh` checks generated locales, `/etc/default/locale` categories, and
that `~/.config/plasma-localerc` matches the dave.box file.

**`agents/AGENTS.md`:** stays in agent-box-setup as-is, including
`Github is https://github.com/dxmann73`. Do not overlay or duplicate it.

## Specification

No new architecture. Two wording nits in `docs/specification/agent-box.md`:

1. §1 and §7 keep "Chrome, Dropbox, documents" as examples of host-personal vs
   guest-automation, not as a package list. §4 already describes the host AppImage
   control plane; do not name this laptop.
2. Chrome-in-a-guest (`dave.box-setup/_incoming/2026-09-13-03-agent-box-chrome-vm-plan.md`)
   is a dave.box personal-app choice under `agent-box/`. Do not change spec §1 until that
   pattern is promoted as generic advice.

## Sequence

Do not interleave with a live SSH apply, and do not mix commits with windows-box incoming
02–04. Each step is one commit per repo, or a paired pair of commits, so a bisect on
agent-box never sees placeholders without the overlay that supplies values.

1. **Scaffold `agent-box/`** — README, mirrored `machines/` paths, `box.env`, move
   `setup/11` → `agent-box/machines/vm/06-shared-folders.md`, retarget the agent-box-setup
   share-guide link, move `setup/09`, `wezterm-gallery/`, `scripts/gl.sh` into
   `agent-box/extras/`, delete leftover `scripts/ua.sh`.
2. **Parameterize agent-box scripts** — required env vars, no `xmg-evo-*` defaults
   (`guest-baseline.sh`, `backup-agent-vm.sh`, `verify-setup.sh`). Guides switch to
   `VM_NAME` placeholders in the same change set. Drop locale from
   `prepare-host-system.sh` and `guest-baseline.sh`.
3. **Write overlays** — hardware BOM, virt-install line (80 GiB), personal apps, Vibe Typer,
   locale, git identity include, clackworks host-completion. Cite `infra/tailscale/` for
   Serve URLs and SSH `from=`; do not copy them into the overlay.
4. **Move `machines/migration/`** to `agent-box/machines/migration/`. **Delete
   `machines/wsl/`** and the README/AGENTS WSL touchpoints. Do not leave a stub
   directory.
5. **Grep guards** — add the agent-box greps to `AGENTS.md`. Expand dave.box's procedure
   grep from `windows-box/` to the whole repo. Point dave.box `agent-box/README.md` at
   the landed overlay instead of this incoming plan.
6. **START-HERE** — generic prompt in agent-box-setup; Dave prompt in
   `agent-box/README.md` that clones both and sources `box.env`.
7. **Verify** — generic `./verify-setup.sh --host --operational` no longer requires
   `clackworks.agents`, hostname `xmg-evo-agent-vm`, or `de_DE`.
   `agent-box/verify-dave-box.sh` does.

## Out of scope

- Making agent-box-setup public.
- Re-homing skills or agent CLI config.
- Rewriting `user-home/` into a general overlay/dotfiles framework.
- Host backups (still deferred).
- Implementing the Chrome VM or the live backup proof — backup procedure has landed;
  chrome-vm stays its own incoming under dave.box. When that plan runs, paths go under
  `agent-box/`.
- Changing libvirt resource numbers on the running guest.
- Keeping any WSL variant anywhere.
- Touching `windows-box/` or executing dave.box incoming plans 01–04.
- Applying live SSH key/`from=`/UFW changes (separate hardening plan).
