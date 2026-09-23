# vm-snapshots

What: Guest snapshot policy.

Does: Tracks rollback snapshots for whichever guest roles the profile owns.

Catalog metadata: see [Modular machine catalog](../../README.md) for typ, sit, scp, requires, and
ticks.

Recipe: [recipe.md](recipe.md)

Apply: `./apply.sh --domain DOMAIN --name SNAPSHOT --mode live|offline`

Verify: `./verify.sh --domain DOMAIN --snapshot SNAPSHOT --mode live|offline`
