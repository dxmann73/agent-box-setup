# github-cli

What: GitHub command-line tool.

Does: Installs Ubuntu's `gh` CLI on daily hosts and the agent VM. Authentication is deferred to the
`github-auth` credential module.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `sudo ./apply.sh --target daily-host|agent-vm`

Verify: `./verify.sh --target daily-host|agent-vm`
