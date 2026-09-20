# host-sudo-session recipe

Run this on daily hosts before rootful module work that will perform many `sudo` operations.

```bash
cd ~/projects/agent-box-setup/modules/00-os/host-sudo-session
./keepalive.sh
```

Keep that terminal open while setup continues in another terminal or agent session. The helper asks
for the normal user sudo password once, then refreshes the timestamp with `sudo -n -v` until it is
stopped.

Do not add a host `NOPASSWD` sudoers rule. Guest passwordless sudo belongs only to
`guest-ssh-sudo-bootstrap`.

Verify the babysit terminal from another shell:

```bash
./verify.sh --terminal-id TERM_ID
```

Use `--require-active` only when checking the current shell. Sudo timestamps are usually scoped to
the terminal, so a BB side terminal does not make `sudo -n` pass in another shell.
