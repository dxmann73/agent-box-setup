# Common setup

Install guides that apply to **both** the host and the agent VM. Each file carries the full
install and verification detail; the ordered, target-specific entry points are
[`../host/04-dev-and-agents.md`](../host/04-dev-and-agents.md) and
[`../vm/02-dev-and-agents.md`](../vm/02-dev-and-agents.md).

Start from those, not from here — they carry the per-target deltas.

| File | Description |
| --- | --- |
| [00-home-environment.md](00-home-environment.md) | Shell config, dotfiles |
| [01-agent-setup.md](01-agent-setup.md) | Claude, Cursor CLI, Codex, global rule file, skills, hooks |
| [02-core-tools.md](02-core-tools.md) | GitHub CLI, jq, Docker (VM only) |
| [03-dev-environment.md](03-dev-environment.md) | Node.js (apt), pnpm, Firecrawl CLI, SDKMAN, Java, Quarkus, Maven |
| [04-ide+tooling.md](04-ide+tooling.md) | Cursor IDE, keybindings, Java extensions |
| [06-optional.md](06-optional.md) | Helm, Minikube, kubectl |
| [07-imaging-tools.md](07-imaging-tools.md) | ImageMagick, sharp, resvg, ffmpeg, Inkscape |
| [08-auto-updates.md](08-auto-updates.md) | Unattended apt upgrades, needrestart, weekly tooling update |

## Deltas

Not covered here, because it belongs to one target only:

| Target-specific | Where |
| --- | --- |
| GPU stack, local model runtime | [`../local-llm/`](../local-llm/), host |
| hypervisor and VM creation | [`../host/05-hypervisor.md`](../host/05-hypervisor.md) |
| T3 Code server in the VM | [`../vm/04-t3code.md`](../vm/04-t3code.md) |
| Playwright browser binaries | [`../vm/02-dev-and-agents.md`](../vm/02-dev-and-agents.md) |
| agent-specific credentials | [`../vm/05-credentials.md`](../vm/05-credentials.md) |
| personal applications | [`../host/02-applications.md`](../host/02-applications.md) |
