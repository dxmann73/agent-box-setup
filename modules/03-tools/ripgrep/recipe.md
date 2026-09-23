# ripgrep recipe

Run after `kubuntu-baseline` on every catalog-ticked daily host or agent VM. Chrome guests do not
receive this module.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/03-tools/ripgrep
sudo ./apply.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM. The script installs Ubuntu's `ripgrep` package.

## Verify

```bash
./verify.sh --target daily-host
```

The verifier checks the package, `rg` on PATH, and a direct search.
