# vibe-typer

What: Deployment-owned VibeTyper host AppImage.

Does: Wires a reviewed manual AppImage to the deployment-owned launcher, desktop entry, and weekly
update reminder. It never downloads or replaces the AppImage unattended.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh --overlay /absolute/path/to/identity`

Verify: `./verify.sh --overlay /absolute/path/to/identity`
