# ssh-client recipe

Run this module after `kubuntu-baseline` on every box that initiates SSH sessions. The Chrome VM
does not tick it.

This module is the one-agent + askpass configuration, not the `openssh-client` package. Apply fails
if `ssh`, `ssh-add`, or `ksshaskpass` is missing.

## Why one agent

Kubuntu starts up to three SSH agents in the user session: OpenSSH's `ssh-agent`
(`ssh-agent.socket`), GNOME's `gcr-ssh-agent`, and `gpg-agent`'s SSH socket. Whichever sets
`SSH_AUTH_SOCK` last wins. When gcr wins, it offers every key in `~/.ssh` that has a `.pub` file
next to it but cannot unlock a passphrase-protected key under Plasma:

```text
sign_and_send_pubkey: signing failed for RSA from agent: agent refused operation
```

SSH then falls back to password authentication, with `ksshaskpass` filling the password from
KWallet. It looks passwordless; `ssh -v` shows `Authenticated … using "password"`.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/00-os/ssh-client
./apply.sh
```

Apply runs as the normal desktop user, not under `sudo`. It:

- creates `~/.ssh` at `700` and corrects private key (`600`) and public key (`644`) modes
- appends a `Host *` / `AddKeysToAgent yes` block to `~/.ssh/config` at `600` when absent
- masks `gcr-ssh-agent.socket` and `gcr-ssh-agent.service`
- enables `ssh-agent.socket` and points `SSH_AUTH_SOCK` at `$XDG_RUNTIME_DIR/openssh_agent`

`ssh-agent.socket` exports `SSH_AUTH_SOCK` itself on start, and `plasma-workspace` ships
`/etc/xdg/plasma-workspace/env/ksshaskpass.sh`, which exports `SSH_ASKPASS` and
`SSH_ASKPASS_REQUIRE=prefer` into the session. Apply asserts that script instead of duplicating it,
and fails if it is missing. The explicit `systemctl --user set-environment` matters because
lingering is on (`loginctl show-user "$USER" -p Linger`): the systemd user manager survives a
logout and would keep gcr's dead socket path in its environment.

Apply stops if `enable-ssh-support` is set in `~/.gnupg/gpg-agent.conf`. Remove that line by hand
and rerun; this module does not edit GnuPG configuration. The `/etc/X11/Xsession.d` agent scripts do
not run in the Plasma Wayland session, so they are not a factor.

Log out and back in after apply. The first `ssh` of a session asks for the key passphrase through
`ksshaskpass`; tick **Remember** and KWallet supplies it from then on, while the agent holds the key
until logout. If the dialog asks for a remote _password_ instead of the key passphrase, the key is
still not being used.

Keys themselves are not created here. Each approved administration client uses its own dedicated,
passphrase-protected Ed25519 key; `github-auth` and the other `06-cred` modules own key material.
The host's `~/.ssh` is never shared into a guest.

## Verify

```bash
./verify.sh
```

Checks read the systemd user manager environment, which is what the session actually uses. Add the
current shell's own variables after a fresh login:

```bash
./verify.sh --check-shell
```

Prove a real key login against a reachable host that already trusts this client's public key:

```bash
./verify.sh --remote VM_NAME
```

That check runs `ssh -v VM_NAME true` and requires `Authenticated … using "publickey"`.
