# Steps for bootstrapping a Ubuntu VM

These steps will have already been done when any coding agents hit this repo. This file is kept here purely to keep track of the process.

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

Run a complete update `sudo apt update && sudo apt upgrade`, pin Terminal (Ctrl Alt T)
App Center > Manage > Update

### Settings

Change Ubuntu Settings (top right)

Power > Power saving > Screen blank > Never
System > Enable automatic login

### One-time steps

Generate a keypair with `ssh-keygen -t ed25519 -C "dave GH key"` and put it into GitHub.

Create a [Hugging Face access token](https://huggingface.co/settings/tokens), Click New token, Choose Read access (enough for downloads)

```bash
export HF_TOKEN=hf_your_token_here
```

### Installations

Install [Voice typing](./bootstrap/01-voice-typing.md)

[Google Chrome](https://www.google.com/intl/de_de/chrome/)

- Download, open folder, "Open With App Center"
- Dock: Unpin Firefox, pin Chrome

Install git and curl via `sudo apt install -y git curl`

[Set up at least one coding agent](./bootstrap/02-agent-bootstrapping.md)

Follow instructions in [README.md](./README.md)
