# Agent Box Setup Checklist

Master verification checklist for new machine setup. Follow the numbered guides in
`machines/host/`, `machines/vm/` and `machines/common/` plus `agents/`, then verify here.

## 00 - Home Environment

- [ ] Shell config files symlinked to home directory (including `update-tools.sh`)
- [ ] Secrets file created from template (`~/.bash_secrets`)
- [ ] Shell configuration reloaded
- [ ] Aliases working
- [ ] Git config loaded (`git config --global --list`)

## 01 - Agent Setup

- [ ] Claude Code CLI installed (`claude --version`)
- [ ] Cursor CLI installed (`agent --version`)
- [ ] Codex installed (`codex --version`)
- [ ] `~/AGENTS.md` and `~/CLAUDE.md` symlinked
- [ ] Claude settings symlinked to `~/.claude/settings.json`
- [ ] Codex config symlinked to `~/.codex/config.toml`; `[features] hooks = true`
- [ ] Codex hooks symlinked to `~/.codex/hooks.json`
- [ ] Cursor hooks symlinked (`~/.cursor/hooks.json`, `~/.cursor/hooks/`) and caveman hook returns
      `additional_context`
- [ ] `~/.agents` symlinked to repo config (`~/projects/agent-box-setup/agents`)
- [ ] Skills symlinked (`~/.claude/skills/`, `~/.cursor/skills/`, `~/.agents/skills/`) and verified
      against `agents/skills/`

## 02 - Core Tools

- [ ] GitHub CLI installed and authenticated (`gh auth status`)
- [ ] jq installed (`jq --version`)
- [ ] Docker installed (`docker --version`) — **VM only**, the `docker` group is root-equivalent

## 03 - Development Environment

- [ ] Node.js installed from apt (`command -v node` is `/usr/bin/node`)
- [ ] npm working (`command npm --version`)
- [ ] npm global prefix is user-owned (`npm config get prefix` → `~/.npm-global`)
- [ ] TypeScript compiler (`tsc --version`)
- [ ] pnpm package manager (`type -a pnpm` then `hash -r && pnpm --version`)
- [ ] Markdown linting available (`markdownlint --version || npx --yes markdownlint-cli --version`)
- [ ] ripgrep installed (`rg --version`)
- [ ] Firecrawl CLI installed and authenticated (`firecrawl --status`)
- [ ] Playwright system deps installed (`sudo npx --yes playwright@latest install-deps chromium`)
- [ ] Playwright Chromium installed (`npx --yes playwright@latest install chromium`)
- [ ] SDKMAN installed (`sdk version`)
- [ ] SDKMAN auto-env enabled
- [ ] Java installed (`java --version`)
- [ ] Quarkus installed (`quarkus --version`)
- [ ] Maven installed (`mvn --version`)

## 04 - Editor (Cursor IDE)

- [ ] Cursor IDE installed (`cursor --version`)
- [ ] `cursor` command works from terminal
- [ ] Keybindings customized
- [ ] Java extensions installed (if applicable)
- [ ] Settings profile exported

## 06 - Optional (check what's installed; see `machines/common/06-optional.md`)

- [ ] Helm (`helm version`)
- [ ] Minikube (`minikube version`)
- [ ] kubectl (`kubectl version --client`)

## 08 - Automatic Updates

- [ ] `unattended-upgrades` and `needrestart` installed
- [ ] Periodic tasks enabled (`/etc/apt/apt.conf.d/20auto-upgrades`)
- [ ] Local policy written (`/etc/apt/apt.conf.d/52unattended-upgrades-local`)
- [ ] Dry run clean (`sudo unattended-upgrade --dry-run`)
- [ ] `Automatic-Reboot "false"`, pending reboots checked via `/var/run/reboot-required`
- [ ] Weekly tooling timer enabled (`systemctl --user is-enabled update-tools.timer`)
- [ ] Lingering enabled (`loginctl enable-linger "$USER"`)
- [ ] Release upgrades set to `Prompt=lts`
- [ ] T3 Code excluded from automation, updated on both ends together

## 07 - Imaging Tools

- [ ] ImageMagick installed (`magick -version` or `convert -version`)
- [ ] sharp CLI installed (`sharp --help`)
- [ ] sharp module installed (`NODE_PATH="$(npm root -g)" node -e "require('sharp')"`)
- [ ] resvg JS module installed (`NODE_PATH="$(npm root -g)" node -e "require('@resvg/resvg-js')"`)
- [ ] ffmpeg installed (`ffmpeg -version`)
- [ ] inkscape installed (`inkscape --version`)
- [ ] graphicsmagick installed (`gm version`)
- [ ] Optional: pngquant, optipng, exiftool if needed

## Final Verification

- [ ] Show Claude agents setup with `claude config list`
- [ ] Make sure MCP Servers are disabled using `/mcp`
