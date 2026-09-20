# home-dotfiles recipe

Run this after the repo is cloned so the managed shell dotfiles replace the ones
Kubuntu creates on first login. Ticked on `xhost`, `xagt`, `bhost`; not on `xchr`.

The agent VM (`xagt`) currently receives the same symlinks from
[`machines/vm/guest-baseline.sh`](../../../machines/vm/guest-baseline.sh) during
the host-streamed guest baseline. After the module cutover phase this module
becomes the single source of truth on both host and guest.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/01-home/home-dotfiles
./apply.sh
```

`apply.sh` is idempotent:

- If the target is already a symlink, it is refreshed (`ln -sfn`) so a stale
  target is repointed at the repo payload.
- If the target is a regular file, it is moved into
  `~/.agent-box-setup-backup/` before the symlink is created.
- If the target does not exist, the symlink is created.

## What it links

Every link points into `~/projects/agent-box-setup/user-home/`:

- `~/.bashrc`
- `~/.bash_aliases`
- `~/.profile`
- `~/ua.sh`
- `~/update-tools.sh`

## What it deliberately does not touch

- `~/.bash_secrets` — populated in the login stage (`firecrawl-login`, etc.).
- `~/projects/.markdownlint.json` — owned by the `markdownlint` module.
- `~/.gitconfig` — Dave overlay in `dave.box-setup/agent-box/user-home/.gitconfig`.
- `wezterm/`, `vscode/`, `systemd/`, `pi-launch.sh`, `klipper-clipboard-sync.sh`
  — payloads owned by `wezterm`, `vscode`, `update-tools-timer`,
  `cursor-agent-launcher` / `pi`, and `guest-integration` respectively.

## Verify

```bash
./verify.sh
```

Checks each managed target is a symlink whose resolved path is the matching
file under the repo's `user-home/`.

After a shell restart, `. ~/.bashrc` should still load without error and
`type ll` should resolve to the alias.
