# 01 – VM bootstrap

Bringing a fresh Kubuntu guest to the point where a coding agent can take over the rest of the setup
(specification §13).

Prerequisite: the VM exists and Kubuntu 26.04 is installed in it, see
[`../host/05-hypervisor.md`](../host/05-hypervisor.md).

## 1. First boot

```bash
sudo apt update && sudo apt full-upgrade
```

That is the last upgrade you should have to type. Set up unattended patching now, so the guest stays
current on its own from here on:
[`../common/08-auto-updates.md`](../common/08-auto-updates.md).

The guest is a full Plasma desktop, the same one as the host. Agents do not need it — T3 Code runs
headless in the VM ([04-t3code.md](04-t3code.md)) and Playwright drives headless Chromium — but a
human inspecting an agent's work does.

## 2. Desktop settings

System Settings:

- **Power Management** → screen energy saving off; the VM must not blank while agents work
- **Users** → automatic login for the agent user, so a reboot lands in a session without a keyboard
- **Display & Monitor** → scale to taste; 100% is usually right in a window

Autologin can also be written directly, `/etc/sddm.conf.d/autologin.conf`:

```ini
[Autologin]
User=YOUR_USER_NAME
Session=plasmax11
```

`plasmax11` is the X11 session and `plasma` is the Wayland one. Use **X11**: the SPICE clipboard
only works there (§3), and nothing in this guest needs Wayland.

## 3. Getting at the desktop

One way in, deliberately: the **SPICE console**, from `virt-manager` or from
`virt-viewer agent-vm` on the host. It works before the network is up, it is what the Kubuntu
installer ran in, it needs no password of its own, and it opens no listening port.

Clipboard sharing and window auto-resize need the guest agent:

```bash
sudo apt install -y spice-vdagent
systemctl is-active spice-vdagentd
```

`spice-vdagent` shares the clipboard **only in an X11 session**. Under Wayland it starts but the
clipboard channel does not work — a long-standing gap, not a misconfiguration. So keep the guest on
`Session=plasmax11` (§2) and the clipboard works both ways.

**Not installed: KRdp.** Plasma's RDP server was the earlier plan for reaching the desktop from
other machines. It is not needed — other machines reach *T3 Code*, not the guest desktop
([04-t3code.md](04-t3code.md)) — and it would add a password-protected login surface to the machine
that holds every agent credential. If a graphical session from a second machine ever becomes
necessary, `virt-viewer` over SSH to the host is the route that adds no new listener:

```bash
virt-viewer --connect "qemu+ssh://you@host/system" agent-vm
```

## 4. Guest agent

```bash
sudo apt install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

This is what lets the host shut the VM down gracefully, read its addresses with `virsh domifaddr`,
and freeze its filesystems while a snapshot is taken. Unrelated to virtiofs shares
([06-shared-folders.md](06-shared-folders.md)), which are a kernel filesystem in the guest.

## 5. Passwordless sudo

Agents run unattended, so `sudo` must not block on a password prompt:

```bash
sudo visudo -f /etc/sudoers.d/agent-nopasswd
```

Add this line (replace `YOUR_USER_NAME` with your username):

```text
YOUR_USER_NAME ALL=(ALL) NOPASSWD: ALL
```

```bash
sudo -l | grep NOPASSWD
```

**This makes the agent user root inside the VM, and that is the honest description.** An earlier
version of this file listed only `apt`, `apt-get`, `mount` and `umount`, which reads like
containment but is not: `apt -o APT::Update::Pre-Invoke::=...` runs arbitrary commands as root,
`apt install ./x.deb` runs root maintainer scripts, and `mount --bind` rewrites any path on the
system. A narrow-looking rule that is trivially escaped is worse than a wide one that is written
down, because only the wide one gets treated with the caution it deserves.

The containment is the VM, not the sudoers file (specification §2, §3). Treat everything reachable
from inside the guest as reachable by an agent, and keep the boundary where it actually holds:
what is shared in ([06-shared-folders.md](06-shared-folders.md)), what credentials live here
([05-credentials.md](05-credentials.md)), and what the network reaches
([03-networking.md](03-networking.md)).

## 6. Credentials

Generate the VM's own keys and tokens rather than copying the host's, see
[05-credentials.md](05-credentials.md). Add the host's public key to `~/.ssh/authorized_keys` so
`ssh agent-vm` works from the host; that key is for access into the VM, not the VM's identity
towards GitHub.

## 7. Base applications

```bash
sudo apt install -y git curl openssh-server
```

`openssh-server` is what makes `ssh agent-vm` work from the host. Add the host's public key so the
login is by key, not password:

```bash
# on the host
ssh-copy-id agent-vm
```

Name resolution comes from `libnss-libvirt` on the host and the guest hostname `agent-vm`, both set
in [`../host/05-hypervisor.md`](../host/05-hypervisor.md) §3 and §5.

[Google Chrome](https://www.google.com/chrome/) goes in for manual debugging and stays signed out of
personal accounts (specification §7). Agent browser work is headless Chromium via Playwright,
installed in [02-dev-and-agents.md](02-dev-and-agents.md).

## 8. First coding agent

Install at least [one coding agent](../../agents/README.md), then clone this repo:

```bash
mkdir ~/projects && cd ~/projects && git clone https://github.com/dxmann73/agent-box-setup
```

=> **Let the agent take over from here!**

```bash
cd agent-box-setup && claude --dangerously-skip-permissions
```

Tell the agent to follow [02-dev-and-agents.md](02-dev-and-agents.md).

## 9. Checklist

- [ ] guest hostname is `agent-vm`
- [ ] guest fully updated, autologin into the Plasma **X11** session
- [ ] screen blanking off
- [ ] desktop reachable over the SPICE console, clipboard works both ways
- [ ] no RDP or other extra listener added
- [ ] `qemu-guest-agent` active
- [ ] `unattended-upgrades` active ([`../common/08-auto-updates.md`](../common/08-auto-updates.md))
- [ ] passwordless sudo configured, and understood as root-in-the-VM
- [ ] `ssh agent-vm` works from the host by key
- [ ] VM-specific SSH key and tokens created
- [ ] git, curl, openssh-server, Chrome installed
- [ ] one coding agent installed and authenticated
- [ ] repo cloned to `~/projects/agent-box-setup`
