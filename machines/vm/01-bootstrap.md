# 01 – VM bootstrap

The guest console performs only the bootstrap needed to let the completed host manage the VM
remotely. Everything else is the credential-free host-invoked baseline in
[`guest-baseline.sh`](guest-baseline.sh).

## 1. Console bootstrap

At the guest console, install SSH, add the physical host key and any approved administration client
public keys, and configure passwordless sudo for the guest user only:

```bash
sudo apt update
sudo apt install -y openssh-server
mkdir -p ~/.ssh && chmod 700 ~/.ssh
# Add one public key per line. Never copy a private key into the guest.
nano ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
sudo visudo -f /etc/sudoers.d/agent-nopasswd
```

Restrict the physical host's key to the exact libvirt bridge source while preserving interactive
shells, forwarding, and sudo automation:

```text
from="HYPERVISOR_BRIDGE_IPV4",no-agent-forwarding,no-X11-forwarding ssh-ed25519 PUBLIC_KEY COMMENT
```

Use the key type already generated on the host; `ssh-ed25519` is illustrative. Measure the bridge
address with `ip -4 addr show virbr0` on the host and replace every placeholder. Do not authorize
the whole libvirt subnet.

The sudoers file must contain exactly this policy, substituting the guest user name:

```text
YOUR_USER_NAME ALL=(ALL) NOPASSWD: ALL
```

Do not add a matching rule on the personal host. Host sudo stays password-protected.

## 2. Verify the remote boundary

From the host, verify key authentication and non-interactive guest sudo before proceeding:

```bash
ssh "$AGENT_BOX_VM_HOSTNAME" hostname
ssh "$AGENT_BOX_VM_HOSTNAME" 'sudo -n true && echo guest-sudo-ready'
```

If hostname resolution is not ready yet, use the guest's libvirt address from
`virsh domifaddr VM_NAME --source lease` instead. Do not use `ssh-copy-id`: it needs a guest
password and is unnecessary once the key is placed in `authorized_keys`.

Before disabling SSH passwords, test each approved key in a second session through its intended
path. Follow the key-only SSH configuration and lockout-safe validation sequence in
[`../host/03-system-config.md`](../host/03-system-config.md) §5. The guest firewall permits TCP/22
from only the physical host's libvirt bridge address on the private guest interface. The host
retains direct libvirt SSH and console recovery paths. Remote clients may use Tailscale; this box's
`from=` lines live in `~/projects/infra/tailscale/ssh.md`. Complete the libvirt exception in
[03-networking.md](03-networking.md) §4.

## 3. Run the guest baseline from the host

The script is streamed from the host so a fresh guest does not need GitHub authentication or an
existing repository checkout. It clones the public setup repository itself and then configures
packages, dotfiles, four agent CLIs without login, Playwright, guest agents, and guest desktop
defaults.

```bash
cd ~/projects/agent-box-setup
ssh "$AGENT_BOX_VM_HOSTNAME" \
  "AGENT_BOX_VM_HOSTNAME='$AGENT_BOX_VM_HOSTNAME' bash -s" \
  < machines/vm/guest-baseline.sh
```

The script refuses to run outside a virtualized guest, with the wrong hostname, or without guest
`NOPASSWD` sudo. Re-running it is safe: package installation, links, service enablement, and managed
desktop settings converge on the same state. Managed desktop settings include disabled display
blanking, disabled screen locking, automatic login, and disabling the top-left Plasma hot corner
that opens the overview/all-windows effect.

It deliberately does not authenticate GitHub, Claude, Codex, Cursor, Pi, Firecrawl, model providers,
or configure host shares/network exposure. Those are later, explicit phases.

## 4. Verify and snapshot

```bash
ssh -t "$AGENT_BOX_VM_HOSTNAME" \
  'cd ~/projects/agent-box-setup && ./verify-setup.sh --vm --bootstrap'
```

Once this profile passes, take the credential-free `clean-guest` snapshot as described in
[07-snapshots.md](07-snapshots.md). Then continue to the optional or credentialed phases
deliberately.

## Checklist

- [ ] guest hostname is `VM_NAME`
- [ ] host public key works over SSH
- [ ] approved client public keys work with password fallback disabled
- [ ] SSH passwords, keyboard-interactive authentication, and root login are disabled
- [ ] guest port 22 is reachable through the single-host libvirt exception only
- [ ] only the guest user has passwordless sudo
- [ ] host-driven baseline finishes without provider or GitHub login
- [ ] SSH, QEMU guest agent, autologin, disabled blanking, disabled locking, and disabled top-left
      hot corner work
- [ ] toolchain, four agent CLIs, and Playwright Chromium are installed
- [ ] `./verify-setup.sh --vm --bootstrap` passes before `clean-guest` is taken

Next: [02-dev-and-agents.md](02-dev-and-agents.md) for review and later optional tooling, or
[05-credentials.md](05-credentials.md) when credentials are explicitly wanted.
