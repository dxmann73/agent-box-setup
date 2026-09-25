# firecrawl-login recipe

Run after `firecrawl-cli` on every catalog-ticked daily host or agent VM. Browser login stores that
target's API credential in its Firecrawl CLI home-state. Do not copy this state between targets.

```bash
cd ~/projects/agent-box-setup/modules/06-cred/firecrawl-login
./apply.sh --target daily-host
```

Complete the browser login without pasting the key into a terminal, command history, or repository.
Then verify the CLI session:

```bash
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the VM after `clean-guest`. Each target has its own Firecrawl
session; do not transfer it between host and guest.
