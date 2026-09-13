# Plan: home Tailscale and SSH docs in infra

**Status:** done 2026-09-13. Infra pull landed earlier. Later abs pass ran with the dave.box
split (`9949cd6`): placeholders, infra pointers, no live Tailscale URLs in abs.

**Date:** 2026-09-13.

agent-box-setup stays the reusable host+VM architecture. Concrete Tailscale and SSH for *this*
box — node names, MagicDNS, IPv4, Serve URLs, `blade-14`, `from=` addresses, measured sshd/UFW —
live in `infra/tailscale/`. Windows client UI stays in `dave.box-setup/windows-box/`.

Do not delete anything in agent-box-setup in the later cleanup until this plan's "Later abs pass"
is explicitly started. Pointers may be added; concrete names may remain until that pass.

Amends [`dave-box-split-plan.md`](./2026-09-13-dave-box-split-plan.md): live Serve URLs do **not** move into
the dave.box overlay. Overlay cites infra.

## Outcome

- `infra` is the source of truth for this tailnet's lived state and for the concrete apply order
  that uses those names.
- `agent-box-setup` describes how *a* box joins Tailscale, publishes Serve, and hardens OpenSSH,
  with placeholders (`VM_NAME`, `CLIENT_TAILSCALE_IPV4`, `TAILSCALE_NAME`).
- `dave.box-setup/windows-box/` keeps blade-14 keygen, `%USERPROFILE%\.ssh\config`, and VS Code
  Remote SSH. It cites infra for MagicDNS and IPv4, abs for Linux sshd procedure.

## Contract

| Repo | Owns | Does not own |
| ---- | ---- | ------------ |
| `infra` | This tailnet: inventory, join status, Serve origins, SSH measured/target, ACL matrix, `check.sh` | Generic KVM/BB/sshd drop-in text; Windows VS Code UI |
| `agent-box-setup` | Generic join/Serve/SSH/firewall procedure, lockout-safe order, libvirt SSH exception as a pattern | `xmg-evo`, `tailb67542`, `blade-14` IPv4, live Serve URLs (after the later pass) |
| `dave.box-setup` / `windows-box/` | blade-14 Windows: Tailscale app, keygen, Remote SSH config | Linux sshd/UFW; tailnet ACL editor steps |
| `dave.box-setup` / `agent-box/` | Hardware BOM, VM size, locale, apps, Geld paths | Live Tailscale URLs (cite infra) |

## Done this turn

Pulled into infra (no abs deletions):

- `~/projects/infra/tailscale/ssh.md` — measured guest key-only + UFW;
  host `sshd` still inactive; hypervisor `from="192.168.122.1"`; `blade-14` not joined; apply
  order after it joins.
- `join.md` Windows section renamed to `blade-14`; points at ssh.md and dave.box VS Code notes.
- Spec device table uses `blade-14`. Inventory points at ssh.md.
- `check.sh` treats `blade-14` as pending (fail if it appears before inventory is updated).
- Pointers added in abs `03-system-config.md` §5, `01-bootstrap.md`, `03-networking.md`,
  `05-bb.md`. Concrete names in those files were left in place.

Measured 2026-09-13 (see ssh.md): guest sshd publickey-only, UFW 22 on `tailscale0` plus
`enp1s0` from `192.168.122.1`; host sshd inactive; `blade-14` absent from `tailscale status`.

## Later abs pass (do not start now)

Replace Dave-specific Tailscale/SSH literals with placeholders. Keep a single pointer per file to
`~/projects/infra/tailscale/`. Do not move BOM, locale, Vibe Typer, or Geld — those stay on
[`dave-box-split-plan.md`](./2026-09-13-dave-box-split-plan.md).

| File | Later generic remainder | What leaves |
| ---- | ----------------------- | ----------- |
| `machines/host/03-system-config.md` §5 | Key-only drop-in, lockout-safe order, one-SSH-agent Plasma notes as *a* host failure mode | `xmg-evo-agent-vm` in the verify command; any lived IPv4 |
| `machines/vm/01-bootstrap.md` | `VM_NAME` in ssh examples; libvirt exception as hypervisor-bridge IPv4 | Hardcoded `xmg-evo-agent-vm` |
| `machines/vm/03-networking.md` | Tailscale assumed present; `tailscale status` / `ip -4` | Phone/laptop as named clients |
| `machines/vm/04-bb.md` | Serve via infra; enroll guest; optional standalone origin | `https://xmg-evo-agent-vm.tailb67542.ts.net` |
| `machines/common/05-bb.md` | Android: join tailnet, open *the* host origin from infra | Hardcoded host Serve URL |
| `machines/vm/README.md` | Naming pattern `<host>-agent-vm` | The string `xmg-evo` as the default |
| `verify-setup.sh` / `guest-baseline.sh` | Required `AGENT_BOX_VM_HOSTNAME` | Default `xmg-evo-agent-vm` (already in the dave.box split) |

Grep after that pass (Tailscale/SSH slice only; may still match until the dave.box split removes
the rest):

```bash
grep -rilE 'tailb67542|blade-14|zenfone-9|100\.117\.160\.74|100\.118\.120\.23' \
  machines/host machines/vm machines/common verify-setup.sh \
  --exclude-dir=skills
```

Must be empty except the infra pointer sentences.

## Sequence for the later pass

1. Approve this file for abs cleanup (separate from the infra pull already done).
2. One abs commit: placeholders + pointers; no file deletions beyond unused sentences.
3. Grep guard above empty.
4. `./verify-setup.sh --host --operational` still passes (it does not require Tailscale names).
5. `~/projects/infra/tailscale/check.sh` remains the lived tailnet check.

Do not interleave with applying host `sshd` or joining `blade-14`. Those are live infra/ssh.md
work. Do not interleave with deleting `machines/wsl/` (dave.box split).

## Out of scope

- Deleting abs files or WSL/migration trees.
- Applying host sshd, `blade-14` join, or tailnet ACL edits.
- Moving hardware BOM or locale (dave.box split).
- Copying Windows VS Code procedure into infra.
