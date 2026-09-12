# Remote-first bootstrap design

## Goal

From a vanilla Kubuntu host, a user opens one GitHub Markdown document in the
preinstalled browser, performs the minimum needed to start one local coding
agent, and lets that host agent set up the host. Once the host is ready, the
same host agent provisions the guest over SSH. Guest provider logins and other
credentials are deferred until the guest is operational.

## Constraints

- The personal host remains a supervised environment. The bootstrap must not
  make the host agent passwordless root or silently enable unrestricted host
  permissions.
- The guest is the agent-execution boundary. Passwordless sudo is configured
  there after SSH is available.
- The initial document must stand alone when viewed on GitHub in a fresh
  Kubuntu browser; it cannot assume a local clone.
- Scripts are appropriate for idempotent, deterministic package and
  configuration work. Decisions, authentication, credentials, and personal
  application setup remain explicit agent/user steps.

## Proposed flow

```text
Fresh Kubuntu host
  -> START-HERE.md in GitHub
  -> install and authenticate one local host agent
  -> host agent clones agent-box-setup
  -> host baseline script plus host guides
  -> host agent creates or restores guest
  -> host agent provisions guest over SSH
  -> guest credentials and BB provider access, when wanted
```

### First human interaction

`START-HERE.md` becomes the browser-readable entry point. It contains only:

1. one command to install the selected local agent and its prerequisite
   downloader;
2. the provider login required for that single host agent; and
3. one prompt directing the agent to clone this repository and execute the
   host path in supervised mode.

It must not ask the user to clone the repository, install a full development
toolchain, configure locale, or create the VM manually before the local agent
starts.

### Host completion

After cloning the repository, the host agent runs an idempotent host-baseline
script for the deterministic root-level work already partly covered by
`machines/host/prepare-host-system.sh`. The script must be safe to re-run,
validate inputs, preserve existing configuration where necessary, and stop on
an error. The host agent continues with the targeted guides for hardware
validation, personal applications, backup choices, and credentials. It keeps
host permissions supervised and never installs a host-wide `NOPASSWD` rule.

### Guest completion

The host agent creates the guest or restores `clean-guest`, then uses SSH for
all guest configuration. A guest-baseline script is invoked over SSH and runs
only after SSH plus guest passwordless sudo are available. It configures the
deterministic guest state: packages, desktop/session defaults, locale,
dotfiles, toolchain, Playwright, BB service, and verification. It does not
authenticate Claude, Codex, GitHub, Firecrawl, Tailscale, or model providers.

The first provider authentication is a separate, explicit "enable guest
agents" phase. This removes the circular requirement to authenticate a guest
agent in order to set up the guest that will run it.

## Grouping by concern

Use a common guide only where the desired result is identical on host and
guest. Keep target-specific session and hardware policies in their respective
guides.

| Concern | Home | Reason |
| --- | --- | --- |
| Locale and regional formats | new `machines/common/01-localization.md` | Same English UI and German regional profile on both machines. |
| Host power, displays, suspend, screen locking | `machines/host/01-hardware-validation.md` | Depends on physical hardware and personal-host security. |
| Guest screen blanking, locking, autologin, virtual display scale | `machines/vm/01-bootstrap.md` under one "Desktop and session" section | Deliberately different from the host; the guest is the agent boundary. |
| VM access, SSH, guest agent, base packages | `machines/vm/01-bootstrap.md` | Establishes the remote-management path. |
| Credentials and remote service exposure | dedicated VM credential/network guides | Must remain optional and separately reviewed. |

## Locale profile

Track `user-home/plasma-localerc` as the canonical Plasma user configuration
and symlink it to `~/.config/plasma-localerc` on both machines. Its profile is:

```ini
[Formats]
LANG=en_US.UTF-8
LC_ADDRESS=de_DE.UTF-8
LC_MEASUREMENT=de_DE.UTF-8
LC_MONETARY=de_DE.UTF-8
LC_NAME=de_DE.UTF-8
LC_NUMERIC=de_DE.UTF-8
LC_PAPER=de_DE.UTF-8
LC_TELEPHONE=de_DE.UTF-8
LC_TIME=de_DE.UTF-8

[Translations]
LANGUAGE=en_US
```

The baseline scripts generate both `en_US.UTF-8` and `de_DE.UTF-8`, then set
the same system-level category defaults. The result is an American-English UI
with German date, numeric, monetary, metric, and A4 conventions without using
KDE System Settings.

## Documentation changes

- Add `START-HERE.md` at repository root and link it prominently from
  `README.md`.
- Replace the current generic "agent-led bootstrap" text with a host-first
  flow and an explicit no-guest-login bootstrap phase.
- Rework `machines/host/prepare-host-system.sh` into the documented idempotent
  host baseline, rather than a loosely related prerequisite helper.
- Add a guest baseline script that the host agent invokes over SSH.
- Move the guest first-agent authentication instruction out of
  `machines/vm/01-bootstrap.md` and into a later optional credentials phase.
- Add `machines/common/01-localization.md`, the tracked Plasma locale profile,
  and locale verification to `verify-setup.sh`.
- Reframe verification as bootstrap/operational/full checks so deferred
  credentials and optional tools do not look like a failed guest bootstrap.

## Acceptance checks

- A fresh host user reaches an authenticated local agent from `START-HERE.md`
  with no local repository checkout before that agent starts.
- The host agent completes deterministic host baseline work with at most the
  normal supervised sudo confirmation.
- The guest can be fully provisioned over SSH without a guest Claude/Codex
  login.
- Host and guest report `en_US.UTF-8` UI translation settings plus German
  regional categories, and Plasma reads the tracked locale file after login.
- Re-running either baseline script changes nothing when the intended state is
  already present.
- `main` remains unchanged until the revised flow has been exercised against a
  disposable guest or the `clean-guest` restore point.
