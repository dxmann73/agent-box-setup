# Dave Box Setup Checklist

Master verification checklist for new machine setup. Follow the numbered guides in `setup/` directory, then verify here.

## 01 - Core Tools

- [ ] Package manager working (winget/brew/apt)
- [ ] Git installed (`git --version`)
- [ ] Git identity configured (`git config --global --list`)
- [ ] Terminal configured (Windows Terminal / iTerm2)
- [ ] SSH key generated (`ls ~/.ssh/id_ed25519.pub`)

## 02 - Development Environment

- [ ] Node.js installed (`node --version`)
- [ ] npm working (`npm --version`)
- [ ] Python installed (`python3 --version`)
- [ ] pip working (`pip3 --version`)
- [ ] Build tools available (if needed)

## 03 - Editor

- [ ] VS Code installed (`code --version`)
- [ ] `code` command works from terminal
- [ ] Essential extensions installed
- [ ] Settings applied from configs/

## 04 - Claude Code

- [ ] Claude CLI installed (`claude --version`)
- [ ] Authentication complete
- [ ] VS Code extension working (optional)

## 05 - Voice Tools

- [ ] Wispr Flow installed and running
- [ ] Microphone working
- [ ] Hotkey configured
- [ ] Test dictation working

## 06 - Optional (check what's installed)

- [ ] Docker (`docker --version`)
- [ ] AWS CLI (`aws --version`)
- [ ] GCloud CLI (`gcloud --version`)
- [ ] Azure CLI (`az --version`)
- [ ] jq (`jq --version`)
- [ ] ripgrep (`rg --version`)

## Final Verification

- [ ] Can clone a repo via SSH
- [ ] Can run `claude` and get a response
- [ ] Can dictate text with Wispr Flow
- [ ] VS Code opens with correct settings
