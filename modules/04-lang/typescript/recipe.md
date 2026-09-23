# typescript recipe

Run after `node-24` on every catalog-ticked daily host or agent VM. This module owns the global
`typescript` and `ts-node` packages only.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/04-lang/typescript
./apply.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM. Apply writes only to the normal user's npm prefix.

## Verify

```bash
./verify.sh --target daily-host
```

The verifier checks both CLIs, their version commands, and global package registration.
