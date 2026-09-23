# wezterm recipe

Run after `kubuntu-baseline` and `home-dotfiles` on every catalog-ticked daily host or agent VM.
Chrome guests do not receive this module.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/03-tools/wezterm
sudo ./apply.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM. Apply requires the normal desktop user to invoke
`sudo`; it installs the signed WezTerm apt key and source, writes a module-owned unattended-upgrades
allow-list fragment, then links `user-home/wezterm/wezterm.lua` into that user's configuration.

Existing regular configurations are moved to `~/.agent-box-setup-backup/` before the symlink is
created. Existing symlinks are refreshed. `home-dotfiles` deliberately does not own this file.

## Verify

```bash
./verify.sh --target daily-host
```

Run as the normal desktop user. The verifier checks the package, executable, apt source,
unattended-upgrades fragment, and managed configuration link.
