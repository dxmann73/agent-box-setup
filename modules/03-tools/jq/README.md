# jq

What: JSON command-line tool.

Does: Installs Ubuntu's `jq` for JSON querying and transformation on daily hosts and the agent VM.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `sudo ./apply.sh --target daily-host|agent-vm`

Verify: `./verify.sh --target daily-host|agent-vm`
