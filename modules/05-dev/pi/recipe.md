# pi recipe

Run after `node-24` on every catalog-ticked daily host or agent VM. This installs Pi without its
post-install scripts and does not open its login flow. The `pi-login` module owns authentication;
`agent-config` links global instructions and the shared skills index.

```bash
./apply.sh --target daily-host
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM.
