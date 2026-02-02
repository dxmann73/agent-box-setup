# 04 - Editor Setup

VS Code is the primary editor. Adapt for other editors as needed.

## Prerequisites

- Completed `02-core-tools.md`
- Completed `03-dev-environment.md`

---

## 1. Install VS Code

```bash
sudo apt install software-properties-common apt-transport-https wget -y
wget -q https://packages.microsoft.com/keys/microsoft.asc -O- | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main"
sudo apt update
sudo apt install code -y
```

Or download from https://code.visualstudio.com/

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
cp configs/vscode/settings.json ~/.config/Code/User/settings.json
```

Or open VS Code and paste settings manually:
1. `Ctrl+Shift+P`
2. Type "Preferences: Open User Settings (JSON)"
3. Paste contents from `configs/vscode/settings.json`

---

## 4. Keybindings (Optional)

Custom keybindings can be added similarly:

```bash
cp configs/vscode/keybindings.json ~/.config/Code/User/keybindings.json
```

---

## 5. Enable CLI Integration

The `code` command should be automatically added to PATH with apt installation.

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

**Next:** Continue to `06-voice-tools.md`
