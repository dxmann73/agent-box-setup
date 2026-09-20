# kubuntu-baseline

What: Shared Kubuntu baseline configuration.

Does: Installs the minimum OS packages, update policy, locale support, wallet support, and
host-or-guest desktop/session policy after the Kubuntu installer.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `sudo ./apply.sh --target daily-host|guest`

Verify: `./verify.sh --target daily-host|guest`
