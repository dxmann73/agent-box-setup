# node-24 recipe

Run after `kubuntu-baseline` on every catalog-ticked daily host or agent VM. Chrome guests do not
receive Node.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/04-lang/node-24
sudo ./apply.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM. Apply installs Node.js 24 from NodeSource, then sets
the invoking user's npm prefix to `~/.npm-global`. It does not install JavaScript CLIs; their
separate modules own those packages.

## Verify

```bash
./verify.sh --target daily-host
```

Run the verifier as the normal desktop user. It checks the NodeSource source, Node 24, npm, and the
user-owned global npm prefix.
