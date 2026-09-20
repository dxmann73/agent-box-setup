# ssh-server recipe

Run this module on any box that accepts incoming SSH: `xhost`, `bhost`, agent VMs, and `chrome-vm`.
`kubuntu-baseline` and `host-sudo-session` (on daily hosts) run first.

This module is the key-only sshd configuration, not `authorized_keys` material. Key placement lives
in `06-cred/setup-agent-login`, `06-cred/github-auth`, and the guest-side bootstrap in
`machines/vm/01-bootstrap.md`. The `from=` source restrictions and Tailscale grants live in
`~/projects/infra/tailscale/ssh.md`.

## Trust map

| Client               | Target             | Path                        | `from=` on target             |
| -------------------- | ------------------ | --------------------------- | ----------------------------- |
| `xhost`              | `xagt`             | libvirt bridge `virbr0`     | `from="192.168.122.1"`        |
| `xhost`              | `xchr`             | libvirt bridge `virbr0`     | `from="192.168.122.1"`        |
| `blade-14` (Windows) | `xhost`            | Tailscale MagicDNS          | `from="BLADE14_TS_IPV4"`      |
| `blade-14` (Windows) | `xagt`             | Tailscale MagicDNS          | `from="BLADE14_TS_IPV4"`      |
| `xhost`, `xagt`      | GitHub             | Internet                    | n/a                           |

`xchr` has no `ssh-client` and initiates no SSH. `xagt` initiates only to GitHub over Tailscale, not
back to `xhost`. Live `from=` values live in `~/projects/infra/tailscale/ssh.md`.

## What apply does

- `sudo apt install -y openssh-server`.
- Aborts if `/etc/ssh/sshd_config.d/50-cloud-init.conf` sets `PasswordAuthentication`,
  `KbdInteractiveAuthentication`, or `ChallengeResponseAuthentication`. sshd applies the first value
  seen; cloud-init at `50-` would beat our `10-` drop-in. Remove those lines from cloud-init and
  rerun. Do not silently rewrite cloud-init state.
- Snapshots the pre-change effective config to
  `~/system-info/sshd-effective-before-hardening.txt` and the host-key fingerprints to
  `~/system-info/ssh-host-key-fingerprints.txt`. Existing snapshots are preserved. `~/system-info`
  is created by `kubuntu-baseline` on both daily hosts and guests.
- Writes `/etc/ssh/sshd_config.d/10-key-only.conf` at `0644` root:root with:

  ```text
  PubkeyAuthentication yes
  PasswordAuthentication no
  KbdInteractiveAuthentication no
  AuthenticationMethods publickey
  PermitRootLogin no
  PermitEmptyPasswords no
  ```

  Any legacy `90-key-only.conf` from earlier runs is removed.

- Runs `sudo sshd -t`. On failure the drop-in is removed and the running server is untouched.
- Runs `sudo sshd -T` and asserts every one of the six keywords resolves to the expected value.
  Fails hard (and removes the drop-in) if any Match block or later drop-in overrides them.
- Reloads sshd if it is already active. Does not enable or start sshd on its own.

## Lockout safety

Apply refuses to reload a running sshd unless the invoking user has at least one line in
`~/.ssh/authorized_keys`, or `--i-have-a-key` is passed. Enabling sshd for the first time is an
explicit operator step after a public-key login is proven:

```bash
ssh -4 -o PasswordAuthentication=no -o KbdInteractiveAuthentication=no USER@HOST
sudo systemctl enable --now ssh
```

Keep the original session open until a second fresh public-key session succeeds.

Do not add `restrict`, `command=`, `no-port-forwarding`, or `no-pty`: interactive shells and IDE SSH
tunnels need those.

Do not forward TCP/22 on the router.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/00-os/ssh-server
./apply.sh
```

## Verify

```bash
./verify.sh
```

`--require-active` also requires the sshd unit to be running. Use it on guests and on any host that
has finished enabling sshd.
