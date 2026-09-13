# 02 – VM development toolchain and agents

[`guest-baseline.sh`](guest-baseline.sh) installs the deterministic VM
toolchain and all four agent CLIs from the host. This guide records the result,
the deliberate extras, and the separation between installation and login.

## Baseline contents

The baseline installs development essentials, Docker, Node 24 with a
user-owned npm prefix, TypeScript, pnpm, Markdownlint, WezTerm, Firecrawl CLI,
Playwright Chromium, QEMU/SPICE guest agents, and these CLIs:

- Claude Code
- Codex CLI
- Cursor CLI Agent
- Pi

It links the shared global instructions, skills, agent configuration, and
checked-in WezTerm Lua configuration from the guest checkout. It does not
invoke any CLI interactively, so it cannot create provider credentials.

Verify the credential-free state:

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh --vm --bootstrap
```

## Shared guidance and intentional extras

Read the common guides for maintenance and optional choices, not as a second
mandatory installation pass:

| Concern | Guide |
| --- | --- |
| locale and managed home links | [`../common/01-localization.md`](../common/01-localization.md), [`../common/00-home-environment.md`](../common/00-home-environment.md) |
| toolchain detail | [`../common/02-core-tools.md`](../common/02-core-tools.md), [`../common/03-dev-environment.md`](../common/03-dev-environment.md) |
| agent configuration | [`../../agents/README.md`](../../agents/README.md) |
| editor, imaging, and update policy | [`../common/04-ide+tooling.md`](../common/04-ide+tooling.md), [`../common/07-imaging-tools.md`](../common/07-imaging-tools.md), [`../common/08-auto-updates.md`](../common/08-auto-updates.md) |

Install SDKMAN, Java, Quarkus, imaging utilities, VS Code, or other optional
tools only when the guest's projects require them. They belong in the `full`
verification profile once enabled.

## Projects and credentials

Agent-worked repositories belong under `~/projects` inside the VM. The host
home directory is never mounted. Clone private projects only after the VM has
its own GitHub credential in [05-credentials.md](05-credentials.md).

Do not run `claude`, `codex`, `agent`, `pi`, `gh auth`, or `firecrawl login`
as part of bootstrap. Those commands begin authentication and belong to the
later credential phase.

## Checklist

- [ ] baseline toolchain and all four CLI binaries are installed
- [ ] shared instructions, skills, and agent configuration links resolve
- [ ] Playwright Chromium can take a headless screenshot
- [ ] no provider, GitHub, Firecrawl, or other credential was created by bootstrap
- [ ] optional tools are installed only when required and then checked with `--full`
