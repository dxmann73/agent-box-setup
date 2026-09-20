# 02 – VM development toolchain and agents

[`guest-baseline.sh`](guest-baseline.sh) installs the deterministic VM toolchain and all four agent
CLIs from the host. This guide records the result, the deliberate extras, and the separation between
installation and login.

## Baseline contents

The baseline installs development essentials, Docker, Node 24 with a user-owned npm prefix,
TypeScript, pnpm, Markdownlint, `jq`, `yq`, WezTerm, VS Code, Firecrawl CLI, Playwright Chromium,
QEMU/SPICE guest agents, and these CLIs:

- Claude Code
- Codex CLI
- Cursor CLI Agent
- Pi

The guest desktop is Plasma on Wayland, but `spice-vdagent` only watches the X11 clipboard. The
baseline therefore enables the user service
[`klipper-clipboard-sync`](../../user-home/klipper-clipboard-sync.sh). It listens for Klipper's
`clipboardHistoryUpdated` DBus signal and copies the current text into the XWayland clipboard, so
text copied in the guest reaches the host through SPICE. Keep Klipper clipboard history enabled;
only text Klipper records is copied.

The baseline also disables the top-left Plasma hot corner that opens the overview/all-windows
effect.

It links the shared global instructions, skills, agent configuration, and checked-in WezTerm Lua
configuration from the guest checkout. It does not invoke any CLI interactively, so it cannot create
provider credentials.

Verify the credential-free state:

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh --vm --bootstrap
```

## Shared guidance and intentional extras

Read the common guides for maintenance and optional choices, not as a second mandatory installation
pass:

| Concern                               | Guide                                                                                                                            |
| ------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------- |
| locale overlay and managed home links | deployment overlay, [`../common/00-home-environment.md`](../common/00-home-environment.md)                                       |
| toolchain detail                      | [`../common/02-core-tools.md`](../common/02-core-tools.md), [`../common/03-dev-environment.md`](../common/03-dev-environment.md) |
| agent configuration                   | [`../../agents/README.md`](../../agents/README.md)                                                                               |
| editor and update policy              | [`../common/04-ide+tooling.md`](../common/04-ide+tooling.md), [`../common/08-auto-updates.md`](../common/08-auto-updates.md)     |

Install Dave-specific SDKMAN, Java, Quarkus, Maven, Docker Compose, imaging utilities, or other
overlay tools from the Dave box setup, not from this generic VM baseline.

## Projects and credentials

Agent-worked repositories belong under `~/projects` inside the VM. The host home directory is never
mounted. Clone private projects only after the VM has its own GitHub credential in
[05-credentials.md](05-credentials.md).

Do not run `claude`, `codex`, `agent`, `pi`, `gh auth`, or `firecrawl login` as part of bootstrap.
Those commands begin authentication and belong to the later credential phase.

## Checklist

- [ ] baseline toolchain and all four CLI binaries are installed
- [ ] shared instructions, skills, and agent configuration links resolve
- [ ] VS Code settings and keybindings are symlinked from this repository
- [ ] Playwright Chromium can take a headless screenshot
- [ ] no provider, GitHub, Firecrawl, or other credential was created by bootstrap
- [ ] Dave-specific overlay tools are installed only from the Dave box setup
