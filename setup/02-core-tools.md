# 02 - Core Tools

Essential tools that everything else depends on.

## Prerequisites

- Fresh Ubuntu installation or clean environment
- sudo access

---

## 1. Package Manager

```bash
sudo apt update && sudo apt upgrade -y
```

### Optional: Passwordless apt (for automation/AI agents)

To allow running apt without password prompts (useful when Claude or other tools need to install packages):

**Step 1: Create sudoers rule**

```bash
sudo visudo -f /etc/sudoers.d/apt-nopasswd
```

Add this line (replace `dave` with your username):

```
dave ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get
```

Save and exit. Now `sudo apt` won't require a password.

**Step 2: Add aliases to skip typing sudo**

Add to your `~/.bashrc`:

```bash
# Passwordless apt (requires sudoers NOPASSWD rule for apt)
alias apt='sudo apt'
alias apt-get='sudo apt-get'
```

Now you can just type `apt update` instead of `sudo apt update`.

---

## 2. Git

```bash
sudo apt install git -y
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

## 4. SSH Keys

Generate a new SSH key for this machine:

```bash
ssh-keygen -t ed25519 -C "your.email@example.com"
```

Start the SSH agent:

```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
```

**Copy public key for GitHub/GitLab:**

```bash
cat ~/.ssh/id_ed25519.pub
```

---

## 5. GitHub CLI

GitHub CLI (`gh`) enables GitHub operations from the terminal.

```bash
sudo apt install gh -y
```

**Authenticate:**

```bash
gh auth login
```

Follow the prompts to authenticate via browser or token.

**Verify:**

```bash
gh --version
gh auth status
```

---

## Verification Checklist

- [ ] apt package manager working
- [ ] Git installed and configured
- [ ] SSH key generated
- [ ] GitHub CLI installed and authenticated (`gh auth status`)

**Next:** Continue to `03-dev-environment.md`
