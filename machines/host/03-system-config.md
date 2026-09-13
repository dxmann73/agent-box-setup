# 03 – Host system configuration

Filesystem layout, backups, packaging, SSH and firewall on the host.

## 1. Host baseline

Run the idempotent privileged baseline from the checked-out repository before the detailed host
configuration. It installs only deterministic host prerequisites, configures locale defaults,
firewall and automatic-update timers, and prepares libvirt; it never creates a VM or changes
host-agent permissions. The shared auto-update guide owns the third-party APT-origin policy, so the
baseline does not overwrite a source that has already been verified for this machine.

```bash
cd ~/projects/agent-box-setup
sudo ./machines/host/prepare-host-system.sh
```

The script backs up a managed configuration file only when it changes it. Its backup directory is
reported at completion. Log out and back in after it adds the user to `libvirt` and `kvm` groups.

## 2. Filesystem organization

```text
/home/you/
├── Documents/
├── Downloads/
├── Dropbox/
├── backup/
│   └── vm/              # same-host live VM disk backups (07-snapshots.md)
├── projects/            # host-side repos only (this repo, local-llm work)
├── models/
│   ├── 8b/
│   ├── 32b/
│   └── moe/
├── llm-bench/
├── system-info/         # hardware baselines from 01-hardware-validation.md
└── vms/                 # ISOs, domain XML, virtiofs share XML (not the disks)
```

```bash
mkdir -p ~/models ~/llm-bench ~/system-info ~/vms
```

VM **disk images** live in libvirt's stock pool at `/var/lib/libvirt/images`, not under `$HOME`
([05-hypervisor.md](05-hypervisor.md) §4). `~/vms/` holds only the text that describes them.

Large downloaded model files are replaceable, so decide whether they are worth including in backups.

Agent-driven project work happens inside the VM, not here (specification §8). The host keeps this
repo and the local-model work.

## 3. Backups

Current host decision (September 10, 2026): defer host backups. Do not configure a backup service or
destination during this setup. The guidance below is for later.

Configure Linux backups before moving the only copy of important data to Kubuntu.

Prioritize:

```text
~/Documents
~/Dropbox               # if not treated as already-replicated
~/projects
~/.ssh
~/vms                   # domain XML and share definitions; small, and painful to rebuild
important application configuration
recovery material
```

Large GGUF model downloads can usually be excluded because they are reproducible downloads.

VM disk images are backed up separately as live copies under `~/backup/vm/` plus live snapshots, see
[`../vm/07-snapshots.md`](../vm/07-snapshots.md).

## 4. Flatpak and Snap

- Flatpak: <https://flatpak.org/>
- Flathub: <https://flathub.org/>

A useful packaging rule is:

```text
System/development components → apt
Desktop applications          → apt, Snap, or Flatpak
GPU/ROCm compute stack        → AMD-supported instructions
```

Prefer Snap or Flatpak when the Ubuntu package lags and the app should follow its own release
cadence. Snap refreshes itself; Flatpak uses the user timer in
[`../common/08-auto-updates.md`](../common/08-auto-updates.md) §2. Kubuntu/Ubuntu already ships
snapd. There is no need to remove it preemptively.

Avoid mixing packaging systems for low-level GPU components without a reason.

## 5. SSH

Client:

```bash
sudo apt install -y openssh-client
```

Only install the server if the laptop needs to accept incoming SSH connections:

```bash
sudo apt install -y openssh-server
systemctl status ssh
```

Before installing the server, have at least one approved public key ready and confirm that a local
console or other recovery route works. After installation but before changing the server, inventory
the current firewall, interfaces, listeners, Tailscale state, SSH drop-ins, effective configuration,
and host-key fingerprints. Save the latter two:

```bash
sudo sshd -T > ~/sshd-effective-before-hardening.txt
for key in /etc/ssh/ssh_host_*_key.pub; do ssh-keygen -lf "$key"; done \
  > ~/ssh-host-key-fingerprints.txt
sudo ufw status verbose
ip -brief address
tailscale status
```

Each approved administration client must use its own dedicated, passphrase-protected Ed25519 key.
Keep the private key on that client and install only its public key in the target user's
`~/.ssh/authorized_keys`. Bind a device-specific key to the client's exact Tailscale IPv4 address;
the resulting line has this form:

```text
from="CLIENT_TAILSCALE_IPV4",no-agent-forwarding,no-X11-forwarding ssh-ed25519 PUBLIC_KEY COMMENT
```

Lived names, IPv4 addresses, `from=` lines, and current sshd/UFW for Dave's machines are in
`~/projects/infra/tailscale/ssh.md`. This section is the reusable procedure.

Substitute the measured address and complete public-key line; never install the placeholders. Do not
add `restrict`, `command=`, `no-port-forwarding`, or `no-pty`, because interactive shells and IDE
SSH tunnels require those capabilities. Keep the current session or a local recovery console open,
then prove that a fresh public-key connection works with IPv4 selected and password fallback
disabled:

```bash
ssh -4 -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no USER@TAILSCALE_NAME
```

Do not expose port 22 through the router or permit password, keyboard-interactive, or root login.

Only after that succeeds, create `/etc/ssh/sshd_config.d/90-tailnet-key-only.conf`:

```text
PubkeyAuthentication yes
PasswordAuthentication no
KbdInteractiveAuthentication no
AuthenticationMethods publickey
PermitRootLogin no
PermitEmptyPasswords no
```

Inspect `sudo sshd -T` for settings overridden by vendor or cloud-init drop-ins. Validate before
reloading; a failed validation must leave the running server untouched:

```bash
sudo sshd -t
sudo systemctl reload ssh
```

Restrict inbound port 22 to `tailscale0` with the host firewall. Check existing firewall rules and
defaults before enabling or changing it; preserve any rules needed by the host. The resulting policy
must allow TCP/22 on `tailscale0` and deny TCP/22 on LAN, Wi-Fi, and public interfaces. Tailscale
Funnel and router port forwarding are not used for SSH.

The live access policy and device-specific SSH grant remain in the
[`infra/tailscale`](https://github.com/dxmann73/infra/tree/main/tailscale) documentation. A narrow
grant is not effective while a broader allow rule also permits TCP/22, so include both permit and
deny policy tests there.

From the approved client, open another new connection after both SSH and firewall changes. Keep the
original session open until this final test passes.

The host's `~/.ssh` is never shared into the VM. Agents get their own purpose-specific keys, see
[`../vm/05-credentials.md`](../vm/05-credentials.md) (specification §12).

If you migrate existing private SSH keys, preserve their permissions: `~/.ssh` at `700`, private
keys at `600`. OpenSSH silently skips a private key that others can read
(`Permissions 0644 for '~/.ssh/id_rsa' are too open. This private key will be ignored.`), which only
shows up in `ssh -v`. Generating a machine-specific new key is often preferable.

```bash
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_* ~/.ssh/*.pem
chmod 644 ~/.ssh/*.pub
```

### One SSH agent

Kubuntu 26.04 starts up to three SSH agents in the user session: OpenSSH's `ssh-agent`
(`ssh-agent.socket`), GNOME's `gcr-ssh-agent`, and `gpg-agent`'s SSH socket. Whichever sets
`SSH_AUTH_SOCK` last wins. On this host that was gcr. It lists every key in `~/.ssh` that has a
`.pub` file next to it, but cannot unlock a passphrase-protected key under Plasma, so key logins
failed with

```text
sign_and_send_pubkey: signing failed for RSA "/home/dave/.ssh/id_rsa" from agent: agent refused operation
```

and SSH fell back to password authentication, with `ksshaskpass` filling the password from KWallet.
It looked passwordless; `ssh -v` showed `Authenticated … using "password"`.

Use one agent — OpenSSH's, with `ksshaskpass` and KWallet — and switch gcr off:

```bash
systemctl --user mask --now gcr-ssh-agent.socket gcr-ssh-agent.service
systemctl --user set-environment SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/openssh_agent"
```

The second line matters because lingering is on (`loginctl show-user "$USER" -p Linger`): the
systemd user manager survives a logout and keeps gcr's dead socket path in its environment, so the
next login would inherit it. After a reboot, `ssh-agent.socket` sets the variable itself.

`~/.ssh/config`, mode `600`:

```text
Host *
    AddKeysToAgent yes
```

Log out and back in. The first `ssh` of a session asks for the key passphrase through `ksshaskpass`;
tick **Remember** and KWallet supplies it from then on, while the agent holds the key until logout.
If the dialog asks for a remote _password_ instead of the key passphrase, the key is still not being
used.

`gpg-agent`'s SSH socket only claims `SSH_AUTH_SOCK` when `enable-ssh-support` is set in
`~/.gnupg/gpg-agent.conf`; leave it unset. The `/etc/X11/Xsession.d` agent scripts do not run in the
Plasma Wayland session.

Verify:

```bash
echo "$SSH_AUTH_SOCK"                                     # …/openssh_agent
ssh-add -l                                                # the key, after the first ssh
ssh -v xmg-evo-agent-vm true 2>&1 | grep Authenticated    # … using "publickey"
```

## 6. Firewall

This is a laptop that joins networks you do not control, so the firewall is on. Not a preference:

```bash
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw enable
sudo ufw status verbose
```

`ufw enable` survives reboots. libvirt installs its own rules for the guest network in separate
chains, so the NAT bridge keeps working with the firewall up.

The local model server binds to the libvirt bridge `virbr0` rather than `0.0.0.0`, so the VM can
reach inference while the LAN cannot. Rules for that interface are in
[`../vm/03-networking.md`](../vm/03-networking.md).

## 7. System checklist

- [ ] directory layout created
- [ ] backups configured and restore tested, including `~/vms` and `/var/lib/libvirt/images`
- [ ] packaging rule understood
- [ ] SSH client/server state decided
- [ ] if the SSH server is enabled, an approved client's device-bound key-only login works and
      password fallback fails
- [ ] inbound SSH is allowed on `tailscale0` only; there is no router forward or Funnel
- [ ] `~/.ssh` at `700`, private keys at `600`
- [ ] one SSH agent: gcr masked, `SSH_AUTH_SOCK` on `openssh_agent`, `ssh -v` shows `publickey`
- [ ] `ufw` enabled, default deny incoming
- [ ] unattended security updates active
      ([`../common/08-auto-updates.md`](../common/08-auto-updates.md))
- [ ] local model endpoint not exposed to the LAN
- [ ] `prepare-host-system.sh` completes with no VM creation and no host `NOPASSWD` sudo rule

Next: [04-dev-and-agents.md](04-dev-and-agents.md)
