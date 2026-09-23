# docker

What: Container runtime and tooling.

Does: Installs Ubuntu's Docker engine on the agent VM only and grants the desktop user access via
the root-equivalent `docker` group.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `sudo ./apply.sh --target agent-vm`

Verify: `./verify.sh --target agent-vm [--smoke]`
