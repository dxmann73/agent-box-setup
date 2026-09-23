# build-essential recipe

Run after `kubuntu-baseline` on every catalog-ticked daily host or agent VM. Chrome guests do not
receive this module.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/03-tools/build-essential
sudo ./apply.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM. The script refreshes apt metadata and installs only
Ubuntu's `build-essential` meta-package.

## Verify

```bash
./verify.sh --target daily-host
```

The verifier checks the package and that both `gcc` and `make` run.
