# 00 - Home Environment Setup

Set up shell environment and user configuration files.

## Prerequisites

- Fresh Ubuntu installation
- This repository cloned to local machine
- Access to the configs directory

On the WSL host variant, see [`../wsl/README.md`](../wsl/README.md) first.

---

## 1. Overview

The `user-home/` contains dotfiles and configuration that should live in your home directory:

- `.bashrc` - Bash shell configuration
- `.bash_aliases` - Custom command aliases
- `.bash_secrets.CHANGE-ME` - Template for API tokens/secrets (copy and customize)
- `.profile` - User profile settings
- `.gitconfig` - Git configuration
- `ua.sh` - Update-all script: fetch/pull all git repos under a root dir
- `update-tools.sh` - Weekly tooling update: npm globals, agent CLIs, SDKMAN (see `08-auto-updates.md`)
- `vscode/` - VS Code settings/keybindings reference copy (see `04-ide+tooling.md`)

The repo root also contains:

- `.markdownlint.json` - Shared markdownlint config, symlinked to `~/projects/.markdownlint.json`

---



## 2. Symlink Configuration Files

```bash
# Navigate to repo root
cd ~/projects/agent-box-setup

# Symlink all dotfiles
ln -sf ~/projects/agent-box-setup/user-home/.bashrc ~/.bashrc
ln -sf ~/projects/agent-box-setup/user-home/.bash_aliases ~/.bash_aliases
ln -sf ~/projects/agent-box-setup/user-home/.profile ~/.profile
ln -sf ~/projects/agent-box-setup/user-home/.gitconfig ~/.gitconfig
ln -sf ~/projects/agent-box-setup/user-home/ua.sh ~/ua.sh
ln -sf ~/projects/agent-box-setup/user-home/update-tools.sh ~/update-tools.sh
# Shared markdownlint config for all projects in ~/projects
ln -sf ~/projects/agent-box-setup/.markdownlint.json ~/projects/.markdownlint.json
```

---



## 3. Set Up Secrets File

The `.bash_secrets` file stores API tokens and credentials. It is sourced by `.bashrc` but never checked into version
control (via `.gitignore`).

```bash
# Copy the template to create your secrets file (in the repo)
cp user-home/.bash_secrets.CHANGE-ME user-home/.bash_secrets

# Edit and add your actual tokens
nano user-home/.bash_secrets

# Symlink to home directory
ln -sf ~/projects/agent-box-setup/user-home/.bash_secrets ~/.bash_secrets
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
ls -la ~/.bashrc ~/.bash_aliases ~/.profile ~/.gitconfig ~/.bash_secrets ~/ua.sh ~/update-tools.sh
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
- [ ] `ua.sh` symlinked (`~/ua.sh`)
- [ ] `update-tools.sh` symlinked (`~/update-tools.sh`)
- [ ] Secrets file created from template and symlinked (`~/.bash_secrets`)
- [ ] Shared markdownlint config symlinked (`~/projects/.markdownlint.json`)
- [ ] Shell configuration reloaded (`source ~/.bashrc`)
- [ ] Aliases working (test with `alias` command)
- [ ] Git config loaded (`git config --global --list`)
- [ ] Secrets loaded (e.g., `echo $HF_TOKEN` shows your token)

**Next:** Continue to [`../../agents/`](../../agents/README.md)
