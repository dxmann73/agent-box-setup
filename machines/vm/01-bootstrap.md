# 01 – VM bootstrap

Bringing a fresh Kubuntu guest to the point where a coding agent can take over the rest of the setup
(specification §13).

Prerequisite: the VM exists and Kubuntu 26.04 is installed in it, see
[`../host/05-hypervisor.md`](../host/05-hypervisor.md).

## 1. First boot and SSH

In the guest console:

```bash
sudo apt update && sudo apt full-upgrade
sudo apt install -y openssh-server
```

SSH goes in first. The SPICE console has no shared clipboard on 26.04 (§4), so without SSH every
command has to be typed by hand; over SSH, everything after this step can be pasted into a terminal
on the host. `sshd` listens on port 22, which only the host can reach:
the libvirt NAT network hides `192.168.122.x` from the LAN ([03-networking.md](03-networking.md)).

Add the host's public key so the login is by key, not password:

```bash
# on the host
ssh-copy-id xmg-evo-agent-vm
ssh xmg-evo-agent-vm hostname      # prints xmg-evo-agent-vm without a password prompt
```

The first connection asks whether to trust the guest's host key. Compare the fingerprint it shows
with the guest's own before answering `yes`:

```bash
# in the guest console
ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub
```

Name resolution comes from `libnss-libvirt` on the host and the guest hostname `xmg-evo-agent-vm`,
both set in [`../host/05-hypervisor.md`](../host/05-hypervisor.md) §3 and §5.

If the upgrade brought a new kernel, reboot now; nothing runs in the guest yet.

That is the last upgrade you should have to type. Set up unattended patching next, so the guest
stays current on its own from here on:
[`../common/08-auto-updates.md`](../common/08-auto-updates.md).

The guest is a full Plasma desktop, the same one as the host. Agents do not need it — BB runs
headless in the VM ([04-bb.md](04-bb.md)) and Playwright drives headless Chromium — but a human
inspecting an agent's work does.

## 2. Passwordless sudo

This comes second, right after SSH, because everything below is driven from the host over SSH. A
`sudo` that stops for a password cannot be answered from a pasted command or by an agent, so the
rest of the bootstrap — and [`../common/08-auto-updates.md`](../common/08-auto-updates.md) — would
stall on the first privileged command.

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

Use `visudo -f`, not an editor or `tee`: it syntax-checks the file before installing it and creates
it mode `0440`. A broken sudoers file locks the only root path out of the guest.

**This makes the agent user root inside the VM, and that is the honest description.** An earlier
version of this file listed only `apt`, `apt-get`, `mount` and `umount`, which reads like
containment but is not: `apt -o APT::Update::Pre-Invoke::=...` runs arbitrary commands as root,
`apt install ./x.deb` runs root maintainer scripts, and `mount --bind` rewrites any path on the
system. A narrow-looking rule that is trivially escaped is worse than a wide one that is written
down, because only the wide one gets treated with the caution it deserves.

The containment is the VM, not the sudoers file (specification §2, §3). Treat everything reachable
from inside the guest as reachable by an agent, and keep the boundary where it actually holds: what
is shared in ([06-shared-folders.md](06-shared-folders.md)), what credentials live here
([05-credentials.md](05-credentials.md)), and what the network reaches
([03-networking.md](03-networking.md)).

## 3. Desktop settings

System Settings:

- **Power Management** → screen energy saving off; the VM must not blank while agents work
- **Users** → automatic login for the agent user, so a reboot lands in a session without a keyboard
- **Display & Monitor** → scale to taste; 100% is usually right in a window

Autologin can also be written directly. Kubuntu already ships `/etc/sddm.conf.d/20-kubuntu.conf`
with an empty `[Autologin] User=`, and SDDM reads `conf.d` in lexical order, so the override needs a
higher prefix — `/etc/sddm.conf.d/99-autologin.conf`:

```ini
[Autologin]
User=YOUR_USER_NAME
Session=plasma
Relogin=false
```

`plasma` is the **Wayland** session, and on 26.04 it is the only one. `plasma-workspace-x11` has no
installation candidate, `/usr/share/xsessions/` does not exist, and `Session=plasmax11` therefore
fails. Earlier revisions of this file prescribed X11 for the SPICE clipboard; that trade is no
longer available (§4).

Autologin means the SPICE console opens straight into an unlocked desktop. That matches the model
here — the VM is the boundary, and anyone who can reach the console can already reach the agents —
but it is worth stating rather than discovering.

## 4. Getting at the desktop

One way in, deliberately: the **SPICE console**, from `virt-manager` or from
`virt-viewer --attach xmg-evo-agent-vm` on the host. It works before the network is up, it is what
the Kubuntu installer ran in, it needs no password of its own, and it opens no listening port.

Clipboard sharing and window auto-resize need the guest agent:

```bash
sudo apt install -y spice-vdagent
systemctl is-active spice-vdagentd
```

`spice-vdagent` shares the clipboard **only in an X11 session**. Under Wayland it starts but the
clipboard channel does not work — a long-standing upstream gap, not a misconfiguration. Kubuntu
26.04 ships no X11 session (§3), so **the SPICE console has no shared clipboard on this guest**, and
window auto-resize is limited in the same way.

That is why §1 puts SSH first: paste into the guest through `ssh xmg-evo-agent-vm` from the host,
and treat the console as the way in when the network is down, not as a daily workspace.

**Not installed: KRdp.** Plasma's RDP server was the earlier plan for reaching the desktop from
other machines. It is not needed — other machines reach _BB_, not the guest desktop
([04-bb.md](04-bb.md)) — and it would add a password-protected login surface to the machine that
holds every agent credential. If a graphical session from a second machine ever becomes necessary,
`virt-viewer` over SSH to the host is the route that adds no new listener:

```bash
virt-viewer --connect "qemu+ssh://you@host/system" xmg-evo-agent-vm
```

## 5. Guest agent

```bash
sudo apt install -y qemu-guest-agent
sudo systemctl enable --now qemu-guest-agent
```

This is what lets the host shut the VM down gracefully, read its addresses with `virsh domifaddr`,
and freeze its filesystems while a snapshot is taken. Unrelated to virtiofs shares
([06-shared-folders.md](06-shared-folders.md)), which are a kernel filesystem in the guest.

## 6. Credentials

Generate the VM's own keys and tokens rather than copying the host's, see
[05-credentials.md](05-credentials.md). The host's public key that §1 put into
`~/.ssh/authorized_keys` is for access into the VM, not the VM's identity towards GitHub.

## 7. Base applications

```bash
sudo apt install -y git curl
```

[Google Chrome](https://www.google.com/chrome/) goes in for manual debugging and stays signed out of
personal accounts (specification §7). Agent browser work is headless Chromium via Playwright,
installed in [02-dev-and-agents.md](02-dev-and-agents.md).

## 8. First coding agent

Install at least [one coding agent](../../agents/README.md), then clone this repo:

```bash
mkdir ~/projects && cd ~/projects && git clone https://github.com/dxmann73/agent-box-setup
```

=> **Let the installed agent take over from here.** Follow the
[agent-led bootstrap](../../README.md#agent-led-bootstrap) instructions, selecting the VM target.

## 9. Checklist

- [ ] guest hostname is `xmg-evo-agent-vm`
- [ ] guest fully updated, autologin into the Plasma **Wayland** session (26.04 ships no X11 one)
- [ ] screen blanking off
- [ ] desktop reachable over the SPICE console; no clipboard sharing under Wayland, paste over SSH
- [ ] no RDP or other extra listener added
- [ ] `qemu-guest-agent` active
- [ ] `unattended-upgrades` active ([`../common/08-auto-updates.md`](../common/08-auto-updates.md))
- [ ] passwordless sudo configured, and understood as root-in-the-VM
- [ ] `ssh xmg-evo-agent-vm` works from the host by key
- [ ] VM-specific SSH key and tokens created
- [ ] git, curl, openssh-server, Chrome installed
- [ ] one coding agent installed and authenticated
- [ ] repo cloned to `~/projects/agent-box-setup`
