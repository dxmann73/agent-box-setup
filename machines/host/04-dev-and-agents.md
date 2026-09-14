# 04 – Host development tools and agents

The host runs the same development toolchain as the VM, plus coding agents for local work. The
install detail lives once in [`../common/`](../common/); this file is the host-side order and the
host-side deltas.

Why agents run here too: the host is where the local model is built, benchmarked and driven, and
where this repo is edited. Agent work on personal projects still belongs in the VM (specification
§2, §8) — the host agent is for host-scoped tasks.

Complete the host baseline and, when selected, the overlay's personal browser phase first. Use that
browser for the remaining account setup. Existing working CLI credentials stay in place; installing
a new browser does not require repeating CLI login. The early virtualization phase is independent of
this guide's later tooling-completion checkpoint.

## 1. Development basics

```bash
sudo apt install -y \
  git curl wget build-essential pkg-config \
  python3 python3-pip python3-venv pipx jq yq htop btop tmux \
  ripgrep fd-find
```

```bash
mkdir -p ~/projects
```

## 2. Common guides, in order

| Step                         | Guide                                                                  |
| ---------------------------- | ---------------------------------------------------------------------- |
| shell/dotfiles               | [`../common/00-home-environment.md`](../common/00-home-environment.md) |
| core tools                   | [`../common/02-core-tools.md`](../common/02-core-tools.md)             |
| languages/runtimes           | [`../common/03-dev-environment.md`](../common/03-dev-environment.md)   |
| coding agents, skills, hooks | [`../../agents/`](../../agents/README.md)                              |
| imaging overlay              | [`../common/07-imaging-tools.md`](../common/07-imaging-tools.md)       |
| editor                       | [`../common/04-ide+tooling.md`](../common/04-ide+tooling.md)           |
| automatic updates            | [`../common/08-auto-updates.md`](../common/08-auto-updates.md)         |
| optional                     | [`../common/06-optional.md`](../common/06-optional.md)                 |

Clone this repo into `~/projects` first — the dotfile symlinks point at it.

## 3. Host deltas

Applies on the host and not in the VM:

- **Docker is skipped here.** The `docker` group is root-equivalent, and the host holds personal
  data; container work belongs in the VM ([`../common/02-core-tools.md`](../common/02-core-tools.md)
  §3)
- GPU/compute stack and the local model runtime: the separate
  [local-llm](https://github.com/dxmann73/local-llm) repo
- the hypervisor and the agent VM itself: [05-hypervisor.md](05-hypervisor.md)
- the personal browser profile stays outside the agent VM, at the location selected by the overlay;
  host agents must not drive it either
- personal desktop applications stay on the host ([02-applications.md](02-applications.md)); the
  overlay has the install list

### WezTerm

Link the managed configuration:

```bash
mkdir -p ~/.config/wezterm
ln -sfn ~/projects/agent-box-setup/user-home/wezterm/wezterm.lua \
  ~/.config/wezterm/wezterm.lua
```

### Cursor Agent launcher

Install the icon and link the desktop entry:

```bash
mkdir -p ~/.local/share/icons/hicolor/scalable/apps ~/.local/share/applications
curl -fsSL https://cursor.com/favicon.svg \
  -o ~/.local/share/icons/hicolor/scalable/apps/cursor-agent.svg
image_converter="$(command -v magick || command -v convert)" || {
  echo 'Install ImageMagick via the imaging overlay before generating this launcher icon.' >&2
  exit 1
}
for s in 16 24 32 48 64 128 256 512; do
  mkdir -p ~/.local/share/icons/hicolor/${s}x${s}/apps
  "${image_converter}" -background none ~/.local/share/icons/hicolor/scalable/apps/cursor-agent.svg \
    -resize ${s}x${s} ~/.local/share/icons/hicolor/${s}x${s}/apps/cursor-agent.png
done
gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor
ln -sfn ~/projects/agent-box-setup/user-home/applications/cursor-agent.desktop \
  ~/.local/share/applications/cursor-agent.desktop
update-desktop-database ~/.local/share/applications
```

Open **Cursor Agent** from the launcher and pin it to the task manager if wanted.

### BB on the host

Use the official [BB](https://getbb.app/) Linux AppImage on the host. It provides the desktop UI and
manages its bundled server and host daemon, so the host does not need a separate browser tab or
`bb.service`. Follow the host section of [the shared BB guide](../common/05-bb.md). BB state stays
in `~/.bb/`, separate from projects in `~/projects`. Remote clients may reach this host origin over
Tailscale; this box's URL lives in `infra/tailscale/`.

The host server is the shared control plane. Host and VM agents use YOLO settings. Enroll the VM as
an execution machine using [the VM BB guide](../vm/04-bb.md). Remote desktop and Android clients
connect to that host origin and can then select the host or VM for execution. The VM's standalone
interface has independent history and is only a temporary fallback.

Applies in the VM and not here:

- Playwright browser binaries ([`../vm/02-dev-and-agents.md`](../vm/02-dev-and-agents.md))
- agent-specific GitHub/SSH credentials ([`../vm/05-credentials.md`](../vm/05-credentials.md))

## 4. Host completion gate

Before the **agent-VM creation branch** of [05-hypervisor.md](05-hypervisor.md), complete the
following on the physical host. This gate does not apply to early virtualization preparation or an
overlay's personal browser guest:

- the shared desktop/session policy is configured;
- Claude Code, Codex, Cursor CLI, and Pi are installed and authenticated;
- Firecrawl is installed and authenticated;
- VS Code settings and keyboard shortcuts are installed and checked;
- the BB desktop AppImage opens normally;
- the host verification command below has been reviewed and any required failures have been
  resolved.

Host and VM agent CLIs use YOLO settings. Do not make host sudo passwordless.

## 5. Verification

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh --host --operational
```

## 6. Development checklist

- [ ] apt development basics installed
- [ ] unattended security updates active
      ([`../common/08-auto-updates.md`](../common/08-auto-updates.md))
- [ ] dotfiles symlinked, secrets file populated
- [ ] `gh auth status` shows logged in
- [ ] Node 24 + pnpm (Corepack shim) + tsc/ts-node
- [ ] `jq` and `yq` available
- [ ] markdownlint and Firecrawl CLIs available; Firecrawl authenticated
- [ ] VS Code installed and configured
- [ ] BB desktop AppImage installed in a writable user directory and opens normally
- [ ] Claude Code, Codex, Cursor CLI, and Pi installed and authenticated
- [ ] skills symlinked into all four agents
- [ ] `./verify-setup.sh --host --operational` passes

Next: the [agent-VM creation branch](05-hypervisor.md#4-create-the-agent-vm), if needed.
