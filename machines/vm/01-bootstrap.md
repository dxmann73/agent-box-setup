# 01 – VM bootstrap

Prepare the Kubuntu 26.04 guest for agent setup. The VM definition is in
[`../host/05-hypervisor.md`](../host/05-hypervisor.md).

## 1. First boot and SSH

In the guest console:

```bash
sudo apt update && sudo apt full-upgrade
sudo apt install -y openssh-server
```

Add the host key, then finish the remaining setup from the host:

```bash
ssh-copy-id xmg-evo-agent-vm
ssh xmg-evo-agent-vm hostname
```

If the upgrade installed a kernel, reboot now. Then configure automatic updates in
[`../common/08-auto-updates.md`](../common/08-auto-updates.md).

## 2. Passwordless sudo

The agent user has unrestricted sudo inside the VM boundary:

```bash
sudo visudo -f /etc/sudoers.d/agent-nopasswd
```

```text
YOUR_USER_NAME ALL=(ALL) NOPASSWD: ALL
```

```bash
sudo -l | grep NOPASSWD
```

## 3. Desktop settings

In System Settings, turn off screen energy saving and screen locking, and enable automatic login for
the agent user. The rebuild commands are:

```bash
kwriteconfig6 --file powerdevilrc --group AC --group Display --key DimDisplayWhenIdle false
kwriteconfig6 --file powerdevilrc --group AC --group Display --key DimDisplayIdleTimeoutSec -- -1
kwriteconfig6 --file powerdevilrc --group AC --group Display --key TurnOffDisplayWhenIdle false
kwriteconfig6 --file powerdevilrc --group AC --group Display --key TurnOffDisplayIdleTimeoutSec -- -1
kwriteconfig6 --file kscreenlockerrc --group Daemon --key Autolock false
kwriteconfig6 --file kscreenlockerrc --group Daemon --key LockOnResume false
kwriteconfig6 --file kscreenlockerrc --group Daemon --key Timeout 0
systemctl --user restart plasma-powerdevil.service
```

Configure SDDM autologin in `/etc/sddm.conf.d/99-autologin.conf`:

```ini
[Autologin]
User=YOUR_USER_NAME
Session=plasma
Relogin=false
```

Kubuntu 26.04 uses the Plasma Wayland session. The SPICE clipboard is unavailable, so paste setup
commands through SSH.

## 4. SPICE console

Use the host console for guest recovery and inspection:

```bash
virt-viewer --attach xmg-evo-agent-vm
```

Install the guest display agent:

```bash
sudo apt install -y spice-vdagent
systemctl is-active spice-vdagentd
```

## 5. QEMU guest agent

```bash
sudo apt install -y qemu-guest-agent
systemctl is-active qemu-guest-agent
```

Verify from the host:

```bash
virsh --connect qemu:///system domifaddr xmg-evo-agent-vm --source agent
```

## 6. Base applications

```bash
sudo apt install -y git curl gh
cd /tmp
curl -fsSLO https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -y /tmp/google-chrome-stable_current_amd64.deb
```

Add Chrome's verified origin to unattended upgrades as described in
[`../common/08-auto-updates.md`](../common/08-auto-updates.md) §1. Then take the credential-free
`clean-guest` snapshot ([07-snapshots.md](07-snapshots.md) §2).

## 7. GitHub credentials

Complete [05-credentials.md](05-credentials.md) §1 before continuing. The secrets file is created
after the repository clone and home-environment setup in
[02-dev-and-agents.md](02-dev-and-agents.md).

## 8. Initial coding agent: Claude Code

In an SSH shell on the guest, clone the configuration repository and install Claude Code:

```bash
mkdir -p ~/projects
cd ~/projects
git clone https://github.com/dxmann73/agent-box-setup
curl -fsSL https://claude.ai/install.sh | bash
claude
```

Authenticate, then run `/exit`. Configure the statusline and install the Caveman plugin from
[`../../agents/claude/README.md`](../../agents/claude/README.md). Install skills after Node arrives
in [02-dev-and-agents.md](02-dev-and-agents.md).

## 9. Checklist

- [ ] guest hostname is `xmg-evo-agent-vm`
- [ ] SSH from the host uses its key
- [ ] passwordless sudo, autologin, disabled blanking and disabled locking configured
- [ ] SPICE console and `qemu-guest-agent` work
- [ ] automatic updates active
- [ ] Git, curl, gh and Chrome installed; Chrome origin included in unattended upgrades
- [ ] `clean-guest` snapshot taken before GitHub and API credentials
- [ ] GitHub authenticated over HTTPS
- [ ] Claude Code installed and authenticated; install Codex, Cursor CLI, and Pi in `vm/02`
- [ ] repository cloned to `~/projects/agent-box-setup`
