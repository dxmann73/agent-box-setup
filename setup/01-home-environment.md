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
- `.gitconfig` - Git configuration (personalize email/name)
- `dave-cursor-default.code-profile` - Cursor IDE profile

---

## 2. Copy Configuration Files

### Backup Existing Files (Optional)

If you have existing configurations you want to preserve:

```bash
mkdir -p ~/config-backup
cp ~/.bashrc ~/config-backup/.bashrc.bak 2>/dev/null || true
cp ~/.bash_aliases ~/config-backup/.bash_aliases.bak 2>/dev/null || true
cp ~/.profile ~/config-backup/.profile.bak 2>/dev/null || true
cp ~/.gitconfig ~/config-backup/.gitconfig.bak 2>/dev/null || true
```

### Copy Files to Home Directory

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

## 3. Personalize Git Configuration

Edit `~/.gitconfig` to update with your information:

```bash
nano ~/.gitconfig
```

Update these lines:
```
[user]
    name = Your Name
    email = your.email@example.com
```

Or use git commands:
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

---

## 4. Reload Shell Configuration

Apply the new configuration:

```bash
source ~/.bashrc
```

---

## 5. Verify

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
- [ ] Git identity personalized
- [ ] Shell configuration reloaded
- [ ] Aliases working (test with `alias` command)

**Next:** Continue to `02-core-tools.md`
