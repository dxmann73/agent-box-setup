# Steps for bootstrapping a Ubuntu VM

These steps will have already been done when any coding agents hit this repo. This file is kept here purely to keep track of the process.

## Manual Steps Required

- **Passwordless apt**: Configure sudoers for automation (see One-time steps section below)
- **SSH Keys**: Generate SSH keypair and add to GitHub (see One-time steps section below)

## VMWare Workstation Pro

Get [VMWare Workstation Pro](https://www.vmware.com/products/desktop-hypervisor/workstation-and-fusion)

Notes:

- maybe need to try in another browser when it says "temporarily unavailable"
- Setup
  - 2 Processors x 8 cores
  - 4GB mem
  - NAT
  - 40 GB Disk, single file, allocate as needed

Get [Ubuntu ISO](https://ubuntu.com/download/desktop)

## Ubuntu setup

### Initial installation

Run a complete update:

```bash
sudo apt update && sudo apt upgrade
```

Pin Terminal (Ctrl Alt T), then go to App Center > Manage > Update

### Settings

Change Ubuntu Settings (top right)

Power > Power saving > Screen blank > Never
System > Enable automatic login

### One-time steps

Set up passwordless apt for automation/AI agents:

```bash
sudo visudo -f /etc/sudoers.d/apt-nopasswd
```

Add this line (replace `dave` with your username):

```
dave ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get
```

Save and exit. Now `sudo apt` won't require a password.

Generate a keypair and put it into GitHub:

```bash
ssh-keygen -t ed25519 -C "dave GH key"
```

Create a [Hugging Face access token](https://huggingface.co/settings/tokens), Click New token, Choose Read access (enough for downloads)

```bash
export HF_TOKEN=hf_your_token_here
```

### Installations

Install [Voice typing](./bootstrap/01-voice-typing.md)

[Google Chrome](https://www.google.com/intl/de_de/chrome/)

- Download, open folder, "Open With App Center"
- Dock: Unpin Firefox, pin Chrome

Install git and curl:

```bash
sudo apt install -y git curl
```

[Set up at least one coding agent](./bootstrap/02-agent-bootstrapping.md)

Follow instructions in [README.md](./README.md)
