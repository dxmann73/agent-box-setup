# 04 – Host development tools and agents

The host runs the same development toolchain as the VM, plus coding agents for local work. The
install detail lives once in [`../common/`](../common/); this file is the host-side order and the
host-side deltas.

Why agents run here too: the host is where the local model is built, benchmarked and driven, and
where this repo is edited. Agent work on personal projects still belongs in the VM
(specification §2, §8) — the host agent is for host-scoped tasks.

## 1. Development basics

```bash
sudo apt install -y \
  git curl wget build-essential cmake ninja-build pkg-config \
  python3 python3-pip python3-venv pipx jq htop btop tmux \
  ripgrep fd-find
```

```bash
mkdir -p ~/projects
```

`build-essential`, `cmake` and `ninja-build` are also what `llama.cpp` needs, see
[`../local-llm/steps/02-build-llama-cpp.md`](../local-llm/steps/02-build-llama-cpp.md).

## 2. Common guides, in order

| Step | Guide |
| --- | --- |
| shell/dotfiles | [`../common/00-home-environment.md`](../common/00-home-environment.md) |
| coding agents, skills, hooks | [`../common/01-agent-setup.md`](../common/01-agent-setup.md) |
| core tools | [`../common/02-core-tools.md`](../common/02-core-tools.md) |
| languages/runtimes | [`../common/03-dev-environment.md`](../common/03-dev-environment.md) |
| editor | [`../common/04-ide+tooling.md`](../common/04-ide+tooling.md) |
| imaging | [`../common/07-imaging-tools.md`](../common/07-imaging-tools.md) |
| optional | [`../common/06-optional.md`](../common/06-optional.md) |

Clone this repo into `~/projects` first — the dotfile symlinks point at it.

## 3. Host deltas

Applies on the host and not in the VM:

- GPU/compute stack and the local model runtime: [`../local-llm/`](../local-llm/)
- the hypervisor and the agent VM itself: [05-hypervisor.md](05-hypervisor.md)
- the personal Chrome profile: agents on the host must not drive it either; use a separate
  profile or the VM's Chromium

Applies in the VM and not here:

- the herdr server ([`../vm/03-herdr.md`](../vm/03-herdr.md)) — the host runs only a client
- Playwright browser binaries ([`../vm/02-dev-and-agents.md`](../vm/02-dev-and-agents.md))
- agent-specific GitHub/SSH credentials ([`../vm/05-credentials.md`](../vm/05-credentials.md))

## 4. Verification

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh --host
```

## 5. Development checklist

- [ ] apt development basics installed
- [ ] dotfiles symlinked, secrets file populated
- [ ] `gh auth status` shows logged in
- [ ] Docker works without sudo
- [ ] Node LTS + pnpm (Corepack shim) + tsc/ts-node
- [ ] markdownlint and firecrawl CLIs available, firecrawl authenticated
- [ ] SDKMAN with auto-env, Java 21, Quarkus, Maven
- [ ] Cursor IDE installed and configured
- [ ] Claude Code / Cursor CLI / Codex installed and authenticated
- [ ] skills and hooks symlinked
- [ ] imaging tools installed
- [ ] `./verify-setup.sh --host` passes

Next: [05-hypervisor.md](05-hypervisor.md)
