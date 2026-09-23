# virtiofs-desktop-share

What: Desktop share for browser guests.

Does: Attaches one narrow host Desktop virtiofs share to the Chrome VM role and mounts it as the
guest desktop.

Catalog metadata: see [Modular machine catalog](../../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh --host`, then `./apply.sh --guest`

Verify: `./verify.sh --host`, then `./verify.sh --guest`
