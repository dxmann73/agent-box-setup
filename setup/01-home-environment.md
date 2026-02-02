# 01 - Home Environment Setup

Set up shell environment and user configuration files.

## Prerequisites

- Fresh Ubuntu installation
- This repository cloned to local machine
- Access to the configs directory

---

## 1. Overview

The `configs/user-home-directory/` contains dotfiles and configuration that should live in your home directory:

- `.bashrc` - Bash shell configuration
- `.bash_aliases` - Custom command aliases
- `.profile` - User profile settings
- `.gitconfig` - Git configuration
- `dave-cursor-default.code-profile` - Cursor IDE profile

---

## 2. Copy Configuration Files

```bash
# Navigate to repo root
cd ~/projects/dave-box-setup

# Copy all dotfiles
cp configs/user-home-directory/.bashrc ~/
cp configs/user-home-directory/.bash_aliases ~/
cp configs/user-home-directory/.profile ~/
cp configs/user-home-directory/.gitconfig ~/
```

---

## 3. Reload Shell Configuration

Apply the new configuration:

```bash
source ~/.bashrc
```

---

## 4. Verify

Check that aliases and configuration are loaded:

```bash
# Test an alias (if defined in .bash_aliases)
alias

# Verify git config
git config --global --list
```

---

## Verification Checklist

- [ ] Configuration files copied to home directory
- [ ] Shell configuration reloaded
- [ ] Aliases working (test with `alias` command)
- [ ] Git config loaded (`git config --global --list`)

**Next:** Continue to `02-core-tools.md`
