# 00 - Home Environment Setup

Set up shell environment and user configuration files.

## Prerequisites

- Fresh Ubuntu installation (or WSL Ubuntu)
- This repository cloned to local machine
- Access to the configs directory

## WSL Note

If running on WSL, keep your projects on the WSL filesystem (`\\wsl$\<distro>\home\<user>\`) for a ~10x build speed improvement over the Windows filesystem.

---

## 1. Overview

The `configs/user-home-directory/` contains dotfiles and configuration that should live in your home directory:

- `.bashrc` - Bash shell configuration
- `.bash_aliases` - Custom command aliases
- `.bash_secrets.CHANGE-ME` - Template for API tokens/secrets (copy and customize)
- `.profile` - User profile settings
- `.gitconfig` - Git configuration
- `cursor-default.code-profile` - Cursor IDE profile

The repo root also contains:

- `.markdownlint.json` - Shared markdownlint config, symlinked to `~/projects/.markdownlint.json`

---

## 2. Symlink Configuration Files

```bash
# Navigate to repo root
cd ~/projects/agent-box-setup

# Symlink all dotfiles
ln -sf ~/projects/agent-box-setup/configs/user-home-directory/.bashrc ~/.bashrc
ln -sf ~/projects/agent-box-setup/configs/user-home-directory/.bash_aliases ~/.bash_aliases
ln -sf ~/projects/agent-box-setup/configs/user-home-directory/.profile ~/.profile
ln -sf ~/projects/agent-box-setup/configs/user-home-directory/.gitconfig ~/.gitconfig
# Shared markdownlint config for all projects in ~/projects
ln -sf ~/projects/agent-box-setup/.markdownlint.json ~/projects/.markdownlint.json
```

---

## 3. Set Up Secrets File

The `.bash_secrets` file stores API tokens and credentials. It is sourced by `.bashrc` but never checked into version control (via `.gitignore`).

```bash
# Copy the template to create your secrets file (in the repo)
cp configs/user-home-directory/.bash_secrets.CHANGE-ME configs/user-home-directory/.bash_secrets

# Edit and add your actual tokens
nano configs/user-home-directory/.bash_secrets

# Symlink to home directory
ln -sf ~/projects/agent-box-setup/configs/user-home-directory/.bash_secrets ~/.bash_secrets
```

Update the placeholder values with your real tokens (e.g., `HF_TOKEN` for Hugging Face).

---

## 4. Reload Shell Configuration

Apply the new configuration:

```bash
source ~/.bashrc
```

---

## 5. Verify

Run the project-wide verification script (covers this step and all others):

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh
```

Or check manually:

```bash
# All dotfiles should be symlinks, not regular files
ls -la ~/.bashrc ~/.bash_aliases ~/.profile ~/.gitconfig ~/.bash_secrets
ls -la ~/projects/.markdownlint.json

# Test an alias (if defined in .bash_aliases)
alias

# Verify git config
git config --global --list

# Verify secrets are loaded
echo $HF_TOKEN
```

---

## Verification Checklist

- [ ] `.bashrc` symlinked (not a regular file)
- [ ] `.bash_aliases` symlinked (not a regular file)
- [ ] `.profile` symlinked (not a regular file)
- [ ] `.gitconfig` symlinked (not a regular file)
- [ ] Secrets file created from template and symlinked (`~/.bash_secrets`)
- [ ] Shared markdownlint config symlinked (`~/projects/.markdownlint.json`)
- [ ] Shell configuration reloaded (`source ~/.bashrc`)
- [ ] Aliases working (test with `alias` command)
- [ ] Git config loaded (`git config --global --list`)
- [ ] Secrets loaded (e.g., `echo $HF_TOKEN` shows your token)

**Next:** Continue to `01-agent-setup.md`
