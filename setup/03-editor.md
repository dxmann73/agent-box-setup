# 03 - Editor Setup

VS Code is the primary editor. Adapt for other editors as needed.

## Prerequisites

- Completed `01-core-tools.md`
- Completed `02-dev-environment.md`

---

## 1. Install VS Code

### Windows

```powershell
winget install Microsoft.VisualStudioCode
```

### Linux

```bash
# Debian/Ubuntu
sudo apt install software-properties-common apt-transport-https wget -y
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt update
sudo apt install code -y
```

Or download from https://code.visualstudio.com/

### macOS

```bash
brew install --cask visual-studio-code
```

**Verify:**
```bash
code --version
```

---

## 2. Essential Extensions

Install via command line:

```bash
# Claude Code extension
code --install-extension anthropic.claude-code

# Language support
code --install-extension ms-python.python
code --install-extension ms-vscode.vscode-typescript-next
code --install-extension dbaeumer.vscode-eslint
code --install-extension esbenp.prettier-vscode

# Git
code --install-extension eamodio.gitlens

# Utilities
code --install-extension streetsidesoftware.code-spell-checker
code --install-extension usernamehw.errorlens
```

---

## 3. Settings

Copy settings from this repo:

```bash
# Windows
cp configs/vscode/settings.json "$APPDATA/Code/User/settings.json"

# Linux
cp configs/vscode/settings.json ~/.config/Code/User/settings.json

# macOS
cp configs/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
```

Or open VS Code and paste settings manually:
1. `Ctrl+Shift+P` (or `Cmd+Shift+P` on macOS)
2. Type "Preferences: Open User Settings (JSON)"
3. Paste contents from `configs/vscode/settings.json`

---

## 4. Keybindings (Optional)

Custom keybindings can be added similarly:

```bash
# Windows
cp configs/vscode/keybindings.json "$APPDATA/Code/User/keybindings.json"
```

---

## 5. Enable CLI Integration

Ensure `code` command is in PATH:

### Windows
Usually automatic with winget installation.

### macOS
1. Open VS Code
2. `Cmd+Shift+P`
3. Type "Shell Command: Install 'code' command in PATH"

### Linux
Usually automatic with apt installation.

**Verify:**
```bash
code --version
```

---

## Verification Checklist

- [ ] VS Code installed
- [ ] `code` command works from terminal
- [ ] Essential extensions installed
- [ ] Settings applied

**Next:** Continue to `04-claude-setup.md`
