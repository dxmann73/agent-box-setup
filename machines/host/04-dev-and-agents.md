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
[`../../local-llm/steps/02-build-llama-cpp.md`](../../local-llm/steps/02-build-llama-cpp.md).

## 2. Common guides, in order

| Step | Guide |
| --- | --- |
| shell/dotfiles | [`../common/00-home-environment.md`](../common/00-home-environment.md) |
| coding agents, skills, hooks | [`../../agents/`](../../agents/README.md) |
| core tools | [`../common/02-core-tools.md`](../common/02-core-tools.md) |
| languages/runtimes | [`../common/03-dev-environment.md`](../common/03-dev-environment.md) |
| editor | [`../common/04-ide+tooling.md`](../common/04-ide+tooling.md) |
| imaging | [`../common/07-imaging-tools.md`](../common/07-imaging-tools.md) |
| automatic updates | [`../common/08-auto-updates.md`](../common/08-auto-updates.md) |
| optional | [`../common/06-optional.md`](../common/06-optional.md) |

Clone this repo into `~/projects` first — the dotfile symlinks point at it.

## 3. Host deltas

Applies on the host and not in the VM:

- **Docker is skipped here.** The `docker` group is root-equivalent, and the host holds personal
  data; container work belongs in the VM ([`../common/02-core-tools.md`](../common/02-core-tools.md)
  §3)
- GPU/compute stack and the local model runtime: [`../../local-llm/`](../../local-llm/)
- the hypervisor and the agent VM itself: [05-hypervisor.md](05-hypervisor.md)
- the personal Chrome profile: agents on the host must not drive it either; use a separate
  profile or the VM's Chromium

### T3 Code on the host

The host runs T3 Code twice over: its own server, for host-scoped work that cannot move into the VM
(local model runtime, hypervisor, this repo), and the desktop app, which holds both environments,
the local one and the VM's headless server.

On Linux the desktop app ships as an AppImage only — there is no `.deb`, and the `winget`/Homebrew/
AUR packages in the upstream README do not apply to Kubuntu. AppImages need FUSE 2, which Ubuntu no
longer installs by default; without it the app exits with a "cannot mount AppImage" error that
looks like a corrupt download:

```bash
sudo apt install -y libfuse2t64
mkdir -p ~/opt/t3code
gh release download --repo pingdotgg/t3code --pattern '*.AppImage' --dir ~/opt/t3code
chmod +x ~/opt/t3code/T3-Code-*.AppImage
```

Give it a launcher so it behaves like an installed application:

```bash
mkdir -p ~/.local/share/applications
cat > ~/.local/share/applications/t3code.desktop <<EOF
[Desktop Entry]
Type=Application
Name=T3 Code
Exec=$(echo ~/opt/t3code/T3-Code-*.AppImage) %U
Icon=utilities-terminal
Categories=Development;
EOF
update-desktop-database ~/.local/share/applications
```

**Pin the version, and update the app and the VM server together.** The server in the VM has to
match the app ([`../vm/04-t3code.md`](../vm/04-t3code.md) §4), so T3 Code is deliberately left out
of the automatic update path ([`../common/08-auto-updates.md`](../common/08-auto-updates.md)).
Record the version you installed:

```bash
ls ~/opt/t3code/                        # the filename carries the version
```

The CLI needs no separate install — `npx t3@<that-version>` uses the Node from
[`../common/03-dev-environment.md`](../common/03-dev-environment.md).

Then pair the VM environment as described in [`../vm/04-t3code.md`](../vm/04-t3code.md) §3.

Applies in the VM and not here:

- Playwright browser binaries ([`../vm/02-dev-and-agents.md`](../vm/02-dev-and-agents.md))
- agent-specific GitHub/SSH credentials ([`../vm/05-credentials.md`](../vm/05-credentials.md))

## 4. Verification

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh --host
```

## 5. Development checklist

- [ ] apt development basics installed
- [ ] unattended security updates active ([`../common/08-auto-updates.md`](../common/08-auto-updates.md))
- [ ] dotfiles symlinked, secrets file populated
- [ ] `gh auth status` shows logged in
- [ ] Node LTS + pnpm (Corepack shim) + tsc/ts-node
- [ ] markdownlint and firecrawl CLIs available, firecrawl authenticated
- [ ] SDKMAN with auto-env, Java 21, Quarkus, Maven
- [ ] VS Code installed and configured
- [ ] T3 Code AppImage installed with `libfuse2t64` present, version recorded
- [ ] Claude Code / Cursor CLI / Codex installed and authenticated
- [ ] skills and hooks symlinked
- [ ] imaging tools installed
- [ ] `./verify-setup.sh --host` passes

Next: [05-hypervisor.md](05-hypervisor.md)
