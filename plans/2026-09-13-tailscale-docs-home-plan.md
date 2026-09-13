# Plan: home Tailscale docs — abs cites access, does not teach Tailscale

**Status:** remaining abs strip done 2026-09-13. Infra pull, dave.box pointers, and the first abs
placeholder pass (`9949cd6`) landed earlier the same day.

**Date:** 2026-09-13.

The first abs pass replaced live names with placeholders but left join, Serve, `tailscale0`
UFW, `from=` key binding, and Android Tailscale steps in agent-box-setup. That is still too
much. Tailscale is personal network infrastructure, not AgentBox architecture.

agent-box-setup may say remote clients **might** reach the host BB origin and SSH over a
private tailnet. It does not teach how to install, join, Serve, or firewall Tailscale.

Lived how-to and measured state stay in [`infra/tailscale/`](https://github.com/dxmann73/infra/tree/main/tailscale).
Windows client UI stays in `dave.box-setup/windows-box/`. dave.box `agent-box/` already cites
infra for URLs and `from=` — do not grow a Tailscale cookbook there.

Amends [`dave-box-split-plan.md`](./2026-09-13-dave-box-split-plan.md): generic join/Serve/SSH
procedure does **not** remain in abs. Locked decision 7 and the infra contract row there still
say the opposite; fix them in the same abs commit as this strip.

## Already landed (do not redo)

- `infra/tailscale/`: inventory, `join.md`, `serve.md`, `ssh.md`, `policy.md`, `check.sh`.
- dave.box `agent-box/` pointers to infra (README, `identity.md`, host overlays).
- dave.box `windows-box/host/05-vscode-remote-ssh.md` (blade-14 keygen, SSH config, VS Code UI).
- abs placeholders instead of `xmg-evo` / `tailb67542` Serve URLs.

Measured 2026-09-13 (see `infra/tailscale/ssh.md`): guest sshd publickey-only, UFW 22 on
`tailscale0` plus `enp1s0` from `192.168.122.1`; host sshd inactive; `blade-14` not joined.

## Contract

| Repo | Owns | Does not own |
| ---- | ---- | ------------ |
| `infra` | This tailnet: inventory, join, Serve, SSH apply + measured state, ACL, `check.sh` | Generic KVM/BB/sshd drop-in text; Windows VS Code UI |
| `agent-box-setup` | Host+VM architecture. One-line: remote access **may** use Tailscale for host BB URLs and SSH; cite infra. Generic sshd key-only, no public port 22, libvirt SSH exception, BB loopback + enroll | Join, Serve commands, `tailscale0` UFW, `from=` Tailscale IPv4, MagicDNS, Android Tailscale install, live node names |
| `dave.box-setup` / `windows-box/` | blade-14: Tailscale app, keygen, `%USERPROFILE%\.ssh\config`, Remote SSH | Linux sshd/UFW apply; tailnet ACL editor |
| `dave.box-setup` / `agent-box/` | Hardware BOM, VM size, locale, apps, Geld paths; cite infra for this box’s URLs | Tailscale procedure (generic or lived) |

## Remaining abs pass

Replace Tailscale cookbooks with a single access pointer per file. Keep generic SSH and BB.
Do not move BOM, locale, Vibe Typer, or Geld.

| File | Remainder | What leaves |
| ---- | --------- | ----------- |
| `docs/specification/agent-box.md` §4, §11 | Host BB must be reachable from authorized remote clients. That path **may** be private Tailscale Serve; this box’s URLs live in infra | Required “connect over Tailscale Serve HTTPS” / “reach over Tailscale” as abs procedure |
| `machines/host/03-system-config.md` §5 | Optional sshd, key-only, lockout-safe order, Plasma one-agent notes, no public port 22 | `tailscale status`, `from="CLIENT_TAILSCALE_IPV4"`, `tailscale0` UFW, `USER@TAILSCALE_NAME`, Funnel/ACL editor steps. Pointer: infra `ssh.md` |
| `machines/host/04-dev-and-agents.md` | Host AppImage is the shared control plane; enroll the VM | Serve proxy commands; “Android clients connect to the Tailscale origin”. Pointer: infra for this box’s host URL |
| `machines/vm/01-bootstrap.md` | Guest sshd later; libvirt exception for hypervisor | MagicDNS, `tailscale0` reachability checks |
| `machines/vm/03-networking.md` | NAT, host model on `virbr0`, BB listeners on loopback, libvirt SSH exception | `tailscale status` / `ip -4`, Serve HTTPS how-to, `tailscale0` UFW, phone/laptop as tailnet clients. One sentence: remote BB/SSH **may** use Tailscale; cite infra |
| `machines/vm/04-bb.md` | Loopback service, SSH tunnel for local setup, enroll into host server | `tailscale serve …`, `GUEST_SERVE_ORIGIN`, Funnel. Pointer: infra `serve.md` if this box publishes HTTPS |
| `machines/common/05-bb.md` | Host AppImage / guest `bb.service`; Android may open **the** host origin from infra | Install Tailscale, join tailnet, “turning Tailscale off must fail”, Funnel |
| `machines/vm/README.md`, repo `README.md` | NAT, model endpoint, BB reachability | “Tailscale” as a numbered setup step |
| `START-HERE.md` | Guest credentials are a later phase | Naming Tailscale as a guest credential to collect here |
| `verify-setup.sh` | Keep libvirt SSH UFW check if present | `tailscale status`; UFW `22/tcp on tailscale0`. Those stay `infra/tailscale/check.sh` |
| `machines/vm/07-snapshots.md` | Clone copies node identity; stop that daemon before raising the link | Do not add join/Serve. Keep the clone-fight warning; point apply details at infra if the exact unit name is needed |

dave.box fix in the same pass: `windows-box/host/05-vscode-remote-ssh.md` currently points at
abs host §5 for Linux sshd. Point it at `infra/tailscale/ssh.md` instead.

## Grep after the pass

In agent-box-setup (except `plans/` and `agents/skills`):

```bash
grep -rilE 'tailscale|tailnet|MagicDNS|tailb67542|Funnel' \
  machines docs START-HERE.md README.md verify-setup.sh guest-baseline.sh \
  --exclude-dir=skills
```

Allowed leftovers: the one-line “may use Tailscale for host URLs / SSH; see infra” sentences,
and the snapshot clone-identity warning. No `tailscale serve`, no `tailscale0`, no join steps.

`infra/tailscale/check.sh` remains the lived tailnet check.

## Sequence

1. Approve this revision (separate from the infra pull and the first placeholder pass).
2. One abs commit: strip cookbooks, leave pointers; amend dave-box-split locked decision 7
   and its infra contract row to match this file.
3. One dave.box commit: Windows sshd pointer → infra `ssh.md` (no new Tailscale prose).
4. Grep guard above.
5. `./verify-setup.sh --host --operational` still passes.

Do not interleave with applying host `sshd` or joining `blade-14`. Those remain
`infra/tailscale/ssh.md`. Do not interleave with deleting `machines/wsl/`.

## Out of scope

- Deleting abs files or WSL/migration trees.
- Applying host sshd, `blade-14` join, or tailnet ACL edits.
- Moving hardware BOM or locale (dave.box split, already done).
- Copying Windows VS Code procedure into infra or abs.
- Teaching Tailscale inside dave.box `agent-box/` — it already cites infra.
