# wezterm

What: Terminal emulator.

Does: Installs WezTerm from its signed upstream apt repository and symlinks the managed user
configuration on daily hosts and the agent VM.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `sudo ./apply.sh --target daily-host|agent-vm`

Verify: `./verify.sh --target daily-host|agent-vm`
