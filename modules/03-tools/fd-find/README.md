# fd-find

What: Fast file finder.

Does: Installs Ubuntu's `fd-find`, which intentionally provides `fdfind` rather than `fd`, for fast
path discovery on daily hosts and the agent VM.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `sudo ./apply.sh --target daily-host|agent-vm`

Verify: `./verify.sh --target daily-host|agent-vm`
