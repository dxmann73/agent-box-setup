# firecrawl-cli recipe

Run after `node-24` on every catalog-ticked daily host or agent VM. Installation is credential-free;
the later `firecrawl-login` module owns API-key setup.

## Apply

```bash
cd ~/projects/agent-box-setup/modules/04-lang/firecrawl-cli
./apply.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM. Apply installs the `firecrawl-cli` npm package for the
normal user and does not invoke login.

## Verify

```bash
./verify.sh --target daily-host
```

The verifier checks package registration and the unauthenticated CLI version command. Run
`firecrawl-login` separately before checking authentication status.
