# guest-ssh-sudo-bootstrap recipe

Run this inside a freshly installed Kubuntu guest, from the guest console, after its role module has
created the VM and the manual ISO install is complete. This module owns only the guest access
bootstrap:

- install and enable OpenSSH server;
- install approved public keys into the guest user's `authorized_keys`;
- make the guest user passwordless for sudo;
- harden sshd to public-key-only login.
- when `GUEST_BOOTSTRAP_HOST_IPV4` is set, allow SSH in UFW from that exact
  host bridge address.

It does not install guest integration packages, stream the agent baseline, clone repositories,
authenticate CLIs, join Tailscale, mount shares, or create snapshots.

Public keys are not stored in this repo. Prepare a temporary file inside the guest with one
`authorized_keys` line per approved key. Restrict the daily host's key to the exact libvirt bridge
gateway address:

```text
from="HOST_BRIDGE_IPV4",no-agent-forwarding,no-X11-forwarding ssh-ed25519 PUBLIC_KEY COMMENT
```

Use the key type already generated on the host. Measure `HOST_BRIDGE_IPV4` on the host with the
role's bridge, for example:

```bash
ip -4 addr show GUEST_BRIDGE_NAME
```

Do not authorize the whole guest subnet. Add other approved administration-client keys only through
their intended path and test each one before disabling password fallback.

## Apply

From the guest console:

```bash
cd ~/projects/agent-box-setup/modules/02-virt/guest-ssh-sudo-bootstrap
export GUEST_BOOTSTRAP_HOST_IPV4=HOST_BRIDGE_IPV4
./apply.sh --authorized-keys ~/bootstrap-authorized-keys
```

For a brand-new guest that does not yet have this checkout, copy this module into the guest through
the console clipboard, a temporary ISO, or another explicit operator-controlled path. Do not use
`ssh-copy-id`; it requires a guest password path that this module is trying to remove.

`apply.sh`:

- refuses to run as root or outside a virtualized guest;
- validates that the key file has public key material and no private key markers;
- installs `openssh-server`;
- writes `~/.ssh/authorized_keys` with mode `600` and directory mode `700`;
- writes `/etc/sudoers.d/agent-nopasswd` for the current guest user and validates it with
  `visudo`;
- installs the module's `90-key-only.conf` sshd drop-in;
- validates sshd configuration, enables ssh, and reloads it.
- when `GUEST_BOOTSTRAP_HOST_IPV4` is set, adds the exact source UFW rule for
  SSH. It does not enable UFW; `ufw-firewall` owns the baseline.
- uses interactive sudo from a console and non-interactive sudo over SSH, so
  host-streamed reruns do not require a guest console TTY.

## Verify

Inside the guest:

```bash
./verify.sh
```

Optional checks:

```bash
export GUEST_BOOTSTRAP_HOSTNAME=...
export GUEST_BOOTSTRAP_HOST_IPV4=...
./verify.sh
```

`GUEST_BOOTSTRAP_HOSTNAME` checks the current hostname. If omitted, `verify.sh` also accepts
`AGENT_BOX_VM_HOSTNAME` for compatibility with the agent VM overlay environment.
`GUEST_BOOTSTRAP_HOST_IPV4` checks that at least one authorized key is restricted with
`from="..."` for the host bridge address, has agent and X11 forwarding disabled, and that UFW
allows SSH from the same address.

From the host, also prove the remote boundary before continuing:

```bash
ssh "$GUEST_BOOTSTRAP_HOSTNAME" hostname
ssh "$GUEST_BOOTSTRAP_HOSTNAME" 'sudo -n true && echo guest-sudo-ready'
```

If name resolution is not ready, use the guest address from:

```bash
virsh domifaddr VM_NAME --source lease
```

## Next Steps

For the agent VM, run the ticked guest modules only after this verify passes. For the browser guest,
run the browser package module instead; do not apply agent-only modules.

This module owns the SSH service exception. `ufw-firewall` owns UFW's baseline
policy; other guest services own their own exceptions.

## Simplification Candidates

- `ssh-server` and this module now share the same key-only sshd policy shape. Consider moving the
  drop-in and effective-configuration assertions to a common helper when cutover starts.
- The catalog runner deliberately keeps this boundary verifier separate from later guest modules.
