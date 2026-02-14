# Agent Box Setup Checklist

Master verification checklist for new machine setup. Follow the numbered guides in `setup/` directory, then verify here.

## 00 - Home Environment

- [ ] Shell config files symlinked to home directory
- [ ] Secrets file created from template (`~/.bash_secrets`)
- [ ] Shell configuration reloaded
- [ ] Aliases working
- [ ] Git config loaded (`git config --global --list`)

## 01 - Agent Setup

- [ ] Claude Code CLI installed (`claude --version`)
- [ ] Cursor CLI installed (`agent --version`)
- [ ] Codex installed (if needed)
- [ ] `~/AGENTS.md` and `~/CLAUDE.md` symlinked
- [ ] Claude settings symlinked to `~/.claude/settings.json`
- [ ] User-level rules symlinked (`~/.claude/rules/`, `~/.cursor/rules/`)

## 02 - Core Tools

- [ ] GitHub CLI installed and authenticated (`gh auth status`)
- [ ] jq installed (`jq --version`)
- [ ] Docker installed (`docker --version`)

## 03 - Development Environment

- [ ] Node.js installed (`node --version`)
- [ ] npm working (`npm --version`)
- [ ] nvm can switch versions (`nvm list`)
- [ ] TypeScript compiler (`tsc --version`)
- [ ] pnpm package manager (`pnpm --version`)
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

## 05 - Voice Tools

- [ ] Voice input tool installed (nerd-dictation or Talon)
- [ ] Microphone working
- [ ] Hotkey configured
- [ ] Test dictation working

## 06 - Optional (check what's installed)

- [ ] Helm (`helm version`)
- [ ] Minikube (`minikube version`)
- [ ] kubectl (`kubectl version --client`)

## Final Verification

- [ ] Show Claude agents setup with `claude config list`
- [ ] Make sure MCP Servers are disabled using `/mcp`
