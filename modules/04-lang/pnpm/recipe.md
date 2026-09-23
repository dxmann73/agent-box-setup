# pnpm recipe

Run after `node-24` on every catalog-ticked daily host or agent VM. This module deliberately uses
the user-owned npm prefix from `node-24`; it does not use a Corepack shim.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/04-lang/pnpm
./apply.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM. Apply installs pnpm globally for the normal user.

## Verify

```bash
./verify.sh --target daily-host
```

The verifier confirms the executable, version command, and global package registration.
