# 01 – VM bootstrap

The guest console performs only the bootstrap needed to let the completed host
manage the VM remotely. Everything else is the credential-free host-invoked
baseline in [`guest-baseline.sh`](guest-baseline.sh).

## 1. Console bootstrap

At the guest console, install SSH, add the host public key, and configure
passwordless sudo for the guest user only:

```bash
sudo apt update
sudo apt install -y openssh-server
mkdir -p ~/.ssh && chmod 700 ~/.ssh
# Paste the public key from the host's ~/.ssh/*.pub file into this file.
nano ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
sudo visudo -f /etc/sudoers.d/agent-nopasswd
```

The sudoers file must contain exactly this policy, substituting the guest user
name:

```text
YOUR_USER_NAME ALL=(ALL) NOPASSWD: ALL
```

Do not add a matching rule on the personal host. The VM is the unrestricted
agent boundary; the host remains supervised.

## 2. Verify the remote boundary

From the host, verify key authentication and non-interactive guest sudo before
proceeding:

```bash
ssh xmg-evo-agent-vm hostname
ssh xmg-evo-agent-vm 'sudo -n true && echo guest-sudo-ready'
```

If hostname resolution is not ready yet, use the guest's libvirt address from
`virsh domifaddr xmg-evo-agent-vm --source lease` instead. Do not use
`ssh-copy-id`: it needs a guest password and is unnecessary once the key is
placed in `authorized_keys`.

## 3. Run the guest baseline from the host

The script is streamed from the host so a fresh guest does not need GitHub
authentication or an existing repository checkout. It clones the public setup
repository itself and then configures packages, locales, dotfiles, four agent
CLIs without login, Playwright, the BB service, guest agents, and guest desktop
defaults.

```bash
cd ~/projects/agent-box-setup
ssh xmg-evo-agent-vm 'bash -s' < machines/vm/guest-baseline.sh
```

The script refuses to run outside a virtualized guest, with the wrong hostname,
or without guest `NOPASSWD` sudo. Re-running it is safe: package installation,
links, service enablement, and managed desktop settings converge on the same
state.

It deliberately does not authenticate GitHub, Claude, Codex, Cursor, Pi,
Firecrawl, Tailscale, model providers, or configure host shares/network
exposure. Those are later, explicit phases.

## 4. Verify and snapshot

```bash
ssh -t xmg-evo-agent-vm \
  'cd ~/projects/agent-box-setup && ./verify-setup.sh --vm --bootstrap'
```

Once this profile passes, take the credential-free `clean-guest` snapshot as
described in [07-snapshots.md](07-snapshots.md). Then continue to the optional
or credentialed phases deliberately.

## Checklist

- [ ] guest hostname is `xmg-evo-agent-vm`
- [ ] host public key works over SSH
- [ ] only the guest user has passwordless sudo
- [ ] host-driven baseline finishes without provider or GitHub login
- [ ] SSH, QEMU guest agent, autologin, disabled blanking, and disabled locking work
- [ ] toolchain, four agent CLIs, Playwright Chromium, and BB service are installed
- [ ] `./verify-setup.sh --vm --bootstrap` passes before `clean-guest` is taken

Next: [02-dev-and-agents.md](02-dev-and-agents.md) for review and later optional tooling, or
[05-credentials.md](05-credentials.md) when credentials are explicitly wanted.
