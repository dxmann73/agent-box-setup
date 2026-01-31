# 01 - Core Tools

Essential tools that everything else depends on.

## Prerequisites

- Fresh OS installation or clean environment
- Administrator/sudo access

---

## 1. Package Manager

### Windows

**Option A: winget (Recommended - built into Windows 11)**
```powershell
# Verify winget is available
winget --version
```

**Option B: Scoop (alternative)**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
irm get.scoop.sh | iex
```

**Verify:**
```powershell
scoop --version
```

### Linux (Debian/Ubuntu)

```bash
sudo apt update && sudo apt upgrade -y
```

### Linux (Fedora/RHEL)

```bash
sudo dnf update -y
```

### macOS

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Verify:**
```bash
brew --version
```

---

## 2. Git

### Windows

```powershell
winget install Git.Git
```

Or with Scoop:
```powershell
scoop install git
```

### Linux

```bash
# Debian/Ubuntu
sudo apt install git -y

# Fedora
sudo dnf install git -y
```

### macOS

```bash
brew install git
```

**Verify:**
```bash
git --version
```

---

## 3. Configure Git Identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

**Verify:**
```bash
git config --global --list
```

---

## 4. Terminal Setup

### Windows

**Windows Terminal (Recommended)**
```powershell
winget install Microsoft.WindowsTerminal
```

**Git Bash** - Included with Git installation

### Linux

Default terminal is usually fine. Consider:
```bash
# Optional: Install a better terminal
sudo apt install tilix   # Debian/Ubuntu
```

### macOS

Default Terminal.app works. Consider iTerm2:
```bash
brew install --cask iterm2
```

---

## 5. SSH Keys

Generate a new SSH key for this machine:

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```

Start the SSH agent:

```bash
# Linux/macOS
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519

# Windows (Git Bash)
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

**Copy public key for GitHub/GitLab:**
```bash
# Linux
cat ~/.ssh/id_ed25519.pub

# macOS
pbcopy < ~/.ssh/id_ed25519.pub

# Windows
clip < ~/.ssh/id_ed25519.pub
```

---

## Verification Checklist

- [ ] Package manager working (`winget`/`brew`/`apt`)
- [ ] Git installed and configured
- [ ] Terminal configured
- [ ] SSH key generated

**Next:** Continue to `02-dev-environment.md`
