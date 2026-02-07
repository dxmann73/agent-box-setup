# Steps for bootstrapping a Ubuntu VM

These steps will have already been done when any coding agents hit this repo. This file is here purely to keep track of the process.

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

Pin Terminal (Ctrl Alt T) to Dash, then go to App Center > Manage > Update

### Settings

Change Ubuntu Settings (top right)

Power > Power saving > Screen blank > Never
System > Enable automatic login

### One-time steps

#### Passwordless apt

Set up passwordless apt for automation/AI agents:

```bash
sudo visudo -f /etc/sudoers.d/apt-nopasswd
```

Add this line (replace `dave` with your username):

```text
dave ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get
```

Save and exit. Now `sudo apt` won't require a password.

#### SSH keys

Generate a keypair and copy it to the `~/.ssh` directory

#### HF token

Create a [Hugging Face access token](https://huggingface.co/settings/tokens), Click New token, Choose Read access (enough for downloads)

```bash
export HF_TOKEN=hf_your_token_here
```

### Installations

[Google Chrome](https://www.google.com/intl/de_de/chrome/)

- Download, open folder, "Open With App Center"
- Dock: Unpin Firefox, pin Chrome

Install git and curl:

```bash
sudo apt install -y git curl
```

Set up at least [one coding agent](./bootstrap/01-agent-bootstrapping.md)

Then follow the instructions in the [README.md](./README.md)

## Mount VM directory

As an info for the user: What they need to do to map local directories into the VM.

In VMWare Pro under Settings > Options > Shared Folders
Always enabled, name vm-shares

On host os (should already be there!)

```bash
sudo apt install open-vm-tools open-vm-tools-desktop

# if anything was installed, trigger a `sudo reboot`
```

Mount the directories in fstab

```bash
sudo nano /etc/fstab

# add
#.host:/   /mnt/hgfs   fuse.vmhgfs-fuse   allow_other,uid=1000,gid=1000   0   0

# test it safely
sudo mount -a
```

Link to home directory

```bash
ln -s /mnt/hgfs/vm-shares ~/vm-shares
```
