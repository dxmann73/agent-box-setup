# 02 – VM development toolchain and agents

The complete development toolchain and every coding agent live in the VM (specification §5, §6).
Install detail lives once in [`../common/`](../common/); this file is the VM-side order and the
VM-side deltas.

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

Claude Code, Cursor CLI and Codex coexist and run in multiple simultaneous instances. Agent choice
does not change anything about the isolation architecture — it is the VM that isolates, not the
agent (specification §5).

## 3. Projects

Agent-worked repositories live in `~/projects` **inside the VM** (specification §8). The host
`$HOME` is not mounted. Individual host directories can be shared in deliberately, see
[06-shared-folders.md](06-shared-folders.md).

## 4. Browser automation

Agents need a browser for testing and for producing proof of work — screenshots, traces, videos,
console output (specification §7). Headless is the normal mode.

Install the browser and its system libraries once, machine-wide, so any project can drive it
without repeating the download:

```bash
sudo npx --yes playwright@latest install-deps chromium
npx --yes playwright@latest install chromium
```

`install-deps` installs apt packages and needs root; `install` downloads the browser into
`~/.cache/ms-playwright` and must run as your own user, so the two commands differ deliberately.
Projects that pin their own Playwright version will fetch a matching build on first use.

Verify with a headless screenshot:

```bash
npx --yes playwright@latest screenshot --viewport-size=1280,720 https://example.com /tmp/pw.png
```

The Chromium that Playwright downloads is separate from the host's personal Chrome profile, and
must stay that way. Never mount the host browser profile into the VM.

## 5. Model endpoints

Agents reach the host's local model over the controlled interface described in
[03-networking.md](03-networking.md). Cloud LLM APIs go out over NAT.

## 6. Verification

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh --vm
```

## 7. Checklist

- [ ] apt development basics installed
- [ ] unattended security updates active ([`../common/08-auto-updates.md`](../common/08-auto-updates.md))
- [ ] dotfiles symlinked, secrets file populated
- [ ] `gh auth status` shows logged in with the VM's own credentials
- [ ] Docker works without sudo
- [ ] Node LTS + pnpm (Corepack shim) + tsc/ts-node
- [ ] markdownlint and firecrawl CLIs available, firecrawl authenticated
- [ ] Playwright Chromium installed, headless screenshot of `example.com` succeeds
- [ ] SDKMAN with auto-env, Java 21, Quarkus, Maven
- [ ] Claude Code / Cursor CLI / Codex installed and authenticated
- [ ] skills and hooks symlinked
- [ ] imaging tools installed
- [ ] `./verify-setup.sh --vm` passes

Next: [03-networking.md](03-networking.md)
