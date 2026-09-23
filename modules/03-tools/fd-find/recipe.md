# fd-find recipe

Run after `kubuntu-baseline` on every catalog-ticked daily host or agent VM. Chrome guests do not
receive this module.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/03-tools/fd-find
sudo ./apply.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM. Ubuntu calls the executable `fdfind` to avoid a
collision with another package. This module deliberately does not add an `fd` alias or a system-wide
symlink.

## Verify

```bash
./verify.sh --target daily-host
```

The verifier checks the package, `fdfind` on PATH, and a temporary-file search.
