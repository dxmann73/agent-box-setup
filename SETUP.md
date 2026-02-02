# Dave Box Setup Checklist

Master verification checklist for new machine setup. Follow the numbered guides in `setup/` directory, then verify here.

## 00 - Agent setup

- [ ] Claude Code CLI installed (`claude --version`)
- [ ] Settings copied to `~/.claude/settings.json`
- [ ] Rules copied to `~/.claude/rules/`

## 01 - Home Environment

- [ ] Shell config files copied to home directory
- [ ] Git identity personalized in `~/.gitconfig`
- [ ] Shell configuration reloaded
- [ ] Aliases working

## 02 - Core Tools

- [ ] apt package manager working
- [ ] Git installed (`git --version`)
- [ ] Git identity configured (`git config --global --list`)
- [ ] SSH key generated (`ls ~/.ssh/id_ed25519.pub`)
- [ ] GitHub CLI installed and authenticated (`gh auth status`)

## 03 - Development Environment

- [ ] Node.js installed (`node --version`)
- [ ] npm working (`npm --version`)
- [ ] Python installed (`python3 --version`)
- [ ] pip working (`pip3 --version`)
- [ ] Build tools available (if needed)

## 04 - Editor

- [ ] VS Code installed (`code --version`)
- [ ] `code` command works from terminal
- [ ] Essential extensions installed
- [ ] Settings applied from configs/

## 06 - Voice Tools

- [ ] Voice input tool installed (nerd-dictation or Talon)
- [ ] Microphone working
- [ ] Hotkey configured
- [ ] Test dictation working

## 07 - Optional (check what's installed)

- [ ] Docker (`docker --version`)
- [ ] AWS CLI (`aws --version`)
- [ ] GCloud CLI (`gcloud --version`)
- [ ] Azure CLI (`az --version`)
- [ ] jq (`jq --version`)
- [ ] ripgrep (`rg --version`)

## Final Verification

- [ ] Show Claude agents setup with `claude config list`
- [ ] Make sure MCP Servers are disabled using `/mcp`
