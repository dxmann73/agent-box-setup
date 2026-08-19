# 01 – VM bootstrap

Bringing a fresh Ubuntu guest to the point where a coding agent can take over the rest of the setup
(specification §13). The VM must be cheap to recreate, so everything here should end up scripted.

Prerequisite: the VM exists, see [`../host/05-hypervisor.md`](../host/05-hypervisor.md).

## 1. Initial installation

Install Ubuntu in the guest, then update:

```bash
sudo apt update && sudo apt upgrade
```

Pin Terminal (Ctrl Alt T) to Dash, then go to App Center > Manage > Update.

## 2. Settings

Ubuntu Settings (top right):

- Power > Power saving > Screen blank > Never
- System > Enable automatic login

Install `Gnome Tweaks` and set proper font scaling under "Appearance".

## 3. Guest tooling

```bash
sudo apt install -y open-vm-tools open-vm-tools-desktop
```

Reboot if anything was installed. Needed for shared folders,
see [06-shared-folders.md](06-shared-folders.md).

## 4. Passwordless apt and mount

Agents run unattended, so `apt` and `mount` must not block on a password prompt:

```bash
sudo visudo -f /etc/sudoers.d/agent-nopasswd
```

Add this line (replace `YOUR_USER_NAME` with your username):

```text
YOUR_USER_NAME ALL=(ALL) NOPASSWD: /usr/bin/apt, /usr/bin/apt-get, /usr/bin/mount, /usr/bin/umount
```

This is a deliberate widening of what agents can do inside the VM. It is acceptable only because
the VM is the boundary — treat everything reachable from inside it as reachable by an agent
(specification §12).

## 5. Credentials

Generate the VM's own keys and tokens rather than copying the host's, see
[05-credentials.md](05-credentials.md).

## 6. Base applications

```bash
sudo apt install -y git curl
```

[Google Chrome](https://www.google.com/chrome/): download, open the folder, "Open With App Center".
Dock: unpin Firefox, pin Chrome. This browser is for agent use and manual debugging — it is not
signed into personal accounts (specification §7).

## 7. First coding agent

Install at least [one coding agent](../common/01-agent-setup.md), then clone this repo:

```bash
mkdir ~/projects && cd ~/projects && git clone https://github.com/dxmann73/agent-box-setup
```

=> **Let the agent take over from here!**

```bash
cd agent-box-setup && claude --dangerously-skip-permissions
```

Tell the agent to follow [02-dev-and-agents.md](02-dev-and-agents.md).

## 8. Checklist

- [ ] guest installed and fully updated
- [ ] `open-vm-tools` installed
- [ ] passwordless apt/mount configured
- [ ] VM-specific SSH key and tokens created
- [ ] git, curl, Chrome installed
- [ ] one coding agent installed and authenticated
- [ ] repo cloned to `~/projects/agent-box-setup`
