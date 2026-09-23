# github-cli recipe

Run after `kubuntu-baseline` on every catalog-ticked daily host or agent VM. Chrome guests do not
receive this module.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/03-tools/github-cli
sudo ./apply.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM. The script installs Ubuntu's `gh` package but never
opens a browser or writes credentials.

## Verify

```bash
./verify.sh --target daily-host
```

This is an installation check. Run the later `github-auth` module to authenticate, then verify that
credential stage with `gh auth status`.
