# ripgrep

What: Fast recursive search tool.

Does: Installs Ubuntu's `ripgrep`, which provides `rg` for codebase and documentation search on
daily hosts and the agent VM.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `sudo ./apply.sh --target daily-host|agent-vm`

Verify: `./verify.sh --target daily-host|agent-vm`
