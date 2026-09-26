# git-identity recipe

Run this module after `kubuntu-baseline` and `github-cli` on every box that commits: `xhost`,
`xagt`, `bhost`. The Chrome VM does not tick it.

The payload is the deployment overlay's `.gitconfig`. In this deployment that is
`~/projects/dave.box-setup/agent-box/user-home/.gitconfig`. Pass it with `--source`; the module has
no default path and fails fast if the file is missing or has no `[user]` section.

## Why a real file, not a symlink

`gh auth setup-git` and `git config --global` write to `~/.gitconfig`. When that path is a symlink
into a checked-out repository, those writes land in the repository's working tree, and the overlay
repository shows dirty on every re-auth. The agent VM previously had a dangling symlink into the
public repository, which produced a `~/.gitconfig` with credential helpers and no identity at all.

The overlay holds license keys and the agent VM runs agents in YOLO mode, so the overlay is not
cloned onto the guest. The host streams the file instead, like the guest baseline.

## Apply on the daily host

```bash
cd ~/projects/agent-box-setup/modules/00-os/git-identity
./apply.sh --target daily-host --source ~/projects/dave.box-setup/agent-box/user-home/.gitconfig
gh auth setup-git
```

An existing symlink at `~/.gitconfig` is removed. An existing regular file whose content differs is
moved into `~/.agent-box-setup-backup/` first. Re-running with unchanged content writes no backup.

## Apply to the agent VM

Run this on the daily host, not in the guest. It uses the libvirt-bridge SSH path, not Tailscale.

```bash
cd ~/projects/agent-box-setup/modules/00-os/git-identity
./apply.sh --target agent-vm \
  --source ~/projects/dave.box-setup/agent-box/user-home/.gitconfig \
  --vm-host xmg-evo-agent-vm
ssh xmg-evo-agent-vm 'gh auth setup-git'
```

The host key has a passphrase. `Permission denied (publickey)` under `-o BatchMode=yes` usually
means an empty agent: check `ssh-add -l`, then run `ssh-add </dev/null` so `ksshaskpass` and KWallet
load the key.

## Editor

`core.editor = nano` in the overlay `.gitconfig`, and `EDITOR=nano` in `user-home/.bashrc`. VS Code
terminals override both: `user-home/vscode/settings.json` sets `GIT_EDITOR` and `EDITOR` to
`code --wait` in `terminal.integrated.env.linux`, and `GIT_EDITOR` wins over `core.editor`.

The reason is that `code` exists only inside a VS Code terminal. With `code --wait` as the global
editor, `git commit` without `-m` fails in a BB thread or a plain SSH session.

## Verify

```bash
./verify.sh --target daily-host
ssh xmg-evo-agent-vm '~/projects/agent-box-setup/modules/00-os/git-identity/verify.sh --target agent-vm'
```

Checks `~/.gitconfig` is a regular file, `user.name` and `user.email` resolve, `core.editor` is
`nano`, and the `https://github.com` credential helper is `gh auth git-credential`.

## Boundaries

- In: `~/.gitconfig` on host and agent VM, and its identity, editor, and helper checks.
- Out: shell dotfiles (`home-dotfiles`), the `gh` package and login (`github-cli`, `github-auth`),
  SSH keys (`ssh-client`, `06-cred`), VS Code settings payload (`vscode`).
