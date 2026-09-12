# Next-session handoff: host-first agent box

## Read first

This handoff supersedes the earlier assumption that a guest-resident agent must
be authenticated before it can finish setting up the guest. Do not reset the
repository, the guest, or a snapshot unless the user explicitly asks.

The source baseline is GitHub `main`. The guest-setup branch was compared and
merged into `main`; do not recreate or merge it again.

## Agreed end state

Starting from a vanilla Kubuntu installation on the physical host:

1. The user opens one GitHub Markdown document in Kubuntu's preinstalled
   browser.
2. That document gives the minimum steps to install and authenticate one local
   bootstrap agent.
3. The local host agent clones `agent-box-setup` and completes the **host**
   before any VM work.
4. Host completion includes:
   - American-English UI with German regional formats;
   - host power, display, resolution, screensaver/lock, and session settings;
   - all four agents: Claude Code, Cursor CLI Agent, Codex CLI, and Pi;
   - VS Code with its intended settings and keyboard shortcuts;
   - all repositories checked out on the host permanently;
   - host tooling, applications, automation, BB desktop app, and hypervisor.
5. Only then does the same host agent create or restore and provision the guest
   entirely over SSH.
6. The guest needs no Claude/Codex login to complete its deterministic setup.
   Guest provider, GitHub, Firecrawl, Tailscale, and model credentials are a
   later explicit phase.

The host is a supervised environment. Do not make host sudo passwordless or
enable unrestricted host-agent permissions. The VM remains the unrestricted
agent-execution boundary, with its own clones of repositories; it is not the
only place projects exist.

## Design already recorded

Read [`../plans/2026-09-12-remote-first-bootstrap-design.md`](../plans/2026-09-12-remote-first-bootstrap-design.md).
It records the remote-first flow, scripts-versus-decisions boundary, shared
locale profile, concern grouping, and acceptance checks.

The plan requires a revision only if it does not yet fully reflect this
handoff. In particular, it must make full host completion the milestone before
VM creation, include Pi, VS Code shortcuts, and permanent host repository
clones.

## Grouping policy

Group instructions by concern when the policy is genuinely shared:

| Concern | Home |
| --- | --- |
| Locale and regional formats | shared `machines/common/` guide |
| Host power, displays, suspend, and lock policy | `machines/host/` |
| Guest blanking, locking, autologin, and virtual scale | `machines/vm/` |
| VM SSH/access and guest-agent plumbing | `machines/vm/` |
| Credentials, network exposure, and shares | their existing separate VM guides |

Do not put host autologin or physical-display policy in a shared document: the
host's personal-data/security posture and hardware differ from the guest's.

## Locale requirement

The canonical user-facing profile is American-English UI with German regional
formats:

- `LANG` and Plasma translations: `en_US.UTF-8` / `en_US`;
- monetary, numeric, date/time, measurement, paper, address, name, and
  telephone categories: `de_DE.UTF-8`.

This produces euro, metric units, A4, comma decimals, 24-hour time, and German
date conventions without a German UI. The current guest's
`~/.config/plasma-localerc` already has this desired profile. The intended
implementation is a tracked `user-home/plasma-localerc`, symlinked on both
machines, plus generated and system-level `en_US.UTF-8` and `de_DE.UTF-8`
locales. Do not rely on manual KDE Settings changes.

## Current live state

### Host

- Libvirt works with `qemu:///system`.
- The OpenSSH user agent has the host key loaded; host-to-guest SSH works by
  public key.
- The BB AppImage exists; the host `bb.service` is intentionally inactive.
- Host locale configuration is currently inconsistent: system defaults are
  German, while Plasma is a British-English/German mixture. Treat the tracked
  locale profile above as the intended replacement.

### Guest

- Domain: `xmg-evo-agent-vm`, running at `192.168.122.123`.
- SSH, guest passwordless sudo, qemu guest agent, autologin, and the SPICE
  console baseline work.
- Snapshot `clean-guest` exists and is the credential-free baseline.
- The active guest has partial later-stage tools and credentials. It is not a
  clean test of the revised flow.
- Its checkout is clean but behind GitHub `main`; pull only if retaining this
  guest for migration work.

## Reset decision: leave unchanged for now

After the revised design is approved, choose one approach:

1. Prefer restoring `clean-guest` to test the new host-driven provisioning
   flow. It preserves the working VM hardware and SSH baseline while removing
   later guest tools and credentials.
2. Retain the running guest only if the goal is to migrate its existing state.
3. Reinstall Kubuntu in a new guest only to test a new installer/autoinstall
   path. It is not needed to test host-driven SSH provisioning.

## Next work, in order

1. Read the design and this handoff; reconcile them without discarding merged
   guest fixes from `main`.
2. Inspect the official Pi documentation and decide its supported install,
   configuration, authentication, update, and verification path. Add it beside
   `agents/claude/`, `agents/cursor/`, and `agents/codex/`.
3. Confirm the authoritative repository inventory and how the host agent
   checks out or updates every repository. Existing documentation delegates
   project inventory to `clackworks.agents`; update that handoff for the
   permanent host-workspace requirement.
4. Refine the implementation plan for:
   - root-level `START-HERE.md` for the browser bootstrap;
   - an idempotent, narrow host-baseline script;
   - a host-invoked guest-baseline script over SSH;
   - concern-grouped locale, host desktop/session, and guest desktop/session
     guides;
   - bootstrap/operational/full verification profiles.
5. Present the revised plan to the user before changing setup guides or scripts.
6. Implement only after approval, exercise the flow against `clean-guest` or a
   disposable clone, and then decide whether to reset the real guest.

## Repository state at handoff

At the time of this handoff, the local workspace is on `main` at `6c28941`, a
local documentation commit that adds the explicit Pi and permanent-host-workspace
requirements to the design. It has not been pushed by this session. Check
`git status`, `git log`, and `git ls-remote origin refs/heads/main` before
making any Git decision.
