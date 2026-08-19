# 04 – Development setup

Developer tooling, after the daily applications from
[03-software-installation.md](03-software-installation.md).

This mirrors the agent-box tooling in [`../setup/`](../setup/). The files there carry the full
install/verify detail; this file is the ordered list for a fresh Kubuntu machine.

| Area | Detail |
| --- | --- |
| shell/dotfiles | [`../setup/00-home-environment.md`](../setup/00-home-environment.md) |
| coding agents | [`../setup/01-agent-setup.md`](../setup/01-agent-setup.md) |
| core tools | [`../setup/02-core-tools.md`](../setup/02-core-tools.md) |
| languages/runtimes | [`../setup/03-dev-environment.md`](../setup/03-dev-environment.md) |
| editor | [`../setup/04-ide+tooling.md`](../setup/04-ide+tooling.md) |
| imaging | [`../setup/07-imaging-tools.md`](../setup/07-imaging-tools.md) |
| optional | [`../setup/06-optional.md`](../setup/06-optional.md) |

## 1. Development basics

```bash
sudo apt install -y \
  git curl wget build-essential cmake ninja-build pkg-config \
  python3 python3-pip python3-venv pipx jq htop btop tmux \
  ripgrep fd-find
```

Keep active repositories in `~/projects` on ext4 rather than developing directly on a mounted
Windows NTFS filesystem.

```bash
mkdir -p ~/projects
```

## 2. Home environment

Clone `agent-box-setup` into `~/projects` and symlink the dotfiles (`.bashrc`, `.bash_aliases`,
`.profile`, `.gitconfig`, `.bash_secrets`, `ua.sh`, `.markdownlint.json`) as described in
[`../setup/00-home-environment.md`](../setup/00-home-environment.md).

## 3. GitHub CLI

```bash
sudo apt install -y gh
gh auth login
gh auth status
```

## 4. Docker

```bash
sudo apt install -y docker.io docker-compose
sudo usermod -aG docker $USER
```

Log out and back in for the group change, then `docker run --rm hello-world`.

Upstream docs if the distro packages are too old:
<https://docs.docker.com/engine/install/ubuntu/>

## 5. Node.js via nvm

```bash
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
source ~/.bashrc
nvm install --lts
nvm use --lts
nvm alias default lts/*
```

## 6. JS package managers and global tools

```bash
corepack enable
corepack prepare pnpm@latest --activate
hash -r
npm install -g typescript ts-node markdownlint-cli firecrawl-cli
```

`firecrawl --status` must report `Authenticated`; the key lives in `~/.bash_secrets` as
`FIRECRAWL_API_KEY`.

## 7. Playwright browser runtime

From a project that has Playwright as a dependency:

```bash
pnpm exec playwright install chromium
pnpm exec playwright install-deps chromium
```

## 8. Java toolchain via SDKMAN

```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sed -i 's/sdkman_auto_env=false/sdkman_auto_env=true/' ~/.sdkman/etc/config
sdk install java 21.0.8-oracle
sdk install quarkus
sdk install maven
```

Opt in to Quarkus build analytics so dev runs are not blocked by the interactive prompt:

```bash
mkdir -p ~/.redhat
echo '{"disabled":false}' > ~/.redhat/io.quarkus.analytics.localconfig
```

## 9. Editors

- **Cursor IDE** (primary): download the `.deb` from <https://cursor.com/download>, install, then
  apply the profile/keybinding tweaks in [`../setup/04-ide+tooling.md`](../setup/04-ide+tooling.md)
- **VS Code** (fallback, integrates with normal updates):
  <https://code.visualstudio.com/docs/setup/linux>

## 10. Coding agents

```bash
curl -fsSL https://claude.ai/install.sh | bash     # Claude Code
curl https://cursor.com/install -fsS | bash        # Cursor CLI agent
```

Then follow [`../setup/01-agent-setup.md`](../setup/01-agent-setup.md) for Codex, `~/AGENTS.md`,
agent settings, caveman hooks, and skills.

## 11. Imaging tools

```bash
sudo apt install -y imagemagick ffmpeg inkscape graphicsmagick
sudo apt install -y pngquant optipng libimage-exiftool-perl
npm install -g sharp sharp-cli @resvg/resvg-js
```

## 12. Optional: Kubernetes

```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 | bash
sudo apt install -y kubectl
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64
```

## 13. Verification

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh
```

## 14. Development checklist

- [ ] apt development basics installed
- [ ] dotfiles symlinked, secrets file populated
- [ ] `gh auth status` shows logged in
- [ ] Docker works without sudo
- [ ] Node LTS + pnpm (Corepack shim) + tsc/ts-node
- [ ] markdownlint and firecrawl CLIs available, firecrawl authenticated
- [ ] Playwright Chromium installed
- [ ] SDKMAN with auto-env, Java 21, Quarkus, Maven
- [ ] Cursor IDE installed and configured
- [ ] Claude Code / Cursor CLI / Codex installed and authenticated
- [ ] imaging tools installed
- [ ] Kubernetes tools installed if needed
- [ ] `./verify-setup.sh` passes
